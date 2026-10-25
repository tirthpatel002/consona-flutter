/// Consona Loader — Minimalist geometric spinner
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';

class ConsonaLoader extends StatefulWidget {
  const ConsonaLoader({
    super.key,
    this.size = 20.0,
    this.strokeWidth = 2.0,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  State<ConsonaLoader> createState() => _ConsonaLoaderState();
}

class _ConsonaLoaderState extends State<ConsonaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final spinnerColor = widget.color ?? theme.colors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SpinnerPainter(
            progress: _controller.value,
            color: spinnerColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track arc
    final trackPaint = Paint()
      ..color = color.withAlpha((255 * ConsonaOpacities.faint * 3).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Spinning sweep arc
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi;
    const sweepAngle = math.pi * 0.75;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}
