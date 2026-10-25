/// Consona Button Variant — Variant resolver and downstream extensibility
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_data.dart';

typedef ButtonStyleResolver = ({
  Color background,
  Color foreground,
  BoxBorder border,
  List<BoxShadow> shadows,
})
    Function({
  required ConsonaThemeData theme,
  required ConsonaInteractionState state,
  BuildContext? context,
});

class ConsonaButtonVariant {
  const ConsonaButtonVariant._(this._resolver);

  final ButtonStyleResolver _resolver;

  ({
    Color background,
    Color foreground,
    BoxBorder border,
    List<BoxShadow> shadows
  }) resolve({
    required ConsonaThemeData theme,
    required ConsonaInteractionState state,
    BuildContext? context,
  }) {
    return _resolver(theme: theme, state: state, context: context);
  }

  /// Primary button variant: solid brand fill, high-contrast foreground.
  static final ConsonaButtonVariant primary =
      ConsonaButtonVariant._(({required theme, required state, context}) {
    final colors =
        theme.colors.resolveIntent(ConsonaIntent.primary, state: state);
    final border = theme.border
        .resolve(ConsonaBorderRole.subtle, state: state, context: context);
    final baseShadows = state == ConsonaInteractionState.disabled
        ? const <BoxShadow>[]
        : theme.shadow
            .resolve(ConsonaShadowLevel.subtle, isDark: theme.colors.isDark);
    final shadows = state == ConsonaInteractionState.focused
        ? <BoxShadow>[
            ...baseShadows,
            ...theme.shadow.focusGlow(theme.colors.focusRing),
          ]
        : baseShadows;
    return (
      background: colors.fill,
      foreground: colors.content,
      border: border,
      shadows: shadows,
    );
  });

  /// Subtle button variant: tinted surface secondary, neutral foreground.
  static final ConsonaButtonVariant subtle =
      ConsonaButtonVariant._(({required theme, required state, context}) {
    final colors =
        theme.colors.resolveIntent(ConsonaIntent.subtle, state: state);
    final border = theme.border
        .resolve(ConsonaBorderRole.subtle, state: state, context: context);
    final baseShadows = theme.shadow
        .resolve(ConsonaShadowLevel.none, isDark: theme.colors.isDark);
    return (
      background: colors.fill,
      foreground: colors.content,
      border: border,
      // `none` level still yields the hairline edge under shadow/both strategies.
      shadows: state == ConsonaInteractionState.focused
          ? <BoxShadow>[
              ...baseShadows,
              ...theme.shadow.focusGlow(theme.colors.focusRing),
            ]
          : baseShadows,
    );
  });

  /// Outline button variant: transparent background with crisp border.
  static final ConsonaButtonVariant outline =
      ConsonaButtonVariant._(({required theme, required state, context}) {
    final colors =
        theme.colors.resolveIntent(ConsonaIntent.outline, state: state);
    final border = theme.border.resolve(ConsonaBorderRole.defaultBorder,
        state: state, context: context);
    final baseShadows = theme.shadow
        .resolve(ConsonaShadowLevel.none, isDark: theme.colors.isDark);
    return (
      background: colors.fill,
      foreground: colors.content,
      border: border,
      // `none` level still yields the hairline edge under shadow/both strategies.
      shadows: state == ConsonaInteractionState.focused
          ? <BoxShadow>[
              ...baseShadows,
              ...theme.shadow.focusGlow(theme.colors.focusRing),
            ]
          : baseShadows,
    );
  });

  /// Plain / Ghost button variant: transparent background, text-only styling.
  static final ConsonaButtonVariant plain =
      ConsonaButtonVariant._(({required theme, required state, context}) {
    final colors =
        theme.colors.resolveIntent(ConsonaIntent.plain, state: state);
    return (
      background: colors.fill,
      foreground: colors.content,
      border: const Border(),
      shadows: state == ConsonaInteractionState.focused
          ? theme.shadow.focusGlow(theme.colors.focusRing)
          : const [],
    );
  });

  /// Danger button variant: high-visibility destructive fill.
  static final ConsonaButtonVariant danger =
      ConsonaButtonVariant._(({required theme, required state, context}) {
    final colors =
        theme.colors.resolveIntent(ConsonaIntent.danger, state: state);
    final border = theme.border
        .resolve(ConsonaBorderRole.error, state: state, context: context);
    final baseShadows = state == ConsonaInteractionState.disabled
        ? const <BoxShadow>[]
        : theme.shadow
            .resolve(ConsonaShadowLevel.subtle, isDark: theme.colors.isDark);
    return (
      background: colors.fill,
      foreground: colors.content,
      border: border,
      shadows: state == ConsonaInteractionState.focused
          ? <BoxShadow>[
              ...baseShadows,
              ...theme.shadow.focusGlow(theme.colors.danger),
            ]
          : baseShadows,
    );
  });

  /// Extends or creates a custom variant for downstream apps.
  static ConsonaButtonVariant custom(ButtonStyleResolver customResolver) {
    return ConsonaButtonVariant._(customResolver);
  }

  /// Extends an existing variant with an override resolver.
  ConsonaButtonVariant extend(ButtonStyleResolver overrideResolver) {
    return ConsonaButtonVariant._(({required theme, required state, context}) {
      return overrideResolver(theme: theme, state: state, context: context);
    });
  }
}
