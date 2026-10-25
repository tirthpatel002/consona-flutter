/// Fallback when the camera plugin is not linked (desktop / tests).
library;

import '../camera/camera_runtime.dart';

class ConsonaCameraRuntimeStub implements ConsonaCameraRuntime {
  @override
  bool get isPluginAvailable => false;

  @override
  Future<List<ConsonaCameraLens>> availableLenses() async => const [];

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<int> fileLength(String path) async => 0;

  @override
  String basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  @override
  String inferMimeType({required String path, required bool isVideo}) {
    if (isVideo) return 'video/mp4';
    return 'image/jpeg';
  }

  @override
  Future<ConsonaCameraHandle> openCamera(ConsonaCameraLens lens) async {
    throw UnsupportedError('Camera plugin is not available');
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<ConsonaCameraPermissionOutcome> resolveCameraPermission() async {
    return const ConsonaCameraPermissionOutcome(granted: false);
  }

  @override
  Future<ConsonaCameraPermissionOutcome> resolveMicrophonePermission() async {
    return const ConsonaCameraPermissionOutcome(granted: false);
  }
}
