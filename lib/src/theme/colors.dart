/// Consona Colors — Semantic color roles container
library;

import 'package:flutter/painting.dart';
import '../core/types.dart';

/// Semantic colors for Consona Mobile components.
class ConsonaColors {
  const ConsonaColors({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.foreground,
    required this.mutedFg,
    required this.border,
    required this.borderLight,
    required this.borderStrong,
    required this.primary,
    required this.onPrimary,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.focusRing,
    required this.muted,
    this.isDark = false,
  });

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color foreground;
  final Color mutedFg;
  final Color border;
  final Color borderLight;
  final Color borderStrong;
  final Color primary;
  final Color onPrimary;
  final Color danger;
  final Color onDanger;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color focusRing;
  final Color muted;
  final bool isDark;

  /// Resolves an interaction state into a tinted variation of a given base color.
  Color stateTint(Color base, ConsonaInteractionState state) {
    return switch (state) {
      ConsonaInteractionState.idle => base,
      ConsonaInteractionState.hovered => Color.alphaBlend(
          foreground.withAlpha((255 * 0.06).round()),
          base,
        ),
      ConsonaInteractionState.pressed => Color.alphaBlend(
          foreground.withAlpha((255 * 0.12).round()),
          base,
        ),
      ConsonaInteractionState.focused => Color.alphaBlend(
          focusRing.withAlpha((255 * 0.16).round()),
          base,
        ),
      ConsonaInteractionState.selected => Color.alphaBlend(
          primary.withAlpha((255 * 0.10).round()),
          base,
        ),
      ConsonaInteractionState.error => Color.alphaBlend(
          danger.withAlpha((255 * 0.10).round()),
          base,
        ),
      ConsonaInteractionState.disabled => base.withAlpha((255 * 0.38).round()),
    };
  }

  /// Resolves an intent into a background/foreground color pair.
  ({Color fill, Color content}) resolveIntent(
    ConsonaIntent intent, {
    ConsonaInteractionState state = ConsonaInteractionState.idle,
  }) {
    Color fill;
    Color content;

    switch (intent) {
      case ConsonaIntent.primary:
        fill = primary;
        content = onPrimary;
      case ConsonaIntent.subtle:
        fill = surfaceSecondary;
        content = foreground;
      case ConsonaIntent.outline:
        fill = const Color(0x00000000);
        content = foreground;
      case ConsonaIntent.plain || ConsonaIntent.ghost:
        fill = const Color(0x00000000);
        content = primary;
      case ConsonaIntent.danger:
        fill = danger;
        content = onDanger;
      case ConsonaIntent.success:
        fill = success;
        content = onSuccess;
      case ConsonaIntent.warning:
        fill = warning;
        content = onWarning;
      case ConsonaIntent.secondary:
        fill = surface;
        content = mutedFg;
    }

    if (state == ConsonaInteractionState.disabled) {
      return (
        fill: fill == const Color(0x00000000)
            ? fill
            : muted.withAlpha((255 * 0.4).round()),
        content: mutedFg.withAlpha((255 * 0.5).round()),
      );
    }

    if (state == ConsonaInteractionState.hovered ||
        state == ConsonaInteractionState.pressed) {
      fill = stateTint(fill, state);
    }

    return (fill: fill, content: content);
  }

  /// Linearly interpolates between two [ConsonaColors] instances.
  static ConsonaColors lerp(ConsonaColors a, ConsonaColors b, double t) {
    return ConsonaColors(
      background: Color.lerp(a.background, b.background, t) ?? a.background,
      surface: Color.lerp(a.surface, b.surface, t) ?? a.surface,
      surfaceSecondary:
          Color.lerp(a.surfaceSecondary, b.surfaceSecondary, t) ??
              a.surfaceSecondary,
      foreground: Color.lerp(a.foreground, b.foreground, t) ?? a.foreground,
      mutedFg: Color.lerp(a.mutedFg, b.mutedFg, t) ?? a.mutedFg,
      border: Color.lerp(a.border, b.border, t) ?? a.border,
      borderLight:
          Color.lerp(a.borderLight, b.borderLight, t) ?? a.borderLight,
      borderStrong:
          Color.lerp(a.borderStrong, b.borderStrong, t) ?? a.borderStrong,
      primary: Color.lerp(a.primary, b.primary, t) ?? a.primary,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t) ?? a.onPrimary,
      danger: Color.lerp(a.danger, b.danger, t) ?? a.danger,
      onDanger: Color.lerp(a.onDanger, b.onDanger, t) ?? a.onDanger,
      success: Color.lerp(a.success, b.success, t) ?? a.success,
      onSuccess: Color.lerp(a.onSuccess, b.onSuccess, t) ?? a.onSuccess,
      warning: Color.lerp(a.warning, b.warning, t) ?? a.warning,
      onWarning: Color.lerp(a.onWarning, b.onWarning, t) ?? a.onWarning,
      focusRing: Color.lerp(a.focusRing, b.focusRing, t) ?? a.focusRing,
      muted: Color.lerp(a.muted, b.muted, t) ?? a.muted,
      isDark: t < 0.5 ? a.isDark : b.isDark,
    );
  }

  /// Returns an inverted variation of these colors.
  /// Light mode becomes a dark tonal palette; dark mode becomes a light tonal palette.
  ConsonaColors invert() {
    final hsl = HSLColor.fromColor(primary);
    final rgbSpread = (primary.r - primary.g).abs() +
        (primary.g - primary.b).abs() +
        (primary.r - primary.b).abs();
    final isAchromatic = hsl.saturation < 0.15 ||
        rgbSpread <= 0.18 ||
        primary == const Color(0xFF111827) ||
        primary == const Color(0xFF09090B) ||
        primary == const Color(0xFF18181B);
    if (isDark) {
      final invPrimary =
          isAchromatic ? const Color(0xFF111827) : hsl.withLightness(0.40).toColor();
      return ConsonaColors(
        background: const Color(0xFFFFFFFF),
        surface: const Color(0xFFF9FAFB),
        surfaceSecondary: const Color(0xFFF3F4F6),
        foreground: const Color(0xFF111827),
        mutedFg: const Color(0xFF6B7280),
        border: const Color(0xFFE5E7EB),
        borderLight: const Color(0xFFF3F4F6),
        borderStrong: const Color(0xFFD1D5DB),
        primary: invPrimary,
        onPrimary: const Color(0xFFFFFFFF),
        danger: danger,
        onDanger: onDanger,
        success: success,
        onSuccess: onSuccess,
        warning: warning,
        onWarning: onWarning,
        focusRing: isAchromatic ? invPrimary : focusRing,
        muted: const Color(0xFFE5E7EB),
        isDark: false,
      );
    } else {
      final invPrimary =
          isAchromatic ? const Color(0xFFFAFAFA) : hsl.withLightness(0.75).toColor();
      return ConsonaColors(
        background: const Color(0xFF09090B),
        surface: const Color(0xFF18181B),
        surfaceSecondary: const Color(0xFF27272A),
        foreground: const Color(0xFFFAFAFA),
        mutedFg: const Color(0xFFA1A1AA),
        border: const Color(0xFF27272A),
        borderLight: const Color(0xFF1F1F23),
        borderStrong: const Color(0xFF3F3F46),
        primary: invPrimary,
        onPrimary: const Color(0xFF18181B),
        danger: danger,
        onDanger: onDanger,
        success: success,
        onSuccess: onSuccess,
        warning: warning,
        onWarning: onWarning,
        focusRing: isAchromatic ? invPrimary : focusRing,
        muted: const Color(0xFF27272A),
        isDark: true,
      );
    }
  }
}
