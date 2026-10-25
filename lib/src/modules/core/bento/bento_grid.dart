/// Consona BentoGrid — Modular summary tile grid for mobile dashboards.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';

/// Individual tile in a [ConsonaBentoGrid].
class ConsonaBentoTile extends StatelessWidget {
  const ConsonaBentoTile({
    super.key,
    required this.child,
    this.colSpan = 1,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final int colSpan;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final tile = Container(
      padding: padding ?? const EdgeInsets.all(ConsonaSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border: theme.border.resolve(ConsonaBorderRole.subtle),
      ),
      child: child,
    );

    if (onTap != null) {
      return ConsonaSpringPress(
        onTap: () {
          ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
          onTap!();
        },
        child: tile,
      );
    }

    return tile;
  }
}

/// Responsive mobile bento grid container.
class ConsonaBentoGrid extends StatelessWidget {
  const ConsonaBentoGrid({
    super.key,
    required this.tiles,
    this.crossAxisCount = 2,
    this.spacing = ConsonaSpacing.sm,
  });

  final List<ConsonaBentoTile> tiles;
  final int crossAxisCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final colWidth = (totalWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

        final rows = <Widget>[];
        var currentRow = <Widget>[];
        var currentSpan = 0;

        for (final tile in tiles) {
          final span = tile.colSpan.clamp(1, crossAxisCount);
          if (currentSpan + span > crossAxisCount) {
            rows.add(
              Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < currentRow.length; i++) ...[
                      if (i > 0) SizedBox(width: spacing),
                      currentRow[i],
                    ],
                  ],
                ),
              ),
            );
            currentRow = [];
            currentSpan = 0;
          }

          final width = span == 1
              ? colWidth
              : colWidth * span + spacing * (span - 1);

          currentRow.add(
            SizedBox(
              width: width,
              child: tile,
            ),
          );
          currentSpan += span;
        }

        if (currentRow.isNotEmpty) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < currentRow.length; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  currentRow[i],
                ],
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
