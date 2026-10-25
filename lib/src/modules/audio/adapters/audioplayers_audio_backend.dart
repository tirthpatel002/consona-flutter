import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../assets/synth/sound_recipe.dart';
import '../engine/audio_engine.dart';
import 'io_support.dart';

/// Production [AudioBackend] backed by `audioplayers`.
///
/// Design contract:
/// - [load] writes bytes once and calls setSource — may take a moment.
/// - [play] calls resume() (fast path) or play(source) (cold path). Never
///   re-binds while playing or paused — that would emit spurious stop events.
/// - [pause] calls player.pause() immediately, then fires onStatus. Fast.
/// - Status truth comes from the stream listener ONLY — no duplicate emits.
class AudioplayersAudioBackend implements AudioBackend {
  AudioplayersAudioBackend({String? playerId})
      : _player = AudioPlayer(
          playerId:
              playerId ?? 'consona_${DateTime.now().microsecondsSinceEpoch}',
        );

  final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subs = [];

  void Function(Duration)? _onPosition;
  void Function(AudioPlaybackStatus)? _onStatus;
  void Function(Duration)? _onDuration;
  void Function(Duration)? _onBuffered;

  TempAudioDirectory? _dir;
  Source? _source;
  AudioTrack? _track;
  bool _ready = false;
  bool _looping = false;
  bool _mute = false; // suppress stream events during bind
  bool _playing =
      false; // owned play/pause state — timer uses this, not player.state
  Timer? _posTimer;

  // ── Attach ────────────────────────────────────────────────────────────────

  @override
  void attach({
    required void Function(Duration position) onPosition,
    required void Function(AudioPlaybackStatus status) onStatus,
    void Function(Duration duration)? onDuration,
    void Function(Duration buffered)? onBuffered,
    void Function(Object error)? onError,
  }) {
    _onPosition = onPosition;
    _onStatus = onStatus;
    _onDuration = onDuration;
    _onBuffered = onBuffered;
    // onError is unused — we never forward errors from this backend directly;
    // the engine receives status events only.

    _subs.addAll([
      _player.onPositionChanged.listen((pos) {
        if (_mute) return;
        _onPosition?.call(pos);
      }),
      _player.onDurationChanged.listen((dur) {
        if (dur <= Duration.zero) return;
        _onDuration?.call(dur);
        _onBuffered?.call(dur);
      }),
      _player.onPlayerStateChanged.listen((ps) {
        if (_mute) return;
        final s = _map(ps);
        if (s != null) _onStatus?.call(s);
        // Start timer when stream says playing; NEVER stop it from here —
        // our _playing flag is the source of truth for the pump.
        if (s == AudioPlaybackStatus.playing) {
          _startTimer();
        }
      }),
    ]);
  }

  AudioPlaybackStatus? _map(PlayerState ps) {
    return switch (ps) {
      PlayerState.playing => AudioPlaybackStatus.playing,
      PlayerState.paused => AudioPlaybackStatus.paused,
      // `stopped` fires after setSource / stop — treat as paused if loaded.
      PlayerState.stopped =>
        _track != null ? AudioPlaybackStatus.paused : AudioPlaybackStatus.idle,
      PlayerState.completed =>
        _looping ? AudioPlaybackStatus.playing : AudioPlaybackStatus.completed,
      PlayerState.disposed => null,
    };
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await AudioPlayer.global
          .ensureInitialized()
          .timeout(const Duration(seconds: 5));
      if (!kIsWeb && isMobilePlatform) {
        await AudioPlayer.global
            .setAudioContext(AudioContextConfig().build())
            .timeout(const Duration(seconds: 5));
      }
      await _player
          .setPlayerMode(PlayerMode.mediaPlayer)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('AudioplayersAudioBackend._ensureReady: $e (continuing)');
    }
    _ready = true;
  }

  Future<Source> _makeSource(AudioTrack track) async {
    if (track.url != null && track.url!.isNotEmpty) {
      final url = track.url!;
      if (url.startsWith('asset:')) {
        return AssetSource(url.replaceFirst('asset:', ''));
      }
      if (!kIsWeb && (url.startsWith('file://') || url.startsWith('/'))) {
        final path =
            url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
        return DeviceFileSource(path);
      }
      return UrlSource(url);
    }
    final bytes = track.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      final rawBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      if (kIsWeb) {
        return BytesSource(
          rawBytes,
          mimeType: 'audio/wav',
        );
      }
      final dir = _dir ??= await createTempAudioDirectory('consona_ap_');
      final filePath = await dir.writeTempFile('${track.id}.wav', rawBytes);
      return DeviceFileSource(filePath);
    }
    throw StateError('AudioTrack "${track.id}" has neither url nor bytes.');
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  @override
  Future<void> load(AudioTrack track) async {
    await _ensureReady();
    _track = track;

    // Suppress player state noise while binding.
    _mute = true;
    try {
      try {
        await _player.stop().timeout(const Duration(seconds: 2));
      } catch (_) {}

      final src = await _makeSource(track);
      _source = src;

      try {
        await _player.setSource(src).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint(
            'AudioplayersAudioBackend: setSource note: $e (will retry on play)');
      }

      try {
        await _player
            .setReleaseMode(_looping ? ReleaseMode.loop : ReleaseMode.stop)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      // Emit known duration immediately from track metadata.
      if (track.duration > Duration.zero) {
        _onDuration?.call(track.duration);
        _onBuffered?.call(track.duration);
      }
      // Try to get decoded duration (may be more accurate).
      try {
        final dur =
            await _player.getDuration().timeout(const Duration(seconds: 2));
        if (dur != null && dur > Duration.zero) {
          _onDuration?.call(dur);
          _onBuffered?.call(dur);
        }
      } catch (_) {}

      _onPosition?.call(Duration.zero);
    } finally {
      _mute = false;
    }

    // Tell engine we're ready.
    _onStatus?.call(AudioPlaybackStatus.paused);
  }

  // ── Play ──────────────────────────────────────────────────────────────────

  @override
  Future<void> play() async {
    await _ensureReady();

    if (_source == null && _track != null) {
      // Re-resolve source without full bind — just make the source object.
      try {
        _source = await _makeSource(_track!);
        await _player.setSource(_source!).timeout(const Duration(seconds: 8));
        await _player
            .setReleaseMode(_looping ? ReleaseMode.loop : ReleaseMode.stop)
            .timeout(const Duration(seconds: 2));
        _onPosition?.call(Duration.zero);
      } catch (e) {
        debugPrint('AudioplayersAudioBackend.play: source re-bind failed: $e');
      }
    }

    final src = _source;
    final ps = _player.state;

    // When track naturally finished, rewind before resume.
    if (ps == PlayerState.completed) {
      try {
        await _player.seek(Duration.zero).timeout(const Duration(seconds: 2));
        _onPosition?.call(Duration.zero);
      } catch (_) {}
    }

    // Mark ourselves as playing and start the pump immediately — don't wait
    // for the stream to fire `playing` (it may not re-fire if already playing).
    _playing = true;
    _startTimer();

    // Fast path: resume if already loaded and paused/stopped.
    try {
      await _player.resume().timeout(const Duration(seconds: 4));
      return; // stream listener will also fire playing — that's fine
    } catch (e) {
      debugPrint(
          'AudioplayersAudioBackend: resume failed ($e), trying play(src)');
    }

    // Cold path: full play(source).
    if (src != null) {
      try {
        await _player.play(src).timeout(const Duration(seconds: 8));
        return;
      } catch (e) {
        debugPrint('AudioplayersAudioBackend: play(src) failed: $e');
      }
    }

    // Both paths failed — stop the pump and tell engine we're paused.
    _playing = false;
    _stopTimer();
    _onStatus?.call(AudioPlaybackStatus.paused);
  }

  // ── Pause ─────────────────────────────────────────────────────────────────

  @override
  Future<void> pause() async {
    _playing = false;
    _stopTimer();
    try {
      await _player.pause().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('AudioplayersAudioBackend: pause note: $e');
      // Even if pause fails, ensure the engine knows we're paused.
      _onStatus?.call(AudioPlaybackStatus.paused);
    }
    // Status comes from the stream; only emit explicitly if stream is silent.
    // The stream will fire paused when _player.pause() completes.
  }

  // ── Seek ──────────────────────────────────────────────────────────────────

  @override
  Future<void> seek(Duration position) async {
    _onPosition?.call(position); // immediate UI update
    try {
      await _player.seek(position).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('AudioplayersAudioBackend: seek note: $e');
    }
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  @override
  Future<void> stop() async {
    _playing = false;
    _stopTimer();
    // If the player was never loaded, skip the native stop call — calling
    // _player.stop() on a brand-new, never-loaded AudioPlayer can stall for
    // seconds on iOS (waiting for AVPlayer to initialise before aborting).
    if (_source != null) {
      _mute = true;
      try {
        await _player.stop().timeout(const Duration(seconds: 3));
      } catch (_) {}
      _mute = false;
    }
    _onPosition?.call(Duration.zero);
    _onStatus?.call(AudioPlaybackStatus.idle);
  }

  // ── Rate / Volume / Looping ───────────────────────────────────────────────

  @override
  Future<void> setRate(double rate) async {
    try {
      await _player
          .setPlaybackRate(rate.clamp(0.5, 2.0))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    _mute = false; // not the same flag — just ensure not stuck
    try {
      await _player
          .setVolume(volume.clamp(0.0, 1.0))
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Future<void> setLooping(bool looping) async {
    _looping = looping;
    try {
      await _player
          .setReleaseMode(looping ? ReleaseMode.loop : ReleaseMode.stop)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  // ── Position timer ────────────────────────────────────────────────────────

  bool _pumpRunning = false;

  void _startTimer() {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      // Guard: if the previous getCurrentPosition() is still in flight, skip.
      // Without this, concurrent calls pile up on the platform channel when
      // the audio system is busy (e.g., recording is active), saturating the
      // method channel and freezing the entire app.
      if (!_playing || _pumpRunning) return;
      _pumpRunning = true;
      try {
        final pos = await _player
            .getCurrentPosition()
            .timeout(const Duration(milliseconds: 300));
        if (pos != null && _playing) _onPosition?.call(pos);
      } catch (_) {
      } finally {
        _pumpRunning = false;
      }
    });
  }

  void _stopTimer() {
    _posTimer?.cancel();
    _posTimer = null;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopTimer();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    unawaited(_player.dispose());
    _dir?.dispose();
    _dir = null;
  }
}

// ─── Demo tone ───────────────────────────────────────────────────────────────

Uint8List buildDemoToneWav({
  double frequency = 220.0,
  double durationMs = 2400.0,
  double gain = 0.22,
}) {
  final recipe = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: frequency,
    sweepTo: frequency * 1.5,
    durationMs: durationMs,
    gain: gain,
    envelope: const SoundEnvelope(
      attackMs: 40,
      decayMs: 180,
      sustain: 0.55,
      releaseMs: 320,
    ),
    harmonics: const [0.35, 0.12],
  );
  return recipe.toWav();
}
