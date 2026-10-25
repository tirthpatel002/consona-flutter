/// Consona Haptic Engine — Platform vibration and taptic feedback
library;

import 'package:flutter/services.dart';
import '../models/feedback_event.dart';

class HapticEngine {
  const HapticEngine({this.enabled = true});

  final bool enabled;

  Future<void> trigger(HapticIntensity intensity) async {
    if (!enabled || intensity == HapticIntensity.none) return;

    try {
      switch (intensity) {
        case HapticIntensity.none:
          break;
        case HapticIntensity.selection:
          await HapticFeedback.selectionClick();
        case HapticIntensity.light:
          await HapticFeedback.lightImpact();
        case HapticIntensity.medium:
          await HapticFeedback.mediumImpact();
        case HapticIntensity.heavy:
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Ignored: platform does not support haptics
    }
  }

  Future<void> selection() => trigger(HapticIntensity.selection);
  Future<void> light() => trigger(HapticIntensity.light);
  Future<void> medium() => trigger(HapticIntensity.medium);
  Future<void> heavy() => trigger(HapticIntensity.heavy);
}
