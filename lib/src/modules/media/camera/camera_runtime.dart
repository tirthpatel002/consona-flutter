/// Platform camera session contract — implemented in [adapters/].
library;

import 'package:flutter/widgets.dart';

enum ConsonaCameraLens { front, back }

class ConsonaCameraPermissionOutcome {
  const ConsonaCameraPermissionOutcome({
    required this.granted,
    this.openSettings = false,
  });

  final bool granted;
  final bool openSettings;
}

/// Live camera session (preview + capture).
abstract class ConsonaCameraHandle {
  bool get isInitialized;
  ConsonaCameraLens get lens;

  /// Sensor orientation in degrees (0/90/180/270) when known.
  int get sensorOrientationDegrees;

  /// Width/height of the sensor preview (may be swapped vs layout).
  double? get previewWidth;
  double? get previewHeight;

  Widget buildPreview();

  Future<void> dispose();
  Future<double> getMinZoom();
  Future<double> getMaxZoom();
  Future<void> setZoom(double level);
  Future<String> takePicture();
  Future<void> startVideoRecording();
  Future<void> pauseVideoRecording();
  Future<void> resumeVideoRecording();
  Future<String> stopVideoRecording();
}

/// File helpers kept in the adapter so UI stays IO-agnostic where possible.
abstract class ConsonaCameraRuntime {
  bool get isPluginAvailable;

  Future<ConsonaCameraPermissionOutcome> resolveCameraPermission();
  Future<ConsonaCameraPermissionOutcome> resolveMicrophonePermission();
  Future<void> openAppSettings();

  Future<List<ConsonaCameraLens>> availableLenses();
  Future<ConsonaCameraHandle> openCamera(ConsonaCameraLens lens);

  Future<bool> fileExists(String path);
  Future<int> fileLength(String path);
  String basename(String path);
  String inferMimeType({required String path, required bool isVideo});
}
