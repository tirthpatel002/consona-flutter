/// Consona Chip — Filter, action, and input tag with selected states and delete action
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/motion.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../typography/text.dart';

class ConsonaChip extends StatelessWidget {
  const ConsonaChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.leading,
    this.trailing,
    this.disabled = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? leading;
  final Widget? trailing;
  final bool disabled;

  /// Dense visual + layout (no 44pt hit-target inflation). Used by
  /// [ConsonaTagInput] so chips wrap tightly without empty row gaps.
  final bool compact;

  void _handleTap(BuildContext context) {
    if (disabled || onTap == null) return;
    FeedbackEngine.maybeOf(context)?.trigger(FeedbackEvent.selection);
    onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !disabled && (onTap != null || onDelete != null);

    final motion = theme.motion.resolve(ConsonaMotionRole.focus, context);

    final border = theme.border.resolve(
      ConsonaBorderRole.defaultBorder,
      state: selected
          ? ConsonaInteractionState.selected
          : disabled
              ? ConsonaInteractionState.disabled
              : ConsonaInteractionState.idle,
      context: context,
    );

    return ConsonaInteractionStateBuilder(
      disabled: disabled,
      interactive: isInteractive,
      builder: (
        context,
        interactionState,
        onPressedChanged,
        onHoverChanged,
        onFocusChanged,
      ) {
        final baseFill =
            selected ? theme.colors.primary : theme.colors.surfaceSecondary;
        final fillColor = isInteractive
            ? theme.colors.stateTint(baseFill, interactionState)
            : baseFill;
        final contentColor =
            selected ? theme.colors.onPrimary : theme.colors.foreground;
        return _buildChip(
          context,
          theme: theme,
          motion: motion,
          border: border,
          fillColor: fillColor,
          contentColor: contentColor,
          isInteractive: isInteractive,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required ConsonaThemeData theme,
    required ConsonaMotionSpec motion,
    required BoxBorder border,
    required Color fillColor,
    required Color contentColor,
    required bool isInteractive,
    required ValueChanged<bool> onPressedChanged,
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<bool> onFocusChanged,
  }) {
    final children = <Widget>[];

    if (leading != null) {
      children.add(leading!);
      children.add(const SizedBox(width: 6.0));
    }

    children.add(
      ConsonaText.label(
        label,
        color: contentColor,
      ),
    );

    if (onDelete != null) {
      children.add(const SizedBox(width: 4.0));
      children.add(
        Semantics(
          button: true,
          label: 'Remove $label',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: disabled
                ? null
                : () {
                    FeedbackEngine.of(context).trigger(FeedbackEvent.tap);
                    onDelete!();
                  },
            child: Icon(
              const IconData(0xe15b, fontFamily: 'MaterialIcons'),
              size: 14.0,
              color: contentColor,
            ),
          ),
        ),
      );
    } else if (trailing != null) {
      children.add(const SizedBox(width: 6.0));
      children.add(trailing!);
    }

    final padding = theme.density.resolvePadding(
      compact
          ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
          : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: isInteractive,
      label: label,
      child: ConsonaHitTarget(
        inflateLayout: !compact,
        minSize: compact ? const Size(32, 28) : null,
        child: ConsonaSpringPress(
          enabled: isInteractive,
          feedbackEvent: null, // selection feedback is triggered in _handleTap
          pressedScale: 0.97,
          onTap: onTap != null ? () => _handleTap(context) : null,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
          child: Opacity(
            opacity:
                disabled ? ConsonaOpacities.disabled : ConsonaOpacities.opaque,
            child: AnimatedContainer(
              duration: motion.duration,
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BoxDecoration(
                color: fillColor,
                // Follows the radius knob (macro role); the default radius is
                // large enough that chips still render as pills.
                borderRadius: theme.radius.resolve(
                  compact ? ConsonaRadiusRole.base : ConsonaRadiusRole.macro,
                ),
                border: selected ? null : border,
                boxShadow: theme.shadow.resolve(
                  ConsonaShadowLevel.none,
                  isDark: theme.colors.isDark,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
