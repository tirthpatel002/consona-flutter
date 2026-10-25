/// Consona Presets — Whole-theme out-of-the-box configurations with distinct identities
library;

import 'package:flutter/painting.dart';
import '../core/types.dart';
import 'border.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'density.dart';
import 'motion.dart';
import 'radius.dart';
import 'shadow.dart';
import 'stroke.dart';
import 'theme_data.dart';
import 'typography.dart';

abstract final class ConsonaPresets {
  /// Default minimal preset: hairline borders, no elevation shadow, soft motion.
  static ConsonaThemeData minimal() {
    final colors = ConsonaColorScheme.minimal().light;
    const stroke = ConsonaStroke.standard();
    return ConsonaThemeData(
      radius: const ConsonaRadius.md(),
      density: const ConsonaDensity.normal(),
      shadow: const ConsonaShadow.none(),
      stroke: stroke,
      border: ConsonaBorder(stroke: stroke, colors: colors),
      colors: colors,
      typography: const ConsonaTypography(),
      motion: const ConsonaMotion.soft(),
    );
  }

  /// Linear preset: high-tech slate/indigo palette, tight tabular figures, compact density, 5pt sharp corners.
  static ConsonaThemeData linear() {
    const light = ConsonaColors(
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      surfaceSecondary: Color(0xFFEEF2F6),
      foreground: Color(0xFF0F172A),
      mutedFg: Color(0xFF64748B),
      border: Color(0xFFE2E8F0),
      borderLight: Color(0xFFF1F5F9),
      borderStrong: Color(0xFFCBD5E1),
      primary: Color(0xFF4F46E5), // Indigo
      onPrimary: Color(0xFFFFFFFF),
      danger: Color(0xFFEF4444),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF10B981),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFF59E0B),
      onWarning: Color(0xFF000000),
      focusRing: Color(0xFF6366F1),
      muted: Color(0xFFE2E8F0),
      isDark: false,
    );

    const stroke = ConsonaStroke.standard();
    return const ConsonaThemeData(
      radius: ConsonaRadius.sm(),
      density: ConsonaDensity.compact(),
      shadow: ConsonaShadow.subtle(),
      stroke: stroke,
      border: ConsonaBorder(stroke: stroke, colors: light),
      colors: light,
      typography: ConsonaTypography(tabularFigures: true),
      motion: ConsonaMotion.crisp(),
    );
  }

  /// iOS-style preset: Apple system blue, squircle corners, bouncy springs, normal density.
  static ConsonaThemeData ios() {
    const light = ConsonaColors(
      background: Color(0xFFF2F2F7),
      surface: Color(0xFFFFFFFF),
      surfaceSecondary: Color(0xFFE5E5EA),
      foreground: Color(0xFF000000),
      mutedFg: Color(0xFF8E8E93),
      border: Color(0xFFD1D1D6),
      borderLight: Color(0xFFE5E5EA),
      borderStrong: Color(0xFFAEAEB2),
      primary: Color(0xFF007AFF), // System Blue
      onPrimary: Color(0xFFFFFFFF),
      danger: Color(0xFFFF3B30),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF34C759),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFFF9500),
      onWarning: Color(0xFFFFFFFF),
      focusRing: Color(0xFF007AFF),
      muted: Color(0xFFE5E5EA),
      isDark: false,
    );

    const stroke = ConsonaStroke.standard();
    return const ConsonaThemeData(
      radius: ConsonaRadius.squircle(),
      density: ConsonaDensity.normal(),
      shadow: ConsonaShadow.subtle(),
      stroke: stroke,
      border: ConsonaBorder(stroke: stroke, colors: light),
      colors: light,
      typography: ConsonaTypography(),
      motion: ConsonaMotion.bouncy(),
    );
  }

  /// Mechanical preset: razor-sharp corners (0 radius), bold 1.5pt strokes, amber accents, crisp motion.
  static ConsonaThemeData mechanical() {
    const light = ConsonaColors(
      background: Color(0xFFFAFAFA),
      surface: Color(0xFFF4F4F5),
      surfaceSecondary: Color(0xFFE4E4E7),
      foreground: Color(0xFF18181B),
      mutedFg: Color(0xFF71717A),
      border: Color(0xFF27272A),
      borderLight: Color(0xFF52525B),
      borderStrong: Color(0xFF09090B),
      primary: Color(0xFFD97706), // Amber industrial
      onPrimary: Color(0xFFFFFFFF),
      danger: Color(0xFFDC2626),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF16A34A),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFD97706),
      onWarning: Color(0xFFFFFFFF),
      focusRing: Color(0xFFD97706),
      muted: Color(0xFFD4D4D8),
      isDark: false,
    );

    const stroke = ConsonaStroke.bold();
    return const ConsonaThemeData(
      radius: ConsonaRadius.none(),
      density: ConsonaDensity.compact(),
      shadow: ConsonaShadow.strong(),
      stroke: stroke,
      border: ConsonaBorder(
        stroke: stroke,
        colors: light,
        strategy: ConsonaBorderStrategy.border,
      ),
      colors: light,
      typography: ConsonaTypography(tabularFigures: true),
      motion: ConsonaMotion.crisp(),
    );
  }

  /// Soft preset: XL plush pill curves (22pt), borderless (flat stroke), soft elevation shadows, emerald accents.
  static ConsonaThemeData soft() {
    const light = ConsonaColors(
      background: Color(0xFFF0FDF4),
      surface: Color(0xFFFFFFFF),
      surfaceSecondary: Color(0xFFDCFCE7),
      foreground: Color(0xFF064E3B),
      mutedFg: Color(0xFF059669),
      border: Color(0xFFBBF7D0),
      borderLight: Color(0xFFDCFCE7),
      borderStrong: Color(0xFF86EFAC),
      primary: Color(0xFF059669), // Emerald
      onPrimary: Color(0xFFFFFFFF),
      danger: Color(0xFFEF4444),
      onDanger: Color(0xFFFFFFFF),
      success: Color(0xFF10B981),
      onSuccess: Color(0xFFFFFFFF),
      warning: Color(0xFFF59E0B),
      onWarning: Color(0xFF000000),
      focusRing: Color(0xFF34D399),
      muted: Color(0xFFDCFCE7),
      isDark: false,
    );

    const stroke = ConsonaStroke.flat();
    return const ConsonaThemeData(
      radius: ConsonaRadius.xl(),
      density: ConsonaDensity.spacious(),
      shadow: ConsonaShadow(
        preset: ConsonaShadowLevel.soft,
        strategy: ConsonaBorderStrategy.shadow,
      ),
      stroke: stroke,
      border: ConsonaBorder(
        stroke: stroke,
        colors: light,
        strategy: ConsonaBorderStrategy.shadow,
      ),
      colors: light,
      typography: ConsonaTypography(),
      motion: ConsonaMotion.bouncy(),
    );
  }
}
