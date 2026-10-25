import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  group('SoundRecipe & WAV Renderer', () {
    test('renders valid 16-bit PCM WAV headers', () {
      const recipe = SoundRecipe(
        frequency: 440.0,
        durationMs: 20.0,
      );

      final wav = recipe.toWav(sampleRate: 44100);
      expect(wav.length, greaterThan(44));

      final data = ByteData.sublistView(wav);

      // Verify RIFF header
      final riff = String.fromCharCodes(wav.sublist(0, 4));
      expect(riff, equals('RIFF'));

      // Verify WAVE tag
      final wave = String.fromCharCodes(wav.sublist(8, 12));
      expect(wave, equals('WAVE'));

      // Verify fmt tag
      final fmt = String.fromCharCodes(wav.sublist(12, 16));
      expect(fmt, equals('fmt '));

      // Verify PCM format = 1
      expect(data.getUint16(20, Endian.little), equals(1));

      // Verify mono channel = 1
      expect(data.getUint16(22, Endian.little), equals(1));

      // Verify sample rate
      expect(data.getUint32(24, Endian.little), equals(44100));

      // Verify bits per sample = 16
      expect(data.getUint16(34, Endian.little), equals(16));

      // Verify data tag
      final dataTag = String.fromCharCodes(wav.sublist(36, 40));
      expect(dataTag, equals('data'));
    });

    test('deterministic noise waveform produces identical byte buffer', () {
      const recipe = SoundRecipe(
        waveform: SoundWaveform.noise,
        frequency: 1000.0,
        durationMs: 25.0,
      );

      final wavA = recipe.toWav();
      final wavB = recipe.toWav();

      expect(wavA, equals(wavB));
    });

    test('all default sound cues render successfully', () {
      for (final entry in DefaultSoundCues.all.entries) {
        final wav = entry.value.toWav();
        expect(wav.length, greaterThan(44), reason: 'Cue "${entry.key}" failed');
      }
    });
  });
}
