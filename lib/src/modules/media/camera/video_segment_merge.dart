/// Multi-clip video merge contract (implemented in [adapters/]).
library;

import 'camera_runtime.dart';

/// One recorded clip with the lens used when it was captured.
class ConsonaVideoSegment {
  const ConsonaVideoSegment({
    required this.path,
    required this.lens,
    this.sensorOrientationDegrees = 90,
  });

  final String path;
  final ConsonaCameraLens lens;

  /// From [ConsonaCameraHandle.sensorOrientationDegrees] when the clip was saved.
  final int sensorOrientationDegrees;
}

/// Outcome of merging ordered segment files (originals are never deleted).
class ConsonaVideoMergeOutcome {
  const ConsonaVideoMergeOutcome({
    required this.playbackPath,
    required this.segmentPaths,
    this.combinedSuccessfully = true,
    this.notice,
  });

  /// File used for preview / confirm (merged or best single segment).
  final String playbackPath;

  /// Every segment kept on disk, in capture order.
  final List<String> segmentPaths;

  final bool combinedSuccessfully;

  /// Short copy for a minimal inline banner (null when fully successful).
  final String? notice;
}

abstract class ConsonaVideoSegmentMerger {
  Future<ConsonaVideoMergeOutcome> mergeSegments(
    List<ConsonaVideoSegment> orderedSegments,
  );
}
