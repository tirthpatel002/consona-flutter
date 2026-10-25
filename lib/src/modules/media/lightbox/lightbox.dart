/// Consona Lightbox — Full-screen immersive media viewer with zoom, swipe, and filmstrip gallery.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/icon_button.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/common/overlay_host.dart';
import '../../overlay/popover/popover.dart';
import '../image/smart_image.dart';
import '../models/media_item.dart';
import '../shared/thin_icons.dart';
import '../video/video_player.dart';

/// Builds overflow-menu content for the lightbox more button.
///
/// Called with the overlay [BuildContext] and the currently focused item so
/// hosts can render item-specific actions (share, delete, open in app, …).
typedef ConsonaLightboxMoreMenuBuilder = Widget Function(
  BuildContext context,
  ConsonaMediaItem item,
);

/// Full-screen media viewer modal featuring pinch-to-zoom, pan, desktop arrow navigation,
/// and an interactive bottom thumbnail filmstrip gallery.
class ConsonaLightbox extends StatefulWidget {
  const ConsonaLightbox({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onDownload,
    this.moreMenuBuilder,
    this.moreMenuTitle = 'Actions',
    this.moreMenuWidth = 260.0,
    this.onClose,
  });

  /// List of media items to display in the viewer.
  final List<ConsonaMediaItem> items;

  /// Initially active item index.
  final int initialIndex;

  /// Optional callback invoked when the download action is triggered.
  final void Function(ConsonaMediaItem item)? onDownload;

  /// When non-null, shows a toolbar more button that opens a [ConsonaPopover]
  /// filled by this builder. Downstream apps own the menu children.
  final ConsonaLightboxMoreMenuBuilder? moreMenuBuilder;

  /// Title shown at the top of the more-menu popover.
  final String? moreMenuTitle;

  /// Width of the more-menu popover card.
  final double moreMenuWidth;

  /// Optional close callback. If omitted, [Navigator.of(context).pop()] is called.
  final VoidCallback? onClose;

  /// Presents the [ConsonaLightbox] full-screen overlay.
  static Future<void> show(
    BuildContext context, {
    required List<ConsonaMediaItem> items,
    int initialIndex = 0,
    void Function(ConsonaMediaItem item)? onDownload,
    ConsonaLightboxMoreMenuBuilder? moreMenuBuilder,
    String? moreMenuTitle = 'Actions',
    double moreMenuWidth = 260.0,
  }) {
    if (items.isEmpty) return Future.value();
    return showConsonaOverlay<void>(
      context: context,
      barrierDismissible: true,
      builder: (overlayContext, animation) {
        return ConsonaLightbox(
          items: items,
          initialIndex: initialIndex,
          onDownload: onDownload,
          moreMenuBuilder: moreMenuBuilder,
          moreMenuTitle: moreMenuTitle,
          moreMenuWidth: moreMenuWidth,
          onClose: () => Navigator.of(overlayContext).pop(),
        );
      },
    );
  }

  @override
  State<ConsonaLightbox> createState() => _ConsonaLightboxState();
}

class _ConsonaLightboxState extends State<ConsonaLightbox> {
  late int _currentIndex;
  late final PageController _pageController;
  final TransformationController _transformController =
      TransformationController();
  final ScrollController _filmstripController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _moreButtonKey = GlobalKey();

  /// Quarter-turns clockwise applied to the active still image (0–3).
  int _rotationQuarterTurns = 0;

  static const ConsonaRadiusRole _filmstripRadiusRole = ConsonaRadiusRole.micro;
  static const double _filmstripThumbSize = 56.0;
  static const double _toolbarIconSize = 20.0;
  static const double _navChevronSize = 26.0;
  static const double _navHitSize = 36.0;
  static const double _selectedTickSize = 22.0;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex.clamp(0, math.max(0, widget.items.length - 1));
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scrollFilmstripToCurrent();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    _filmstripController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int nextIndex) {
    if (widget.items.isEmpty) return;
    final target = nextIndex.clamp(0, widget.items.length - 1);
    if (target == _currentIndex) return;

    // Adjacent steps keep a short page slide; non-adjacent filmstrip / jumps
    // skip intermediates so the stage doesn't scrub through every item.
    final isAdjacent = (target - _currentIndex).abs() == 1;
    if (!isAdjacent) {
      _pageController.jumpToPage(target);
      return;
    }

    final motion = ConsonaTheme.of(context)
        .motion
        .resolve(ConsonaMotionRole.reveal, context);
    _pageController.animateToPage(
      target,
      duration: motion.duration == Duration.zero
          ? const Duration(milliseconds: 220)
          : motion.duration,
      curve: motion.curve,
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _rotationQuarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    _scrollFilmstripToCurrent();
  }

  void _scrollFilmstripToCurrent() {
    if (!_filmstripController.hasClients || widget.items.length <= 1) return;
    const itemWidth = _filmstripThumbSize;
    const spacing = ConsonaSpacing.xs;
    final targetOffset = (_currentIndex * (itemWidth + spacing)) - 100.0;
    final motion = ConsonaTheme.of(context)
        .motion
        .resolve(ConsonaMotionRole.reveal, context);
    _filmstripController.animateTo(
      targetOffset.clamp(0.0, _filmstripController.position.maxScrollExtent),
      duration: motion.duration,
      curve: motion.curve,
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_currentIndex - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_currentIndex + 1);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose?.call();
    }
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      // Keep zoom/pan coherent with the new orientation.
      _transformController.value = Matrix4.identity();
    });
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
  }

  Future<void> _openMoreMenu(ConsonaMediaItem item) async {
    final builder = widget.moreMenuBuilder;
    if (builder == null) return;

    final renderObject = _moreButtonKey.currentContext?.findRenderObject();
    Rect? anchorRect;
    if (renderObject is RenderBox && renderObject.hasSize) {
      final origin = renderObject.localToGlobal(Offset.zero);
      anchorRect = origin & renderObject.size;
    }

    await ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
    if (!mounted) return;
    await ConsonaPopover.show<void>(
      context,
      anchorRect: anchorRect,
      width: widget.moreMenuWidth,
      title: widget.moreMenuTitle,
      builder: (popoverContext) => builder(popoverContext, item),
    );
  }

  bool get _isZoomed {
    final scale = _transformController.value.getMaxScaleOnAxis();
    return scale > 1.02;
  }

  Widget _buildStagePage(ConsonaMediaItem item, {required int index}) {
    final isActive = index == _currentIndex;
    if (item.isVideo) {
      final uri = item.uri?.trim();
      if (uri == null || uri.isEmpty) {
        return const Center(child: Text('No video source'));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ConsonaVideoPlayer(
              uri: uri,
              posterUri: item.thumbnailUri,
              active: isActive,
              borderRadiusRole: ConsonaRadiusRole.micro,
            ),
          ),
        ),
      );
    }

    final turns = isActive ? _rotationQuarterTurns : 0;
    return InteractiveViewer(
      transformationController: isActive ? _transformController : null,
      minScale: 0.8,
      maxScale: 4.0,
      child: Center(
        child: RotatedBox(
          quarterTurns: turns,
          child: ConsonaImage(
            uri: item.uri,
            bytes: item.bytes,
            fit: BoxFit.contain,
            zoomOnHover: false,
            radiusRole: null,
            borderRole: null,
          ),
        ),
      ),
    );
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
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Container(
        color: colors.background.withAlpha(240),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopToolbar(theme, colors, currentItem),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListenableBuilder(
                      listenable: _transformController,
                      builder: (context, _) {
                        final allowSwipe = hasMultiple && !_isZoomed;
                        return PageView.builder(
                          controller: _pageController,
                          itemCount: widget.items.length,
                          physics: allowSwipe
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            return _buildStagePage(
                              widget.items[index],
                              index: index,
                            );
                          },
                        );
                      },
                    ),
                    if (hasMultiple && _currentIndex > 0)
                      Positioned(
                        left: ConsonaSpacing.md,
                        child: _buildNavArrow(
                          colors: colors,
                          direction: _NavChevronDirection.left,
                          semanticLabel: 'Previous',
                          onTap: () => _goTo(_currentIndex - 1),
                        ),
                      ),
                    if (hasMultiple &&
                        _currentIndex < widget.items.length - 1)
                      Positioned(
                        right: ConsonaSpacing.md,
                        child: _buildNavArrow(
                          colors: colors,
                          direction: _NavChevronDirection.right,
                          semanticLabel: 'Next',
                          onTap: () => _goTo(_currentIndex + 1),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasMultiple) _buildBottomFilmstrip(theme, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar(
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
        color: colors.surface.withAlpha(200),
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentItem.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.titleMedium.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (currentItem.caption != null)
                  Text(
                    currentItem.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption.copyWith(
                      color: colors.mutedFg,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.items.length > 1)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: ConsonaSpacing.sm,
                vertical: ConsonaSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
              ),
              child: Text(
                '${_currentIndex + 1} of ${widget.items.length}',
                style: theme.typography.caption.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!currentItem.isVideo) ...[
            ConsonaIconButton(
              icon: const Icon(
                Icons.rotate_90_degrees_cw_outlined,
                size: _toolbarIconSize,
              ),
              size: ConsonaOpticalSize.sqSm,
              semanticLabel: 'Rotate',
              onTap: _rotateClockwise,
            ),
            const SizedBox(width: ConsonaSpacing.xs),
          ],
          if (widget.onDownload != null) ...[
            ConsonaIconButton(
              icon: const ConsonaThinDownloadIcon(size: _toolbarIconSize),
              size: ConsonaOpticalSize.sqSm,
              semanticLabel: 'Download',
              onTap: () => widget.onDownload!(currentItem),
            ),
            const SizedBox(width: ConsonaSpacing.xs),
          ],
          if (widget.moreMenuBuilder != null) ...[
            KeyedSubtree(
              key: _moreButtonKey,
              child: ConsonaIconButton(
                icon: const Icon(
                  Icons.more_horiz_outlined,
                  size: _toolbarIconSize,
                ),
                size: ConsonaOpticalSize.sqSm,
                semanticLabel: 'More actions',
                onTap: () => _openMoreMenu(currentItem),
              ),
            ),
            const SizedBox(width: ConsonaSpacing.xs),
          ],
          ConsonaIconButton(
            icon: const Icon(
              Icons.close_outlined,
              size: _toolbarIconSize,
            ),
            size: ConsonaOpticalSize.sqSm,
            semanticLabel: 'Close (Esc)',
            onTap: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow({
    required ConsonaColors colors,
    required _NavChevronDirection direction,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: _navHitSize,
          height: _navHitSize,
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(200),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.foreground.withAlpha(28),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size.square(_navChevronSize),
            painter: _ThinChevronPainter(
              color: colors.foreground,
              direction: direction,
              strokeWidth: 1.35,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFilmstrip(
    ConsonaThemeData theme,
    ConsonaColors colors,
  ) {
    final thumbRadius = theme.radius.resolve(_filmstripRadiusRole);

    return Container(
      height: 72.0,
      padding: const EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.md,
        vertical: ConsonaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(210),
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
            child: AnimatedOpacity(
              duration: thumbMotion.duration,
              curve: thumbMotion.curve,
              opacity: isSelected ? 1.0 : 0.62,
              child: Container(
                width: _filmstripThumbSize,
                height: _filmstripThumbSize,
                decoration: BoxDecoration(
                  borderRadius: thumbRadius,
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
                      uri: item.thumbnailUri ??
                          (item.isVideo ? null : item.uri),
                      bytes: item.isVideo ? null : item.bytes,
                      fit: BoxFit.cover,
                      zoomOnHover: false,
                      radiusRole: null,
                      borderRole: null,
                    ),
                    if (item.isVideo)
                      Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colors.surface.withAlpha(200),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_arrow_outlined,
                            size: 14,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    if (isSelected)
                      Center(
                        child: Container(
                          width: _selectedTickSize,
                          height: _selectedTickSize,
                          decoration: BoxDecoration(
                            color: colors.surface.withAlpha(230),
                            shape: BoxShape.circle,
                            border: theme.border.resolve(
                              ConsonaBorderRole.subtle,
                              context: context,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check_outlined,
                            size: 14.0,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _NavChevronDirection { left, right }

/// Hairline chevron — Material glyphs stay too heavy at nav scale.
class _ThinChevronPainter extends CustomPainter {
  const _ThinChevronPainter({
    required this.color,
    required this.direction,
    required this.strokeWidth,
  });

  final Color color;
  final _NavChevronDirection direction;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final insetX = size.width * 0.32;
    final insetY = size.height * 0.22;
    final midY = size.height * 0.5;
    final tipX = direction == _NavChevronDirection.left
        ? insetX
        : size.width - insetX;
    final wingX = direction == _NavChevronDirection.left
        ? size.width - insetX
        : insetX;

    final path = Path()
      ..moveTo(wingX, insetY)
      ..lineTo(tipX, midY)
      ..lineTo(wingX, size.height - insetY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ThinChevronPainter oldDelegate) =>
      color != oldDelegate.color ||
      direction != oldDelegate.direction ||
      strokeWidth != oldDelegate.strokeWidth;
}
