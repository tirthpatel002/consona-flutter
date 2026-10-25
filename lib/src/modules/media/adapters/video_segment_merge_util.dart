/// Shared helpers for segment merge (no plugin imports).
library;

import 'dart:io';

import '../camera/video_segment_merge.dart';

/// Picks the largest segment by byte size (proxy for longest take).
Future<String> pickLongestVideoSegment(List<String> paths) async {
  if (paths.isEmpty) {
    throw ArgumentError.value(paths, 'paths', 'must not be empty');
  }
  if (paths.length == 1) return paths.first;
  var best = paths.first;
  var bestLen = await File(best).length();
  for (var i = 1; i < paths.length; i++) {
    final len = await File(paths[i]).length();
    if (len > bestLen) {
      best = paths[i];
      bestLen = len;
    }
  }
  return best;
}

Future<String> writeConcatListFile(List<String> paths) async {
  final file = File(
    '${Directory.systemTemp.path}/consona_concat_'
    '${DateTime.now().microsecondsSinceEpoch}.txt',
  );
  final buffer = StringBuffer();
  for (final path in paths) {
    buffer.writeln("file '${path.replaceAll("'", "'\\''")}'");
  }
  await file.writeAsString(buffer.toString());
  return file.path;
}

String escapeFfmpegPath(String path) => path.replaceAll("'", "'\\''");

bool segmentsUseMixedLenses(List<ConsonaVideoSegment> segments) {
  if (segments.length < 2) return false;
  return segments.map((s) => s.lens).toSet().length > 1;
}

/// Fast concat demuxer copy — no re-encode, no rotation fix.
/// Only safe when both clips have identical codec/rotation metadata.
String buildConcatCopyCommand({
  required String listPath,
  required String outputPath,
}) {
  final list = escapeFfmpegPath(listPath);
  final out = escapeFfmpegPath(outputPath);
  return "-y -f concat -safe 0 -i '$list' -c copy -movflags +faststart '$out'";
}

/// Re-encode all clips to a shared portrait canvas.
///
/// FFmpeg's default autorotate is ON — it reads each clip's rotation
/// metadata and decodes frames already upright. The same filter chain
/// works for every clip regardless of which lens recorded it.
/// No per-lens hflip/vflip/transpose is needed or applied.
String buildPortraitMergeCommand({
  required List<ConsonaVideoSegment> orderedSegments,
  required String outputPath,
  int targetWidth = 720,
  int targetHeight = 1280,
}) {
  assert(orderedSegments.length >= 2);

  final inputs = orderedSegments
      .map((s) => "-i '${escapeFfmpegPath(s.path)}'")
      .join(' ');

  final filters = StringBuffer();
  final concatInputs = StringBuffer();

  for (var i = 0; i < orderedSegments.length; i++) {
    // Autorotate ON (FFmpeg default): frames arrive already portrait-upright.
    // Scale to target, pad to fill, force consistent pixel format.
    filters
      ..write('[$i:v]setpts=PTS-STARTPTS,')
      ..write('scale=$targetWidth:$targetHeight')
      ..write(':force_original_aspect_ratio=decrease,')
      ..write('pad=$targetWidth:$targetHeight:(ow-iw)/2:(oh-ih)/2:black,')
      ..write('setsar=1,format=yuv420p[v$i];')
      ..write('[$i:a]asetpts=PTS-STARTPTS,')
      ..write('aresample=async=1:first_pts=0[a$i];');
    concatInputs.write('[v$i][a$i]');
  }

  final n = orderedSegments.length;
  filters.write('${concatInputs}concat=n=$n:v=1:a=1[outv][outa]');

  final out = escapeFfmpegPath(outputPath);
  return '-y $inputs '
      '-filter_complex "${filters.toString()}" '
      '-map "[outv]" -map "[outa]" '
      '-c:v libx264 -preset ultrafast -crf 26 -threads 0 '
      '-c:a aac -b:a 96k -movflags +faststart '
      "'$out'";
}
