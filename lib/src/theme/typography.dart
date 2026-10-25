/// Consona Typography — Text scale awareness, tabular figures, and role styling
library;

import 'package:flutter/widgets.dart';
import '../core/types.dart';
import 'colors.dart';

class ConsonaTypography {
  const ConsonaTypography({
    this.fontFamily,
    this.fontFamilyFallback = const ['SF Pro Text', 'Roboto', 'system-ui'],
    this.tabularFigures = false,
  });

  final String? fontFamily;
  final List<String> fontFamilyFallback;
  final bool tabularFigures;

  List<FontFeature>? get _fontFeatures =>
      tabularFigures ? const [FontFeature.tabularFigures()] : null;

  TextStyle get hero => TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get titleLarge => TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.3,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get titleMedium => TextStyle(
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        height: 1.30,
        letterSpacing: -0.2,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get body => TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: -0.1,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get caption => TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        height: 1.40,
        letterSpacing: 0.0,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get label => TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.20,
        letterSpacing: 0.1,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  TextStyle get labelSmall => TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        height: 1.20,
        letterSpacing: 0.1,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontFeatures: _fontFeatures,
      );

  /// Resolves the canonical [TextStyle] for a given [ConsonaTextRole],
  /// scaling safely via [MediaQuery.textScalerOf] without clipping chrome.
  TextStyle resolve(
    ConsonaTextRole role, {
    required ConsonaColors colors,
    BuildContext? context,
  }) {
    double baseSize = switch (role) {
      ConsonaTextRole.hero => 32.0,
      ConsonaTextRole.titleLarge => 22.0,
      ConsonaTextRole.titleMedium => 17.0,
      ConsonaTextRole.body => 15.0,
      ConsonaTextRole.caption => 13.0,
      ConsonaTextRole.label => 12.0,
    };

    FontWeight weight = switch (role) {
      ConsonaTextRole.hero => FontWeight.w700,
      ConsonaTextRole.titleLarge => FontWeight.w600,
      ConsonaTextRole.titleMedium => FontWeight.w600,
      ConsonaTextRole.body => FontWeight.w400,
      ConsonaTextRole.caption => FontWeight.w400,
      ConsonaTextRole.label => FontWeight.w500,
    };

    double letterSpacing = switch (role) {
      ConsonaTextRole.hero => -0.5,
      ConsonaTextRole.titleLarge => -0.3,
      ConsonaTextRole.titleMedium => -0.2,
      ConsonaTextRole.body => -0.1,
      ConsonaTextRole.caption => 0.0,
      ConsonaTextRole.label => 0.1,
    };

    double height = switch (role) {
      ConsonaTextRole.hero => 1.15,
      ConsonaTextRole.titleLarge => 1.25,
      ConsonaTextRole.titleMedium => 1.30,
      ConsonaTextRole.body => 1.45,
      ConsonaTextRole.caption => 1.40,
      ConsonaTextRole.label => 1.20,
    };

    Color color = switch (role) {
      ConsonaTextRole.caption => colors.mutedFg,
      _ => colors.foreground,
    };

    // Text scaling with role-specific clamping
    double effectiveSize = baseSize;
    if (context != null) {
      final scaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
      final maxScale = switch (role) {
        ConsonaTextRole.label => 1.3,
        ConsonaTextRole.caption => 1.35,
        ConsonaTextRole.body => 1.5,
        _ => 1.4,
      };
      final scaled = scaler.scale(baseSize);
      effectiveSize = scaled.clamp(baseSize * 0.8, baseSize * maxScale);
    }

    return TextStyle(
      fontSize: effectiveSize,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontFeatures: tabularFigures ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// Linearly interpolates between two [ConsonaTypography] instances.
  static ConsonaTypography lerp(ConsonaTypography a, ConsonaTypography b, double t) {
    return t < 0.5 ? a : b;
  }
}
