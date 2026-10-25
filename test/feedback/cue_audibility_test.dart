import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  test('every cue (and profile variant) is clearly audible, not near-silent',
      () {
    for (final e in DefaultSoundCues.allWithVariants.entries) {
      final wav = e.value.toWav();
      final pcm = Int16List.sublistView(wav, 44);
      var peak = 0;
      for (final s in pcm) {
        if (s.abs() > peak) peak = s.abs();
      }
      final p = peak / 32768.0;
      expect(p, greaterThan(0.45), reason: '${e.key} peak=$p too quiet');
      expect(p, lessThanOrEqualTo(0.9), reason: '${e.key} peak=$p too hot');
    }
  });
}
