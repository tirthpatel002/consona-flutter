/// Consona SwipeDismiss — Velocity-sensitive spring swipe dismisser.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Wraps [child] so horizontal or vertical swipes beyond [dismissThreshold]
/// or with sufficient fling velocity animate out and invoke [onDismissed].
class ConsonaSwipeDismiss extends StatefulWidget {
  const ConsonaSwipeDismiss({
    super.key,
    required this.child,
    this.onDismissed,
    this.axis = Axis.horizontal,
    this.dismissThreshold = 0.35,
    this.velocityThreshold = 600.0,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onDismissed;
  final Axis axis;
  final double dismissThreshold;
  final double velocityThreshold;
  final bool enabled;

  @override
  State<ConsonaSwipeDismiss> createState() => _ConsonaSwipeDismissState();
}

class _ConsonaSwipeDismissState extends State<ConsonaSwipeDismiss> {
  double _dragOffset = 0.0;
  bool _passedThreshold = false;
  bool _isDragging = false;

  void _onDragUpdate(DragUpdateDetails details, double extent) {
    if (!widget.enabled || extent <= 0) return;
    final delta = widget.axis == Axis.horizontal
        ? details.primaryDelta ?? 0.0
        : details.primaryDelta ?? 0.0;
    final next = _dragOffset + delta;
    final ratio = (next.abs() / extent).clamp(0.0, 1.0);
    if (ratio >= widget.dismissThreshold && !_passedThreshold) {
      _passedThreshold = true;
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tick);
    } else if (ratio < widget.dismissThreshold && _passedThreshold) {
      _passedThreshold = false;
    }
    setState(() {
      _isDragging = true;
      _dragOffset = next;
    });
  }

  void _onDragEnd(DragEndDetails details, double extent) {
    if (!widget.enabled) return;
    final velocity = details.primaryVelocity?.abs() ?? 0.0;
    final ratio = extent > 0 ? (_dragOffset.abs() / extent) : 0.0;

    if (ratio >= widget.dismissThreshold ||
        velocity >= widget.velocityThreshold) {
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
      widget.onDismissed?.call();
      if (mounted) {
        setState(() {
          _isDragging = false;
          _dragOffset = 0.0;
          _passedThreshold = false;
        });
      }
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0.0;
        _passedThreshold = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = widget.axis == Axis.horizontal
            ? (constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0)
            : (constraints.maxHeight.isFinite ? constraints.maxHeight : 200.0);
        final progress =
            extent > 0 ? (_dragOffset.abs() / extent).clamp(0.0, 1.0) : 0.0;
        final opacity = (1.0 - progress * 0.65).clamp(0.0, 1.0);

        final offset = widget.axis == Axis.horizontal
            ? Offset(_dragOffset, 0.0)
            : Offset(0.0, _dragOffset);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: widget.axis == Axis.horizontal && widget.enabled
              ? (d) => _onDragUpdate(d, extent)
              : null,
          onHorizontalDragEnd: widget.axis == Axis.horizontal && widget.enabled
              ? (d) => _onDragEnd(d, extent)
              : null,
          onVerticalDragUpdate: widget.axis == Axis.vertical && widget.enabled
              ? (d) => _onDragUpdate(d, extent)
              : null,
          onVerticalDragEnd: widget.axis == Axis.vertical && widget.enabled
              ? (d) => _onDragEnd(d, extent)
              : null,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: Offset.zero, end: offset),
            duration: _isDragging ? Duration.zero : motion.duration,
            curve: motion.curve,
            builder: (context, value, child) {
              return Transform.translate(
                offset: value,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
