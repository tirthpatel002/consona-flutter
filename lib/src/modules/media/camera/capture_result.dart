/// Result returned when the user confirms a camera capture.
library;

import 'package:flutter/widgets.dart';

/// Kind of media captured from [ConsonaCamera].
enum ConsonaCapturedMediaKind {
  image,
  video,
}

/// Confirmed photo or video from the camera sheet.
class ConsonaCameraCaptureResult {
  const ConsonaCameraCaptureResult({
    required this.path,
    required this.kind,
    required this.mimeType,
    required this.fileName,
    required this.fileSize,
    this.durationMs,
    this.isMuted = false,
    this.sourceSegmentPaths,
    this.notice,
  });

  final String path;
  final ConsonaCapturedMediaKind kind;
  final String mimeType;
  final String fileName;
  final int fileSize;
  final int? durationMs;
  final bool isMuted;

  /// Original segment files when multi-clip capture ran (never deleted by Consona).
  final List<String>? sourceSegmentPaths;

  /// Short user-facing note (e.g. merge fallback); optional.
  final String? notice;

  bool get isVideo => kind == ConsonaCapturedMediaKind.video;
  bool get isImage => kind == ConsonaCapturedMediaKind.image;

  ConsonaCameraCaptureResult copyWith({
    String? path,
    ConsonaCapturedMediaKind? kind,
    String? mimeType,
    String? fileName,
    int? fileSize,
    int? durationMs,
    bool? isMuted,
    List<String>? sourceSegmentPaths,
    String? notice,
  }) {
    return ConsonaCameraCaptureResult(
      path: path ?? this.path,
      kind: kind ?? this.kind,
      mimeType: mimeType ?? this.mimeType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      durationMs: durationMs ?? this.durationMs,
      isMuted: isMuted ?? this.isMuted,
      sourceSegmentPaths: sourceSegmentPaths ?? this.sourceSegmentPaths,
      notice: notice ?? this.notice,
    );
  }
}

/// Optional hook to open an app-specific editor after capture.
typedef ConsonaCameraEditCallback = Future<ConsonaCameraCaptureResult?>
    Function(
  BuildContext context,
  ConsonaCameraCaptureResult draft,
);
