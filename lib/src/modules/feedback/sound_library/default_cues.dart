/// Consona Default Sound Cues — Synthesized micro-sound cue definitions
library;

import '../../assets/synth/sound_recipe.dart';
import '../models/feedback_profile.dart';

/// Soft, soothing UI sound kit.
///
/// Every cue is a pure (or almost pure) sine in the warm ~250–1000Hz range,
/// with a rounded onset (no click: attacks of 3ms+ on short cues, longer on
/// bigger ones), a smooth linear fade to silence, very light harmonics and a
/// low gain. Only [swipe] and [scroll] use noise, kept dark, airy and quiet.
///
/// Envelopes are sized so `attack + decay <= duration - release`, which means
/// every cue fades fully out instead of being cut off (another click source).
///
/// Cues still differ in duration, pitch and sweep direction so each one is
/// recognisable on its own (verified by `test/feedback/distinct_cues_test.dart`).
abstract final class DefaultSoundCues {
  /// Gentle detent: short, flat A5 sine with a soft rounded onset.
  static const SoundRecipe tick = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 880.0,
    envelope: SoundEnvelope(attackMs: 3.0, decayMs: 10.0, releaseMs: 2.0),
    durationMs: 16.0,
    gain: 0.25,
  );

  /// Selection change: a light, slightly rising sine 740 -> 800Hz.
  static const SoundRecipe selection = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 740.0,
    sweepTo: 800.0,
    envelope: SoundEnvelope(attackMs: 3.0, decayMs: 15.0, releaseMs: 3.0),
    durationMs: 22.0,
    gain: 0.22,
  );

  /// Soft touch: warm sine easing down 660 -> 520Hz.
  static const SoundRecipe tap = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 660.0,
    sweepTo: 520.0,
    harmonics: [0.06],
    envelope: SoundEnvelope(attackMs: 4.0, decayMs: 21.0, releaseMs: 4.0),
    durationMs: 30.0,
    gain: 0.28,
  );

  /// Switch on: soft sine gliding up a perfect fifth, 520 -> 780Hz.
  static const SoundRecipe toggleOn = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 520.0,
    sweepTo: 780.0,
    harmonics: [0.05],
    envelope: SoundEnvelope(attackMs: 5.0, decayMs: 29.0, releaseMs: 5.0),
    durationMs: 40.0,
    gain: 0.28,
  );

  /// Switch off: soft sine gliding down a perfect fifth, 780 -> 520Hz
  /// (mirror of [toggleOn]).
  static const SoundRecipe toggleOff = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 780.0,
    sweepTo: 520.0,
    harmonics: [0.05],
    envelope: SoundEnvelope(attackMs: 5.0, decayMs: 29.0, releaseMs: 5.0),
    durationMs: 40.0,
    gain: 0.28,
  );

  /// Soft round bubble: low sine dropping 440 -> 260Hz.
  static const SoundRecipe pop = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 440.0,
    sweepTo: 260.0,
    envelope: SoundEnvelope(attackMs: 5.0, decayMs: 44.0, releaseMs: 6.0),
    durationMs: 56.0,
    gain: 0.30,
  );

  /// Warm two-tone confirmation: C5 then G5 (a perfect fifth up), each a
  /// soft-onset bell that fades smoothly to silence.
  static const SoundRecipe successChime = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 523.25, // C5
    harmonics: [0.08],
    envelope: SoundEnvelope(attackMs: 6.0, decayMs: 130.0, releaseMs: 10.0),
    durationMs: 240.0,
    gain: 0.30,
    secondFrequency: 783.99, // G5
    secondStartMs: 90.0,
  );

  /// Gentle "mm-mm": two soft, low sine hums stepping down G4 -> E4.
  /// A calm "not quite" rather than a buzz.
  static const SoundRecipe errorBlip = SoundRecipe(
    waveform: SoundWaveform.sine,
    frequency: 392.0, // G4, easing slightly down
    sweepTo: 330.0,
    envelope: SoundEnvelope(attackMs: 8.0, decayMs: 50.0, releaseMs: 4.0),
    durationMs: 130.0,
    gain: 0.28,
    secondFrequency: 329.63, // E4
    secondStartMs: 65.0,
  );

  /// Soft breath on page swipe: dark low-passed noise easing 440 -> 240Hz
  /// with a slow swell and fade. [FeedbackEngine] also attenuates playback.
  static const SoundRecipe swipe = SoundRecipe(
    waveform: SoundWaveform.noise,
    frequency: 440.0,
    sweepTo: 240.0,
    harmonics: [],
    envelope: SoundEnvelope(
      attackMs: 90.0,
      decayMs: 150.0,
      sustain: 0.10,
      releaseMs: 120.0,
    ),
    durationMs: 360.0,
    gain: 0.22,
  );

  /// Reserved library cue (not emitted by scroll UI — swipe only): a short,
  /// quiet, airy whisper opening slightly 520 -> 640Hz.
  static const SoundRecipe scroll = SoundRecipe(
    waveform: SoundWaveform.noise,
    frequency: 520.0,
    sweepTo: 640.0,
    harmonics: [],
    envelope: SoundEnvelope(
      attackMs: 50.0,
      decayMs: 80.0,
      sustain: 0.06,
      releaseMs: 50.0,
    ),
    durationMs: 180.0,
    gain: 0.20,
  );

  static Map<String, SoundRecipe> get all => {
        'tick': tick,
        'tap': tap,
        'toggle_on': toggleOn,
        'toggle_off': toggleOff,
        'pop': pop,
        'selection': selection,
        'success_chime': successChime,
        'error_blip': errorBlip,
        'swipe': swipe,
        'scroll': scroll,
      };

  /// Cue-key suffix for the crisper/softer per-profile variants.
  static String variantKey(String cue, FeedbackProfile profile) =>
      switch (profile) {
        FeedbackProfile.mechanical => '$cue@mechanical',
        FeedbackProfile.subtle => '$cue@subtle',
        _ => cue,
      };

  /// Derives the profile-specific recipe for [base]:
  ///
  /// * `mechanical` is a little crisper — quicker attack (never under 2ms, so
  ///   still click-free), shorter decay and a faint 2nd harmonic — but its
  ///   brightness (harmonics <= 0.15) and gain (<= 0.4) are capped so it never
  ///   turns harsh.
  /// * `subtle` is softer still — slower attack, no harmonics, lower gain —
  ///   keeping `attack + decay` unchanged so the fade-out stays smooth.
  static SoundRecipe forProfile(SoundRecipe base, FeedbackProfile profile) {
    final isNoise = base.waveform == SoundWaveform.noise;
    switch (profile) {
      case FeedbackProfile.mechanical:
        final attack = (base.envelope.attackMs * 0.6).clamp(2.0, 1000.0);
        return base.copyWith(
          envelope: base.envelope.copyWith(
            attackMs: attack,
            decayMs: base.envelope.decayMs * 0.8,
          ),
          harmonics: isNoise
              ? base.harmonics
              : [
                  for (final h in base.harmonics) h.clamp(0.0, 0.15),
                  if (base.harmonics.isEmpty) 0.12,
                ],
          gain: (base.gain * 1.1).clamp(0.0, 0.4),
        );
      case FeedbackProfile.subtle:
        final attack = base.envelope.attackMs * 1.6;
        final decay = (base.envelope.decayMs - (attack - base.envelope.attackMs))
            .clamp(1.0, 10000.0);
        return base.copyWith(
          envelope: base.envelope.copyWith(attackMs: attack, decayMs: decay),
          harmonics: const [],
          gain: base.gain * 0.75,
        );
      case FeedbackProfile.tactile:
      case FeedbackProfile.silent:
        return base;
    }
  }

  /// All base cues plus their `@mechanical` / `@subtle` variants.
  static Map<String, SoundRecipe> get allWithVariants {
    final result = <String, SoundRecipe>{...all};
    for (final entry in all.entries) {
      for (final profile in const [
        FeedbackProfile.mechanical,
        FeedbackProfile.subtle,
      ]) {
        result[variantKey(entry.key, profile)] =
            forProfile(entry.value, profile);
      }
    }
    return result;
  }
}
