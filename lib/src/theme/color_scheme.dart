/// Consona Color Scheme — Light/dark pairing, seed derivation, and WCAG AA verification
library;

import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'colors.dart';

class ConsonaColorScheme {
  const ConsonaColorScheme({
    required this.light,
    required this.dark,
  });

  final ConsonaColors light;
  final ConsonaColors dark;

  /// Default minimal monochrome color scheme.
  factory ConsonaColorScheme.minimal() {
    const light = ConsonaColors(
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFF9FAFB),
      surfaceSecondary: Color(0xFFF3F4F6),
      foreground: Color(0xFF111827),
      mutedFg: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
      borderLight: Color(0xFFF3F4F6),
      borderStrong: Color(0xFFD1D5DB),
      primary: Color(0xFF111827),
      onPrimary: Color(0xFFFFFFFF),
      danger: Color(0xFFDC2626),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF16A34A),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFD97706),
      onWarning: Color(0xFFFFFFFF),
      // Mono focus = primary (near-black), not a chromatic ring.
      focusRing: Color(0xFF111827),
      muted: Color(0xFFE5E7EB),
      isDark: false,
    );

    const dark = ConsonaColors(
      background: Color(0xFF09090B),
      surface: Color(0xFF18181B),
      surfaceSecondary: Color(0xFF27272A),
      foreground: Color(0xFFFAFAFA),
      mutedFg: Color(0xFFA1A1AA),
      border: Color(0xFF27272A),
      borderLight: Color(0xFF1F1F23),
      borderStrong: Color(0xFF3F3F46),
      primary: Color(0xFFFAFAFA),
      onPrimary: Color(0xFF18181B),
      danger: Color(0xFFEF4444),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF22C55E),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFF59E0B),
      onWarning: Color(0xFF000000),
      // Mono focus = primary (near-white).
      focusRing: Color(0xFFFAFAFA),
      muted: Color(0xFF27272A),
      isDark: true,
    );

    return const ConsonaColorScheme(light: light, dark: dark);
  }

  /// Derives light and dark color schemes from a brand seed color.
  factory ConsonaColorScheme.fromSeed(Color seed) {
    // If the seed is the Mono preset seed (or achromatic / grayscale),
    // resolve directly to the minimal neutral monochrome scheme where
    // dark mode primary is crisp whitish (0xFFFAFAFA) rather than a bluish tint.
    final hsl = HSLColor.fromColor(seed);
    final rgbSpread = (seed.r - seed.g).abs() +
        (seed.g - seed.b).abs() +
        (seed.r - seed.b).abs();
    final isAchromatic = hsl.saturation < 0.15 ||
        rgbSpread <= 0.18 ||
        seed == const Color(0xFF111827) ||
        seed == const Color(0xFF09090B) ||
        seed == const Color(0xFF18181B);
    if (isAchromatic) {
      return ConsonaColorScheme.minimal();
    }

    // Generate harmonious tonal palette from chromatic seed
    final lightPrimary = hsl.withLightness(math.min(hsl.lightness, 0.40)).toColor();
    final darkPrimary = hsl.withLightness(math.max(hsl.lightness, 0.75)).toColor();

    final light = ConsonaColors(
      background: const Color(0xFFFFFFFF),
      surface: hsl.withLightness(0.98).withSaturation(0.08).toColor(),
      surfaceSecondary: hsl.withLightness(0.95).withSaturation(0.12).toColor(),
      foreground: const Color(0xFF0F172A),
      mutedFg: const Color(0xFF64748B),
      border: hsl.withLightness(0.90).withSaturation(0.08).toColor(),
      borderLight: hsl.withLightness(0.94).withSaturation(0.06).toColor(),
      borderStrong: hsl.withLightness(0.80).withSaturation(0.12).toColor(),
      primary: lightPrimary,
      onPrimary: const Color(0xFFFFFFFF),
      danger: const Color(0xFFDC2626),
      onDanger: const Color(0xFFFFFFFF),
      success: const Color(0xFF16A34A),
      onSuccess: const Color(0xFFFFFFFF),
      warning: const Color(0xFFD97706),
      onWarning: const Color(0xFFFFFFFF),
      focusRing: seed,
      muted: const Color(0xFFE2E8F0),
      isDark: false,
    );

    final dark = ConsonaColors(
      background: const Color(0xFF0B0F17),
      surface: hsl.withLightness(0.10).withSaturation(0.12).toColor(),
      surfaceSecondary: hsl.withLightness(0.15).withSaturation(0.16).toColor(),
      foreground: const Color(0xFFF8FAFC),
      mutedFg: const Color(0xFF94A3B8),
      border: hsl.withLightness(0.18).withSaturation(0.12).toColor(),
      borderLight: hsl.withLightness(0.14).withSaturation(0.10).toColor(),
      borderStrong: hsl.withLightness(0.26).withSaturation(0.16).toColor(),
      primary: darkPrimary,
      onPrimary: const Color(0xFF0B0F17),
      danger: const Color(0xFFEF4444),
      onDanger: const Color(0xFFFFFFFF),
      success: const Color(0xFF22C55E),
      onSuccess: const Color(0xFFFFFFFF),
      warning: const Color(0xFFF59E0B),
      onWarning: const Color(0xFF000000),
      focusRing: hsl.withLightness(0.65).toColor(),
      muted: const Color(0xFF1E293B),
      isDark: true,
    );

    return ConsonaColorScheme(
      light: verifyContrast(light),
      dark: verifyContrast(dark),
    );
  }

  /// Calculates relative luminance in sRGB space.
  static double relativeLuminance(Color color) {
    double transform(double val) {
      return (val <= 0.03928)
          ? val / 12.92
          : math.pow((val + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Computes WCAG contrast ratio between two colors (range: 1.0 to 21.0).
  static double contrastRatio(Color a, Color b) {
    final lumA = relativeLuminance(a);
    final lumB = relativeLuminance(b);
    final lighter = math.max(lumA, lumB);
    final darker = math.min(lumA, lumB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Validates contrast and auto-adjusts any failing color pair.
  static ConsonaColors verifyContrast(ConsonaColors colors) {
    Color adjustForContrast(Color fg, Color bg, double minRatio) {
      if (contrastRatio(fg, bg) >= minRatio) return fg;
      final hsl = HSLColor.fromColor(fg);
      final bgLum = relativeLuminance(bg);

      // Shift lightness away from background
      for (double step = 0.05; step <= 0.60; step += 0.05) {
        final candidate = hsl.withLightness(
          bgLum > 0.5
              ? math.max(0.0, hsl.lightness - step)
              : math.min(1.0, hsl.lightness + step),
        ).toColor();
        if (contrastRatio(candidate, bg) >= minRatio) {
          return candidate;
        }
      }
      return bgLum > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    }

    final verifiedFg = adjustForContrast(colors.foreground, colors.background, 4.5);
    final verifiedMutedFg = adjustForContrast(colors.mutedFg, colors.surface, 3.0);
    final verifiedOnPrimary = adjustForContrast(colors.onPrimary, colors.primary, 4.5);

    return ConsonaColors(
      background: colors.background,
      surface: colors.surface,
      surfaceSecondary: colors.surfaceSecondary,
      foreground: verifiedFg,
      mutedFg: verifiedMutedFg,
      border: colors.border,
      borderLight: colors.borderLight,
      borderStrong: colors.borderStrong,
      primary: colors.primary,
      onPrimary: verifiedOnPrimary,
      danger: colors.danger,
      onDanger: colors.onDanger,
      success: colors.success,
      onSuccess: colors.onSuccess,
      warning: colors.warning,
      onWarning: colors.onWarning,
      focusRing: colors.focusRing,
      muted: colors.muted,
      isDark: colors.isDark,
    );
  }
}
