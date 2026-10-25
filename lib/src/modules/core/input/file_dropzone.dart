/// Consona FileDropzone — Responsive file drop target and upload progress list.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../badge/badge.dart';
import '../progress/progress.dart';

/// Represents a file item in [ConsonaFileDropzone].
@immutable
class ConsonaUploadItem {
  const ConsonaUploadItem({
    required this.name,
    this.sizeLabel,
    this.progress = 1.0,
    this.hasError = false,
  });

  final String name;
  final String? sizeLabel;

  /// Normalized upload progress in `0.0 .. 1.0`.
  final double progress;
  final bool hasError;
}

/// Responsive file dropzone and upload queue surface for desktop/web drag-or-click
/// and mobile tap-to-browse workflows.
class ConsonaFileDropzone extends StatefulWidget {
  const ConsonaFileDropzone({
    super.key,
    this.title = 'Drop files here or tap to browse',
    this.subtitle = 'Supports audio stems, presets, or JSON configs up to 50 MB',
    this.icon,
    this.files = const <ConsonaUploadItem>[],
    this.onBrowse,
    this.onRemoveFile,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? icon;
  final List<ConsonaUploadItem> files;
  final VoidCallback? onBrowse;
  final ValueChanged<int>? onRemoveFile;
  final bool enabled;

  @override
  State<ConsonaFileDropzone> createState() => _ConsonaFileDropzoneState();
}

class _ConsonaFileDropzoneState extends State<ConsonaFileDropzone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    final interactionState = !widget.enabled
        ? ConsonaInteractionState.disabled
        : _hovered
            ? ConsonaInteractionState.hovered
            : ConsonaInteractionState.idle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.title,
          child: MouseRegion(
            cursor: widget.enabled && widget.onBrowse != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled && widget.onBrowse != null
                  ? () {
                      unawaited(
                        ConsonaFeedbackScope.maybeOf(context)?.trigger(
                          FeedbackEvent.tap,
                        ),
                      );
                      widget.onBrowse!();
                    }
                  : null,
              child: AnimatedContainer(
                duration: theme.motion
                    .resolve(ConsonaMotionRole.press, context)
                    .duration,
                padding: EdgeInsets.all(ConsonaSpacing.xl * scale),
                decoration: BoxDecoration(
                  color: _hovered
                      ? colors.primary.withAlpha(18)
                      : colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                  border: theme.border.resolve(
                    ConsonaBorderRole.inputOutline,
                    state: interactionState,
                    context: context,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40 * scale,
                      height: 40 * scale,
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(28),
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.base),
                      ),
                      alignment: Alignment.center,
                      child: widget.icon != null
                          ? IconTheme(
                              data: IconThemeData(
                                size: 20 * scale,
                                color: colors.primary,
                              ),
                              child: widget.icon!,
                            )
                          : Text(
                              '↑',
                              style: theme.typography.titleMedium.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    SizedBox(height: ConsonaSpacing.sm * scale),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: theme.typography.label.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      SizedBox(height: ConsonaSpacing.xxs * scale),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.typography.caption.copyWith(
                          color: colors.mutedFg,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.files.isNotEmpty) ...[
          const SizedBox(height: ConsonaSpacing.sm),
          for (int i = 0; i < widget.files.length; i++) ...[
            if (i > 0) const SizedBox(height: ConsonaSpacing.xs),
            _buildFileRow(context, widget.files[i], i, scale),
          ],
        ],
      ],
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    ConsonaUploadItem item,
    int index,
    double scale,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final isDone = item.progress >= 1.0 && !item.hasError;

    return Container(
      padding: EdgeInsets.all(ConsonaSpacing.sm * scale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border: theme.border.resolve(
          item.hasError
              ? ConsonaBorderRole.error
              : ConsonaBorderRole.surfaceEdge,
          context: context,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              if (item.sizeLabel != null) ...[
                const SizedBox(width: ConsonaSpacing.xs),
                Text(
                  item.sizeLabel!,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                  ),
                ),
              ],
              const SizedBox(width: ConsonaSpacing.xs),
              ConsonaBadge(
                label: item.hasError
                    ? 'Error'
                    : isDone
                        ? 'Ready'
                        : '${(item.progress * 100).round()}%',
                intent: item.hasError
                    ? ConsonaIntent.danger
                    : isDone
                        ? ConsonaIntent.success
                        : ConsonaIntent.subtle,
              ),
              if (widget.onRemoveFile != null) ...[
                const SizedBox(width: ConsonaSpacing.xs),
                GestureDetector(
                  onTap: () => widget.onRemoveFile!(index),
                  child: Padding(
                    padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                    child: Text(
                      '✕',
                      style: theme.typography.caption.copyWith(
                        color: colors.mutedFg,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: ConsonaSpacing.xs),
            ConsonaProgress(
              value: item.progress,
              height: 5,
              color: item.hasError ? colors.danger : colors.primary,
            ),
          ],
        ],
      ),
    );
  }
}
