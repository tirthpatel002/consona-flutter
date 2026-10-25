/// Consona File Card & Row — High-density document & attachment items with semantic badges.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/icon_button.dart';
import '../../core/progress/progress.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../models/media_item.dart';
import '../shared/thin_icons.dart';

/// Card-format file attachment displaying semantic extension badges, file size,
/// upload progress, and download/remove actions.
class ConsonaFileCard extends StatelessWidget {
  const ConsonaFileCard({
    super.key,
    required this.item,
    this.progress,
    this.statusLabel,
    this.onTap,
    this.onDownload,
    this.onRemove,
  });

  /// The media item model representing this file.
  final ConsonaMediaItem item;

  /// Optional upload or download progress (0.0 to 1.0).
  final double? progress;

  /// Optional status label (e.g. 'Uploading...', 'Synced', 'Failed').
  final String? statusLabel;

  /// Callback when the card is tapped (e.g. to inspect via [ConsonaFileViewerModal]).
  final VoidCallback? onTap;

  /// Callback when download action is pressed.
  final VoidCallback? onDownload;

  /// Callback when remove action is pressed.
  final VoidCallback? onRemove;

  static Color _resolveBadgeColor(ConsonaColors colors, ConsonaMediaType type) {
    return switch (type) {
      ConsonaMediaType.document => colors.danger,
      ConsonaMediaType.code => colors.success,
      ConsonaMediaType.video => colors.primary,
      ConsonaMediaType.audio => colors.primary,
      ConsonaMediaType.archive => colors.warning,
      ConsonaMediaType.image => colors.primary,
      ConsonaMediaType.generic => colors.mutedFg,
    };
  }

  static IconData _fileIconFor(ConsonaMediaType type) {
    return switch (type) {
      ConsonaMediaType.document => Icons.description_outlined,
      ConsonaMediaType.image => Icons.image_outlined,
      ConsonaMediaType.code => Icons.code_outlined,
      ConsonaMediaType.archive => Icons.folder_zip_outlined,
      ConsonaMediaType.audio => Icons.audiotrack_outlined,
      ConsonaMediaType.video => Icons.videocam_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final type = item.resolvedType;
    final badgeColor = _resolveBadgeColor(colors, type);

    final card = Container(
      padding: const EdgeInsets.all(ConsonaSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border: theme.border.resolve(
          ConsonaBorderRole.subtle,
          context: context,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Semantic Extension Badge
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(22),
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                  border: Border.all(
                    color: badgeColor.withAlpha(60),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileIconFor(type),
                      size: 18.0,
                      color: badgeColor,
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      type.badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 8.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ConsonaSpacing.md),

              // File Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: ConsonaSpacing.xxs),
                    Row(
                      children: [
                        if (item.sizeLabel != null)
                          Text(
                            item.sizeLabel!,
                            style: theme.typography.caption.copyWith(
                              color: colors.mutedFg,
                              fontSize: 11.5,
                            ),
                          ),
                        if (item.sizeLabel != null && statusLabel != null)
                          Text(
                            ' • ',
                            style: theme.typography.caption.copyWith(
                              color: colors.mutedFg,
                              fontSize: 11.5,
                            ),
                          ),
                        if (statusLabel != null)
                          Text(
                            statusLabel!,
                            style: theme.typography.caption.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (onDownload != null)
                ConsonaIconButton(
                  icon: const ConsonaThinDownloadIcon(size: 16.0),
                  size: ConsonaOpticalSize.sqXs,
                  semanticLabel: 'Download',
                  onTap: onDownload,
                ),
              if (onRemove != null) ...[
                const SizedBox(width: ConsonaSpacing.xs),
                ConsonaIconButton(
                  icon: const Icon(Icons.close_outlined, size: 16.0),
                  size: ConsonaOpticalSize.sqXs,
                  semanticLabel: 'Remove',
                  onTap: onRemove,
                ),
              ],
            ],
          ),

          // Optional Progress Indicator
          if (progress != null) ...[
            const SizedBox(height: ConsonaSpacing.sm),
            ConsonaProgress(
              value: progress!,
              height: 4.0,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return ConsonaSpringPress(
        onTap: () {
          ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
          onTap!();
        },
        child: card,
      );
    }

    return card;
  }
}

/// Dense row format for attachments and file tables.
class ConsonaFileRow extends StatelessWidget {
  const ConsonaFileRow({
    super.key,
    required this.item,
    this.statusLabel,
    this.onTap,
    this.onDownload,
    this.onRemove,
  });

  final ConsonaMediaItem item;
  final String? statusLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final type = item.resolvedType;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap != null
          ? () {
              ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ConsonaSpacing.md,
          vertical: ConsonaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: theme.border.resolve(
            ConsonaBorderRole.divider,
            context: context,
          ),
        ),
        child: Row(
          children: [
            // Extension Pill with semantic icon
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                color: ConsonaFileCard._resolveBadgeColor(colors, type).withAlpha(22),
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                border: Border.all(
                  color: ConsonaFileCard._resolveBadgeColor(colors, type).withAlpha(60),
                  width: 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                ConsonaFileCard._fileIconFor(type),
                size: 16.0,
                color: ConsonaFileCard._resolveBadgeColor(colors, type),
              ),
            ),
            const SizedBox(width: ConsonaSpacing.md),

            // Name
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.copyWith(
                  color: colors.foreground,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Size / Status
            if (item.sizeLabel != null) ...[
              const SizedBox(width: ConsonaSpacing.sm),
              Text(
                item.sizeLabel!,
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontSize: 11.5,
                ),
              ),
            ],
            if (item.sizeLabel != null && statusLabel != null)
              Text(
                ' • ',
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontSize: 11.5,
                ),
              ),
            if (statusLabel != null) ...[
              if (item.sizeLabel == null)
                const SizedBox(width: ConsonaSpacing.sm),
              Text(
                statusLabel!,
                style: theme.typography.caption.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ],

            // Actions
            if (onDownload != null) ...[
              const SizedBox(width: ConsonaSpacing.xs),
              ConsonaIconButton(
                icon: const ConsonaThinDownloadIcon(size: 16.0),
                size: ConsonaOpticalSize.sqXs,
                semanticLabel: 'Download',
                onTap: onDownload,
              ),
            ],
            if (onRemove != null) ...[
              const SizedBox(width: ConsonaSpacing.xs),
              ConsonaIconButton(
                icon: const Icon(Icons.close_outlined, size: 16.0),
                size: ConsonaOpticalSize.sqXs,
                semanticLabel: 'Remove',
                onTap: onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
