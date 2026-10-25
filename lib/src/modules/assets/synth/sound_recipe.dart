/// Consona Synthesized Sound Recipe & In-Memory WAV Renderer
library;

import 'dart:math' as math;
import 'dart:typed_data';

enum SoundWaveform {
  sine,
  triangle,
  noise,
}

class SoundEnvelope {
  const SoundEnvelope({
    this.attackMs = 1.0,
    this.decayMs = 18.0,
    this.sustain = 0.0,
    this.releaseMs = 6.0,
  });

  final double attackMs;
  final double decayMs;
  final double sustain;
  final double releaseMs;

  SoundEnvelope copyWith({
    double? attackMs,
    double? decayMs,
    double? sustain,
    double? releaseMs,
  }) {
    return SoundEnvelope(
      attackMs: attackMs ?? this.attackMs,
      decayMs: decayMs ?? this.decayMs,
      sustain: sustain ?? this.sustain,
      releaseMs: releaseMs ?? this.releaseMs,
    );
  }

  double at(double tMs, double totalMs) {
    if (tMs < attackMs) {
      return attackMs > 0 ? (tMs / attackMs) : 1.0;
    }
    if (tMs < attackMs + decayMs) {
      final progress = (tMs - attackMs) / (decayMs > 0 ? decayMs : 1.0);
      return 1.0 - (1.0 - sustain) * progress;
    }
    if (tMs < totalMs - releaseMs) {
      return sustain;
    }
    if (releaseMs > 0) {
      return (sustain * ((totalMs - tMs) / releaseMs)).clamp(0.0, 1.0);
    }
    return 0.0;
  }
}

class SoundRecipe {
  const SoundRecipe({
    this.waveform = SoundWaveform.sine,
    required this.frequency,
    double? sweepTo,
    this.harmonics = const [],
    this.envelope = const SoundEnvelope(),
    this.durationMs = 30.0,
    this.gain = 0.5,
    this.secondFrequency,
    this.secondStartMs = 0.0,
  }) : sweepTo = sweepTo ?? frequency;

  final SoundWaveform waveform;
  final double frequency;
  final double sweepTo;
  final List<double> harmonics;
  final SoundEnvelope envelope;
  final double durationMs;
  final double gain;

  /// Optional second tone (e.g. the upper note of a two-tone chime) that
  /// starts [secondStartMs] after the cue begins and reuses [envelope].
  final double? secondFrequency;
  final double secondStartMs;

  SoundRecipe copyWith({
    SoundWaveform? waveform,
    double? frequency,
    double? sweepTo,
    List<double>? harmonics,
    SoundEnvelope? envelope,
    double? durationMs,
    double? gain,
    double? secondFrequency,
    double? secondStartMs,
  }) {
    return SoundRecipe(
      waveform: waveform ?? this.waveform,
      frequency: frequency ?? this.frequency,
      sweepTo: sweepTo ?? this.sweepTo,
      harmonics: harmonics ?? this.harmonics,
      envelope: envelope ?? this.envelope,
      durationMs: durationMs ?? this.durationMs,
      gain: gain ?? this.gain,
      secondFrequency: secondFrequency ?? this.secondFrequency,
      secondStartMs: secondStartMs ?? this.secondStartMs,
    );
  }

  /// Renders 16-bit mono PCM wrapped in an in-memory WAV byte buffer.
  Uint8List toWav({int sampleRate = 44100}) {
    final n = (sampleRate * durationMs / 1000.0).round();
    final data = ByteData(44 + n * 2);
    _writeHeader(data, n, sampleRate);
    final samples = Float64List(n);

    final rng =
        math.Random(7); // Deterministic noise for consistent cue generation
    final norm = 1.0 / (1.0 + harmonics.fold<double>(0.0, (a, b) => a + b));
    var phase = 0.0;
    var phase2 = 0.0;
    var noiseLp = 0.0; // one-pole lowpass → wind / whisper band
    final second = secondFrequency;

    for (var i = 0; i < n; i++) {
      final f = frequency + (sweepTo - frequency) * (i / (n > 0 ? n : 1));
      phase += 2.0 * math.pi * f / sampleRate;

      var v = switch (waveform) {
        SoundWaveform.sine => math.sin(phase),
        SoundWaveform.triangle =>
          2.0 / math.pi * math.asin(math.sin(phase).clamp(-1.0, 1.0)),
        SoundWaveform.noise => () {
            final white = rng.nextDouble() * 2.0 - 1.0;
            // Cutoff tracks [frequency]/[sweepTo] so a descending sweep feels
            // like a gust fading, an ascending one like air opening up.
            final alpha = (f / (sampleRate * 0.22)).clamp(0.02, 0.55);
            noiseLp += alpha * (white - noiseLp);
            return noiseLp * 2.4;
          }(),
      };

      // Harmonics on noise stay very light — airy sheen, not pitched tone.
      if (waveform != SoundWaveform.noise) {
        for (var h = 0; h < harmonics.length; h++) {
          v += harmonics[h] * math.sin(phase * (h + 2));
        }
      } else {
        for (var h = 0; h < harmonics.length; h++) {
          v += harmonics[h] * 0.35 * math.sin(phase * (h + 2));
        }
      }

      final tMs = i * 1000.0 / sampleRate;
      var sample = v * envelope.at(tMs, durationMs) * gain * norm;

      if (second != null && tMs >= secondStartMs) {
        phase2 += 2.0 * math.pi * second / sampleRate;
        final env2 =
            envelope.at(tMs - secondStartMs, durationMs - secondStartMs);
        final tone2 = math.sin(phase2) + 0.2 * math.sin(phase2 * 2.0);
        sample += tone2 * env2 * gain * norm;
      }

      samples[i] = sample;
    }

    // Peak-normalise so every cue is clearly audible (short, quiet-gain cues
    // used to peak at ~0.3 and then got halved again by the 0.5 master volume).
    // Relative loudness between cues/profiles is still driven by [gain].
    var peak = 0.0;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    final target = (gain * 1.5).clamp(0.5, 0.85);
    final scale = peak > 0.0 ? target / peak : 0.0;
    for (var i = 0; i < n; i++) {
      final pcm = (samples[i] * scale * 32767.0)
          .round()
          .clamp(-32768, 32767)
          .toInt();
      data.setInt16(44 + i * 2, pcm, Endian.little);
    }

    return data.buffer.asUint8List();
  }

  static void _writeHeader(ByteData d, int samples, int rate) {
    void tag(int offset, String s) {
      for (var i = 0; i < 4; i++) {
        d.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    d.setUint32(4, 36 + samples * 2, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    d.setUint32(16, 16, Endian.little); // PCM header size
    d.setUint16(20, 1, Endian.little); // PCM format (1)
    d.setUint16(22, 1, Endian.little); // Mono (1)
    d.setUint32(24, rate, Endian.little);
    d.setUint32(28, rate * 2, Endian.little); // Byte rate (rate * 1 * 16/8)
    d.setUint16(32, 2, Endian.little); // Block align (1 * 16/8)
    d.setUint16(34, 16, Endian.little); // Bits per sample
    tag(36, 'data');
    d.setUint32(40, samples * 2, Endian.little);
  }
}
