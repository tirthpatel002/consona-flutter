/// Consona Stroke — Single source of border width precision
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../core/types.dart';

class ConsonaStroke {
  const ConsonaStroke({
    this.preset = ConsonaStrokePreset.standard,
    this.customWidth,
  });

  final ConsonaStrokePreset preset;
  final double? customWidth;

  const ConsonaStroke.flat()
      : preset = ConsonaStrokePreset.flat,
        customWidth = 0.0;

  const ConsonaStroke.standard()
      : preset = ConsonaStrokePreset.standard,
        customWidth = null;

  const ConsonaStroke.bold()
      : preset = ConsonaStrokePreset.bold,
        customWidth = 1.5;

  /// Resolves the physical logical stroke width.
  /// Standard hairline calculates from `devicePixelRatio` with a `0.5` logical px floor.
  double resolveWidth([BuildContext? context]) {
    if (customWidth != null) return customWidth!;

    return switch (preset) {
      ConsonaStrokePreset.flat => 0.0,
      ConsonaStrokePreset.bold => 1.5,
      ConsonaStrokePreset.standard => () {
          if (context != null) {
            final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
            if (dpr > 1.0) {
              return math.max(0.5, 1.0 / dpr);
            }
          }
          return 1.0;
        }(),
    };
  }

  /// Linearly interpolates between two [ConsonaStroke] instances.
  static ConsonaStroke lerp(ConsonaStroke a, ConsonaStroke b, double t) {
    if (a.preset == b.preset && a.customWidth == b.customWidth) return a;
    if (t <= 0.0) return a;
    if (t >= 1.0) return b; // keep the exact target preset (e.g. device hairline)
    final wA =
        a.customWidth ?? (a.preset == ConsonaStrokePreset.flat ? 0.0 : 1.0);
    final wB =
        b.customWidth ?? (b.preset == ConsonaStrokePreset.flat ? 0.0 : 1.0);
    return ConsonaStroke(
      preset: t < 0.5 ? a.preset : b.preset,
      customWidth: wA + (wB - wA) * t,
    );
  }
}
