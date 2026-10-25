/// Consona Theme Config — JSON-serializable schema for whole-theme configurations
library;

import 'package:flutter/painting.dart';
import '../core/types.dart';
import 'border.dart';
import 'color_scheme.dart';
import 'component_themes.dart';
import 'density.dart';
import 'motion.dart';
import 'presets.dart';
import 'radius.dart';
import 'shadow.dart';
import 'stroke.dart';
import 'theme_data.dart';
import 'typography.dart';

class ConsonaThemeConfig {
  const ConsonaThemeConfig({
    this.preset = 'minimal',
    this.radius = 'md',
    this.density = 'normal',
    this.shadow = 'subtle',
    this.stroke = 'standard',
    this.borderStrategy = 'border',
    this.motion = 'soft',
    this.seedColorHex,
    this.tabularFigures = false,
    this.components = const ConsonaComponentThemes(),
  });

  final String preset;
  final String radius;
  final String density;
  final String shadow;
  final String stroke;
  final String borderStrategy;
  final String motion;
  final int? seedColorHex;
  final bool tabularFigures;
  final ConsonaComponentThemes components;

  factory ConsonaThemeConfig.fromJson(Map<String, dynamic> json) {
    return ConsonaThemeConfig(
      preset: json['preset'] as String? ?? 'minimal',
      radius: json['radius'] as String? ?? 'md',
      density: json['density'] as String? ?? 'normal',
      shadow: json['shadow'] as String? ?? 'subtle',
      stroke: json['stroke'] as String? ?? 'standard',
      borderStrategy: json['borderStrategy'] as String? ?? 'border',
      motion: json['motion'] as String? ?? 'soft',
      seedColorHex: json['seedColor'] as int?,
      tabularFigures: json['tabularFigures'] as bool? ?? false,
      components: json['components'] is Map<String, dynamic>
          ? ConsonaComponentThemes.fromJson(
              json['components'] as Map<String, dynamic>,
            )
          : const ConsonaComponentThemes(),
    );
  }

  Map<String, dynamic> toJson() {
    final componentsJson = components.toJson();
    return {
      'preset': preset,
      'radius': radius,
      'density': density,
      'shadow': shadow,
      'stroke': stroke,
      'borderStrategy': borderStrategy,
      'motion': motion,
      if (seedColorHex != null) 'seedColor': seedColorHex,
      'tabularFigures': tabularFigures,
      if (componentsJson.isNotEmpty) 'components': componentsJson,
    };
  }

  ConsonaThemeData toThemeData() {
    // If exact preset matches without custom tweaks, load preset
    ConsonaThemeData baseTheme = switch (preset) {
      'linear' => ConsonaPresets.linear(),
      'ios' => ConsonaPresets.ios(),
      'mechanical' => ConsonaPresets.mechanical(),
      'soft' => ConsonaPresets.soft(),
      _ => ConsonaPresets.minimal(),
    };

    final colors = seedColorHex != null
        ? ConsonaColorScheme.fromSeed(Color(seedColorHex!)).light
        : baseTheme.colors;

    final resolvedRadius = switch (radius) {
      'none' => const ConsonaRadius.none(),
      'sm' => const ConsonaRadius.sm(),
      'md' => const ConsonaRadius.md(),
      'lg' => const ConsonaRadius.lg(),
      'xl' => const ConsonaRadius.xl(),
      'full' => const ConsonaRadius.full(),
      'squircle' => const ConsonaRadius.squircle(),
      _ => baseTheme.radius,
    };

    final resolvedDensity = switch (density) {
      'compact' => const ConsonaDensity.compact(),
      'normal' => const ConsonaDensity.normal(),
      'spacious' => const ConsonaDensity.spacious(),
      _ => baseTheme.density,
    };

    final resolvedShadowLevel = switch (shadow) {
      'none' => ConsonaShadowLevel.none,
      'subtle' => ConsonaShadowLevel.subtle,
      'soft' => ConsonaShadowLevel.soft,
      'strong' => ConsonaShadowLevel.strong,
      _ => baseTheme.shadow.preset,
    };

    final resolvedStroke = switch (stroke) {
      'flat' => const ConsonaStroke.flat(),
      'standard' => const ConsonaStroke.standard(),
      'bold' => const ConsonaStroke.bold(),
      _ => baseTheme.stroke,
    };

    final resolvedStrategy = switch (borderStrategy) {
      'shadow' => ConsonaBorderStrategy.shadow,
      'both' => ConsonaBorderStrategy.both,
      'none' => ConsonaBorderStrategy.none,
      _ => ConsonaBorderStrategy.border,
    };

    final resolvedMotion = switch (motion) {
      'crisp' => const ConsonaMotion.crisp(),
      'soft' => const ConsonaMotion.soft(),
      'bouncy' => const ConsonaMotion.bouncy(),
      'instant' => const ConsonaMotion.instant(),
      _ => baseTheme.motion,
    };

    return ConsonaThemeData(
      radius: resolvedRadius,
      density: resolvedDensity,
      shadow: ConsonaShadow(
        preset: resolvedShadowLevel,
        strategy: resolvedStrategy,
      ),
      stroke: resolvedStroke,
      border: ConsonaBorder(
        stroke: resolvedStroke,
        colors: colors,
        strategy: resolvedStrategy,
      ),
      colors: colors,
      typography: ConsonaTypography(tabularFigures: tabularFigures),
      motion: resolvedMotion,
      components: components,
    );
  }
}
