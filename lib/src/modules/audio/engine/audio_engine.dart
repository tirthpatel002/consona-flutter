/// Consona AudioEngine — Reactive playback state machine and audio controller.
library;

import 'dart:async';

import 'package:flutter/painting.dart';

import '../../../core/engine.dart';
import '../../../core/event_bus.dart';

enum AudioPlaybackStatus {
  idle,
  playing,
  paused,
  completed,
  error,
}

class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.url,
    this.bytes,
    this.duration = Duration.zero,
    this.amplitudes = const [],
    this.artworkUrl,
    this.artwork,
  });

  final String id;
  final String title;
  final String? artist;
  final String? url;
  final List<int>? bytes;
  final Duration duration;
  final List<double> amplitudes;
  final String? artworkUrl;
  final ImageProvider? artwork;

  AudioTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? url,
    List<int>? bytes,
    Duration? duration,
    List<double>? amplitudes,
    String? artworkUrl,
    ImageProvider? artwork,
    bool clearArtist = false,
    bool clearUrl = false,
    bool clearBytes = false,
    bool clearArtworkUrl = false,
    bool clearArtwork = false,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: clearArtist ? null : (artist ?? this.artist),
      url: clearUrl ? null : (url ?? this.url),
      bytes: clearBytes ? null : (bytes ?? this.bytes),
      duration: duration ?? this.duration,
      amplitudes: amplitudes ?? this.amplitudes,
      artworkUrl: clearArtworkUrl ? null : (artworkUrl ?? this.artworkUrl),
      artwork: clearArtwork ? null : (artwork ?? this.artwork),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioTrack && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class AudioPlaybackState {
  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.playbackRate = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.isLooping = false,
    this.errorMessage,
  });

  final AudioPlaybackStatus status;
  final AudioTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final double playbackRate;
  final double volume;
  final bool isMuted;
  final bool isLooping;
  final String? errorMessage;

  double get progress => duration.inMilliseconds > 0
      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  bool get isPlaying => status == AudioPlaybackStatus.playing;
  bool get isPaused => status == AudioPlaybackStatus.paused;
  bool get hasTrack => currentTrack != null;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    AudioTrack? currentTrack,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    double? playbackRate,
    double? volume,
    bool? isMuted,
    bool? isLooping,
    String? errorMessage,
    bool clearTrack = false,
    bool clearError = false,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      playbackRate: playbackRate ?? this.playbackRate,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isLooping: isLooping ?? this.isLooping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Backend contract. Implementations must call the attached callbacks reliably.
///
/// **Thread / async contract:**
/// - All callbacks fire on the Flutter platform thread.
/// - [play] and [pause] must complete quickly (~200ms on the fast path).
/// - [load] may take longer (file I/O, setSource).
abstract interface class AudioBackend {
  void attach({
    required void Function(Duration position) onPosition,
    required void Function(AudioPlaybackStatus status) onStatus,
    void Function(Duration duration)? onDuration,
    void Function(Duration buffered)? onBuffered,
    void Function(Object error)? onError,
  });

  Future<void> load(AudioTrack track);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> setRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setLooping(bool looping);
  void dispose();
}

// ─── Mock backend ────────────────────────────────────────────────────────────

class MockAudioBackend implements AudioBackend {
  Timer? _timer;
  Duration _pos = Duration.zero;
  Duration _dur = const Duration(seconds: 180);
  bool _isPlaying = false;
  bool _looping = false;
  double _rate = 1.0;

  void Function(Duration)? _onPosition;
  void Function(AudioPlaybackStatus)? _onStatus;
  void Function(Duration)? _onDuration;

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
  }

  @override
  Future<void> load(AudioTrack track) async {
    _dur = track.duration > Duration.zero
        ? track.duration
        : const Duration(seconds: 180);
    _pos = Duration.zero;
    _onDuration?.call(_dur);
    _onPosition?.call(_pos);
    _onStatus?.call(AudioPlaybackStatus.paused);
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    _onStatus?.call(AudioPlaybackStatus.playing);
    _timer?.cancel();
    final stepMs = (200 / _rate).round().clamp(40, 500);
    _timer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      if (!_isPlaying) {
        t.cancel();
        return;
      }
      _pos += Duration(milliseconds: stepMs);
      if (_pos >= _dur) {
        if (_looping) {
          _pos = Duration.zero;
        } else {
          _pos = _dur;
          _isPlaying = false;
          t.cancel();
          _onStatus?.call(AudioPlaybackStatus.completed);
        }
      }
      _onPosition?.call(_pos);
    });
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    _timer?.cancel();
    _onStatus?.call(AudioPlaybackStatus.paused);
  }

  @override
  Future<void> seek(Duration position) async {
    _pos = position < Duration.zero
        ? Duration.zero
        : (position > _dur ? _dur : position);
    _onPosition?.call(_pos);
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _timer?.cancel();
    _pos = Duration.zero;
    _onStatus?.call(AudioPlaybackStatus.idle);
    _onPosition?.call(_pos);
  }

  @override
  Future<void> setRate(double rate) async => _rate = rate.clamp(0.5, 2.0);

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setLooping(bool looping) async => _looping = looping;

  @override
  void dispose() => _timer?.cancel();
}

// ─── AudioEngine ─────────────────────────────────────────────────────────────

/// Pure-Dart audio state machine — one instance per player surface.
///
/// **Never share** an [AudioEngine] across widgets unless they intentionally
/// mirror the same transport (they will fight over play/pause state).
class AudioEngine extends ConsonaEngine<AudioPlaybackState> {
  AudioEngine({
    AudioBackend? backend,
    ConsonaEventBus? eventBus,
    this.id,
  })  : _backend = backend ?? MockAudioBackend(),
        super(const AudioPlaybackState(), eventBus: eventBus) {
    _backend.attach(
      onPosition: _onPosition,
      onStatus: _onBackendStatus,
      onDuration: _onDuration,
      onBuffered: _onBuffered,
      onError: _onError,
    );
  }

  final String? id;
  final AudioBackend _backend;
  bool _disposed = false;
  double _volumeBeforeMute = 1.0;
  // Pending play op so pause() can observe whether play is in-flight.
  Completer<void>? _playCompleter;

  AudioBackend get backend => _backend;
  bool get isDisposed => _disposed;

  void _onPosition(Duration pos) {
    if (_disposed) return;
    final dur = state.duration;
    final clamped = (dur > Duration.zero && pos > dur) ? dur : pos;
    // Skip if the position hasn't changed at millisecond resolution.
    // This guards against spurious 60fps setState calls from preview engines
    // (which are idle during recording) and from audioplayers stream events
    // that duplicate the timer pump.
    if (clamped.inMilliseconds == state.position.inMilliseconds) return;
    setState((prev) => prev.copyWith(position: clamped));
  }

  void _onBackendStatus(AudioPlaybackStatus status) {
    if (_disposed) return;
    // Never let the backend flip to idle while a track is loaded.
    final s = (status == AudioPlaybackStatus.idle && state.currentTrack != null)
        ? AudioPlaybackStatus.paused
        : status;
    if (s == state.status) return;
    setState((prev) => prev.copyWith(status: s, clearError: true));
    eventBus?.emit('audio:status', {'id': id, 'status': s.name});
  }

  void _onDuration(Duration d) {
    if (_disposed || d <= Duration.zero || d == state.duration) return;
    setState((prev) {
      final pos = prev.position > d ? d : prev.position;
      return prev.copyWith(duration: d, position: pos);
    });
  }

  void _onBuffered(Duration b) {
    if (_disposed || b == state.buffered) return;
    setState((prev) => prev.copyWith(buffered: b));
  }

  void _onError(Object error) {
    if (_disposed) return;
    setState((prev) => prev.copyWith(
          status: AudioPlaybackStatus.error,
          errorMessage: error.toString(),
        ));
    eventBus?.emit('audio:error', {'id': id, 'error': error.toString()});
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load(AudioTrack track) async {
    if (_disposed) return;
    // Immediate UI update — no hourglass, just paused with track metadata.
    setState((prev) => prev.copyWith(
          status: AudioPlaybackStatus.paused,
          currentTrack: track,
          duration: track.duration,
          position: Duration.zero,
          clearError: true,
        ));
    try {
      await _backend.load(track);
      if (!_disposed && state.status != AudioPlaybackStatus.playing) {
        setState((prev) => prev.copyWith(
              status: AudioPlaybackStatus.paused,
              currentTrack: track,
            ));
      }
      eventBus?.emit('audio:loaded', {
        'id': id,
        'trackId': track.id,
        'title': track.title,
      });
    } catch (e) {
      if (!_disposed) {
        setState((prev) => prev.copyWith(
              status: AudioPlaybackStatus.error,
              errorMessage: e.toString(),
            ));
      }
    }
  }

  Future<void> playTrack(AudioTrack track) async {
    await load(track);
    await play();
  }

  // ── Play / Pause ──────────────────────────────────────────────────────────

  /// [play] is NOT serialised — it fires immediately. The backend must be
  /// idempotent (calling resume while playing is a no-op).
  Future<void> play() async {
    if (_disposed) return;
    final track = state.currentTrack;
    if (track == null) return;

    setState((prev) => prev.copyWith(
          status: AudioPlaybackStatus.playing,
          clearError: true,
        ));
    eventBus?.emit('audio:play', {'id': id});

    final completer = Completer<void>();
    _playCompleter = completer;
    try {
      await _backend.play();
    } catch (e) {
      if (!_disposed) {
        setState((prev) => prev.copyWith(
              status: AudioPlaybackStatus.error,
              errorMessage: e.toString(),
            ));
      }
    } finally {
      if (_playCompleter == completer) _playCompleter = null;
      completer.complete();
    }
  }

  /// [pause] is NOT serialised — fires immediately, regardless of any
  /// in-flight play operation.
  Future<void> pause() async {
    if (_disposed) return;
    // Flip UI immediately — don't wait for the backend.
    setState((prev) => prev.copyWith(status: AudioPlaybackStatus.paused));
    eventBus?.emit('audio:pause', {'id': id});
    try {
      await _backend.pause();
    } catch (_) {
      // Backend pause fail is non-fatal — UI is already paused.
    }
  }

  Future<void> toggle() async {
    if (state.status == AudioPlaybackStatus.playing) {
      await pause();
    } else {
      await play();
    }
  }

  // ── Seek ──────────────────────────────────────────────────────────────────

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    final dur = state.duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (dur > Duration.zero && position > dur ? dur : position);
    // Immediate UI position update.
    setState((prev) => prev.copyWith(position: clamped));
    try {
      await _backend.seek(clamped);
    } catch (_) {}
    eventBus?.emit('audio:seek', {'id': id, 'ms': clamped.inMilliseconds});
  }

  // ── Transport controls ────────────────────────────────────────────────────

  Future<void> stop() async {
    if (_disposed) return;
    setState((prev) => prev.copyWith(
          status: AudioPlaybackStatus.idle,
          position: Duration.zero,
          clearTrack: true,
        ));
    try {
      await _backend.stop();
    } catch (_) {}
    eventBus?.emit('audio:stop', {'id': id});
  }

  Future<void> setPlaybackRate(double rate) async {
    if (_disposed) return;
    final r = rate.clamp(0.5, 2.0);
    setState((prev) => prev.copyWith(playbackRate: r));
    try {
      await _backend.setRate(r);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final v = volume.clamp(0.0, 1.0);
    if (!state.isMuted) _volumeBeforeMute = v;
    setState((prev) => prev.copyWith(volume: v));
    try {
      await _backend.setVolume(state.isMuted ? 0.0 : v);
    } catch (_) {}
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    if (muted == state.isMuted) return;
    if (muted) {
      _volumeBeforeMute = state.volume > 0 ? state.volume : _volumeBeforeMute;
      setState((prev) => prev.copyWith(isMuted: true));
      try {
        await _backend.setVolume(0.0);
      } catch (_) {}
    } else {
      setState((prev) =>
          prev.copyWith(isMuted: false, volume: _volumeBeforeMute));
      try {
        await _backend.setVolume(_volumeBeforeMute.clamp(0.0, 1.0));
      } catch (_) {}
    }
  }

  Future<void> toggleMute() => setMuted(!state.isMuted);

  Future<void> setLooping(bool looping) async {
    if (_disposed) return;
    setState((prev) => prev.copyWith(isLooping: looping));
    try {
      await _backend.setLooping(looping);
    } catch (_) {}
  }

  Future<void> reset() async {
    if (_disposed) return;
    setState((prev) => prev.copyWith(
          status: AudioPlaybackStatus.idle,
          position: Duration.zero,
          duration: Duration.zero,
          clearTrack: true,
          clearError: true,
        ));
    try {
      await _backend.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _backend.dispose();
    super.dispose();
  }
}
