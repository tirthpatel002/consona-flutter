/// Consona Swipe Action — Elastic swipe reveal with threshold haptic snap
library;

import 'package:flutter/widgets.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/models/feedback_event.dart';

class ConsonaSwipeItem {
  const ConsonaSwipeItem({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.foregroundColor,
  });

  final Widget icon;
  final Color backgroundColor;
  final Color? foregroundColor;
  final VoidCallback onTap;
}

class ConsonaSwipeAction extends StatefulWidget {
  const ConsonaSwipeAction({
    super.key,
    required this.child,
    this.endActions = const [],
    this.threshold = 72.0,
  });

  final Widget child;
  final List<ConsonaSwipeItem> endActions;
  final double threshold;

  @override
  State<ConsonaSwipeAction> createState() => _ConsonaSwipeActionState();
}

class _ConsonaSwipeActionState extends State<ConsonaSwipeAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _offsetAnimation;
  double _dragOffset = 0.0;
  bool _thresholdReached = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _offsetAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.endActions.isEmpty) return;

    setState(() {
      _dragOffset = (_dragOffset + details.primaryDelta!).clamp(
        -widget.endActions.length * widget.threshold * 1.2,
        0.0,
      );

      final reached = _dragOffset.abs() >= (widget.endActions.length * widget.threshold);
      if (reached && !_thresholdReached) {
        FeedbackEngine.of(context).trigger(FeedbackEvent.selection);
        _thresholdReached = true;
      } else if (!reached && _thresholdReached) {
        _thresholdReached = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.endActions.isEmpty) return;

    final targetOffset = _thresholdReached
        ? -widget.endActions.length * widget.threshold
        : 0.0;

    _animateTo(targetOffset);
  }

  void _animateTo(double target) {
    _offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0.0).then((_) {
      _dragOffset = target;
      if (target == 0.0) _thresholdReached = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final actionsWidth = widget.endActions.length * widget.threshold;

    return Stack(
      children: [
        if (widget.endActions.isNotEmpty)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: actionsWidth,
                child: Row(
                  children: widget.endActions.map((action) {
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _animateTo(0.0);
                          action.onTap();
                        },
                        child: Container(
                          color: action.backgroundColor,
                          alignment: Alignment.center,
                          child: IconTheme(
                            data: IconThemeData(
                              color: action.foregroundColor ??
                                  theme.colors.onDanger,
                              size: 20.0,
                            ),
                            child: action.icon,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final currentOffset = _controller.isAnimating
                  ? _offsetAnimation.value
                  : _dragOffset;
              return Transform.translate(
                offset: Offset(currentOffset, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
