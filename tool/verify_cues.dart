// ignore_for_file: avoid_relative_lib_imports, avoid_print
// Renders every default cue to a real WAV file and validates it.
// Run: dart run tool/verify_cues.dart [outDir]
import 'dart:io';
import 'dart:typed_data';
import '../lib/src/modules/feedback/sound_library/default_cues.dart';

int u16(ByteData d, int o) => d.getUint16(o, Endian.little);
int u32(ByteData d, int o) => d.getUint32(o, Endian.little);

void main(List<String> args) {
  final out = Directory(args.isNotEmpty ? args[0] : '/tmp/consona_cues')
    ..createSync(recursive: true);
  final seen = <String, String>{};
  var failures = 0;
  for (final e in DefaultSoundCues.allWithVariants.entries) {
    final b = e.value.toWav();
    final d = ByteData.sublistView(b);
    final errs = <String>[];
    String tag(int o) => String.fromCharCodes(b.sublist(o, o + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') errs.add('bad RIFF/WAVE');
    if (u32(d, 4) != b.length - 8) errs.add('RIFF size ${u32(d, 4)} != ${b.length - 8}');
    if (tag(12) != 'fmt ' || u32(d, 16) != 16) errs.add('bad fmt chunk');
    if (u16(d, 20) != 1) errs.add('not PCM');
    if (u16(d, 22) != 1) errs.add('not mono');
    if (u16(d, 34) != 16) errs.add('not 16-bit');
    if (u32(d, 28) != u32(d, 24) * 2 || u16(d, 32) != 2) errs.add('bad byte rate/align');
    if (tag(36) != 'data' || u32(d, 40) != b.length - 44) errs.add('data len ${u32(d, 40)} != ${b.length - 44}');
    var peak = 0.0;
    for (var o = 44; o + 1 < b.length; o += 2) {
      final v = d.getInt16(o, Endian.little).abs() / 32768.0;
      if (v > peak) peak = v;
    }
    if (peak <= 0.1) errs.add('too quiet peak=$peak');
    final key = b.join(',');
    final dup = seen[key];
    if (dup != null) errs.add('identical bytes to $dup');
    seen[key] = e.key;
    File('${out.path}/${e.key.replaceAll('@', '_')}.wav').writeAsBytesSync(b);
    final s = '${e.key.padRight(24)} bytes=${b.length} rate=${u32(d, 24)} peak=${peak.toStringAsFixed(3)}';
    print(errs.isEmpty ? 'OK   $s' : 'FAIL $s  ${errs.join('; ')}');
    if (errs.isNotEmpty) failures++;
  }
  print(failures == 0 ? 'ALL ${seen.length} CUES VALID' : '$failures FAILURES');
  exit(failures == 0 ? 0 : 1);
}
