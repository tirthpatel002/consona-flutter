/// Consona Pill — Soft meta label capsule for tags, counts, and status chrome.
library;

import 'package:flutter/widgets.dart';

import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Lightweight non-filter meta pill. Prefer [ConsonaChip] for selectable filters
/// and [ConsonaBadge] for overlay counts.
class ConsonaPill extends StatelessWidget {
  const ConsonaPill({
    super.key,
    required this.label,
    this.intent = ConsonaIntent.subtle,
    this.size = ConsonaOpticalSize.sm,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final ConsonaIntent intent;
  final ConsonaOpticalSize size;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final optical = size.standardEquivalent;
    final intentColors = colors.resolveIntent(intent);
    final interactive = enabled && onTap != null;

    final padH = switch (optical) {
      ConsonaOpticalSize.xs => 6.0,
      ConsonaOpticalSize.sm => 8.0,
      ConsonaOpticalSize.md => 10.0,
      ConsonaOpticalSize.lg => 12.0,
      _ => 8.0,
    };
    final padV = switch (optical) {
      ConsonaOpticalSize.xs => 2.0,
      ConsonaOpticalSize.sm => 3.0,
      ConsonaOpticalSize.md => 4.0,
      ConsonaOpticalSize.lg => 5.0,
      _ => 3.0,
    };
    final fontSize = ConsonaGeometries.fontSizeFor(optical) * 0.92;
    final iconSize = ConsonaGeometries.iconSizeFor(
          optical == ConsonaOpticalSize.lg
              ? ConsonaOpticalSize.sm
              : ConsonaOpticalSize.xs,
        ) *
        scale;

    final Color fill;
    final Color content;
    final BoxBorder? border;
    switch (intent) {
      case ConsonaIntent.primary:
      case ConsonaIntent.danger:
      case ConsonaIntent.success:
      case ConsonaIntent.warning:
        fill = intentColors.fill.withAlpha(colors.isDark ? 48 : 28);
        content = intentColors.fill;
        border = null;
      case ConsonaIntent.outline:
        fill = colors.surface;
        content = colors.foreground;
        border = theme.border.resolve(
          ConsonaBorderRole.defaultBorder,
          context: context,
        );
      default:
        fill = colors.surfaceSecondary;
        content = colors.mutedFg;
        border = theme.border.resolve(
          ConsonaBorderRole.subtle,
          context: context,
        );
    }

    final child = AnimatedContainer(
      duration: theme.motion
          .resolve(ConsonaMotionRole.focus, context)
          .duration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: padH * scale,
        vertical: padV * scale,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData(size: iconSize, color: content),
              child: leading!,
            ),
            SizedBox(width: ConsonaSpacing.xxs * scale),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.label.copyWith(
                color: content,
                fontSize: fontSize * scale,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: ConsonaSpacing.xxs * scale),
            IconTheme(
              data: IconThemeData(size: iconSize, color: content),
              child: trailing!,
            ),
          ],
        ],
      ),
    );

    if (!interactive) {
      return Semantics(label: label, child: child);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ConsonaHitTarget(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              ConsonaFeedbackScope.maybeOf(context)?.trigger(
                FeedbackEvent.selection,
              );
              onTap!();
            },
            child: child,
          ),
        ),
      ),
    );
  }
}
