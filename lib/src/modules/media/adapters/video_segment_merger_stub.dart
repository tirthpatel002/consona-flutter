/// Merge fallback when FFmpeg is unavailable — keeps all segments, plays longest.
library;

import '../camera/video_segment_merge.dart';
import 'video_segment_merge_util.dart';

class ConsonaVideoSegmentMergerStub implements ConsonaVideoSegmentMerger {
  @override
  Future<ConsonaVideoMergeOutcome> mergeSegments(
    List<ConsonaVideoSegment> orderedSegments,
  ) async {
    if (orderedSegments.isEmpty) {
      throw ArgumentError.value(orderedSegments, 'orderedSegments', 'empty');
    }
    final orderedPaths =
        orderedSegments.map((segment) => segment.path).toList(growable: false);
    if (orderedPaths.length == 1) {
      return ConsonaVideoMergeOutcome(
        playbackPath: orderedPaths.first,
        segmentPaths: List<String>.from(orderedPaths),
      );
    }
    final best = await pickLongestVideoSegment(orderedPaths);
    return ConsonaVideoMergeOutcome(
      playbackPath: best,
      segmentPaths: List<String>.from(orderedPaths),
      combinedSuccessfully: false,
      notice: 'Clips couldn’t be combined. Preview uses the longest part.',
    );
  }
}
