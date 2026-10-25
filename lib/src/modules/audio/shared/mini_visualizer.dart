/// Compact animated bar strip for audio pills.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Six-bar mini visualizer used inside player / recorder pills.
class ConsonaMiniVisualizer extends StatefulWidget {
  const ConsonaMiniVisualizer({
    super.key,
    required this.active,
    this.height = 18.0,
    this.barWidth = 2.5,
    this.gap = ConsonaSpacing.xxs,
    this.color,
  });

  final bool active;
  final double height;
  final double barWidth;
  final double gap;
  final Color? color;

  @override
  State<ConsonaMiniVisualizer> createState() => _ConsonaMiniVisualizerState();
}

class _ConsonaMiniVisualizerState extends State<ConsonaMiniVisualizer>
    with SingleTickerProviderStateMixin {
  static const _bases = [0.35, 0.65, 0.95, 0.55, 0.80, 0.45];
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ConsonaMiniVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final color = widget.color ?? theme.colors.foreground;
    final radius = theme.radius.resolve(ConsonaRadiusRole.full);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _bases.length; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                _bar(i, color, radius),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _bar(int i, Color color, BorderRadiusGeometry radius) {
    final t = widget.active
        ? (math.sin((_controller.value * math.pi * 2) + i * 0.9) + 1) / 2
        : 0.0;
    final idle = _bases[i] * 0.45;
    final live = math.max(
      0.3,
      (_bases[i] * (1 + (i % 3) * 0.15) * (0.55 + t * 0.45)).clamp(0.0, 1.0),
    );
    final h = widget.height * (widget.active ? live : idle);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: widget.barWidth,
      height: h,
      decoration: BoxDecoration(
        color: color.withAlpha(widget.active ? 255 : 178),
        borderRadius: radius,
      ),
    );
  }
}
