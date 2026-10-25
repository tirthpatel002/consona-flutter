/// Consona Checkbox — Vector checkmark draw-in animation with tactile spring pop
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/models/feedback_event.dart';

class ConsonaCheckbox extends StatefulWidget {
  const ConsonaCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.boxSize = 22.0,
    this.inflateLayout = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  /// Painted box edge length. Tables pass a smaller value so the control
  /// matches row text instead of the standalone 22px atom.
  final double boxSize;

  /// When false, layout hugs [boxSize]. Hit testing still extends slightly
  /// past the box without growing the row.
  final bool inflateLayout;

  @override
  State<ConsonaCheckbox> createState() => _ConsonaCheckboxState();
}

class _ConsonaCheckboxState extends State<ConsonaCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.value ? 1.0 : 0.0,
    );
    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 60),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(ConsonaCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.disabled || widget.onChanged == null) return;
    final newValue = !widget.value;
    FeedbackEngine.of(context).trigger(
      newValue ? FeedbackEvent.toggleOn : FeedbackEvent.toggleOff,
    );
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !widget.disabled && widget.onChanged != null;

    final boxSize = widget.boxSize;
    final compactHit = boxSize + 12.0;

    // The motion knob drives the check/uncheck speed.
    _controller.duration = theme.motion.resolve(ConsonaMotionRole.toggle, context).duration;

    return Semantics(
      checked: widget.value,
      enabled: isInteractive,
      child: ConsonaHitTarget(
        inflateLayout: widget.inflateLayout,
        minSize: widget.inflateLayout ? null : Size.square(compactHit),
        child: FocusableActionDetector(
          enabled: isInteractive,
          mouseCursor:
              isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
          actions: <Type, Action<Intent>>{
            if (isInteractive)
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _handleTap();
                  return null;
                },
              ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive ? _handleTap : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final fillColor = Color.lerp(
                  theme.colors.surfaceSecondary,
                  theme.colors.primary,
                  t,
                )!;

                final border = theme.border.resolve(
                  ConsonaBorderRole.inputOutline,
                  state: widget.disabled
                      ? ConsonaInteractionState.disabled
                      : ConsonaInteractionState.idle,
                  context: context,
                );

                return Opacity(
                  opacity: widget.disabled
                      ? ConsonaOpacities.disabled
                      : ConsonaOpacities.opaque,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.atom),
                        border: t > 0.5 ? null : border,
                      ),
                      child: CustomPaint(
                        painter: _CheckmarkPainter(
                          progress: _checkAnimation.value,
                          color: theme.colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.32);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
