/// Consona Banner — Full-bleed page-level notice with leading accent strip.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../button/button_tone_scope.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Edge-to-edge page banner for system notices, maintenance, and billing.
///
/// Distinct from [ConsonaAlert]: no rounded callout chrome — designed to sit
/// flush under app bars or above page content. Parent decides sticky behavior.
class ConsonaBanner extends StatelessWidget {
  const ConsonaBanner({
    super.key,
    required this.title,
    this.description,
    this.intent = ConsonaIntent.primary,
    this.icon,
    this.action,
    this.onClose,
    this.compact = false,
  });

  const ConsonaBanner.info({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.compact = false,
  }) : intent = ConsonaIntent.primary;

  const ConsonaBanner.success({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.compact = false,
  }) : intent = ConsonaIntent.success;

  const ConsonaBanner.warning({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.compact = false,
  }) : intent = ConsonaIntent.warning;

  const ConsonaBanner.danger({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
    this.compact = false,
  }) : intent = ConsonaIntent.danger;

  final String title;
  final String? description;
  final ConsonaIntent intent;
  final Widget? icon;
  final Widget? action;
  final VoidCallback? onClose;

  /// Dense single-line layout for sticky toolbars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    final Color accent = switch (intent) {
      ConsonaIntent.primary => colors.primary,
      ConsonaIntent.success => colors.success,
      ConsonaIntent.warning => colors.warning,
      ConsonaIntent.danger => colors.danger,
      _ => colors.foreground,
    };

    final fill = accent.withAlpha(colors.isDark ? 40 : 22);
    final divider = theme.border.resolve(
      ConsonaBorderRole.divider,
      context: context,
    );
    final dividerSide = divider is Border
        ? divider.bottom
        : BorderSide(
            color: colors.borderLight,
            width: theme.stroke.resolveWidth(context),
          );

    return Semantics(
      container: true,
      liveRegion:
          intent == ConsonaIntent.danger || intent == ConsonaIntent.warning,
      label: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = !constraints.maxWidth.isFinite ||
              constraints.maxWidth < 520;
          final padV =
              (compact ? ConsonaSpacing.sm : ConsonaSpacing.md) * scale;
          final padH = ConsonaSpacing.md * scale;

          final closeButton = onClose == null
              ? null
              : Semantics(
                  button: true,
                  label: 'Dismiss banner',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        unawaited(
                          ConsonaFeedbackScope.maybeOf(context)
                              ?.trigger(FeedbackEvent.tap),
                        );
                        onClose!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                        child: Text(
                          '✕',
                          style: theme.typography.label.copyWith(
                            color: colors.mutedFg,
                          ),
                        ),
                      ),
                    ),
                  ),
                );

          final titleText = Text(
            title,
            maxLines: compact ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.label.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          );

          final descriptionText = description != null && !compact
              ? Text(
                  description!,
                  maxLines: isNarrow ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                  ),
                )
              : null;

          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleText,
              if (descriptionText != null) ...[
                const SizedBox(height: ConsonaSpacing.xxs),
                descriptionText,
              ],
            ],
          );

          final leadingIcon = icon == null
              ? null
              : IconTheme(
                  data: IconThemeData(size: 18 * scale, color: accent),
                  child: icon!,
                );

          final actionWidget = action == null
              ? null
              : ConsonaButtonToneScope(
                  intent: intent,
                  child: action!,
                );

          Widget body;
          if (isNarrow) {
            body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leadingIcon != null) ...[
                      leadingIcon,
                      SizedBox(width: ConsonaSpacing.sm * scale),
                    ],
                    Expanded(child: textBlock),
                    if (closeButton != null) ...[
                      SizedBox(width: ConsonaSpacing.xs * scale),
                      closeButton,
                    ],
                  ],
                ),
                if (actionWidget != null) ...[
                  SizedBox(height: ConsonaSpacing.sm * scale),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: actionWidget,
                  ),
                ],
              ],
            );
          } else {
            body = Row(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon,
                  SizedBox(width: ConsonaSpacing.sm * scale),
                ],
                Expanded(child: textBlock),
                if (actionWidget != null) ...[
                  SizedBox(width: ConsonaSpacing.md * scale),
                  actionWidget,
                ],
                if (closeButton != null) ...[
                  SizedBox(width: ConsonaSpacing.xs * scale),
                  closeButton,
                ],
              ],
            );
          }

          return DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border(
                left: BorderSide(width: 3.0 * scale, color: accent),
                bottom: dividerSide,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
              child: body,
            ),
          );
        },
      ),
    );
  }
}
