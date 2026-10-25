/// FFprobe helpers for segment orientation (ffmpeg_kit only here).
library;

import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';

import '../camera/camera_runtime.dart';

/// Reads the container `rotate` tag (0/90/180/270) when present.
Future<int?> probeVideoRotationDegrees(String path) async {
  try {
    final session = await FFprobeKit.getMediaInformation(path, 8000);
    final info = session.getMediaInformation();
    if (info == null) return null;
    for (final stream in info.getStreams()) {
      if (stream.getType() != 'video') continue;
      final tags = stream.getTags();
      if (tags == null) continue;
      final raw = tags['rotate'] ?? tags['ROTATE'];
      if (raw == null) continue;
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) return parsed % 360;
    }
  } catch (_) {}
  return null;
}

/// Fallback when the file has no rotation tag (common on some Android takes).
int defaultRotationForLens(ConsonaCameraLens lens) {
  return switch (lens) {
    ConsonaCameraLens.front => 270,
    ConsonaCameraLens.back => 90,
  };
}
