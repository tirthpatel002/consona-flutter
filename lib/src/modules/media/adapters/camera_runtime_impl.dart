/// Camera plugin adapter — only this file imports `camera` / `permission_handler`.
library;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart' as ph;

import '../camera/camera_runtime.dart';

class ConsonaCameraRuntimeImpl implements ConsonaCameraRuntime {
  @override
  bool get isPluginAvailable => true;

  List<CameraDescription> _cameras = const [];

  @override
  Future<List<ConsonaCameraLens>> availableLenses() async {
    _cameras = await availableCameras();
    final lenses = <ConsonaCameraLens>{};
    for (final c in _cameras) {
      lenses.add(
        c.lensDirection == CameraLensDirection.front
            ? ConsonaCameraLens.front
            : ConsonaCameraLens.back,
      );
    }
    return lenses.toList(growable: false);
  }

  CameraDescription _pick(ConsonaCameraLens lens) {
    final desired = lens == ConsonaCameraLens.front
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final match =
        _cameras.where((c) => c.lensDirection == desired).toList(growable: false);
    if (match.isNotEmpty) return match.first;
    if (_cameras.isEmpty) {
      throw StateError('No cameras enumerated');
    }
    return _cameras.first;
  }

  @override
  Future<ConsonaCameraHandle> openCamera(ConsonaCameraLens lens) async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    final description = _pick(lens);
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!kIsWeb) {
      if (Platform.isIOS) {
        try {
          await controller.prepareForVideoRecording();
        } catch (e) {
          debugPrint('ConsonaCamera prepareForVideoRecording: $e');
        }
      }
    }
    final minZoom = await controller.getMinZoomLevel();
    final maxZoom = await controller.getMaxZoomLevel();
    final zoom = minZoom.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(zoom);
    return _CameraHandleImpl(
      controller: controller,
      lens: description.lensDirection == CameraLensDirection.front
          ? ConsonaCameraLens.front
          : ConsonaCameraLens.back,
      initialZoom: zoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  @override
  Future<bool> fileExists(String path) => File(path).exists();

  @override
  Future<int> fileLength(String path) => File(path).length();

  @override
  String basename(String path) => p.basename(path);

  @override
  String inferMimeType({required String path, required bool isVideo}) {
    final ext = p.extension(path).toLowerCase();
    if (isVideo) {
      return switch (ext) {
        '.mov' => 'video/quicktime',
        '.webm' => 'video/webm',
        _ => 'video/mp4',
      };
    }
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  @override
  Future<void> openAppSettings() => ph.openAppSettings();

  Future<ConsonaCameraPermissionOutcome> _resolve(ph.Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return const ConsonaCameraPermissionOutcome(granted: true);
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return const ConsonaCameraPermissionOutcome(
        granted: false,
        openSettings: true,
      );
    }
    status = await permission.request();
    if (status.isGranted || status.isLimited) {
      return const ConsonaCameraPermissionOutcome(granted: true);
    }
    return ConsonaCameraPermissionOutcome(
      granted: false,
      openSettings: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  @override
  Future<ConsonaCameraPermissionOutcome> resolveCameraPermission() =>
      _resolve(ph.Permission.camera);

  @override
  Future<ConsonaCameraPermissionOutcome> resolveMicrophonePermission() =>
      _resolve(ph.Permission.microphone);
}

class _CameraHandleImpl implements ConsonaCameraHandle {
  _CameraHandleImpl({
    required CameraController controller,
    required this.lens,
    required double initialZoom,
    required double minZoom,
    required double maxZoom,
  })  : _controller = controller,
        _minZoom = minZoom,
        _maxZoom = maxZoom,
        _zoom = initialZoom;

  CameraController _controller;
  @override
  final ConsonaCameraLens lens;
  final double _minZoom;
  final double _maxZoom;
  double _zoom;

  @override
  int get sensorOrientationDegrees =>
      _controller.description.sensorOrientation;
  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  double? get previewWidth => _controller.value.previewSize?.height;

  @override
  double? get previewHeight => _controller.value.previewSize?.width;

  @override
  Widget buildPreview() {
    if (!isInitialized) return const SizedBox.shrink();
    return CameraPreview(_controller);
  }

  @override
  Future<void> dispose() => _controller.dispose();

  @override
  Future<double> getMaxZoom() async => _maxZoom;

  @override
  Future<double> getMinZoom() async => _minZoom;

  @override
  Future<void> pauseVideoRecording() => _controller.pauseVideoRecording();

  @override
  Future<void> resumeVideoRecording() => _controller.resumeVideoRecording();

  @override
  Future<void> setZoom(double level) async {
    final next = level.clamp(_minZoom, _maxZoom);
    if ((next - _zoom).abs() < 0.0005) return;
    _zoom = next;
    try {
      await _controller.setZoomLevel(next);
    } catch (e) {
      debugPrint('ConsonaCamera setZoom: $e');
    }
  }

  @override
  Future<void> startVideoRecording() => _controller.startVideoRecording();

  @override
  Future<String> stopVideoRecording() async {
    final file = await _controller.stopVideoRecording();
    return file.path;
  }

  @override
  Future<String> takePicture() async {
    final file = await _controller.takePicture();
    return file.path;
  }

}
