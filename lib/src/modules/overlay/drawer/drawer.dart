/// Consona Drawer — Partial-height surface that opens from the **bottom**.
///
/// Route motion is slide-only (full off-screen). Barrier stays put.
library;

import 'package:flutter/material.dart' show Icons, Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

/// Partial-height bottom drawer with multi-snap detents and velocity dismiss.
class ConsonaDrawer extends StatefulWidget {
  const ConsonaDrawer({
    super.key,
    required this.child,
    this.snapPoints = const [0.38, 0.62, 0.92],
    this.initialSnapIndex = 1,
    this.showHandle = true,
    this.dismissible = true,
    this.onDismiss,
    this.header,
    this.scrollable = true,
    this.retainHeight = false,
  });

  final Widget child;
  final List<double> snapPoints;
  final int initialSnapIndex;
  final bool showHandle;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final Widget? header;
  final bool scrollable;

  /// When true, releasing a drag keeps the current height instead of snapping
  /// back to the nearest detent (still dismisses when flung / dragged low).
  final bool retainHeight;

  /// Presents a bottom drawer — barrier fixed, panel slides up.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    List<double> snapPoints = const [0.38, 0.62, 0.92],
    int initialSnapIndex = 1,
    bool showHandle = true,
    bool dismissible = true,
    Widget? header,
    bool scrollable = true,
    bool retainHeight = false,
  }) {
    return showConsonaOverlay<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: dismissible,
      transitionDuration: const Duration(milliseconds: 340),
      builder: (overlayContext, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: ConsonaCurves.subtleEase,
          reverseCurve: ConsonaCurves.easeOut,
        );

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: curved,
                builder: (context, _) {
                  return ConsonaOverlayBackdrop(
                    progress: curved.value,
                    onTap: dismissible
                        ? () => Navigator.of(overlayContext).maybePop()
                        : null,
                  );
                },
              ),
              consonaSlideTransition(
                animation: animation,
                edge: ConsonaOverlayEdge.bottom,
                child: ConsonaDrawer(
                  snapPoints: snapPoints,
                  initialSnapIndex: initialSnapIndex,
                  showHandle: showHandle,
                  dismissible: dismissible,
                  header: header,
                  scrollable: scrollable,
                  retainHeight: retainHeight,
                  onDismiss: () => Navigator.of(overlayContext).maybePop(),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  State<ConsonaDrawer> createState() => _ConsonaDrawerState();
}

class _ConsonaDrawerState extends State<ConsonaDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  late double _fraction;
  double _dragPixels = 0.0;

  @override
  void initState() {
    super.initState();
    final index =
        widget.initialSnapIndex.clamp(0, widget.snapPoints.length - 1);
    _fraction = widget.snapPoints[index].clamp(0.2, 0.96);
    _spring = AnimationController.unbounded(vsync: this, value: _fraction)
      ..addListener(() {
        setState(() {
          _fraction = _spring.value.clamp(0.0, 1.0);
          _dragPixels = 0.0;
        });
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _animateTo(double target, {double velocity = 0.0}) {
    final spring = ConsonaCurves.standardSpring(
      start: _fraction,
      end: target.clamp(0.0, 1.0),
      velocity: velocity / 1200.0,
      damping: 0.86,
      stiffness: 280.0,
    );
    _spring.animateWith(spring);
  }

  void _onDragUpdate(double delta, double total) {
    if (!widget.dismissible || total <= 0) return;
    setState(() {
      _dragPixels = (_dragPixels + delta).clamp(-total * 0.15, total);
    });
  }

  void _onDragEnd(double velocity, double total) {
    if (!widget.dismissible || total <= 0) return;
    final visual = (_fraction * total - _dragPixels).clamp(0.0, total);
    final next = visual / total;
    final minKeep = widget.snapPoints.first * 0.55;

    if (velocity > 900.0 || next < minKeep) {
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
      widget.onDismiss?.call();
      return;
    }

    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);

    // Keep the user-chosen height — do not retract to a snap detent.
    if (widget.retainHeight) {
      final kept = next.clamp(0.28, 0.96);
      _spring.stop();
      setState(() {
        _fraction = kept;
        _dragPixels = 0.0;
        _spring.value = kept;
      });
      return;
    }

    var closest = widget.snapPoints.first;
    var minDiff = (closest - next).abs();
    for (final snap in widget.snapPoints) {
      final diff = (snap - next).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = snap;
      }
    }

    _animateTo(closest, velocity: -velocity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.size.height;
        final availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.size.width;
        final maxDrawerW = theme.components.overlay.maxDrawerWidth;
        final width = availW > maxDrawerW ? maxDrawerW : availW;
        final visualFraction =
            ((_fraction * maxH) - _dragPixels).clamp(120.0, maxH) / maxH;
        final height =
            (maxH * visualFraction - keyboard).clamp(160.0, maxH);
        final radius = theme.radius.resolveRaw(ConsonaRadiusRole.macro);
        final borderRadius =
            BorderRadius.vertical(top: Radius.circular(radius));

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: GestureDetector(
              onVerticalDragUpdate: (d) =>
                  _onDragUpdate(d.primaryDelta ?? 0, maxH),
              onVerticalDragEnd: (d) =>
                  _onDragEnd(d.primaryVelocity ?? 0, maxH),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: borderRadius,
                  border: theme.border.resolve(ConsonaBorderRole.surfaceEdge),
                  boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showHandle)
                      const ConsonaDrawerHandle(
                        edge: ConsonaOverlayEdge.bottom,
                      ),
                    if (widget.header != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ConsonaSpacing.base,
                          ConsonaSpacing.xs,
                          ConsonaSpacing.base,
                          ConsonaSpacing.sm,
                        ),
                        child: widget.header!,
                      ),
                    Expanded(
                      child: ConsonaOverlayBody(
                        scrollable: widget.scrollable,
                        safeArea: true,
                        padding: const EdgeInsets.fromLTRB(
                          ConsonaSpacing.base,
                          0,
                          ConsonaSpacing.base,
                          ConsonaSpacing.base,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Convenience header used inside drawers.
class ConsonaDrawerHeader extends StatelessWidget {
  const ConsonaDrawerHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsonaOverlayText(
                title,
                maxLines: 2,
                style: theme.typography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                ConsonaOverlayText(
                  subtitle!,
                  maxLines: 2,
                  style: theme.typography.caption.copyWith(
                    color: theme.colors.mutedFg,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onClose != null)
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(ConsonaSpacing.xs),
              child: Icon(
                Icons.close_rounded,
                size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
                color: theme.colors.mutedFg,
              ),
            ),
          ),
      ],
    );
  }
}
