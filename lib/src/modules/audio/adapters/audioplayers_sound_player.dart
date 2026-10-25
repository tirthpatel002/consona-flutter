import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import '../../feedback/player/sound_player.dart';
import 'io_support.dart';

/// Concrete SoundPlayer adapter using audioplayers to play synthesized PCM WAV bytes.
///
/// `audioplayers` does NOT implement `BytesSource` on iOS/macOS (the platform
/// call throws "setSourceBytes is not currently implemented on iOS"). The old
/// adapter swallowed that error and fell back to `SystemSound.click`, so every
/// cue produced the same system click. Each distinct WAV is therefore written
/// once to a temp file (keyed by a content hash) and played via
/// [DeviceFileSource]; web keeps using [BytesSource].
class AudioplayersSoundPlayer implements SoundPlayer {
  AudioplayersSoundPlayer();

  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;
  static const int _poolSize = 4;

  final Map<String, String> _files = {};
  final Expando<String> _hashes = Expando<String>('wavHash');
  TempAudioDirectory? _dir;

  Future<bool>? _ready;
  bool _unavailableLogged = false;
  int _playCount = 0;

  /// One-time check that the native audioplayers plugin is registered in the
  /// running binary. Never throws; when the plugin is missing (stale binary
  /// after adding the dependency + hot restart, or a platform without an
  /// implementation) it logs ONE loud, actionable message and the adapter
  /// degrades to a silent no-op instead of throwing on every play.
  Future<bool> _ensureReady() => _ready ??= _init();

  Future<bool> _init() async {
    try {
      // Same call AudioPlayer() makes internally; probing here means a missing
      // native plugin is caught by us instead of surfacing as an unhandled
      // async MissingPluginException from the AudioPlayer constructor.
      await AudioPlayer.global.ensureInitialized();
      if (!kIsWeb && isMobilePlatform) {
        // Short UI cues must not take permanent audio focus from camera/video.
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(
            focus: AudioContextConfigFocus.mixWithOthers,
          ).build(),
        );
      }
      debugPrint('AudioplayersSoundPlayer: native audio ready '
          '(${kIsWeb ? 'web' : operatingSystemName})');
      return true;
    } on MissingPluginException catch (e) {
      _logUnavailable(
        'native audioplayers plugin is not registered in this running app '
        '($e). Stop the app and do a FULL rebuild: '
        '`cd example && flutter clean && flutter pub get && flutter run -d <device>` '
        '(hot restart/reload cannot add native plugins).',
      );
    } catch (e, st) {
      _logUnavailable('audio initialisation failed: $e\n$st');
    }
    return false;
  }

  void _logUnavailable(String reason) {
    if (_unavailableLogged) return;
    _unavailableLogged = true;
    debugPrint('AudioplayersSoundPlayer: SOUND DISABLED - $reason');
  }

  Future<AudioPlayer> _getPlayer() async {
    if (_pool.length < _poolSize) {
      final player = AudioPlayer();
      // Low latency suits short cues (SoundPool on Android, AVAudioPlayer on
      // Apple). Must be set before the release mode / first play.
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      _pool.add(player);
      return player;
    }
    final player = _pool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _poolSize;
    return player;
  }

  /// FNV-1a content hash, so each distinct cue maps to its own file/handle.
  String _hashOf(Uint8List bytes) {
    final cached = _hashes[bytes];
    if (cached != null) return cached;
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xffffffff;
    }
    final hash = '${h.toRadixString(16)}_${bytes.length}';
    _hashes[bytes] = hash;
    return hash;
  }

  Future<String> _fileFor(Uint8List bytes) async {
    final key = _hashOf(bytes);
    final existing = _files[key];
    if (existing != null) return existing;
    final dir = _dir ??= await createTempAudioDirectory('consona_cues_');
    final filePath = await dir.writeTempFile('cue_$key.wav', bytes);
    return _files[key] = filePath;
  }

  @override
  Future<void> playBytes(Uint8List bytes, {double volume = 1.0}) async {
    if (!await _ensureReady()) return;
    try {
      final player = await _getPlayer();
      await player.setVolume(volume.clamp(0.0, 1.0));
      if (kIsWeb) {
        await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      } else {
        final path = await _fileFor(bytes);
        await player.play(DeviceFileSource(path, mimeType: 'audio/wav'));
        if (_playCount < 5) {
          debugPrint('AudioplayersSoundPlayer: play() ok -> $path '
              '(${bytes.length} bytes, volume ${volume.toStringAsFixed(2)})');
        }
      }
      _playCount++;
    } on MissingPluginException catch (e) {
      _ready = Future.value(false);
      _logUnavailable('native plugin missing during play ($e). '
          'Run `flutter clean && flutter pub get` then a full `flutter run`.');
    } catch (e, st) {
      // Do NOT fall back to a single SystemSound click: that made every cue
      // sound identical and hid real playback failures.
      debugPrint('AudioplayersSoundPlayer: playback failed: $e\n$st');
    }
  }

  @override
  void stop() {
    for (final p in _pool) {
      unawaited(p.stop().catchError((Object e) {
        debugPrint('AudioplayersSoundPlayer: stop failed: $e');
      }));
    }
  }

  @override
  void dispose() {
    for (final p in _pool) {
      unawaited(p.dispose().catchError((Object e) {
        debugPrint('AudioplayersSoundPlayer: dispose failed: $e');
      }));
    }
    _pool.clear();
    _dir?.dispose();
    _dir = null;
  }
}
