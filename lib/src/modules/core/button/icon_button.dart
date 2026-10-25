/// Consona Icon Button — Square tactile icon button with optical sizing
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/radius.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/interaction/spring_press.dart';
import 'button_variant.dart';

class ConsonaIconButton extends StatelessWidget {
  const ConsonaIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.variant,
    this.size = ConsonaOpticalSize.sqMd,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.disabled = false,
    this.semanticLabel,
    this.inflateHitTarget = true,
  }) : _intent = null;

  final Widget icon;
  final VoidCallback? onTap;
  final ConsonaButtonVariant? variant;
  final ConsonaOpticalSize size;
  final ConsonaShapeVariant shapeVariant;
  final bool disabled;
  final String? semanticLabel;

  /// When false, layout hugs the icon; hit-testing still expands to 44/48.
  final bool inflateHitTarget;
  final ConsonaIntent? _intent;

  const ConsonaIconButton.subtle({
    super.key,
    required this.icon,
    this.onTap,
    this.size = ConsonaOpticalSize.sqMd,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.disabled = false,
    this.semanticLabel,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.subtle;

  const ConsonaIconButton.outline({
    super.key,
    required this.icon,
    this.onTap,
    this.size = ConsonaOpticalSize.sqMd,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.disabled = false,
    this.semanticLabel,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.outline;

  const ConsonaIconButton.plain({
    super.key,
    required this.icon,
    this.onTap,
    this.size = ConsonaOpticalSize.sqMd,
    this.shapeVariant = ConsonaShapeVariant.base,
    this.disabled = false,
    this.semanticLabel,
    this.inflateHitTarget = true,
  })  : variant = null,
        _intent = ConsonaIntent.plain;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final effectiveVariant = variant ??
        switch (_intent) {
          ConsonaIntent.subtle => ConsonaButtonVariant.subtle,
          ConsonaIntent.outline => ConsonaButtonVariant.outline,
          ConsonaIntent.plain => ConsonaButtonVariant.plain,
          _ => ConsonaButtonVariant.subtle,
        };

    final isInteractive = !disabled && onTap != null;

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
    required ConsonaButtonVariant effectiveVariant,
    required bool isInteractive,
    required ConsonaInteractionState state,
    required ValueChanged<bool> onPressedChanged,
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<bool> onFocusChanged,
  }) {
    final btnTheme = theme.components.button;
    final resolved = effectiveVariant.resolve(
      theme: theme,
      state: state,
      context: context,
    );

    final dimension = ConsonaGeometries.heightFor(size);
    final densityDimension = theme.density.resolveHeight(dimension);

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

    final buttonBox = Container(
      width: densityDimension,
      height: densityDimension,
      decoration: decoration,
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(
          color: resolved.foreground,
          size: ConsonaGeometries.iconSizeFor(size),
        ),
        child: icon,
      ),
    );

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: semanticLabel,
      child: ConsonaHitTarget(
        inflateLayout: inflateHitTarget,
        child: ConsonaSpringPress(
          enabled: isInteractive,
          pressedScale: btnTheme.pressedScale ?? 0.975,
          onTap: onTap,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
          child: buttonBox,
        ),
      ),
    );
  }
}
