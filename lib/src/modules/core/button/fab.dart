/// Consona FAB — Floating action button with spring press and extended label mode.
library;

import 'package:flutter/widgets.dart';

import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';

/// Primary floating action — circular icon or extended pill with label.
class ConsonaFab extends StatelessWidget {
  const ConsonaFab({
    super.key,
    required this.icon,
    this.onTap,
    this.label,
    this.extended,
    this.intent = ConsonaIntent.primary,
    this.size = ConsonaOpticalSize.md,
    this.disabled = false,
    this.semanticLabel,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final String? label;

  /// When null, expands automatically when [label] is non-null and width ≥ 420.
  final bool? extended;
  final ConsonaIntent intent;
  final ConsonaOpticalSize size;
  final bool disabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final optical = size.standardEquivalent;
    final interactive = !disabled && onTap != null;
    final intentColors = colors.resolveIntent(intent);

    final diameter = switch (optical) {
          ConsonaOpticalSize.xs => 40.0,
          ConsonaOpticalSize.sm => 48.0,
          ConsonaOpticalSize.md => 56.0,
          ConsonaOpticalSize.lg => 64.0,
          _ => 56.0,
        } *
        scale;
    final iconSize = ConsonaGeometries.iconSizeFor(
          optical == ConsonaOpticalSize.lg
              ? ConsonaOpticalSize.md
              : ConsonaOpticalSize.sm,
        ) *
        scale;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = !constraints.maxWidth.isFinite || constraints.maxWidth >= 420;
        final showExtended =
            extended ?? (label != null && label!.isNotEmpty && wide);

        final Color fill;
        final Color content;
        switch (intent) {
          case ConsonaIntent.subtle:
            fill = colors.surface;
            content = colors.foreground;
          case ConsonaIntent.outline:
            fill = colors.surface;
            content = colors.foreground;
          case ConsonaIntent.plain:
            fill = colors.surfaceSecondary;
            content = colors.primary;
          default:
            fill = intentColors.fill;
            content = intentColors.content;
        }

        final child = AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          height: diameter,
          padding: EdgeInsets.symmetric(
            horizontal: showExtended ? ConsonaSpacing.md * scale : 0,
          ),
          decoration: BoxDecoration(
            color: fill.withAlpha(interactive ? 255 : (255 * ConsonaOpacities.disabled).round()),
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
            border: theme.border.resolve(
              intent == ConsonaIntent.outline || intent == ConsonaIntent.subtle
                  ? ConsonaBorderRole.surfaceEdge
                  : ConsonaBorderRole.subtle,
              context: context,
            ),
            boxShadow: theme.shadow.resolve(
              ConsonaShadowLevel.soft,
              ambientColor: colors.foreground,
              isDark: colors.isDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: showExtended ? null : diameter,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(size: iconSize, color: content),
                    child: icon,
                  ),
                ),
              ),
              if (showExtended && label != null) ...[
                SizedBox(width: ConsonaSpacing.sm * scale),
                Text(
                  label!,
                  style: theme.typography.label.copyWith(
                    color: content,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(width: ConsonaSpacing.xs * scale),
              ],
            ],
          ),
        );

        return Semantics(
          button: true,
          enabled: interactive,
          label: semanticLabel ?? label ?? 'Floating action',
          child: ConsonaHitTarget(
            inflateLayout: false,
            minSize: Size(diameter, diameter),
            child: ConsonaSpringPress(
              enabled: interactive,
              pressedScale: 0.94,
              feedbackEvent: FeedbackEvent.tap,
              onTap: interactive ? onTap : null,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
