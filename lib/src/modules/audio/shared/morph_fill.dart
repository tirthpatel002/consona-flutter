/// Morphing progress fill — stadium trailing edge (matches interface pills).
library;

import 'package:flutter/widgets.dart';

/// Clips [child] to [progress] from the leading edge, with a full-radius
/// stadium tip on the trailing edge so the fill never looks square-cut.
class ConsonaMorphFill extends StatelessWidget {
  const ConsonaMorphFill({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
    this.height,
  });

  /// 0…1 fill amount.
  final double progress;

  final Color color;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = height ?? constraints.maxHeight;
        final tip = Radius.circular(h / 2);
        final fillW = (w * p).clamp(0.0, w);

        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: ClipRRect(
            borderRadius: BorderRadiusDirectional.horizontal(end: tip),
            child: SizedBox(
              width: fillW,
              height: h,
              child: ColoredBox(
                color: color,
                child: OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: w,
                  maxWidth: w,
                  minHeight: h,
                  maxHeight: h,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: ExcludeSemantics(
                      child: IgnorePointer(child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
