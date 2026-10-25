/// Consona Timeline — Responsive vertical event stream and activity feed.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// A single event entry in a [ConsonaTimeline].
@immutable
class ConsonaTimelineItem {
  const ConsonaTimelineItem({
    required this.title,
    this.subtitle,
    this.timestamp,
    this.intent = ConsonaIntent.primary,
    this.icon,
    this.child,
  });

  final String title;
  final String? subtitle;
  final String? timestamp;
  final ConsonaIntent intent;
  final Widget? icon;
  final Widget? child;
}

/// Vertical activity/event stream with status nodes, connecting hairlines,
/// and responsive timestamp placement (dedicated leading column on wide screens,
/// inline header on compact mobile screens).
class ConsonaTimeline extends StatelessWidget {
  const ConsonaTimeline({
    super.key,
    required this.items,
    this.responsiveTimestamps = true,
  });

  final List<ConsonaTimelineItem> items;
  final bool responsiveTimestamps;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            responsiveTimestamps && constraints.maxWidth >= 520.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++)
              _buildRow(
                context: context,
                item: items[i],
                isLast: i == items.length - 1,
                isWide: isWide,
                scale: scale,
                colors: colors,
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required ConsonaTimelineItem item,
    required bool isLast,
    required bool isWide,
    required double scale,
    required dynamic colors,
  }) {
    final theme = ConsonaTheme.of(context);
    final dotColor = switch (item.intent) {
      ConsonaIntent.primary => theme.colors.primary,
      ConsonaIntent.success => theme.colors.success,
      ConsonaIntent.warning => theme.colors.warning,
      ConsonaIntent.danger => theme.colors.danger,
      _ => theme.colors.mutedFg,
    };

    final nodeSize = 22.0 * scale;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide) ...[
            SizedBox(
              width: 96 * scale,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item.timestamp ?? '',
                  textAlign: TextAlign.end,
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.mutedFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: ConsonaSpacing.md),
          ],
          Column(
            children: [
              Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  color: dotColor.withAlpha(34),
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  border: theme.border.resolve(
                    ConsonaBorderRole.surfaceEdge,
                    context: context,
                  ),
                ),
                alignment: Alignment.center,
                child: item.icon != null
                    ? IconTheme(
                        data: IconThemeData(
                          size: 12 * scale,
                          color: dotColor,
                        ),
                        child: item.icon!,
                      )
                    : Container(
                        width: 8 * scale,
                        height: 8 * scale,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius:
                              theme.radius.resolve(ConsonaRadiusRole.full),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: theme.stroke.resolveWidth(context),
                    margin: const EdgeInsets.symmetric(
                      vertical: ConsonaSpacing.xxs,
                    ),
                    color: theme.colors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: ConsonaSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : ConsonaSpacing.lg * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: theme.typography.label.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isWide && item.timestamp != null) ...[
                        const SizedBox(width: ConsonaSpacing.sm),
                        Text(
                          item.timestamp!,
                          style: theme.typography.caption.copyWith(
                            color: theme.colors.mutedFg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: ConsonaSpacing.xxs),
                    Text(
                      item.subtitle!,
                      style: theme.typography.caption.copyWith(
                        color: theme.colors.mutedFg,
                      ),
                    ),
                  ],
                  if (item.child != null) ...[
                    const SizedBox(height: ConsonaSpacing.sm),
                    item.child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
