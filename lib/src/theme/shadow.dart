/// Consona Shadow — Tinted elevation shadows and edge glow
library;

import 'package:flutter/painting.dart';
import '../core/types.dart';

class ConsonaShadow {
  const ConsonaShadow({
    this.preset = ConsonaShadowLevel.subtle,
    this.strategy = ConsonaBorderStrategy.border,
  });

  final ConsonaShadowLevel preset;
  final ConsonaBorderStrategy strategy;

  const ConsonaShadow.none()
      : preset = ConsonaShadowLevel.none,
        strategy = ConsonaBorderStrategy.border;

  const ConsonaShadow.subtle()
      : preset = ConsonaShadowLevel.subtle,
        strategy = ConsonaBorderStrategy.border;

  const ConsonaShadow.soft()
      : preset = ConsonaShadowLevel.soft,
        strategy = ConsonaBorderStrategy.border;

  const ConsonaShadow.strong()
      : preset = ConsonaShadowLevel.strong,
        strategy = ConsonaBorderStrategy.border;

  /// Maps the level a component *requests* (usually `subtle`) through this
  /// theme's [preset] knob: `none` flattens everything, `subtle` keeps the
  /// requested level, `soft` raises it one step and `strong` two steps.
  ConsonaShadowLevel effectiveLevel(ConsonaShadowLevel requested) {
    if (requested == ConsonaShadowLevel.none) return ConsonaShadowLevel.none;
    return switch (preset) {
      ConsonaShadowLevel.none => ConsonaShadowLevel.none,
      ConsonaShadowLevel.subtle => requested,
      ConsonaShadowLevel.soft => ConsonaShadowLevel.values[
          (requested.index + 1).clamp(1, ConsonaShadowLevel.strong.index)],
      ConsonaShadowLevel.strong => ConsonaShadowLevel.values[
          (requested.index + 2).clamp(1, ConsonaShadowLevel.strong.index)],
    };
  }

  /// Resolves multi-layer ambient tinted box shadows for a requested level,
  /// scaled by the theme's [preset] (see [effectiveLevel]). Under the `shadow`
  /// and `both` border strategies a hairline edge shadow is appended even for
  /// flat surfaces, so borderless themes still read as edges.
  List<BoxShadow> resolve(
    ConsonaShadowLevel requested, {
    Color? ambientColor,
    bool isDark = false,
  }) {
    final level = effectiveLevel(requested);

    final baseTint = ambientColor ??
        (isDark ? const Color(0xFF000000) : const Color(0xFF0F172A));
    final double opacityMultiplier = isDark ? 0.35 : 1.0;

    final shadows = switch (level) {
      ConsonaShadowLevel.none => <BoxShadow>[],
      ConsonaShadowLevel.subtle => [
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.04 * opacityMultiplier).round()),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.03 * opacityMultiplier).round()),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ConsonaShadowLevel.soft => [
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.06 * opacityMultiplier).round()),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.05 * opacityMultiplier).round()),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ConsonaShadowLevel.strong => [
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.08 * opacityMultiplier).round()),
            offset: const Offset(0, 4),
            blurRadius: 10,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: baseTint.withAlpha((255 * 0.08 * opacityMultiplier).round()),
            offset: const Offset(0, 16),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
    };

    // If strategy is shadow or both, inject a hairline edge shadow
    if (strategy == ConsonaBorderStrategy.shadow ||
        strategy == ConsonaBorderStrategy.both) {
      shadows.add(
        BoxShadow(
          color: baseTint.withAlpha((255 * (isDark ? 0.20 : 0.08)).round()),
          offset: Offset.zero,
          blurRadius: 0,
          spreadRadius: 1.0,
        ),
      );
    }

    return shadows;
  }

  /// Focus ring glow shadow used as focus indicator, particularly in flat stroke mode.
  List<BoxShadow> focusGlow(Color focusColor) => focusGlowStatic(focusColor);

  /// Focus ring glow shadow used as focus indicator, particularly in flat stroke mode.
  static List<BoxShadow> focusGlowStatic(Color focusColor) {
    return [
      BoxShadow(
        color: focusColor.withAlpha((255 * 0.35).round()),
        offset: Offset.zero,
        blurRadius: 0,
        spreadRadius: 2.5,
      ),
    ];
  }


  /// Linearly interpolates between two [ConsonaShadow] instances.
  static ConsonaShadow lerp(ConsonaShadow a, ConsonaShadow b, double t) {
    return t < 0.5 ? a : b;
  }
}
