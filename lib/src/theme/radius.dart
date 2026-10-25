/// Consona Radius — Squircle support, nested radius formula, and corner scales
library;

import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../core/types.dart';
import 'tokens.dart';

class ConsonaRadius {
  const ConsonaRadius({
    this.base = ConsonaRadii.base,
    this.isSquircle = false,
  });

  final double base;
  final bool isSquircle;

  const ConsonaRadius.none()
      : base = 0.0,
        isSquircle = false;
  const ConsonaRadius.sm()
      : base = ConsonaRadii.micro,
        isSquircle = false;
  const ConsonaRadius.md()
      : base = ConsonaRadii.base,
        isSquircle = false;
  const ConsonaRadius.lg()
      : base = ConsonaRadii.macro,
        isSquircle = false;
  const ConsonaRadius.xl()
      : base = ConsonaRadii.xl,
        isSquircle = false;
  const ConsonaRadius.full()
      : base = ConsonaRadii.full,
        isSquircle = false;
  const ConsonaRadius.squircle()
      : base = ConsonaRadii.macro,
        isSquircle = true;

  factory ConsonaRadius.fromPreset(ConsonaRadiusPreset preset) =>
      switch (preset) {
        ConsonaRadiusPreset.none => const ConsonaRadius.none(),
        ConsonaRadiusPreset.sm => const ConsonaRadius.sm(),
        ConsonaRadiusPreset.md => const ConsonaRadius.md(),
        ConsonaRadiusPreset.lg => const ConsonaRadius.lg(),
        ConsonaRadiusPreset.xl => const ConsonaRadius.xl(),
        ConsonaRadiusPreset.full => const ConsonaRadius.full(),
        ConsonaRadiusPreset.squircle => const ConsonaRadius.squircle(),
      };

  @override
  bool operator ==(Object other) =>
      other is ConsonaRadius &&
      other.base == base &&
      other.isSquircle == isSquircle;

  @override
  int get hashCode => Object.hash(base, isSquircle);

  /// Resolves the raw radius value for a given semantic role.
  double resolveRaw(ConsonaRadiusRole role) {
    if (role == ConsonaRadiusRole.full) return ConsonaRadii.full;
    if (base >= ConsonaRadii.full) return ConsonaRadii.full;
    if (base == 0.0) return 0.0;

    return switch (role) {
      ConsonaRadiusRole.full => ConsonaRadii.full,
      ConsonaRadiusRole.macro => base * 1.5,
      ConsonaRadiusRole.base => base,
      ConsonaRadiusRole.micro => math.max(2.0, base * 0.65),
      ConsonaRadiusRole.atom => math.max(1.0, base * 0.40),
    };
  }

  /// Resolves a [BorderRadius] for a given role.
  BorderRadius resolve(ConsonaRadiusRole role) {
    final r = resolveRaw(role);
    return BorderRadius.circular(r);
  }

  /// Resolves an [OutlinedBorder] ([ContinuousRectangleBorder] for squircle,
  /// [RoundedRectangleBorder] otherwise) for a given role and border side.
  OutlinedBorder resolveShape(
    ConsonaRadiusRole role, {
    BorderSide side = BorderSide.none,
  }) {
    final borderRadius = resolve(role);
    if (isSquircle && role != ConsonaRadiusRole.full && base < ConsonaRadii.full) {
      return ContinuousRectangleBorder(
        borderRadius: borderRadius,
        side: side,
      );
    }
    return RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: side,
    );
  }

  /// Calculates nested inner child radius to prevent optical corner bunching:
  /// `childRadius = max(0, parentRadius - padding)`
  static BorderRadius nestedChild({
    required BorderRadius parent,
    required double padding,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(math.max(0.0, parent.topLeft.x - padding)),
      topRight: Radius.circular(math.max(0.0, parent.topRight.x - padding)),
      bottomLeft: Radius.circular(math.max(0.0, parent.bottomLeft.x - padding)),
      bottomRight:
          Radius.circular(math.max(0.0, parent.bottomRight.x - padding)),
    );
  }

  /// Linearly interpolates between two [ConsonaRadius] instances.
  static ConsonaRadius lerp(ConsonaRadius a, ConsonaRadius b, double t) {
    if (t <= 0.0) return a;
    if (t >= 1.0) return b;
    return ConsonaRadius(
      base: (a.base + (b.base - a.base) * t).clamp(0.0, ConsonaRadii.full),
      isSquircle: t < 0.5 ? a.isSquircle : b.isSquircle,
    );
  }
}
