/// Consona Sound Engine — Micro-cue playback and prewarming
library;

import 'package:flutter/foundation.dart';

import '../models/feedback_profile.dart';
import '../player/sound_player.dart';
import '../sound_library/default_cues.dart';
import '../sound_library/sound_library.dart';

class SoundEngine {
  SoundEngine({
    required this.library,
    required this.player,
    this.enabled = true,
    this.volume = 0.8,
  });

  final SoundLibrary library;
  final SoundPlayer player;
  bool enabled;
  double volume;

  /// Prewarms synth sound cues in the background.
  Future<void> prewarm([List<String>? cueKeys]) async {
    for (final cue in cueKeys ?? DefaultSoundCues.allWithVariants.keys) {
      try {
        await library.loadCueBytes(cue);
      } catch (e, st) {
        debugPrint('SoundEngine: failed to pre-render cue "$cue": $e\n$st');
      }
    }
  }

  /// Plays a sound cue by name.
  Future<void> playCue(
    String cueName, {
    double? volumeMultiplier,
    double? volumeOverride,
    FeedbackProfile profile = FeedbackProfile.tactile,
  }) async {
    final baseVol = volumeOverride ?? volume;
    if (!enabled || baseVol <= 0.0) return;

    try {
      final bytes =
          await library.loadCueBytes(library.resolveKey(cueName, profile));
      if (bytes == null) {
        debugPrint('SoundEngine: no sound data for cue "$cueName" '
            '(profile ${profile.name}); nothing played.');
      } else {
        final effectiveVolume =
            (baseVol * (volumeMultiplier ?? 1.0)).clamp(0.0, 1.0);
        await player.playBytes(bytes, volume: effectiveVolume);
      }
    } catch (e, st) {
      // Never crash UI, but never hide the failure either.
      debugPrint('SoundEngine: playing cue "$cueName" failed: $e\n$st');
    }
  }

  void dispose() {
    player.dispose();
  }
}
