/// Consona Sheet — Full-screen surface that slides in from any edge.
///
/// Barrier stays put; only the sheet slides (no fade).
library;

import 'package:flutter/material.dart' show Icons, Material;
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

enum ConsonaSheetDirection {
  bottom,
  top,
  left,
  right,
}

extension on ConsonaSheetDirection {
  ConsonaOverlayEdge get overlayEdge => switch (this) {
        ConsonaSheetDirection.bottom => ConsonaOverlayEdge.bottom,
        ConsonaSheetDirection.top => ConsonaOverlayEdge.top,
        ConsonaSheetDirection.left => ConsonaOverlayEdge.left,
        ConsonaSheetDirection.right => ConsonaOverlayEdge.right,
      };

  bool get isVertical =>
      this == ConsonaSheetDirection.bottom ||
      this == ConsonaSheetDirection.top;
}

/// Full-screen edge sheet — covers the viewport, dismissible by drag or close.
class ConsonaSheet extends StatefulWidget {
  const ConsonaSheet({
    super.key,
    required this.child,
    this.direction = ConsonaSheetDirection.bottom,
    this.dismissible = true,
    this.showClose = true,
    this.title,
    this.onDismiss,
    this.scrollable = true,
  });

  final Widget child;
  final ConsonaSheetDirection direction;
  final bool dismissible;
  final bool showClose;
  final String? title;
  final VoidCallback? onDismiss;
  final bool scrollable;

  /// Opens a full-screen sheet — barrier fixed, panel slides from [direction].
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    ConsonaSheetDirection direction = ConsonaSheetDirection.bottom,
    bool dismissible = true,
    bool showClose = true,
    String? title,
    bool scrollable = true,
  }) {
    return showConsonaOverlay<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      transitionDuration: const Duration(milliseconds: 360),
      builder: (overlayContext, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: ConsonaCurves.subtleEase,
          reverseCurve: ConsonaCurves.easeOut,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                return ConsonaOverlayBackdrop(
                  progress: curved.value,
                  blurSigma: 18.0,
                  tintOpacity: 0.38,
                  onTap: dismissible
                      ? () => Navigator.of(overlayContext).maybePop()
                      : null,
                );
              },
            ),
            consonaSlideTransition(
              animation: animation,
              edge: direction.overlayEdge,
              child: ConsonaSheet(
                direction: direction,
                dismissible: dismissible,
                showClose: showClose,
                title: title,
                scrollable: scrollable,
                onDismiss: () => Navigator.of(overlayContext).maybePop(),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  State<ConsonaSheet> createState() => _ConsonaSheetState();
}

class _ConsonaSheetState extends State<ConsonaSheet> {
  double _drag = 0.0;

  void _onDragUpdate(double delta) {
    if (!widget.dismissible) return;
    final signed = switch (widget.direction) {
      ConsonaSheetDirection.bottom => delta,
      ConsonaSheetDirection.top => -delta,
      ConsonaSheetDirection.right => delta,
      ConsonaSheetDirection.left => -delta,
    };
    setState(() => _drag = (_drag + signed).clamp(0.0, 420.0));
  }

  void _onDragEnd(double velocity, Size size) {
    if (!widget.dismissible) return;
    final signed = switch (widget.direction) {
      ConsonaSheetDirection.bottom => velocity,
      ConsonaSheetDirection.top => -velocity,
      ConsonaSheetDirection.right => velocity,
      ConsonaSheetDirection.left => -velocity,
    };
    final threshold =
        widget.direction.isVertical ? size.height * 0.22 : size.width * 0.22;
    if (signed > 850.0 || _drag > threshold) {
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
      widget.onDismiss?.call();
      return;
    }
    setState(() => _drag = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final size = MediaQuery.sizeOf(context);
    final isVertical = widget.direction.isVertical;
    final maxSideW = theme.components.overlay.maxSideSheetWidth;
    final panelWidth = !isVertical && size.width > maxSideW
        ? maxSideW
        : size.width;

    final dragFrac = isVertical
        ? _drag / size.height
        : _drag / panelWidth;
    final dragOffset = switch (widget.direction) {
      ConsonaSheetDirection.bottom => Offset(0, dragFrac),
      ConsonaSheetDirection.top => Offset(0, -dragFrac),
      ConsonaSheetDirection.left => Offset(-dragFrac, 0),
      ConsonaSheetDirection.right => Offset(dragFrac, 0),
    };

    final alignment = switch (widget.direction) {
      ConsonaSheetDirection.left => Alignment.centerLeft,
      ConsonaSheetDirection.right => Alignment.centerRight,
      ConsonaSheetDirection.top => Alignment.topCenter,
      ConsonaSheetDirection.bottom => Alignment.bottomCenter,
    };

    // Panel only — barrier owned by [ConsonaSheet.show].
    // Material is required so Text/Icon never get debug yellow underlines.
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          dragOffset.dx * panelWidth,
          dragOffset.dy * size.height,
        ),
        child: GestureDetector(
          onVerticalDragUpdate: isVertical
              ? (d) => _onDragUpdate(d.primaryDelta ?? 0)
              : null,
          onVerticalDragEnd: isVertical
              ? (d) => _onDragEnd(d.primaryVelocity ?? 0, size)
              : null,
          onHorizontalDragUpdate: !isVertical
              ? (d) => _onDragUpdate(d.primaryDelta ?? 0)
              : null,
          onHorizontalDragEnd: !isVertical
              ? (d) => _onDragEnd(d.primaryVelocity ?? 0, size)
              : null,
          child: Material(
            color: colors.background,
            child: SizedBox(
              width: panelWidth,
              height: size.height,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetChrome(
                      title: widget.title,
                      showClose: widget.showClose,
                      onClose: widget.onDismiss,
                    ),
                    Expanded(
                      child: ClipRect(
                        child: ConsonaOverlayBody(
                          scrollable: widget.scrollable,
                          safeArea: false,
                          padding: const EdgeInsets.fromLTRB(
                            ConsonaSpacing.base,
                            ConsonaSpacing.sm,
                            ConsonaSpacing.base,
                            ConsonaSpacing.base,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({
    this.title,
    required this.showClose,
    this.onClose,
  });

  final String? title;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    if (title == null && !showClose) {
      return const SizedBox(height: ConsonaSpacing.sm);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ConsonaSpacing.base,
        ConsonaSpacing.sm,
        ConsonaSpacing.sm,
        ConsonaSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : ConsonaOverlayText(
                    title!,
                    maxLines: 1,
                    style: theme.typography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colors.foreground,
                    ),
                  ),
          ),
          if (showClose && onClose != null)
            GestureDetector(
              onTap: () {
                ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.tap);
                onClose!();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colors.surfaceSecondary,
                  shape: BoxShape.circle,
                  border: theme.border.resolve(ConsonaBorderRole.subtle),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
                  color: theme.colors.foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
