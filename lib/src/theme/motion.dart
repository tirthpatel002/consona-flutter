/// Consona Motion — Durations, curves, springs, and reduced motion handling
library;

import 'package:flutter/widgets.dart';
import '../core/animation.dart';
import '../core/types.dart';

enum ConsonaMotionSoftness {
  crisp,
  soft,
  bouncy,
}

class ConsonaMotionSpec {
  const ConsonaMotionSpec({
    required this.duration,
    required this.curve,
    this.spring,
  });

  final Duration duration;
  final Curve curve;
  final SpringDescription? spring;
}

class ConsonaMotion {
  const ConsonaMotion({
    this.speed = 1.0,
    this.softness = ConsonaMotionSoftness.soft,
    this.reduced = false,
  });

  final double speed;
  final ConsonaMotionSoftness softness;
  final bool reduced;

  const ConsonaMotion.crisp()
      : speed = 1.0,
        softness = ConsonaMotionSoftness.crisp,
        reduced = false;

  const ConsonaMotion.soft()
      : speed = 1.0,
        softness = ConsonaMotionSoftness.soft,
        reduced = false;

  const ConsonaMotion.bouncy()
      : speed = 1.0,
        softness = ConsonaMotionSoftness.bouncy,
        reduced = false;

  const ConsonaMotion.instant()
      : speed = 0.0,
        softness = ConsonaMotionSoftness.crisp,
        reduced = true;

  /// Resolves the motion specification for a given role,
  /// factoring in speed, curve softness, and reduced motion settings.
  ConsonaMotionSpec resolve(ConsonaMotionRole role, [BuildContext? context]) {
    final isReduced = reduced ||
        (context != null && MediaQuery.maybeDisableAnimationsOf(context) == true);

    if (isReduced) {
      return const ConsonaMotionSpec(
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }

    int baseMs = switch (role) {
      ConsonaMotionRole.press => 120,
      ConsonaMotionRole.toggle => 260,
      ConsonaMotionRole.reveal => 240,
      ConsonaMotionRole.focus => 160,
      ConsonaMotionRole.page => 300,
      ConsonaMotionRole.shimmer => 1500,
      ConsonaMotionRole.pulse => 2400,
    };

    final effectiveMs = (baseMs / (speed > 0 ? speed : 1.0)).round();

    final curve = switch (softness) {
      ConsonaMotionSoftness.crisp => Curves.easeOutCubic,
      ConsonaMotionSoftness.soft => ConsonaCurves.subtleEase,
      ConsonaMotionSoftness.bouncy => ConsonaCurves.bouncySpring,
    };

    final spring = switch (softness) {
      ConsonaMotionSoftness.crisp => const SpringDescription(
          mass: 1.0,
          stiffness: 300.0,
          damping: 25.0,
        ),
      ConsonaMotionSoftness.soft => const SpringDescription(
          mass: 1.0,
          stiffness: 220.0,
          damping: 20.0,
        ),
      ConsonaMotionSoftness.bouncy => const SpringDescription(
          mass: 1.0,
          stiffness: 180.0,
          damping: 14.0,
        ),
    };

    return ConsonaMotionSpec(
      duration: Duration(milliseconds: effectiveMs),
      curve: curve,
      spring: spring,
    );
  }

  /// Linearly interpolates between two [ConsonaMotion] instances.
  static ConsonaMotion lerp(ConsonaMotion a, ConsonaMotion b, double t) {
    return ConsonaMotion(
      speed: a.speed + (b.speed - a.speed) * t,
      softness: t < 0.5 ? a.softness : b.softness,
      reduced: t < 0.5 ? a.reduced : b.reduced,
    );
  }
}
