/// Consona Feedback Engine — Unified sensory feedback orchestrator
library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../context/feedback_scope.dart';
import '../models/feedback_config.dart';
import '../models/feedback_event.dart';
import '../models/feedback_profile.dart';
import 'haptic_engine.dart';
import 'sound_engine.dart';

class FeedbackEngine {
  FeedbackEngine({
    this.config = const FeedbackConfig(),
    HapticEngine? hapticEngine,
    SoundEngine? soundEngine,
  })  : _hapticEngine = hapticEngine ?? const HapticEngine(),
        _soundEngine = soundEngine;

  FeedbackConfig config;
  final HapticEngine _hapticEngine;
  final SoundEngine? _soundEngine;

  static FeedbackEngine of(BuildContext context) {
    return FeedbackScope.of(context);
  }

  static FeedbackEngine? maybeOf(BuildContext context) {
    return FeedbackScope.maybeOf(context);
  }

  /// Triggers a unified sensory feedback event (sound + haptics).
  Future<void> trigger(FeedbackEvent event) async {
    if (!config.enabled || config.profile == FeedbackProfile.silent) return;

    final hapticIntensity = switch (config.profile) {
      FeedbackProfile.silent => HapticIntensity.none,
      FeedbackProfile.subtle => switch (event) {
          FeedbackEvent.selection => HapticIntensity.selection,
          FeedbackEvent.tap => HapticIntensity.selection,
          FeedbackEvent.toggleOn ||
          FeedbackEvent.toggleOff =>
            HapticIntensity.light,
          FeedbackEvent.error => HapticIntensity.medium,
          FeedbackEvent.swipe => HapticIntensity.selection,
          FeedbackEvent.scroll => HapticIntensity.none,
          _ => HapticIntensity.selection,
        },
      FeedbackProfile.tactile => switch (event) {
          FeedbackEvent.tap => HapticIntensity.light,
          FeedbackEvent.toggleOn ||
          FeedbackEvent.toggleOff =>
            HapticIntensity.light,
          FeedbackEvent.selection ||
          FeedbackEvent.tick =>
            HapticIntensity.selection,
          FeedbackEvent.success => HapticIntensity.medium,
          FeedbackEvent.error => HapticIntensity.heavy,
          FeedbackEvent.pop => HapticIntensity.light,
          FeedbackEvent.swipe => HapticIntensity.selection,
          FeedbackEvent.scroll => HapticIntensity.none,
        },
      FeedbackProfile.mechanical => switch (event) {
          FeedbackEvent.tap => HapticIntensity.medium,
          FeedbackEvent.toggleOn ||
          FeedbackEvent.toggleOff =>
            HapticIntensity.medium,
          FeedbackEvent.selection ||
          FeedbackEvent.tick =>
            HapticIntensity.light,
          FeedbackEvent.success => HapticIntensity.heavy,
          FeedbackEvent.error => HapticIntensity.heavy,
          FeedbackEvent.pop => HapticIntensity.medium,
          FeedbackEvent.swipe => HapticIntensity.light,
          FeedbackEvent.scroll => HapticIntensity.none,
        },
    };

    final soundCue = switch (event) {
      FeedbackEvent.tap => 'tap',
      FeedbackEvent.toggleOn => 'toggle_on',
      FeedbackEvent.toggleOff => 'toggle_off',
      FeedbackEvent.tick => 'tick',
      FeedbackEvent.pop => 'pop',
      FeedbackEvent.selection => 'selection',
      FeedbackEvent.success => 'success_chime',
      FeedbackEvent.error => 'error_blip',
      FeedbackEvent.swipe => 'swipe',
      FeedbackEvent.scroll => 'scroll',
    };

    final volumeFactor = switch (config.profile) {
      FeedbackProfile.subtle => 0.6,
      FeedbackProfile.mechanical => 1.2,
      _ => 1.0,
    };

    // Wind / whisper cues stay far under the rest of the kit.
    final hush = switch (event) {
      FeedbackEvent.swipe => 0.22,
      _ => 1.0,
    };

    if (config.hapticsEnabled) {
      await _hapticEngine.trigger(hapticIntensity);
    }

    // Scroll sound is intentionally disabled — swipe-only wind cue.
    if (event == FeedbackEvent.scroll) return;

    if (config.soundEnabled && _soundEngine != null) {
      await _soundEngine.playCue(
        soundCue,
        volumeMultiplier: volumeFactor * hush,
        volumeOverride: config.volume,
        profile: config.profile,
      );
    }
  }

  void tap() => unawaited(trigger(FeedbackEvent.tap));
  void toggle(bool value) => unawaited(
      trigger(value ? FeedbackEvent.toggleOn : FeedbackEvent.toggleOff));
  void tick() => unawaited(trigger(FeedbackEvent.tick));
  void selection() => unawaited(trigger(FeedbackEvent.selection));
  void pop() => unawaited(trigger(FeedbackEvent.pop));
  void success() => unawaited(trigger(FeedbackEvent.success));
  void error() => unawaited(trigger(FeedbackEvent.error));
  void swipe() => unawaited(trigger(FeedbackEvent.swipe));

  /// No-op — scroll sound removed; use [swipe] for page transitions.
  void scroll() {}
}
