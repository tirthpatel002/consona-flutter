/// FFmpeg segment merge — only this file imports [ffmpeg_kit_flutter].
library;

import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path/path.dart' as p;

import '../camera/video_segment_merge.dart';
import 'video_segment_merge_util.dart';

class ConsonaFfmpegVideoSegmentMerger implements ConsonaVideoSegmentMerger {
  @override
  Future<ConsonaVideoMergeOutcome> mergeSegments(
    List<ConsonaVideoSegment> orderedSegments,
  ) async {
    if (orderedSegments.isEmpty) {
      throw ArgumentError.value(orderedSegments, 'orderedSegments', 'empty');
    }
    final orderedPaths =
        orderedSegments.map((s) => s.path).toList(growable: false);

    if (orderedPaths.length == 1) {
      return ConsonaVideoMergeOutcome(
        playbackPath: orderedPaths.first,
        segmentPaths: List<String>.from(orderedPaths),
      );
    }

    // Check which files actually exist (parallel).
    final existsFlags =
        await Future.wait(orderedPaths.map(File.new).map((f) => f.exists()));
    final existingSegments = <ConsonaVideoSegment>[];
    for (var i = 0; i < orderedSegments.length; i++) {
      if (existsFlags[i]) existingSegments.add(orderedSegments[i]);
    }

    if (existingSegments.isEmpty) throw StateError('No segment files on disk');

    if (existingSegments.length < orderedSegments.length) {
      final best = await pickLongestVideoSegment(
        existingSegments.map((s) => s.path).toList(),
      );
      return ConsonaVideoMergeOutcome(
        playbackPath: best,
        segmentPaths: List<String>.from(orderedPaths),
        combinedSuccessfully: false,
        notice: 'Part of the recording was missing. Using the longest saved clip.',
      );
    }

    final out = p.join(
      Directory.systemTemp.path,
      'consona_merged_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );

    // Same-lens clips: try stream copy first (fast, lossless).
    if (!segmentsUseMixedLenses(existingSegments)) {
      final listPath = await writeConcatListFile(
        existingSegments.map((s) => s.path).toList(),
      );
      final copyCmd =
          buildConcatCopyCommand(listPath: listPath, outputPath: out);
      final copySession = await FFmpegKit.execute(copyCmd);
      final copyCode = await copySession.getReturnCode();
      try {
        await File(listPath).delete();
      } catch (_) {}
      if (ReturnCode.isSuccess(copyCode) && File(out).existsSync()) {
        return ConsonaVideoMergeOutcome(
          playbackPath: out,
          segmentPaths: List<String>.from(orderedPaths),
        );
      }
    }

    // Mixed lenses or copy failed: re-encode to a common portrait canvas.
    // FFmpeg autorotate (the default) reads each clip's rotation metadata
    // and decodes frames already upright — no manual transpose needed.
    final reencodeCmd = buildPortraitMergeCommand(
      orderedSegments: existingSegments,
      outputPath: out,
    );
    final session = await FFmpegKit.execute(reencodeCmd);
    final code = await session.getReturnCode();

    if (ReturnCode.isSuccess(code) && File(out).existsSync()) {
      return ConsonaVideoMergeOutcome(
        playbackPath: out,
        segmentPaths: List<String>.from(orderedPaths),
      );
    }

    // Full failure — hand the longest raw segment back unchanged.
    final best = await pickLongestVideoSegment(
      existingSegments.map((s) => s.path).toList(),
    );
    return ConsonaVideoMergeOutcome(
      playbackPath: best,
      segmentPaths: List<String>.from(orderedPaths),
      combinedSuccessfully: false,
      notice: 'Clips couldn\'t be combined. Preview uses the longest part.',
    );
  }
}
