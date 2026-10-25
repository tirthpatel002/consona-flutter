/// Consona Theme Data — Flutter ThemeExtension composing all design token families
library;

import 'package:flutter/material.dart';
import 'border.dart';
import 'colors.dart';
import 'component_themes.dart';
import 'density.dart';
import 'motion.dart';
import 'presets.dart';
import 'radius.dart';
import 'shadow.dart';
import 'stroke.dart';
import 'typography.dart';

class ConsonaThemeData extends ThemeExtension<ConsonaThemeData> {
  const ConsonaThemeData({
    required this.radius,
    required this.density,
    required this.shadow,
    required this.stroke,
    required this.border,
    required this.colors,
    required this.typography,
    required this.motion,
    this.components = const ConsonaComponentThemes(),
  });

  final ConsonaRadius radius;
  final ConsonaDensity density;
  final ConsonaShadow shadow;
  final ConsonaStroke stroke;
  final ConsonaBorder border;
  final ConsonaColors colors;
  final ConsonaTypography typography;
  final ConsonaMotion motion;
  final ConsonaComponentThemes components;

  /// Default minimal preset.
  factory ConsonaThemeData.minimal() => ConsonaPresets.minimal();

  /// Tight, crisp, tabular, low-radius linear preset.
  factory ConsonaThemeData.linear() => ConsonaPresets.linear();

  /// Squircle, large-radius, spring-motion iOS-style preset.
  factory ConsonaThemeData.ios() => ConsonaPresets.ios();

  /// Sharp corners, bold stroke, strong edges mechanical preset.
  factory ConsonaThemeData.mechanical() => ConsonaPresets.mechanical();

  /// Soft corners, borderless + soft shadows, bouncy motion preset.
  factory ConsonaThemeData.soft() => ConsonaPresets.soft();

  /// Safe fallback if no ConsonaThemeData extension is installed in context.
  factory ConsonaThemeData.fallback() => ConsonaPresets.minimal();

  /// Returns a dark mode variation of this theme, preserving brand colors.
  ConsonaThemeData dark({ConsonaColors? darkColors}) {
    final colorsDark = darkColors ?? (colors.isDark ? colors : colors.invert());
    return copyWith(
      colors: colorsDark,
      border: ConsonaBorder(
        stroke: stroke,
        colors: colorsDark,
        strategy: border.strategy,
        darkStrategy: border.darkStrategy,
        roles: border.roles,
      ),
    );
  }

  /// Returns a variation of this theme with inverted colors and updated borders.
  ConsonaThemeData invert() {
    final invColors = colors.invert();
    return copyWith(
      colors: invColors,
      border: ConsonaBorder(
        stroke: stroke,
        colors: invColors,
        strategy: border.strategy,
        darkStrategy: border.darkStrategy,
        roles: border.roles,
      ),
    );
  }

  @override
  ConsonaThemeData copyWith({
    ConsonaRadius? radius,
    ConsonaDensity? density,
    ConsonaShadow? shadow,
    ConsonaStroke? stroke,
    ConsonaBorder? border,
    ConsonaColors? colors,
    ConsonaTypography? typography,
    ConsonaMotion? motion,
    ConsonaComponentThemes? components,
  }) {
    final resolvedColors = colors ?? this.colors;
    final resolvedStroke = stroke ?? this.stroke;
    return ConsonaThemeData(
      radius: radius ?? this.radius,
      density: density ?? this.density,
      shadow: shadow ?? this.shadow,
      stroke: resolvedStroke,
      border: border ??
          (colors != null || stroke != null
              ? ConsonaBorder(
                  stroke: resolvedStroke,
                  colors: resolvedColors,
                  strategy: this.border.strategy,
                  darkStrategy: this.border.darkStrategy,
                  roles: this.border.roles,
                )
              : this.border),
      colors: resolvedColors,
      typography: typography ?? this.typography,
      motion: motion ?? this.motion,
      components: components ?? this.components,
    );
  }

  @override
  ConsonaThemeData lerp(ThemeExtension<ConsonaThemeData>? other, double t) {
    if (other is! ConsonaThemeData) return this;
    if (t <= 0.0) return this;
    if (t >= 1.0) return other; // land exactly on the target theme

    return ConsonaThemeData(
      radius: ConsonaRadius.lerp(radius, other.radius, t),
      density: ConsonaDensity.lerp(density, other.density, t),
      shadow: ConsonaShadow.lerp(shadow, other.shadow, t),
      stroke: ConsonaStroke.lerp(stroke, other.stroke, t),
      border: ConsonaBorder.lerp(border, other.border, t),
      colors: ConsonaColors.lerp(colors, other.colors, t),
      typography: ConsonaTypography.lerp(typography, other.typography, t),
      motion: ConsonaMotion.lerp(motion, other.motion, t),
      components: ConsonaComponentThemes.lerp(components, other.components, t),
    );
  }
}
