/// Plays back a finished [AudioRecordingResult] through [AudioEngine].
library;

import 'package:flutter/foundation.dart';

import '../engine/audio_engine.dart';
import '../engine/recorder_engine.dart';

/// Real audio preview for recorder review (card / pill).
///
/// Pass a platform [AudioBackend] (e.g. audioplayers) for speaker output;
/// defaults to [MockAudioBackend] which advances time without sound.
class ConsonaRecordingPreview extends ChangeNotifier {
  ConsonaRecordingPreview({AudioBackend? backend})
      : _engine = AudioEngine(backend: backend ?? MockAudioBackend()) {
    _engine.addListener(_sync);
  }

  final AudioEngine _engine;
  AudioRecordingResult? _current;

  Duration get position => _engine.state.position;
  bool get playing => _engine.state.status == AudioPlaybackStatus.playing;
  Duration get duration =>
      _current?.duration ?? _engine.state.duration;

  void _sync() => notifyListeners();

  /// Owns a dedicated [AudioEngine] — never share it with a player surface.
  AudioEngine get engine => _engine;

  Future<void> play(AudioRecordingResult result) async {
    final bytes = result.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'Recording "${result.id}" has no audio bytes — cannot preview.',
      );
    }

    final needsReload = _current?.id != result.id ||
        _engine.state.currentTrack?.id != result.id ||
        _engine.state.status == AudioPlaybackStatus.error;
    _current = result;

    try {
      if (needsReload) {
        await _engine.load(
          AudioTrack(
            id: result.id,
            title: 'Recording',
            duration: result.duration,
            bytes: bytes,
            amplitudes: result.amplitudes,
          ),
        );
      } else if (_engine.state.status == AudioPlaybackStatus.completed ||
          (_engine.state.duration > Duration.zero &&
              _engine.state.position >= _engine.state.duration)) {
        await _engine.seek(Duration.zero);
      }
      await _engine.play();
    } catch (e, st) {
      assert(() {
        // ignore: avoid_print
        print('ConsonaRecordingPreview.play failed: $e\n$st');
        return true;
      }());
      rethrow;
    }
  }

  Future<void> pause() => _engine.pause();

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> stop() async {
    await _engine.stop();
    _current = null;
  }

  @override
  void dispose() {
    _engine.removeListener(_sync);
    _engine.dispose();
    super.dispose();
  }
}
