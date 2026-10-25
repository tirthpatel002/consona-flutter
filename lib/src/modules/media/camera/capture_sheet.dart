/// Capture → review card (Kalein-style flow, Consona tokens).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart'
    show
        ContinuousRectangleBorder,
        Icons,
        Material,
        MaterialType,
        RoundedRectangleBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../audio/engine/audio_format.dart';
import '../../core/loader/loader.dart';
import '../../core/slider/slider.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../adapters/create_camera_runtime.dart';
import '../adapters/create_video_segment_merger.dart';
import 'camera_runtime.dart';
import 'capture_result.dart';
import 'video_segment_merge.dart';

/// Floating capture card — plush uniform corners (no stroke).
const _kCaptureCardRadius = 48.0;

enum _CameraAccessState { checking, ready, denied, unavailable }

enum _Stage { capture, review }

/// Full-bleed camera card; parent supplies size and [Navigator.pop] route.
class ConsonaCameraCaptureSheet extends StatefulWidget {
  const ConsonaCameraCaptureSheet({
    super.key,
    this.onEdit,
    this.runtime,
  });

  final ConsonaCameraEditCallback? onEdit;
  final ConsonaCameraRuntime? runtime;

  @override
  State<ConsonaCameraCaptureSheet> createState() =>
      _ConsonaCameraCaptureSheetState();
}

class _ConsonaCameraCaptureSheetState extends State<ConsonaCameraCaptureSheet>
    with WidgetsBindingObserver {
  ConsonaCameraRuntime? _runtime;
  ConsonaCameraHandle? _handle;
  _CameraAccessState _access = _CameraAccessState.checking;
  String? _accessMessage;
  var _busy = false;
  var _recording = false;
  var _recordingPaused = false;
  List<ConsonaCameraLens> _lenses = const [];

  Duration _recordedAccumulated = Duration.zero;
  DateTime? _recordSegmentStartedAt;
  Timer? _recordTicker;
  Duration _recordDisplay = Duration.zero;

  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double? _pendingZoom;
  var _zoomApplyInFlight = false;

  _Stage _stage = _Stage.capture;
  ConsonaCameraCaptureResult? _draft;

  VideoPlayerController? _reviewPlayer;
  var _reviewPlaying = false;
  var _reviewMuted = false;
  final _reviewPositionListenable = ValueNotifier<int>(0);
  var _reviewScrubDisplayMs = 0;
  var _reviewDurationMs = 1;
  var _reviewScrubbing = false;
  var _reviewResumeAfterScrub = false;
  var _reviewTransportBusy = false;
  var _reviewListenerMuted = false;
  Timer? _reviewUiTicker;
  final _reviewTransport = _ReviewTransportQueue();

  ConsonaCameraLens _activeLens = ConsonaCameraLens.back;

  final List<ConsonaVideoSegment> _videoSegments = [];
  ConsonaVideoSegmentMerger? _merger;
  var _cameraSwitching = false;
  var _mergingVideo = false;
  String? _captureNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopReviewUiTicker();
    _reviewPositionListenable.dispose();
    _recordTicker?.cancel();
    final handle = _handle;
    _handle = null;
    unawaited(handle?.dispose() ?? Future<void>.value());
    final player = _reviewPlayer;
    _reviewPlayer = null;
    unawaited(player?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_stage != _Stage.capture) return;
    final handle = _handle;
    if (handle == null || !handle.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(handle.dispose());
      _handle = null;
    } else if (state == AppLifecycleState.resumed &&
        _access == _CameraAccessState.ready) {
      unawaited(_startCamera(preferFront: _activeLens == ConsonaCameraLens.front));
    }
  }

  Future<void> _bootstrap() async {
    final runtime = widget.runtime ?? await createConsonaCameraRuntime();
    if (!mounted) return;
    _runtime = runtime;

    if (!runtime.isPluginAvailable) {
      setState(() {
        _access = _CameraAccessState.unavailable;
        _accessMessage = 'Camera capture is not available on this platform.';
      });
      return;
    }

    try {
      final cameraStatus = await runtime.resolveCameraPermission();
      if (!mounted) return;
      if (!cameraStatus.granted) {
        setState(() {
          _access = _CameraAccessState.denied;
          _accessMessage = cameraStatus.openSettings
              ? 'Camera access is off. Open Settings to allow photos and videos.'
              : 'Camera permission is needed to capture here.';
        });
        return;
      }

      await runtime.resolveMicrophonePermission();

      final lenses = await runtime.availableLenses();
      if (!mounted) return;
      if (lenses.isEmpty) {
        setState(() {
          _access = _CameraAccessState.unavailable;
          _accessMessage = 'No camera is available on this device right now.';
        });
        return;
      }
      _lenses = lenses;
      await _startCamera(preferFront: false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _access = _CameraAccessState.unavailable;
        _accessMessage =
            'Couldn’t open the camera. You can try again in a moment.';
      });
    }
  }

  Future<void> _startCamera({
    required bool preferFront,
    bool duringRecordingLensSwitch = false,
  }) async {
    final runtime = _runtime;
    if (runtime == null || _lenses.isEmpty) {
      if (!mounted || duringRecordingLensSwitch) return;
      setState(() {
        _access = _CameraAccessState.unavailable;
        _accessMessage = 'Camera isn’t ready yet. Try again.';
        _busy = false;
        _cameraSwitching = false;
      });
      return;
    }

    final previous = _handle;
    if (mounted) {
      setState(() => _handle = null);
    } else {
      _handle = null;
    }
    await previous?.dispose();

    final lens = preferFront && _lenses.contains(ConsonaCameraLens.front)
        ? ConsonaCameraLens.front
        : (_lenses.contains(ConsonaCameraLens.back)
            ? ConsonaCameraLens.back
            : _lenses.first);

    try {
      final next = await runtime
          .openCamera(lens)
          .timeout(const Duration(seconds: 20));
      final minZoom = await next.getMinZoom();
      final maxZoom = await next.getMaxZoom();
      final zoom = _zoom.clamp(minZoom, maxZoom);
      await next.setZoom(zoom);
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _handle = next;
        _activeLens = next.lens;
        _access = _CameraAccessState.ready;
        _accessMessage = null;
        if (!duringRecordingLensSwitch) {
          _busy = false;
          _recording = false;
          _recordingPaused = false;
        }
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = zoom;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _handle = null;
        _cameraSwitching = false;
        if (!duringRecordingLensSwitch) {
          _access = _CameraAccessState.unavailable;
          _accessMessage =
              'Couldn’t start the camera preview. Try again, or use Settings if access was denied.';
          _busy = false;
          _recording = false;
          _recordingPaused = false;
        } else {
          _busy = false;
        }
      });
    }
  }

  void _haptic(FeedbackEvent event) {
    ConsonaFeedbackScope.maybeOf(context)?.trigger(event);
  }

  void _accumulateActiveRecordingSegment() {
    if (_recordSegmentStartedAt != null) {
      _recordedAccumulated += DateTime.now().difference(_recordSegmentStartedAt!);
      _recordSegmentStartedAt = null;
    }
  }

  Future<void> _flipCamera() async {
    if (_busy || _cameraSwitching || _mergingVideo || _lenses.length < 2) {
      return;
    }
    if (_recording && !_recordingPaused) {
      await _flipDuringRecording();
      return;
    }
    if (_recording) return;

    _haptic(FeedbackEvent.selection);
    setState(() => _busy = true);
    await _startCamera(
      preferFront: _activeLens != ConsonaCameraLens.front,
    );
  }

  Future<void> _flipDuringRecording() async {
    final handle = _handle;
    if (handle == null || !handle.isInitialized) return;

    _haptic(FeedbackEvent.selection);
    _stopRecordTicker();
    setState(() {
      _busy = true;
      _cameraSwitching = true;
      _accessMessage = null;
      _captureNotice = null;
    });

    try {
      _accumulateActiveRecordingSegment();
      final segmentLens = _activeLens;
      final path = await handle.stopVideoRecording();
      final runtime = _runtime;
      if (runtime != null && await runtime.fileExists(path)) {
        _videoSegments.add(
          ConsonaVideoSegment(
            path: path,
            lens: segmentLens,
            sensorOrientationDegrees: handle.sensorOrientationDegrees,
          ),
        );
      }

      await _startCamera(
        preferFront: _activeLens != ConsonaCameraLens.front,
        duringRecordingLensSwitch: true,
      );

      final next = _handle;
      if (next == null || !next.isInitialized) {
        throw StateError('Camera not ready after lens switch');
      }
      await next.startVideoRecording();

      if (!mounted) return;
      setState(() {
        _busy = false;
        _cameraSwitching = false;
        _recording = true;
        _recordingPaused = false;
        _recordSegmentStartedAt = DateTime.now();
        _recordDisplay = _recordedAccumulated;
      });
      _startRecordTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _cameraSwitching = false;
        _recording = false;
        _recordingPaused = false;
      });
      _stopRecordTicker();
      if (_videoSegments.isNotEmpty) {
        await _finalizeSegmentedRecording(
          notice: 'Couldn’t switch camera. Saved what was recorded so far.',
        );
      } else {
        _showInlineIssue('Couldn’t switch camera.');
      }
    } finally {
      if (mounted && _cameraSwitching && !_recording) {
        setState(() {
          _cameraSwitching = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _finalizeSegmentedRecording({
    String? notice,
    String? lastSegmentPath,
  }) async {
    final runtime = _runtime;
    if (runtime == null) return;

    setState(() {
      _mergingVideo = true;
      _busy = true;
      _recording = false;
      _recordingPaused = false;
      _recordSegmentStartedAt = null;
    });
    _stopRecordTicker();

    final segments = List<ConsonaVideoSegment>.from(_videoSegments);
    _videoSegments.clear();
    if (lastSegmentPath != null && await runtime.fileExists(lastSegmentPath)) {
      final handle = _handle;
      segments.add(
        ConsonaVideoSegment(
          path: lastSegmentPath,
          lens: _activeLens,
          sensorOrientationDegrees: handle?.sensorOrientationDegrees ??
              (_activeLens == ConsonaCameraLens.front ? 270 : 90),
        ),
      );
    }
    final paths = segments.map((segment) => segment.path).toList();

    final durationMs = _recordedAccumulated.inMilliseconds;
    _recordedAccumulated = Duration.zero;
    _recordDisplay = Duration.zero;

    final merger = _merger ?? await createVideoSegmentMerger();
    _merger = merger;

    ConsonaVideoMergeOutcome outcome;
    try {
      outcome = await merger
          .mergeSegments(segments)
          .timeout(const Duration(minutes: 2));
    } catch (_) {
      outcome = ConsonaVideoMergeOutcome(
        playbackPath: paths.isNotEmpty ? paths.last : lastSegmentPath ?? '',
        segmentPaths: paths,
        combinedSuccessfully: false,
        notice: notice ?? 'Couldn’t save the full recording.',
      );
    }

    final userNotice = outcome.notice ?? notice;

    if (!mounted) return;

    if (outcome.playbackPath.isEmpty || !await runtime.fileExists(outcome.playbackPath)) {
      setState(() {
        _mergingVideo = false;
        _busy = false;
      });
      _showInlineIssue('Couldn’t save the recording.');
      return;
    }

    final draft = await _draftFromCapture(
      path: outcome.playbackPath,
      kind: ConsonaCapturedMediaKind.video,
      durationMs: durationMs,
      sourceSegmentPaths: outcome.segmentPaths,
      notice: userNotice,
    );

    if (!mounted) return;
    setState(() {
      _mergingVideo = false;
      _busy = false;
      _captureNotice = userNotice;
    });

    if (draft == null) {
      _showInlineIssue('Couldn’t save the recording.');
      return;
    }
    await _enterReview(draft);
  }

  Future<void> _setZoom(double value) async {
    final handle = _handle;
    if (handle == null || !handle.isInitialized) return;
    final next = value.clamp(_minZoom, _maxZoom);
    if ((next - _zoom).abs() < 0.0005) return;
    setState(() => _zoom = next);
    _pendingZoom = next;
    if (_zoomApplyInFlight) return;
    _zoomApplyInFlight = true;
    try {
      while (mounted) {
        final target = _pendingZoom;
        if (target == null) break;
        _pendingZoom = null;
        await handle.setZoom(target);
        if (_pendingZoom == null) break;
      }
    } finally {
      _zoomApplyInFlight = false;
    }
  }

  void _startRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || !_recording) return;
      setState(() => _recordDisplay = _currentRecordedDuration());
    });
  }

  void _stopRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = null;
  }

  Duration _currentRecordedDuration() {
    var total = _recordedAccumulated;
    if (_recording && !_recordingPaused && _recordSegmentStartedAt != null) {
      total += DateTime.now().difference(_recordSegmentStartedAt!);
    }
    return total;
  }

  String _formatClockMs(int ms) =>
      formatAudioTimestamp(Duration(milliseconds: ms.clamp(0, 359999999)));

  Future<void> _capturePhoto() async {
    if (_busy || _recording) return;
    _haptic(FeedbackEvent.pop);
    setState(() => _busy = true);
    try {
      final handle = _handle;
      if (handle == null || !handle.isInitialized) {
        setState(() => _busy = false);
        return;
      }
      final path = await handle.takePicture();
      final draft = await _draftFromCapture(
        path: path,
        kind: ConsonaCapturedMediaKind.image,
      );
      if (!mounted) return;
      if (draft == null) {
        setState(() => _busy = false);
        return;
      }
      await _enterReview(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showInlineIssue('Couldn’t take that photo. Try again.');
    }
  }

  Future<void> _startOrResumeVideo() async {
    if (_busy) return;

    final handle = _handle;
    if (handle == null || !handle.isInitialized) return;

    if (_recording && _recordingPaused) {
      _haptic(FeedbackEvent.selection);
      setState(() => _busy = true);
      try {
        await handle.resumeVideoRecording();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _recordingPaused = false;
          _recordSegmentStartedAt = DateTime.now();
        });
        _startRecordTicker();
      } catch (_) {
        if (!mounted) return;
        setState(() => _busy = false);
        _showInlineIssue('Couldn’t resume recording.');
      }
      return;
    }

    if (_recording) return;

    _haptic(FeedbackEvent.selection);
    setState(() => _busy = true);
    try {
      _videoSegments.clear();
      await handle.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = true;
        _recordingPaused = false;
        _recordedAccumulated = Duration.zero;
        _recordSegmentStartedAt = DateTime.now();
        _recordDisplay = Duration.zero;
        _captureNotice = null;
      });
      _startRecordTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showInlineIssue(
        'Couldn’t start recording. Check microphone access in Settings if this keeps happening.',
      );
    }
  }

  Future<void> _pauseVideo() async {
    if (!_recording || _recordingPaused || _busy) return;

    final handle = _handle;
    if (handle == null || !handle.isInitialized) return;

    _haptic(FeedbackEvent.selection);
    setState(() => _busy = true);
    try {
      await handle.pauseVideoRecording();
      if (!mounted) return;
      final segment = _recordSegmentStartedAt == null
          ? Duration.zero
          : DateTime.now().difference(_recordSegmentStartedAt!);
      setState(() {
        _busy = false;
        _recordingPaused = true;
        _recordedAccumulated += segment;
        _recordSegmentStartedAt = null;
        _recordDisplay = _recordedAccumulated;
      });
      _stopRecordTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showInlineIssue('Couldn’t pause recording on this device.');
    }
  }

  Future<void> _stopVideo() async {
    if (!_recording ||
        _busy ||
        _cameraSwitching ||
        _mergingVideo) {
      return;
    }

    _haptic(FeedbackEvent.pop);
    setState(() => _busy = true);

    final handle = _handle;
    if (handle == null || !handle.isInitialized) {
      setState(() => _busy = false);
      return;
    }

    try {
      _accumulateActiveRecordingSegment();
      final path = await handle.stopVideoRecording();
      await _finalizeSegmentedRecording(lastSegmentPath: path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _recordingPaused = false;
      });
      _stopRecordTicker();
      if (_videoSegments.isNotEmpty) {
        await _finalizeSegmentedRecording(
          notice: 'Couldn’t finish the last clip. Saved earlier parts.',
        );
      } else {
        _showInlineIssue('Couldn’t finish that video. Try again.');
      }
    }
  }

  Future<ConsonaCameraCaptureResult?> _draftFromCapture({
    required String path,
    required ConsonaCapturedMediaKind kind,
    int? durationMs,
    List<String>? sourceSegmentPaths,
    String? notice,
  }) async {
    final runtime = _runtime;
    if (runtime == null) return null;
    if (!await runtime.fileExists(path)) return null;
    final fileName = runtime.basename(path);
    final mime = runtime.inferMimeType(
      path: path,
      isVideo: kind == ConsonaCapturedMediaKind.video,
    );
    return ConsonaCameraCaptureResult(
      path: path,
      kind: kind,
      mimeType: mime,
      fileName: fileName,
      fileSize: await runtime.fileLength(path),
      durationMs: durationMs,
      sourceSegmentPaths: sourceSegmentPaths,
      notice: notice,
    );
  }

  Future<void> _enterReview(ConsonaCameraCaptureResult draft) async {
    await _disposeReviewPlayer();
    setState(() {
      _draft = draft;
      _stage = _Stage.review;
      _busy = false;
      _reviewMuted = draft.isMuted;
      _reviewPlaying = false;
      _reviewPositionListenable.value = 0;
      _reviewScrubDisplayMs = 0;
      _reviewDurationMs = (draft.durationMs ?? 1).clamp(1, 1 << 30);
      _reviewScrubbing = false;
      _reviewResumeAfterScrub = false;
      _reviewTransportBusy = false;
      _reviewListenerMuted = false;
      _reviewTransport.clear();
      _stopReviewUiTicker();
      _accessMessage = null;
      _captureNotice = draft.notice;
    });

    final camera = _handle;
    _handle = null;
    unawaited(camera?.dispose() ?? Future<void>.value());

    if (draft.isVideo) {
      await _initReviewPlayer(draft);
    }
  }

  Future<void> _initReviewPlayer(ConsonaCameraCaptureResult draft) async {
    final player = VideoPlayerController.file(File(draft.path));
    try {
      await player.initialize();
      await player.setLooping(true);
      await player.setVolume(_reviewMuted ? 0 : 1);
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _reviewPlayer = player;
        _reviewDurationMs =
            player.value.duration.inMilliseconds.clamp(1, 1 << 30);
      });
      await player.play();
      if (mounted) {
        setState(() => _reviewPlaying = true);
        _startReviewUiTicker();
      }
    } catch (_) {
      await player.dispose();
      if (!mounted) return;
      _showInlineIssue('Couldn’t play this video preview.');
    }
  }

  void _startReviewUiTicker() {
    _reviewUiTicker?.cancel();
    _reviewUiTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _pollReviewPosition();
    });
  }

  void _stopReviewUiTicker() {
    _reviewUiTicker?.cancel();
    _reviewUiTicker = null;
  }

  /// Polls position on a timer — avoids [VideoPlayerController.addListener],
  /// which fires native→Dart on every frame and floods the Android looper.
  void _pollReviewPosition() {
    if (!mounted ||
        _reviewScrubbing ||
        _reviewListenerMuted ||
        _reviewTransportBusy) {
      return;
    }
    final player = _reviewPlayer;
    if (player == null || !player.value.isInitialized) return;
    final position = player.value.position.inMilliseconds;
    if (_reviewPositionListenable.value != position) {
      _reviewPositionListenable.value = position;
    }
  }

  void _flushReviewUiFromPlayer() {
    final player = _reviewPlayer;
    if (player == null || !mounted) return;
    final value = player.value;
    if (!value.isInitialized) return;
    final playing = value.isPlaying;
    final position = value.position.inMilliseconds;
    final duration = value.duration.inMilliseconds.clamp(1, 1 << 30);
    _reviewPositionListenable.value = position;
    if (playing == _reviewPlaying && duration == _reviewDurationMs) return;
    setState(() {
      _reviewPlaying = playing;
      _reviewDurationMs = duration;
    });
  }

  Future<void> _withReviewTransport(Future<void> Function() op) {
    return _reviewTransport.enqueue(() async {
      if (!mounted) return;
      setState(() => _reviewTransportBusy = true);
      _reviewListenerMuted = true;
      try {
        await op();
      } finally {
        _reviewListenerMuted = false;
        _flushReviewUiFromPlayer();
        if (mounted) setState(() => _reviewTransportBusy = false);
      }
    });
  }

  Future<void> _disposeReviewPlayer() async {
    _reviewTransport.clear();
    _reviewListenerMuted = true;
    final player = _reviewPlayer;
    _reviewPlayer = null;
    _stopReviewUiTicker();
    await player?.pause();
    await player?.dispose();
    _reviewListenerMuted = false;
  }

  Future<void> _retake() async {
    _haptic(FeedbackEvent.selection);
    await _disposeReviewPlayer();
    setState(() {
      _draft = null;
      _stage = _Stage.capture;
      _busy = true;
      _reviewMuted = false;
      _accessMessage = null;
      _captureNotice = null;
    });
    _videoSegments.clear();
    await _startCamera(
      preferFront: _activeLens == ConsonaCameraLens.front,
    );
  }

  void _toggleReviewPlayback() {
    if (_reviewScrubbing || _reviewTransportBusy) return;
    _haptic(FeedbackEvent.selection);
    unawaited(
      _withReviewTransport(() async {
        final player = _reviewPlayer;
        if (player == null || !player.value.isInitialized) return;
        if (player.value.isPlaying) {
          await player.pause();
          if (mounted) setState(() => _reviewPlaying = false);
        } else {
          await player.play();
          if (mounted) setState(() => _reviewPlaying = true);
        }
      }),
    );
  }

  Future<void> _finishReviewScrub(int ms) async {
    await _withReviewTransport(() async {
      final player = _reviewPlayer;
      if (player == null || !player.value.isInitialized) return;
      final clamped = ms.clamp(0, _reviewDurationMs);
      await player.pause();
      await player.seekTo(Duration(milliseconds: clamped));
      if (!mounted) return;
      final resume = _reviewResumeAfterScrub;
      _reviewResumeAfterScrub = false;
      _reviewPositionListenable.value = clamped;
      setState(() => _reviewScrubbing = false);
      if (resume) {
        await player.play();
        if (mounted) setState(() => _reviewPlaying = true);
      } else if (mounted) {
        setState(() => _reviewPlaying = false);
      }
    });
  }

  Future<void> _toggleMute() async {
    final draft = _draft;
    if (draft == null || !draft.isVideo) return;
    _haptic(FeedbackEvent.selection);
    final next = !_reviewMuted;
    setState(() {
      _reviewMuted = next;
      _draft = draft.copyWith(isMuted: next);
    });
    await _reviewPlayer?.setVolume(next ? 0 : 1);
  }

  Future<void> _openEditor() async {
    final callback = widget.onEdit;
    final draft = _draft;
    if (callback == null || draft == null || _busy) return;
    _haptic(FeedbackEvent.selection);

    final wasPlaying = _reviewPlaying;
    await _reviewPlayer?.pause();
    if (!mounted) return;

    final edited = await callback(context, draft);
    if (!mounted) return;
    if (edited == null) {
      if (wasPlaying) await _reviewPlayer?.play();
      return;
    }

    setState(() => _draft = edited);
    if (edited.isVideo) {
      _reviewMuted = edited.isMuted;
      await _disposeReviewPlayer();
      await _initReviewPlayer(edited);
    }
  }

  void _confirmSend() {
    final draft = _draft;
    if (draft == null) return;
    _haptic(FeedbackEvent.pop);
    Navigator.of(context).pop(
      draft.copyWith(isMuted: draft.isVideo && _reviewMuted),
    );
  }

  void _showInlineIssue(String message) {
    setState(() {
      _accessMessage = message;
      _captureNotice = null;
    });
  }

  String? get _inlineBannerMessage => _captureNotice ?? _accessMessage;

  Future<void> _openSettings() async {
    await _runtime?.openAppSettings();
  }

  Future<void> _retryAccess() async {
    setState(() {
      _access = _CameraAccessState.checking;
      _accessMessage = null;
    });
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final borderRadius = BorderRadius.circular(_kCaptureCardRadius);
    final shape = theme.radius.isSquircle
        ? ContinuousRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide.none,
          )
        : RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide.none,
          );

    return Material(
      type: MaterialType.transparency,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: Stack(
        fit: StackFit.expand,
        children: [
              ColoredBox(
                color: const Color(0xFF000000),
                child: _stage == _Stage.review
                    ? _buildReviewMedia()
                    : _buildCapturePreview(theme),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x8A000000),
                          Color(0x52000000),
                          Color(0x24000000),
                          Color(0x00000000),
                        ],
                        stops: [0.0, 0.32, 0.68, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 200,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xA3000000),
                          Color(0x66000000),
                          Color(0x2E000000),
                          Color(0x00000000),
                        ],
                        stops: [0.0, 0.28, 0.62, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopChrome(
                  title: null,
                  centerChild: _stage == _Stage.capture
                      ? (_mergingVideo
                          ? const _CaptureStatusChip(label: 'Saving')
                          : _cameraSwitching
                              ? const _CaptureStatusChip(label: 'Switching')
                              : (_recording
                                  ? _RecordTimerChip(
                                      elapsed: _recordDisplay,
                                      paused: _recordingPaused,
                                      formatClock: _formatClockMs,
                                    )
                                  : null))
                      : null,
                  showEdit:
                      _stage == _Stage.review && widget.onEdit != null && _draft != null,
                  onEdit: () => unawaited(_openEditor()),
                ),
              ),
              if (_stage == _Stage.capture &&
                  _access == _CameraAccessState.ready &&
                  _lenses.length > 1 &&
                  !_mergingVideo)
                Positioned(
                  top: ConsonaSpacing.lg,
                  right: ConsonaSpacing.lg,
                  child: Opacity(
                    opacity: _cameraSwitching || _busy ? 0.45 : 1,
                    child: _MinimalFlipCameraButton(
                      onTap: _cameraSwitching || _busy
                          ? null
                          : () => unawaited(_flipCamera()),
                    ),
                  ),
                ),
              if (_stage == _Stage.capture &&
                  _access == _CameraAccessState.ready &&
                  _maxZoom > _minZoom + 0.05)
                Positioned(
                  left: ConsonaSpacing.sm,
                  top: 72,
                  bottom: 120,
                  child: _ZoomWheel(
                    value: _zoom,
                    min: _minZoom,
                    max: _maxZoom,
                    onChanged: (v) => unawaited(_setZoom(v)),
                  ),
                ),
              if (_inlineBannerMessage != null &&
                  (_stage == _Stage.review ||
                      _stage == _Stage.capture &&
                          (_access != _CameraAccessState.ready ||
                              _captureNotice != null)))
                Positioned(
                  left: ConsonaSpacing.md,
                  right: ConsonaSpacing.md,
                  bottom: 110,
                  child: Text(
                    _inlineBannerMessage!,
                    textAlign: TextAlign.center,
                    style: theme.typography.caption.copyWith(
                      height: 1.35,
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ConsonaSpacing.md,
                    ConsonaSpacing.lg,
                    ConsonaSpacing.md,
                    ConsonaSpacing.md,
                  ),
                  child: _stage == _Stage.review
                      ? _buildReviewActions(theme)
                      : _buildCaptureActions(theme),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCapturePreview(ConsonaThemeData theme) {
    switch (_access) {
      case _CameraAccessState.checking:
        return Center(
          child: ConsonaLoader(color: theme.colors.primary),
        );
      case _CameraAccessState.denied:
      case _CameraAccessState.unavailable:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(ConsonaSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_off_rounded,
                  size: 40,
                  color: const Color(0xB8FFFFFF),
                ),
                const SizedBox(height: ConsonaSpacing.sm),
                Text(
                  _accessMessage ?? 'Camera unavailable',
                  textAlign: TextAlign.center,
                  style: theme.typography.body.copyWith(
                    height: 1.35,
                    color: const Color(0xE0FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        );
      case _CameraAccessState.ready:
        if (_mergingVideo) {
          return ColoredBox(
            color: const Color(0xFF000000),
            child: Center(
              child: ConsonaLoader(color: theme.colors.primary),
            ),
          );
        }
        final handle = _handle;
        if (handle == null || !handle.isInitialized) {
          return ColoredBox(
            color: const Color(0xFF000000),
            child: _cameraSwitching
                ? Center(child: ConsonaLoader(color: theme.colors.primary))
                : const SizedBox.expand(),
          );
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: handle.previewWidth ?? 1,
            height: handle.previewHeight ?? 1,
            child: handle.buildPreview(),
          ),
        );
    }
  }

  Widget _buildReviewMedia() {
    final draft = _draft;
    if (draft == null) return const SizedBox.expand();
    if (draft.isImage) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: Image.file(
            File(draft.path),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    final player = _reviewPlayer;
    if (player == null || !player.value.isInitialized) {
      return const Center(
        child: ConsonaLoader(color: Color(0xFFFFFFFF)),
      );
    }
    return _ReviewVideoSurface(controller: player);
  }

  Widget _buildCaptureActions(ConsonaThemeData theme) {
    if (_cameraSwitching || _mergingVideo) {
      return const SizedBox(height: _CaptureChrome.actionSize);
    }

    if (_access == _CameraAccessState.denied) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconCircleButton(
            icon: Icons.settings_rounded,
            onTap: () => unawaited(_openSettings()),
            filled: true,
          ),
          const SizedBox(width: ConsonaSpacing.md),
          _IconCircleButton(
            icon: Icons.refresh_rounded,
            onTap: () => unawaited(_retryAccess()),
          ),
        ],
      );
    }

    if (_access == _CameraAccessState.unavailable ||
        _access == _CameraAccessState.checking) {
      return Center(
        child: _IconCircleButton(
          icon: Icons.refresh_rounded,
          onTap: _access == _CameraAccessState.checking
              ? null
              : () => unawaited(_retryAccess()),
          filled: true,
        ),
      );
    }

    if (_recording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconCircleButton(
            icon: _recordingPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onTap: _busy
                ? null
                : () => unawaited(
                      _recordingPaused ? _startOrResumeVideo() : _pauseVideo(),
                    ),
          ),
          const SizedBox(width: ConsonaSpacing.lg),
          _IconCircleButton(
            icon: Icons.stop_rounded,
            onTap: _busy ? null : () => unawaited(_stopVideo()),
            filled: true,
            emphasize: true,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SurfaceIconButton(
          icon: Icons.videocam_rounded,
          onTap: _busy ? null : () => unawaited(_startOrResumeVideo()),
        ),
        const SizedBox(width: ConsonaSpacing.lg),
        _PhotoShutterButton(
          onTap: _busy ? null : () => unawaited(_capturePhoto()),
        ),
      ],
    );
  }

  Widget _buildReviewActions(ConsonaThemeData theme) {
    final draft = _draft;
    final isVideo = draft?.isVideo == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVideo) ...[
          ValueListenableBuilder<int>(
            valueListenable: _reviewPositionListenable,
            builder: (context, polledMs, _) {
              final positionMs =
                  _reviewScrubbing ? _reviewScrubDisplayMs : polledMs;
              return Row(
                children: [
                  Text(
                    _formatClockMs(positionMs),
                    style: theme.typography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(width: ConsonaSpacing.sm),
                  Expanded(
                    child: ConsonaSlider(
                      value: positionMs.toDouble().clamp(
                            0,
                            _reviewDurationMs.toDouble(),
                          ),
                      min: 0,
                      max: _reviewDurationMs.toDouble(),
                      onChanged: (value) {
                        final ms =
                            value.round().clamp(0, _reviewDurationMs);
                        final startingScrub = !_reviewScrubbing;
                        if (startingScrub) {
                          _reviewResumeAfterScrub = _reviewPlaying;
                          unawaited(
                            _withReviewTransport(() async {
                              await _reviewPlayer?.pause();
                            }),
                          );
                        }
                        setState(() {
                          _reviewScrubbing = true;
                          if (startingScrub && _reviewResumeAfterScrub) {
                            _reviewPlaying = false;
                          }
                          _reviewScrubDisplayMs = ms;
                        });
                      },
                      onChangeEnd: (value) {
                        final ms =
                            value.round().clamp(0, _reviewDurationMs);
                        unawaited(_finishReviewScrub(ms));
                      },
                    ),
                  ),
                  const SizedBox(width: ConsonaSpacing.sm),
                  Text(
                    _formatClockMs(_reviewDurationMs),
                    style: theme.typography.labelSmall.copyWith(
                      color: const Color(0xB8FFFFFF),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: ConsonaSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SurfaceIconButton(
              icon: Icons.refresh_rounded,
              onTap: () => unawaited(_retake()),
            ),
            if (isVideo) ...[
              const SizedBox(width: ConsonaSpacing.md),
              _SurfaceIconButton(
                icon: _reviewPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: _reviewScrubbing || _reviewTransportBusy
                    ? null
                    : _toggleReviewPlayback,
              ),
              const SizedBox(width: ConsonaSpacing.md),
              _SurfaceIconButton(
                icon: _reviewMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: () => unawaited(_toggleMute()),
              ),
            ],
            const SizedBox(width: ConsonaSpacing.md),
            _SurfaceIconButton(
              icon: Icons.check_rounded,
              onTap: _confirmSend,
            ),
          ],
        ),
      ],
    );
  }
}

class _MinimalFlipCameraButton extends StatelessWidget {
  const _MinimalFlipCameraButton({this.onTap});

  final VoidCallback? onTap;

  /// Matches the old top-bar [IconButton] footprint (~48dp).
  static const _size = 48.0;
  static const _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Flip camera',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x33FFFFFF),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Center(
            child: Icon(
              Icons.sync_rounded,
              size: _iconSize,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.showEdit,
    required this.onEdit,
    this.title,
    this.centerChild,
  });

  final String? title;
  final Widget? centerChild;
  final bool showEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsonaSpacing.md,
        ConsonaSpacing.sm + 2,
        ConsonaSpacing.sm,
        ConsonaSpacing.md,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: theme.typography.label.copyWith(
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (showEdit)
                _ChromeIconButton(
                  tooltip: 'Edit',
                  icon: Icons.tune_rounded,
                  onTap: onEdit,
                ),
            ],
          ),
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  static const bool dimmed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(ConsonaSpacing.xs),
        child: Icon(
          icon,
          color: dimmed ? const Color(0xE0FFFFFF) : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

class _CaptureChrome {
  static const actionSize = 60.0;
}

class _SurfaceIconButton extends StatelessWidget {
  const _SurfaceIconButton({
    required this.icon,
    this.onTap,
    this.size = _CaptureChrome.actionSize,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x33FFFFFF),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Icon(icon, size: size * 0.42, color: const Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}

class _PhotoShutterButton extends StatelessWidget {
  const _PhotoShutterButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceIconButton(
      icon: Icons.photo_camera_rounded,
      onTap: onTap,
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.emphasize = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool emphasize;
  static const double size = _CaptureChrome.actionSize;

  @override
  Widget build(BuildContext context) {
    if (!emphasize && !filled) {
      return _SurfaceIconButton(icon: icon, onTap: onTap, size: size);
    }
    final enabled = onTap != null;
    final bg = emphasize ? const Color(0xFFE11D48) : const Color(0xFFFFFFFF);
    final fg = emphasize ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Icon(icon, color: fg, size: size * 0.42),
        ),
      ),
    );
  }
}

class _CaptureStatusChip extends StatelessWidget {
  const _CaptureStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(ConsonaRadii.full),
        border: Border.all(color: const Color(0x40FFFFFF)),
      ),
      child: Text(
        label,
        style: theme.typography.label.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

class _RecordTimerChip extends StatelessWidget {
  const _RecordTimerChip({
    required this.elapsed,
    required this.paused,
    required this.formatClock,
  });

  final Duration elapsed;
  final bool paused;
  final String Function(int ms) formatClock;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final ms = elapsed.inMilliseconds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(ConsonaRadii.full),
        border: Border.all(color: const Color(0x40FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: paused
                  ? theme.colors.foreground.withValues(alpha: 0.55)
                  : const Color(0xFFFF4D4D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatClock(ms),
            style: theme.typography.label.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomWheel extends StatelessWidget {
  const _ZoomWheel({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  double _valueForLocalY(double localY, double trackH) {
    final span = (max - min).clamp(0.01, 100.0);
    final localT = 1 - (localY / trackH).clamp(0.0, 1.0);
    return min + localT * span;
  }

  @override
  Widget build(BuildContext context) {
    final span = (max - min).clamp(0.01, 100.0);
    final t = ((value - min) / span).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackH = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              onChanged(_valueForLocalY(details.localPosition.dy, trackH));
            },
            onTapDown: (details) {
              onChanged(_valueForLocalY(details.localPosition.dy, trackH));
            },
            child: CustomPaint(
              size: Size(72, trackH),
              painter: _ZoomScalePainter(
                progress: t,
                min: min,
                max: max,
                labelStyle: ConsonaTheme.of(context).typography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xE0FFFFFF),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ZoomScalePainter extends CustomPainter {
  _ZoomScalePainter({
    required this.progress,
    required this.min,
    required this.max,
    required this.labelStyle,
  });

  final double progress;
  final double min;
  final double max;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final railX = size.width * 0.72;
    final tickPaint = Paint()
      ..color = const Color(0x4DFFFFFF)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final majorPaint = Paint()
      ..color = const Color(0xD1FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const majorCount = 5;
    const minorPerGap = 3;
    const totalMinor = (majorCount - 1) * (minorPerGap + 1);

    for (var i = 0; i <= totalMinor; i++) {
      final tickT = i / totalMinor;
      final y = size.height * (1 - tickT);
      final major = i % (minorPerGap + 1) == 0;
      final len = major ? 14.0 : 8.0;
      canvas.drawLine(
        Offset(railX - len, y),
        Offset(railX, y),
        major ? majorPaint : tickPaint,
      );
    }

    for (var i = 0; i < majorCount; i++) {
      final tickT = i / (majorCount - 1);
      final zoom = min + (max - min) * tickT;
      final y = size.height * (1 - tickT);
      final label = '${zoom.toStringAsFixed(zoom >= 10 ? 0 : 1)}×';
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(railX - 28, y);
      canvas.rotate(-1.57079632679);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final indicatorY = size.height * (1 - progress.clamp(0.0, 1.0));
    final tip = Offset(railX + 5, indicatorY);
    final baseRight = railX + 22;
    const halfH = 11.0;
    const r = 2.8;
    final path = _roundedTrianglePath(
      tip: tip,
      top: Offset(baseRight, indicatorY - halfH),
      bottom: Offset(baseRight, indicatorY + halfH),
      radius: r,
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFFF));
  }

  Path _roundedTrianglePath({
    required Offset tip,
    required Offset top,
    required Offset bottom,
    required double radius,
  }) {
    Offset toward(Offset from, Offset to, double dist) {
      final delta = to - from;
      final length = delta.distance;
      if (length == 0) return from;
      return from + delta * (dist / length);
    }

    final tipToTop = toward(tip, top, radius);
    final tipToBottom = toward(tip, bottom, radius);
    final topToTip = toward(top, tip, radius);
    final topToBottom = toward(top, bottom, radius);
    final bottomToTop = toward(bottom, top, radius);
    final bottomToTip = toward(bottom, tip, radius);

    return Path()
      ..moveTo(tipToTop.dx, tipToTop.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, tipToBottom.dx, tipToBottom.dy)
      ..lineTo(bottomToTip.dx, bottomToTip.dy)
      ..quadraticBezierTo(
        bottom.dx,
        bottom.dy,
        bottomToTop.dx,
        bottomToTop.dy,
      )
      ..lineTo(topToBottom.dx, topToBottom.dy)
      ..quadraticBezierTo(top.dx, top.dy, topToTip.dx, topToTip.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _ZoomScalePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.min != min ||
      oldDelegate.max != max;
}

/// Isolated video surface so timeline ticks don't rebuild the platform view.
class _ReviewVideoSurface extends StatelessWidget {
  const _ReviewVideoSurface({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

/// Serializes review [VideoPlayerController] ops (seek/play/pause) to avoid
/// Android A/V desync under rapid input.
class _ReviewTransportQueue {
  final List<Future<void> Function()> _pending = [];
  var _draining = false;

  Future<void> enqueue(Future<void> Function() op) {
    final completer = Completer<void>();
    _pending.add(() async {
      try {
        await op();
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });
    unawaited(_drain());
    return completer.future;
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    while (_pending.isNotEmpty) {
      final job = _pending.removeAt(0);
      await job();
    }
    _draining = false;
  }

  void clear() => _pending.clear();
}
