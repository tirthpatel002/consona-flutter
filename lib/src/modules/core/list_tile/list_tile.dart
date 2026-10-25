/// Consona List Tile — Workhorse mobile cell with slots, 48pt tap boundary, and press highlights
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../typography/text.dart';

class ConsonaListTile extends StatelessWidget {
  const ConsonaListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.disabled = false,
    this.enableFeedback = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool disabled;

  /// When false the tile does not fire the default `tap` cue, e.g. when the
  /// [onTap] handler triggers its own, more specific feedback.
  final bool enableFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !disabled && onTap != null;

    final dividerBorder = showDivider
        ? theme.border.resolve(ConsonaBorderRole.divider, context: context)
        : const Border();

    Widget buildContent(ConsonaInteractionState state) => Container(
          padding: theme.density.resolvePadding(
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          decoration: BoxDecoration(
            color: theme.colors.stateTint(theme.colors.surface, state),
            border: dividerBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    ConsonaText.body(
                      title,
                      color: disabled
                          ? theme.colors.mutedFg
                          : theme.colors.foreground,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2.0),
                      ConsonaText.caption(
                        subtitle!,
                        color: theme.colors.mutedFg,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12.0),
                trailing!,
              ] else if (isInteractive) ...[
                const SizedBox(width: 8.0),
                Icon(
                  const IconData(0xe15f,
                      fontFamily: 'MaterialIcons', matchTextDirection: true),
                  size: 16.0,
                  color: theme.colors.mutedFg.withAlpha((255 * 0.6).round()),
                ),
              ],
            ],
          ),
        );

    Widget content;
    if (isInteractive) {
      content = ConsonaInteractionStateBuilder(
        disabled: disabled,
        interactive: true,
        builder: (
          context,
          state,
          onPressedChanged,
          onHoverChanged,
          onFocusChanged,
        ) =>
            ConsonaSpringPress(
          enabled: true,
          pressedScale: 0.99,
          feedbackEvent: enableFeedback ? FeedbackEvent.tap : null,
          onTap: onTap,
          onPressedChanged: onPressedChanged,
          onHoverChanged: onHoverChanged,
          onFocusChanged: onFocusChanged,
          child: buildContent(state),
        ),
      );
    } else {
      content = buildContent(ConsonaInteractionState.idle);
    }

    return Semantics(
      button: isInteractive,
      enabled: !disabled,
      child: ConsonaHitTarget(
        child: Opacity(
          opacity:
              disabled ? ConsonaOpacities.disabled : ConsonaOpacities.opaque,
          child: content,
        ),
      ),
    );
  }
}
