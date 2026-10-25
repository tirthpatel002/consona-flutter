/// Consona Choice Box — Selectable card container with border focus and check cue
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../checkbox/checkbox.dart';
import '../typography/text.dart';

class ConsonaChoiceBox extends StatelessWidget {
  const ConsonaChoiceBox({
    super.key,
    required this.title,
    this.description,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
    this.disabled = false,
  });

  final String title;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool disabled;

  void _handleTap(BuildContext context) {
    if (disabled || onTap == null) return;
    FeedbackEngine.of(context).trigger(FeedbackEvent.selection);
    onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !disabled && onTap != null;

    final border = theme.border.resolve(
      ConsonaBorderRole.defaultBorder,
      state: selected
          ? ConsonaInteractionState.selected
          : disabled
              ? ConsonaInteractionState.disabled
              : ConsonaInteractionState.idle,
      context: context,
    );

    return ConsonaPressStateBuilder(
      builder: (context, pressed, onPressedChanged) => ConsonaSpringPress(
        enabled: isInteractive,
        feedbackEvent: null, // selection feedback is triggered in _handleTap
        pressedScale: 0.985,
        onTap: () => _handleTap(context),
        onPressedChanged: onPressedChanged,
        child: Opacity(
          opacity:
              disabled ? ConsonaOpacities.disabled : ConsonaOpacities.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: theme.density.resolvePadding(const EdgeInsets.all(16.0)),
            decoration: BoxDecoration(
              color: (isInteractive && pressed)
                  ? theme.colors.stateTint(
                      selected
                          ? theme.colors.surfaceSecondary
                          : theme.colors.surface,
                      ConsonaInteractionState.pressed,
                    )
                  : selected
                      ? theme.colors.surfaceSecondary
                      : theme.colors.surface,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
              border: border,
              boxShadow: theme.shadow.resolve(
                selected ? ConsonaShadowLevel.subtle : ConsonaShadowLevel.none,
                isDark: theme.colors.isDark,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 14.0),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConsonaText.titleMedium(title),
                      if (description != null) ...[
                        const SizedBox(height: 4.0),
                        ConsonaText.caption(description!),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12.0),
                  trailing!,
                ] else ...[
                  const SizedBox(width: 12.0),
                  ConsonaCheckbox(
                    value: selected,
                    onChanged:
                        isInteractive ? (_) => _handleTap(context) : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
