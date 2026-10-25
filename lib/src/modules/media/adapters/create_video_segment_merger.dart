library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import '../camera/video_segment_merge.dart';
import 'ffmpeg_video_segment_merger.dart';
import 'video_segment_merger_stub.dart';

Future<ConsonaVideoSegmentMerger> createVideoSegmentMerger() async {
  if (kIsWeb) return ConsonaVideoSegmentMergerStub();
  try {
    // Avoid blocking the UI thread on startup with a full FFmpeg probe.
    return ConsonaFfmpegVideoSegmentMerger();
  } on MissingPluginException catch (e) {
    debugPrint('createVideoSegmentMerger: FFmpeg missing ($e) — stub.');
    return ConsonaVideoSegmentMergerStub();
  }
}
