/// Consona Media Grid — Square mosaic (up to 2×2) with lightbox integration.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../image/smart_image.dart';
import '../lightbox/lightbox.dart';
import '../models/media_item.dart';

/// Mosaic media gallery. Four or more items render as a square 2×2 grid; the
/// bottom-right tile shows a light `+N` overlay for remaining items.
/// Tapping a tile opens [ConsonaLightbox].
class ConsonaMediaGrid extends StatelessWidget {
  const ConsonaMediaGrid({
    super.key,
    required this.items,
    this.spacing = ConsonaSpacing.xs,
    this.radiusRole = ConsonaRadiusRole.base,
    this.maxHeight = 360.0,
    this.onItemTap,
    this.openLightboxOnTap = true,
    this.lightboxMoreMenuBuilder,
  });

  /// Media items to display.
  final List<ConsonaMediaItem> items;

  /// Gap between tiles.
  final double spacing;

  /// Corner radius role for each tile chrome.
  final ConsonaRadiusRole radiusRole;

  /// Maximum gallery container height.
  final double maxHeight;

  /// Optional custom callback when a tile is pressed.
  final void Function(int index)? onItemTap;

  /// Whether tapping a tile automatically opens [ConsonaLightbox].
  final bool openLightboxOnTap;

  /// Forwarded to [ConsonaLightbox.moreMenuBuilder] when the grid opens it.
  final ConsonaLightboxMoreMenuBuilder? lightboxMoreMenuBuilder;

  void _handleTap(BuildContext context, int index) {
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
    if (onItemTap != null) {
      onItemTap!(index);
    } else if (openLightboxOnTap) {
      ConsonaLightbox.show(
        context,
        items: items,
        initialIndex: index,
        moreMenuBuilder: lightboxMoreMenuBuilder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = ConsonaTheme.of(context);
    final count = items.length;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: switch (count) {
        1 => _buildSingleItem(context, theme),
        2 => _buildTwoItems(context, theme),
        3 => _buildThreeItems(context, theme),
        _ => _buildSquareFour(context, theme),
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    ConsonaThemeData theme,
    int index, {
    int? overflowCount,
  }) {
    final item = items[index];
    final borderRadius = theme.radius.resolve(radiusRole);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context, index),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: theme.border.resolve(
              ConsonaBorderRole.subtle,
              context: context,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ConsonaImage(
                uri: item.thumbnailUri ?? item.uri,
                bytes: item.bytes,
                fit: BoxFit.cover,
                zoomOnHover: true,
                // Parent already clips + borders the tile.
                radiusRole: null,
                borderRole: null,
              ),
              if (overflowCount != null && overflowCount > 0)
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: theme.colors.background.withAlpha(150),
                      alignment: Alignment.center,
                      child: Text(
                        '+$overflowCount',
                        style: theme.typography.titleMedium.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w400,
                          fontSize: 22.0,
                          letterSpacing: 0.2,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleItem(BuildContext context, ConsonaThemeData theme) {
    final item = items.first;
    final borderRadius = theme.radius.resolve(radiusRole);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: theme.border.resolve(
            ConsonaBorderRole.subtle,
            context: context,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 1,
          child: ConsonaImage(
            uri: item.thumbnailUri ?? item.uri,
            bytes: item.bytes,
            fit: BoxFit.cover,
            zoomOnHover: true,
            radiusRole: null,
            borderRole: null,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoItems(BuildContext context, ConsonaThemeData theme) {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          _buildTile(context, theme, 0),
          SizedBox(width: spacing),
          _buildTile(context, theme, 1),
        ],
      ),
    );
  }

  Widget _buildThreeItems(BuildContext context, ConsonaThemeData theme) {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          _buildTile(context, theme, 0),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              children: [
                _buildTile(context, theme, 1),
                SizedBox(height: spacing),
                _buildTile(context, theme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed 2×2 square. With 5+ items the bottom-right tile shows `+N`.
  Widget _buildSquareFour(BuildContext context, ConsonaThemeData theme) {
    final overflow = items.length > 4 ? items.length - 4 : 0;

    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildTile(context, theme, 0),
                SizedBox(width: spacing),
                _buildTile(context, theme, 1),
              ],
            ),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                _buildTile(context, theme, 2),
                SizedBox(width: spacing),
                _buildTile(
                  context,
                  theme,
                  3,
                  overflowCount: overflow > 0 ? overflow : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
