/// Consona Button — Production button atom with dual-axis slots, spring physics, and variants
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/radius.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../loader/loader.dart';
import '../typography/text.dart';
import 'button_tone_scope.dart';
import 'button_variant.dart';

class ConsonaButton extends StatelessWidget {
  const ConsonaButton({
    super.key,
    this.label,
    this.onTap,
    this.variant,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  }) : _intent = null;

  final String? label;
  final VoidCallback? onTap;
  final ConsonaButtonVariant? variant;
  final ConsonaOpticalSize? size;
  final ConsonaShapeVariant shapeVariant;
  final Widget? leading;
  final Widget? trailing;
  final bool loading;
  final bool disabled;
  final bool fullWidth;
  final bool enableFeedback;

  /// When false, layout hugs the label; hit-testing still expands to 44/48.
  final bool inflateHitTarget;
  final ConsonaIntent? _intent;

  const ConsonaButton.primary({
    super.key,
    this.label,
    this.onTap,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.primary;

  const ConsonaButton.subtle({
    super.key,
    this.label,
    this.onTap,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.subtle;

  const ConsonaButton.outline({
    super.key,
    this.label,
    this.onTap,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.outline;

  const ConsonaButton.plain({
    super.key,
    this.label,
    this.onTap,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.plain;

  const ConsonaButton.danger({
    super.key,
    this.label,
    this.onTap,
    this.size,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.leading,
    this.trailing,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.enableFeedback = true,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.danger;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final btnTheme = theme.components.button;
    final effectiveSize =
        size ?? btnTheme.defaultSize ?? ConsonaSizeScope.of(context);

    // Resolve variant
    final effectiveVariant = variant ??
        switch (_intent) {
          ConsonaIntent.subtle => ConsonaButtonVariant.subtle,
          ConsonaIntent.outline => ConsonaButtonVariant.outline,
          ConsonaIntent.plain => ConsonaButtonVariant.plain,
          ConsonaIntent.danger => ConsonaButtonVariant.danger,
          _ => ConsonaButtonVariant.primary,
        };

    final isInteractive = !disabled && !loading && onTap != null;

    return ConsonaInteractionStateBuilder(
      disabled: disabled,
      interactive: isInteractive,
      builder: (
        context,
        state,
        onPressedChanged,
        onHoverChanged,
        onFocusChanged,
      ) {
        return _buildButton(
          context,
          theme: theme,
          effectiveSize: effectiveSize,
          effectiveVariant: effectiveVariant,
          isInteractive: isInteractive,
          state: state,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
        );
      },
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required ConsonaThemeData theme,
    required ConsonaOpticalSize effectiveSize,
    required ConsonaButtonVariant effectiveVariant,
    required bool isInteractive,
    required ConsonaInteractionState state,
    required ValueChanged<bool> onPressedChanged,
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<bool> onFocusChanged,
  }) {
    final btnTheme = theme.components.button;
    var resolved = effectiveVariant.resolve(
      theme: theme,
      state: state,
      context: context,
    );
    final tone = ConsonaButtonToneScope.maybeOf(context);
    if (tone != null) {
      resolved = _resolveContextualTone(
        theme: theme,
        state: state,
        context: context,
        tone: tone,
        variant: effectiveVariant,
        base: resolved,
      );
    }

    // Dimensions
    final baseHeight = ConsonaGeometries.heightFor(effectiveSize);
    final densityHeight = theme.density.resolveHeight(baseHeight);
    final basePadding = ConsonaGeometries.horizontalPaddingFor(effectiveSize);
    final densityPadding = theme.density.resolvePadding(basePadding);

    final effectiveShape = shapeVariant == ConsonaShapeVariant.base
        ? (btnTheme.shape ?? shapeVariant)
        : shapeVariant;

    final effectiveRadius = btnTheme.radius != null
        ? ConsonaRadius.fromPreset(btnTheme.radius!)
        : theme.radius;
    final isSquircle = effectiveShape == ConsonaShapeVariant.squircle ||
        effectiveRadius.isSquircle;
    final radiusRole = switch (effectiveShape) {
      ConsonaShapeVariant.pill => ConsonaRadiusRole.full,
      ConsonaShapeVariant.squircle => ConsonaRadiusRole.macro,
      ConsonaShapeVariant.inset => ConsonaRadiusRole.micro,
      ConsonaShapeVariant.base => ConsonaRadiusRole.base,
    };

    final Decoration decoration;
    if (isSquircle && effectiveShape != ConsonaShapeVariant.pill) {
      final side = resolved.border is Border
          ? (resolved.border as Border).top
          : BorderSide.none;
      final squircleRadius = effectiveShape == ConsonaShapeVariant.squircle
          ? const ConsonaRadius.squircle()
          : effectiveRadius;
      decoration = ShapeDecoration(
        color: resolved.background,
        shape: squircleRadius.resolveShape(radiusRole, side: side),
        shadows: resolved.shadows,
      );
    } else {
      decoration = BoxDecoration(
        color: resolved.background,
        borderRadius: effectiveRadius.resolve(radiusRole),
        border: resolved.border,
        boxShadow: resolved.shadows,
      );
    }

    Widget content;
    if (loading) {
      content = ConsonaLoader(
        size: ConsonaGeometries.iconSizeFor(effectiveSize),
        color: resolved.foreground,
      );
    } else {
      final children = <Widget>[];

      if (leading != null) {
        children.add(
          IconTheme.merge(
            data: IconThemeData(
              color: resolved.foreground,
              size: ConsonaGeometries.iconSizeFor(effectiveSize),
            ),
            child: leading!,
          ),
        );
        if (label != null) children.add(const SizedBox(width: 8.0));
      }

      if (label != null) {
        final labelText = ConsonaText.label(
          label!,
          color: resolved.foreground,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: ConsonaGeometries.fontSizeFor(effectiveSize),
          ),
        );
        children.add(
          fullWidth ? Flexible(child: labelText) : labelText,
        );
      }

      if (trailing != null) {
        if (label != null || leading != null) {
          children.add(const SizedBox(width: 8.0));
        }
        children.add(trailing!);
      }

      content = Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }

    Widget buttonBox = Container(
      height: densityHeight,
      padding: densityPadding,
      decoration: decoration,
      alignment: Alignment.center,
      child: content,
    );

    if (fullWidth) {
      buttonBox = SizedBox(width: double.infinity, child: buttonBox);
    }

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: label,
      child: ConsonaHitTarget(
        inflateLayout: inflateHitTarget,
        child: ConsonaSpringPress(
          enabled: isInteractive,
          pressedScale: btnTheme.pressedScale ?? 0.975,
          onTap: onTap,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
          feedbackEvent: enableFeedback ? FeedbackEvent.tap : null,
          child: buttonBox,
        ),
      ),
    );
  }
}

({
  Color background,
  Color foreground,
  BoxBorder border,
  List<BoxShadow> shadows,
}) _resolveContextualTone({
  required ConsonaThemeData theme,
  required ConsonaInteractionState state,
  required BuildContext context,
  required ConsonaIntent tone,
  required ConsonaButtonVariant variant,
  required ({
    Color background,
    Color foreground,
    BoxBorder border,
    List<BoxShadow> shadows,
  }) base,
}) {
  if (variant != ConsonaButtonVariant.subtle &&
      variant != ConsonaButtonVariant.plain &&
      variant != ConsonaButtonVariant.outline) {
    return base;
  }

  final colors = theme.colors;
  final accent = switch (tone) {
    ConsonaIntent.success => colors.success,
    ConsonaIntent.warning => colors.warning,
    ConsonaIntent.danger => colors.danger,
    ConsonaIntent.primary ||
    ConsonaIntent.subtle ||
    ConsonaIntent.outline ||
    ConsonaIntent.plain ||
    ConsonaIntent.secondary ||
    ConsonaIntent.ghost =>
      colors.primary,
  };

  if (state == ConsonaInteractionState.disabled) {
    return (
      background: variant == ConsonaButtonVariant.plain
          ? const Color(0x00000000)
          : accent.withAlpha((255 * 0.12).round()),
      foreground: colors.mutedFg.withAlpha((255 * 0.5).round()),
      border: base.border,
      shadows: const <BoxShadow>[],
    );
  }

  final fillAlpha = switch (state) {
    ConsonaInteractionState.pressed => colors.isDark ? 88 : 72,
    ConsonaInteractionState.hovered => colors.isDark ? 68 : 52,
    _ => colors.isDark ? 52 : 36,
  };

  final focusShadows = state == ConsonaInteractionState.focused
      ? theme.shadow.focusGlow(accent)
      : const <BoxShadow>[];

  if (variant == ConsonaButtonVariant.plain) {
    return (
      background: const Color(0x00000000),
      foreground: accent,
      border: const Border(),
      shadows: focusShadows,
    );
  }

  if (variant == ConsonaButtonVariant.outline) {
    return (
      background: const Color(0x00000000),
      foreground: accent,
      border: Border.all(color: accent.withAlpha(180)),
      shadows: focusShadows,
    );
  }

  return (
    background: accent.withAlpha(fillAlpha),
    foreground: accent,
    border: base.border,
    shadows: focusShadows,
  );
}
