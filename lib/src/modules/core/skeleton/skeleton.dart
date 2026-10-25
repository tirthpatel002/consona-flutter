/// Consona Skeleton — High-frame-rate gradient shimmer placeholder
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';

class ConsonaSkeleton extends StatefulWidget {
  const ConsonaSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const ConsonaSkeleton.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        isCircle = true;

  const ConsonaSkeleton.text({
    super.key,
    this.width = 120.0,
    this.height = 16.0,
  })  : borderRadius = null,
        isCircle = false;

  @override
  State<ConsonaSkeleton> createState() => _ConsonaSkeletonState();
}

class _ConsonaSkeletonState extends State<ConsonaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final motion = theme.motion.resolve(ConsonaMotionRole.shimmer, context);

    if (motion.duration == Duration.zero) {
      // Reduced motion: static bone
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colors.surfaceSecondary,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle
              ? null
              : (widget.borderRadius ?? theme.radius.resolve(ConsonaRadiusRole.micro)),
        ),
      );
    }

    final baseColor = theme.colors.surfaceSecondary;
    final highlightColor = theme.colors.surface;

    final effectiveRadius = widget.isCircle
        ? null
        : (widget.borderRadius ?? theme.radius.resolve(ConsonaRadiusRole.micro));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: effectiveRadius,
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (3.0 * t), 0.0),
              end: Alignment(-0.5 + (3.0 * t), 0.0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
