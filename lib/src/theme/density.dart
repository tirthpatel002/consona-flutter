/// Consona Density — Density multiplier knob for mobile geometry
library;

import 'package:flutter/widgets.dart';
import '../core/types.dart';

class ConsonaDensity {
  const ConsonaDensity({
    this.factor = 1.0,
    this.preset = ConsonaDensityPreset.normal,
  });

  final double factor;
  final ConsonaDensityPreset preset;

  const ConsonaDensity.compact()
      : factor = 0.85,
        preset = ConsonaDensityPreset.compact;

  const ConsonaDensity.normal()
      : factor = 1.0,
        preset = ConsonaDensityPreset.normal;

  const ConsonaDensity.spacious()
      : factor = 1.15,
        preset = ConsonaDensityPreset.spacious;

  /// Scales vertical padding while keeping horizontal padding proportional.
  EdgeInsets resolvePadding(EdgeInsets insets) {
    return EdgeInsets.fromLTRB(
      insets.left,
      (insets.top * factor).roundToDouble(),
      insets.right,
      (insets.bottom * factor).roundToDouble(),
    );
  }

  /// Scales height by the density factor.
  double resolveHeight(double height) => (height * factor).roundToDouble();

  /// Linearly interpolates between two [ConsonaDensity] instances.
  static ConsonaDensity lerp(ConsonaDensity a, ConsonaDensity b, double t) {
    if (t <= 0.0) return a;
    if (t >= 1.0) return b;
    final newFactor = a.factor + (b.factor - a.factor) * t;
    final preset = newFactor <= 0.90
        ? ConsonaDensityPreset.compact
        : newFactor >= 1.10
            ? ConsonaDensityPreset.spacious
            : ConsonaDensityPreset.normal;
    return ConsonaDensity(factor: newFactor, preset: preset);
  }
}
