/// Consona File Viewer Modal — Multi-format file & document inspection modal with filmstrip gallery.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons, SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../core/button/icon_button.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/common/overlay_host.dart';
import '../image/smart_image.dart';
import '../models/media_item.dart';
import '../shared/thin_icons.dart';
import '../video/video_player.dart';

/// Universal multi-format file & document viewer modal. Auto-detects and displays
/// interactive zoomable images, syntax/log text, audio players, or document inspection cards.
class ConsonaFileViewerModal extends StatefulWidget {
  const ConsonaFileViewerModal({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.contentBuilder,
    this.onDownload,
    this.onClose,
  });

  /// List of files to inspect.
  final List<ConsonaMediaItem> items;

  /// Active file index.
  final int initialIndex;

  /// Optional custom builder for specialty file renderers (e.g. PDF viewer package).
  final Widget Function(BuildContext context, ConsonaMediaItem item)?
      contentBuilder;

  /// Optional callback invoked when download action is tapped.
  final void Function(ConsonaMediaItem item)? onDownload;

  /// Close callback.
  final VoidCallback? onClose;

  /// Presents the [ConsonaFileViewerModal] dialog/sheet.
  static Future<void> show(
    BuildContext context, {
    ConsonaMediaItem? item,
    List<ConsonaMediaItem>? items,
    int initialIndex = 0,
    Widget Function(BuildContext context, ConsonaMediaItem item)? contentBuilder,
    void Function(ConsonaMediaItem item)? onDownload,
  }) {
    final list = items ?? (item != null ? [item] : const <ConsonaMediaItem>[]);
    if (list.isEmpty) return Future.value();

    return showConsonaOverlay<void>(
      context: context,
      barrierDismissible: true,
      builder: (overlayContext, animation) {
        return ConsonaFileViewerModal(
          items: list,
          initialIndex: initialIndex,
          contentBuilder: contentBuilder,
          onDownload: onDownload,
          onClose: () => Navigator.of(overlayContext).pop(),
        );
      },
    );
  }

  @override
  State<ConsonaFileViewerModal> createState() => _ConsonaFileViewerModalState();
}

class _ConsonaFileViewerModalState extends State<ConsonaFileViewerModal> {
  late int _currentIndex;
  final ScrollController _filmstripController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, math.max(0, widget.items.length - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scrollFilmstripToCurrent();
    });
  }

  @override
  void dispose() {
    _filmstripController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int nextIndex) {
    if (widget.items.isEmpty) return;
    final target = nextIndex.clamp(0, widget.items.length - 1);
    if (target != _currentIndex) {
      setState(() {
        _currentIndex = target;
        _copied = false;
      });
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
      _scrollFilmstripToCurrent();
    }
  }

  void _scrollFilmstripToCurrent() {
    if (!_filmstripController.hasClients || widget.items.length <= 1) return;
    const itemWidth = 60.0;
    const spacing = ConsonaSpacing.xs;
    final targetOffset = (_currentIndex * (itemWidth + spacing)) - 120.0;
    final motion =
        ConsonaTheme.of(context).motion.resolve(ConsonaMotionRole.reveal, context);
    _filmstripController.animateTo(
      targetOffset.clamp(0.0, _filmstripController.position.maxScrollExtent),
      duration: motion.duration,
      curve: motion.curve,
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentItem = widget.items[_currentIndex];
    final hasMultiple = widget.items.length > 1;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _goTo(_currentIndex - 1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _goTo(_currentIndex + 1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 720.0,
            maxHeight: 680.0,
          ),
          margin: const EdgeInsets.all(ConsonaSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
            border: theme.border.resolve(
              ConsonaBorderRole.subtle,
              context: context,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.foreground.withAlpha(35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Header Toolbar
              _buildHeader(theme, colors, currentItem),

              // 2. Active Preview Body
              Expanded(
                child: _buildPreviewBody(theme, colors, currentItem),
              ),

              // 3. Bottom Filmstrip Gallery (when multiple items)
              if (hasMultiple)
                _buildBottomFilmstrip(theme, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ConsonaThemeData theme,
    ConsonaColors colors,
    ConsonaMediaItem currentItem,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.md,
        vertical: ConsonaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: Row(
        children: [
          // Extension badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.xs,
              vertical: ConsonaSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
              border: theme.border.resolve(
                ConsonaBorderRole.subtle,
                context: context,
              ),
            ),
            child: Text(
              currentItem.resolvedType.badgeLabel,
              style: theme.typography.caption.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10.0,
                color: colors.foreground,
              ),
            ),
          ),
          const SizedBox(width: ConsonaSpacing.sm),

          // File name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentItem.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.label.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (currentItem.sizeLabel != null)
                  Text(
                    currentItem.sizeLabel!,
                    style: theme.typography.caption.copyWith(
                      color: colors.mutedFg,
                    ),
                  ),
              ],
            ),
          ),

          // Multiple Items Count
          if (widget.items.length > 1) ...[
            Text(
              '${_currentIndex + 1} of ${widget.items.length}',
              style: theme.typography.caption.copyWith(
                color: colors.mutedFg,
              ),
            ),
            const SizedBox(width: ConsonaSpacing.sm),
          ],

          // Download action
          if (widget.onDownload != null) ...[
            ConsonaIconButton(
              icon: const ConsonaThinDownloadIcon(size: 20.0),
              size: ConsonaOpticalSize.sqXs,
              semanticLabel: 'Download',
              onTap: () => widget.onDownload!(currentItem),
            ),
            const SizedBox(width: ConsonaSpacing.xs),
          ],

          // Close button
          ConsonaIconButton(
            icon: const Icon(Icons.close_outlined, size: 20.0),
            size: ConsonaOpticalSize.sqXs,
            semanticLabel: 'Close (Esc)',
            onTap: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody(
    ConsonaThemeData theme,
    ConsonaColors colors,
    ConsonaMediaItem item,
  ) {
    // 1. Custom app content builder slot
    if (widget.contentBuilder != null) {
      final custom = widget.contentBuilder!(context, item);
      if (custom is! SizedBox) return custom;
    }

    final type = item.resolvedType;

    // 2. Image View
    if (type == ConsonaMediaType.image) {
      return Container(
        color: colors.surfaceSecondary.withAlpha(120),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.5,
          child: Center(
            child: ConsonaImage(
              uri: item.uri,
              bytes: item.bytes,
              fit: BoxFit.contain,
              zoomOnHover: false,
            ),
          ),
        ),
      );
    }

    // 3. Video View
    if (type == ConsonaMediaType.video) {
      final uri = item.uri?.trim();
      if (uri == null || uri.isEmpty) {
        return Center(
          child: Text(
            'No video source',
            style: theme.typography.caption.copyWith(color: colors.mutedFg),
          ),
        );
      }
      return Container(
        color: colors.surfaceSecondary.withAlpha(120),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(ConsonaSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ConsonaVideoPlayer(
            uri: uri,
            posterUri: item.thumbnailUri,
            title: item.caption,
            borderRadiusRole: ConsonaRadiusRole.micro,
          ),
        ),
      );
    }

    // 4. Text / Code / Log View
    if (item.hasTextContent) {
      return _buildTextPreview(theme, colors, item.textContent ?? '');
    }

    // 5. Audio View
    if (type == ConsonaMediaType.audio) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                  border: theme.border.resolve(
                    ConsonaBorderRole.subtle,
                    context: context,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'AUD',
                  style: theme.typography.label.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.md),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.titleMedium.copyWith(
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: ConsonaSpacing.xs),
              Text(
                item.sizeLabel ?? 'Audio recording',
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                ),
              ),
              if (widget.onDownload != null) ...[
                const SizedBox(height: ConsonaSpacing.md),
                ConsonaButton.primary(
                  label: 'Download Audio',
                  size: ConsonaOpticalSize.sm,
                  onTap: () => widget.onDownload!(item),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 5. Binary / Document Inspection Card Fallback (Rule C8)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ConsonaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                shape: BoxShape.circle,
                border: theme.border.resolve(
                  ConsonaBorderRole.subtle,
                  context: context,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                item.resolvedType.badgeLabel,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            const SizedBox(height: ConsonaSpacing.md),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.typography.titleMedium.copyWith(
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: ConsonaSpacing.xs),
            Text(
              '${item.sizeLabel ?? 'Document'} • ${item.fileExtension.toUpperCase()}',
              style: theme.typography.caption.copyWith(
                color: colors.mutedFg,
              ),
            ),
            const SizedBox(height: ConsonaSpacing.lg),
            ConsonaButton.primary(
              label: 'Download Document',
              size: ConsonaOpticalSize.sm,
              onTap: widget.onDownload != null
                  ? () => widget.onDownload!(item)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview(
    ConsonaThemeData theme,
    ConsonaColors colors,
    String rawText,
  ) {
    // Memory protection: clamp displayed characters to prevent freezing UI thread
    const maxChars = 30000;
    final isTruncated = rawText.length > maxChars;
    final displayText = isTruncated ? rawText.substring(0, maxChars) : rawText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTruncated)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.md,
              vertical: ConsonaSpacing.xs,
            ),
            color: colors.warning.withAlpha(25),
            child: Text(
              'Preview truncated for performance. Download file to inspect full contents.',
              style: theme.typography.caption.copyWith(
                color: colors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ConsonaSpacing.md,
            vertical: ConsonaSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            border: theme.border.resolve(
              ConsonaBorderRole.divider,
              context: context,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${displayText.split('\n').length} lines',
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                ),
              ),
              ConsonaButton.subtle(
                label: _copied ? 'Copied!' : 'Copy Content',
                size: ConsonaOpticalSize.xs,
                onTap: () => _copyText(rawText),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ConsonaSpacing.md),
            child: SelectableText(
              displayText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.0,
                color: colors.foreground,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomFilmstrip(
    ConsonaThemeData theme,
    ConsonaColors colors,
  ) {
    return Container(
      height: 64.0,
      padding: const EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.md,
        vertical: ConsonaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: ListView.separated(
        controller: _filmstripController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: ConsonaSpacing.xs),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = index == _currentIndex;

          final thumbMotion =
              theme.motion.resolve(ConsonaMotionRole.press, context);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goTo(index),
            child: AnimatedContainer(
              duration: thumbMotion.duration,
              curve: thumbMotion.curve,
              width: 52.0,
              height: 52.0,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                border: theme.border.resolve(
                  isSelected
                      ? ConsonaBorderRole.focus
                      : ConsonaBorderRole.subtle,
                  context: context,
                ),
              ),
              alignment: Alignment.center,
              child: item.isImage && item.uri != null
                  ? ClipRRect(
                      borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                      child: ConsonaImage(
                        uri: item.thumbnailUri ?? item.uri,
                        fit: BoxFit.cover,
                        zoomOnHover: false,
                      ),
                    )
                  : Text(
                      item.resolvedType.badgeLabel,
                      style: theme.typography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                        color: isSelected ? colors.primary : colors.mutedFg,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
