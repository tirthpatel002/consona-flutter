/// Consona Alert — Responsive inline semantic callout and banner primitive.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Persistent inline callout box for status messages, form errors, warnings,
/// and contextual guidance. Adapts layout automatically between compact mobile
/// and wide desktop/tablet viewports.
class ConsonaAlert extends StatelessWidget {
  const ConsonaAlert({
    super.key,
    required this.title,
    this.description,
    this.intent = ConsonaIntent.subtle,
    this.icon,
    this.action,
    this.onClose,
  });

  const ConsonaAlert.info({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
  }) : intent = ConsonaIntent.primary;

  const ConsonaAlert.success({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
  }) : intent = ConsonaIntent.success;

  const ConsonaAlert.warning({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
  }) : intent = ConsonaIntent.warning;

  const ConsonaAlert.danger({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onClose,
  }) : intent = ConsonaIntent.danger;

  final String title;
  final String? description;
  final ConsonaIntent intent;
  final Widget? icon;
  final Widget? action;
  final VoidCallback? onClose;

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

    final Color fill = switch (intent) {
      ConsonaIntent.subtle || ConsonaIntent.outline || ConsonaIntent.plain =>
        colors.surfaceSecondary,
      _ => accent.withAlpha(colors.isDark ? 36 : 24),
    };

    final borderRole = intent == ConsonaIntent.danger
        ? ConsonaBorderRole.error
        : ConsonaBorderRole.surfaceEdge;

    return Semantics(
      container: true,
      liveRegion: intent == ConsonaIntent.danger,
      label: title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 460;

          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.typography.label.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: ConsonaSpacing.xxs),
                Text(
                  description!,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                  ),
                ),
              ],
              if (isCompact && action != null) ...[
                const SizedBox(height: ConsonaSpacing.sm),
                action!,
              ],
            ],
          );

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(ConsonaSpacing.md * scale),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
              border: theme.border.resolve(borderRole, context: context),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(36),
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                  ),
                  alignment: Alignment.center,
                  child: icon != null
                      ? IconTheme(
                          data: IconThemeData(size: 15 * scale, color: accent),
                          child: icon!,
                        )
                      : Text(
                          switch (intent) {
                            ConsonaIntent.success => '✓',
                            ConsonaIntent.warning => '!',
                            ConsonaIntent.danger => '✕',
                            _ => 'i',
                          },
                          style: theme.typography.label.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: ConsonaSpacing.sm),
                Expanded(child: textBlock),
                if (!isCompact && action != null) ...[
                  const SizedBox(width: ConsonaSpacing.sm),
                  action!,
                ],
                if (onClose != null) ...[
                  const SizedBox(width: ConsonaSpacing.xs),
                  Semantics(
                    button: true,
                    label: 'Dismiss alert',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          unawaited(
                            ConsonaFeedbackScope.maybeOf(context)?.trigger(
                              FeedbackEvent.tap,
                            ),
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
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
