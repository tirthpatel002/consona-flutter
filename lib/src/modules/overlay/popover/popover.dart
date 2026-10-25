/// Consona Popover — Anchored popover card that opens next to its trigger.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

/// Rich interactive popover that opens beside the trigger on every viewport.
class ConsonaPopover extends StatefulWidget {
  const ConsonaPopover({
    super.key,
    required this.child,
    required this.popoverBuilder,
    this.width = 280.0,
    this.title,
  });

  final Widget child;
  final WidgetBuilder popoverBuilder;
  final double width;
  final String? title;

  /// Presents a popover anchored to [anchorRect]. Without a rect, the card
  /// is centered. The route supplies Material and a text style so debug
  /// builds do not paint the fallback yellow double underline.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    Rect? anchorRect,
    double width = 300.0,
    String? title,
  }) {
    final theme = ConsonaTheme.of(context);
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap),
    );

    return showConsonaOverlay<T>(
      context: context,
      barrierDismissible: true,
      transitionDuration: consonaOverlayMotionDuration(motion.duration),
      builder: (routeContext, animation) {
        return _ConsonaPopoverRouteContent(
          anchorRect: anchorRect,
          width: width,
          title: title,
          animation: animation,
          builder: builder,
        );
      },
    );
  }

  @override
  State<ConsonaPopover> createState() => _ConsonaPopoverState();
}

class _ConsonaPopoverState extends State<ConsonaPopover> {
  final GlobalKey _triggerKey = GlobalKey();

  void _open() {
    final renderObject = _triggerKey.currentContext?.findRenderObject();
    Rect? rect;
    if (renderObject is RenderBox && renderObject.hasSize) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      rect = topLeft & renderObject.size;
    }
    unawaited(
      ConsonaPopover.show<void>(
        context,
        anchorRect: rect,
        width: widget.width,
        title: widget.title,
        builder: widget.popoverBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: widget.child,
    );
  }
}

class _ConsonaPopoverRouteContent extends StatelessWidget {
  const _ConsonaPopoverRouteContent({
    required this.anchorRect,
    required this.width,
    required this.title,
    required this.animation,
    required this.builder,
  });

  final Rect? anchorRect;
  final double width;
  final String? title;
  final Animation<double> animation;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final safe = EdgeInsets.fromLTRB(
      math.max(padding.left, 12),
      math.max(padding.top, 12),
      math.max(padding.right, 12),
      math.max(math.max(padding.bottom, insets.bottom), 12),
    );
    final availableWidth = math.max(0.0, screen.width - safe.left - safe.right);
    final panelWidth = math.min(width, availableWidth);
    final opensAbove = anchorRect != null &&
        anchorRect!.bottom + 160.0 > screen.height - safe.bottom;

    final cardContent = Container(
      width: panelWidth,
      constraints: BoxConstraints(
        maxWidth: panelWidth,
        maxHeight: math.max(0.0, screen.height - safe.top - safe.bottom),
      ),
      padding: const EdgeInsets.all(ConsonaSpacing.base),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
        border: theme.border.resolve(
          ConsonaBorderRole.surfaceEdge,
          context: context,
        ),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title!,
                    style: theme.typography.label.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Text(
                    '✕',
                    style: theme.typography.caption.copyWith(
                      color: colors.mutedFg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ConsonaSpacing.sm),
          ],
          Flexible(child: builder(context)),
        ],
      ),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).maybePop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: animation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: ColoredBox(color: colors.foreground.withAlpha(60)),
            ),
          ),
          if (anchorRect == null)
            Center(
              child: Padding(
                padding: safe,
                child: ConsonaSurfaceReveal(
                  animation: animation,
                  alignment: Alignment.center,
                  beginScale: 0.92,
                  beginOffset: const Offset(0, 0.06),
                  child: cardContent,
                ),
              ),
            )
          else
            _PopoverPositioner(
              anchor: anchorRect!,
              maxWidth: panelWidth,
              safe: safe,
              child: ConsonaSurfaceReveal(
                animation: animation,
                alignment: opensAbove ? Alignment.bottomLeft : Alignment.topLeft,
                beginScale: 0.88,
                beginOffset: Offset(0, opensAbove ? 0.08 : -0.08),
                child: cardContent,
              ),
            ),
        ],
      ),
    );
  }
}

/// Places [child] just under [anchor], flipping above when the card would
/// leave the safe rect. Empty space does not absorb taps.
class _PopoverPositioner extends SingleChildRenderObjectWidget {
  const _PopoverPositioner({
    required this.anchor,
    required this.maxWidth,
    required this.safe,
    required super.child,
  });

  final Rect anchor;
  final double maxWidth;
  final EdgeInsets safe;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPopoverPositioner(
      anchor: anchor,
      maxWidth: maxWidth,
      safe: safe,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPopoverPositioner renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..maxWidth = maxWidth
      ..safe = safe;
  }
}

class _RenderPopoverPositioner extends RenderShiftedBox {
  _RenderPopoverPositioner({
    required Rect anchor,
    required double maxWidth,
    required EdgeInsets safe,
  })  : _anchor = anchor,
        _maxWidth = maxWidth,
        _safe = safe,
        super(null);

  Rect _anchor;
  double _maxWidth;
  EdgeInsets _safe;

  set anchor(Rect value) {
    if (_anchor == value) return;
    _anchor = value;
    markNeedsLayout();
  }

  set maxWidth(double value) {
    if (_maxWidth == value) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  set safe(EdgeInsets value) {
    if (_safe == value) return;
    _safe = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    size = constraints.biggest;
    if (child == null) return;

    const gap = 8.0;
    final minX = _safe.left;
    final minY = _safe.top;
    final maxX = math.max(minX, size.width - _safe.right);
    final maxY = math.max(minY, size.height - _safe.bottom);
    final maxChildWidth = math.max(0.0, math.min(_maxWidth, maxX - minX));
    final maxChildHeight = math.max(0.0, maxY - minY);

    child.layout(
      BoxConstraints(maxWidth: maxChildWidth, maxHeight: maxChildHeight),
      parentUsesSize: true,
    );

    final maxDx = math.max(minX, maxX - child.size.width);
    final dx = _anchor.left.clamp(minX, maxDx).toDouble();

    var dy = _anchor.bottom + gap;
    final belowFits = dy + child.size.height <= maxY;
    if (!belowFits) {
      final above = _anchor.top - gap - child.size.height;
      dy = above >= minY ? above : minY;
    }
    dy = dy.clamp(minY, math.max(minY, maxY - child.size.height)).toDouble();

    (child.parentData! as BoxParentData).offset = Offset(dx, dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final childParentData = child.parentData! as BoxParentData;
    final childPosition = position - childParentData.offset;
    return child.hitTest(result, position: childPosition);
  }
}
