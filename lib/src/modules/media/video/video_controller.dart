/// Consona VideoController — ChangeNotifier facade over [video_player].
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart' as vp;

/// Playback lifecycle for [ConsonaVideoController].
enum ConsonaVideoStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  buffering,
  completed,
  error,
}

/// Thin reactive wrapper around a [vp.VideoPlayerController].
class ConsonaVideoController extends ChangeNotifier {
  ConsonaVideoController._(this._inner);

  final vp.VideoPlayerController _inner;
  ConsonaVideoStatus _status = ConsonaVideoStatus.idle;
  String? _errorMessage;
  bool _disposed = false;
  double _volumeBeforeMute = 1.0;

  /// Default headers — some CDNs (e.g. GitHub Pages) 403 bare AVPlayer UAs.
  static const Map<String, String> _defaultNetworkHeaders = {
    'User-Agent':
        'Mozilla/5.0 (compatible; ConsonaVideo/1.0; +https://consona.dev)',
    'Accept': '*/*',
  };

  /// Network stream.
  factory ConsonaVideoController.network(
    String url, {
    Map<String, String>? httpHeaders,
  }) {
    return ConsonaVideoController._(
      vp.VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {
          ..._defaultNetworkHeaders,
          ...?httpHeaders,
        },
      ),
    );
  }

  /// Bundled Flutter asset.
  factory ConsonaVideoController.asset(String assetPath) {
    return ConsonaVideoController._(
      vp.VideoPlayerController.asset(assetPath),
    );
  }

  /// Existing [vp.VideoPlayerController] (tests / advanced hosts).
  factory ConsonaVideoController.fromPlayer(vp.VideoPlayerController player) {
    return ConsonaVideoController._(player);
  }

  ConsonaVideoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _inner.value.isInitialized;
  bool get isPlaying => _inner.value.isPlaying;
  bool get isBuffering => _inner.value.isBuffering;
  bool get isMuted => _inner.value.volume <= 0.001;
  bool get isLooping => _inner.value.isLooping;
  double get volume => _inner.value.volume.clamp(0.0, 1.0);
  double get playbackSpeed => _inner.value.playbackSpeed;
  Duration get position => _inner.value.position;
  Duration get duration => _inner.value.duration;
  Duration get buffered {
    final ranges = _inner.value.buffered;
    if (ranges.isEmpty) return Duration.zero;
    return ranges.last.end;
  }

  double get aspectRatio {
    if (!isInitialized) return 16 / 9;
    final r = _inner.value.aspectRatio;
    return r > 0 ? r : 16 / 9;
  }

  /// Platform video surface. Only valid after [initialize].
  Widget buildView() {
    if (!isInitialized) return const SizedBox.expand();
    return vp.VideoPlayer(_inner);
  }

  Future<void> initialize({bool autoPlay = false, bool looping = false}) async {
    if (_disposed) return;
    _status = ConsonaVideoStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _inner.initialize();
      await _inner.setLooping(looping);
      _inner.addListener(_onTick);
      _status = ConsonaVideoStatus.ready;
      notifyListeners();
      if (autoPlay) await play();
    } catch (e) {
      _status = ConsonaVideoStatus.error;
      _errorMessage = _formatError(e);
      notifyListeners();
    }
  }

  static String _formatError(Object e) {
    if (e is PlatformException) {
      final msg = e.message ?? e.code;
      if (msg.contains('channel-error') || e.code == 'channel-error') {
        return 'Video plugin not linked — stop the app and do a full rebuild '
            '(hot restart is not enough after adding video_player).';
      }
      return msg;
    }
    return e.toString();
  }

  void _onTick() {
    if (_disposed) return;
    final v = _inner.value;
    if (v.hasError) {
      _status = ConsonaVideoStatus.error;
      _errorMessage = v.errorDescription ?? 'Playback error';
      notifyListeners();
      return;
    }
    if (!v.isInitialized) return;

    if (v.isBuffering && v.isPlaying) {
      _status = ConsonaVideoStatus.buffering;
    } else if (v.isPlaying) {
      _status = ConsonaVideoStatus.playing;
    } else if (v.position >= v.duration &&
        v.duration > Duration.zero &&
        !v.isLooping) {
      _status = ConsonaVideoStatus.completed;
    } else {
      _status = ConsonaVideoStatus.paused;
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_disposed || !isInitialized) return;
    await _inner.play();
    _status = ConsonaVideoStatus.playing;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_disposed || !isInitialized) return;
    await _inner.pause();
    _status = ConsonaVideoStatus.paused;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await pause();
    } else {
      if (_status == ConsonaVideoStatus.completed) {
        await seekTo(Duration.zero);
      }
      await play();
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_disposed || !isInitialized) return;
    await _inner.seekTo(position);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final v = volume.clamp(0.0, 1.0);
    if (v > 0.001) _volumeBeforeMute = v;
    await _inner.setVolume(v);
    notifyListeners();
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    if (muted) {
      if (_inner.value.volume > 0.001) {
        _volumeBeforeMute = _inner.value.volume;
      }
      await _inner.setVolume(0.0);
    } else {
      await _inner.setVolume(
        _volumeBeforeMute <= 0.001 ? 1.0 : _volumeBeforeMute,
      );
    }
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_disposed || !isInitialized) return;
    await _inner.setPlaybackSpeed(speed.clamp(0.25, 3.0));
    notifyListeners();
  }

  Future<void> setLooping(bool looping) async {
    if (_disposed) return;
    await _inner.setLooping(looping);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _inner.removeListener(_onTick);
    unawaited(_inner.dispose());
    super.dispose();
  }
}
