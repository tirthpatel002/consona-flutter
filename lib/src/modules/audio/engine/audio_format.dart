/// Shared audio timestamp formatting.
library;

/// Formats [duration] as `m:ss` or `h:mm:ss` with tabular-friendly padding.
String formatAudioTimestamp(Duration duration) {
  final total = duration.inSeconds.clamp(0, 359999);
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:$mm:$ss';
  return '$mm:$ss';
}
