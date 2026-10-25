/// Consona Progress & Meter — Determinate progress bar and threshold capacity meter.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Determinate progress bar with animated fill and optional percentage readout.
class ConsonaProgress extends StatelessWidget {
  const ConsonaProgress({
    super.key,
    required this.value,
    this.label,
    this.showPercentage = false,
    this.height = 8,
    this.color,
  });

  /// Normalized progress in `0.0 .. 1.0`.
  final double value;
  final String? label;
  final bool showPercentage;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final pct = (clamped * 100).round();
    final fill = color ?? theme.colors.primary;
    final motionSpec = theme.motion.resolve(ConsonaMotionRole.toggle, context);

    return Semantics(
      label: label ?? 'Progress',
      value: '$pct%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || showPercentage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Flexible(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '$pct%',
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.mutedFg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ConsonaSpacing.xxs),
          ],
          ClipRRect(
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
            child: Container(
              height: height * theme.density.factor,
              width: double.infinity,
              color: theme.colors.surfaceSecondary,
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: motionSpec.duration,
                curve: motionSpec.curve,
                widthFactor: clamped,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented capacity / level meter with automatic semantic threshold coloring
/// (`success` -> `warning` -> `danger` as capacity approaches 100%).
///
/// Renders as a thin, minimal tick rail — short hairline bars with tight gaps.
class ConsonaMeter extends StatelessWidget {
  const ConsonaMeter({
    super.key,
    required this.value,
    this.segments = 12,
    this.label,
    this.warningThreshold = 0.7,
    this.dangerThreshold = 0.9,
    this.height = 3,
  }) : assert(segments > 0, 'segments must be positive');

  final double value;
  final int segments;
  final String? label;
  final double warningThreshold;
  final double dangerThreshold;

  /// Tick thickness. Defaults to a 3px hairline.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final clamped = value.clamp(0.0, 1.0);
    final activeSegments = (clamped * segments).round();
    final pct = (clamped * 100).round();
    final fastMotion = theme.motion.resolve(ConsonaMotionRole.press, context);
    final tickH = height * scale;
    final gap = 1.5 * scale;
    final idle = colors.border.withAlpha((255 * 0.45).round());

    Color resolveSegmentColor(int index) {
      final ratio = (index + 1) / segments;
      if (ratio >= dangerThreshold) return colors.danger;
      if (ratio >= warningThreshold) return colors.warning;
      return colors.success;
    }

    return Semantics(
      label: label ?? 'Capacity meter',
      value: '$pct%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '$pct%',
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6 * scale),
          ],
          SizedBox(
            height: tickH,
            child: Row(
              children: [
                for (int i = 0; i < segments; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: AnimatedContainer(
                      duration: fastMotion.duration,
                      curve: fastMotion.curve,
                      decoration: BoxDecoration(
                        color: i < activeSegments
                            ? resolveSegmentColor(i)
                            : idle,
                        borderRadius: BorderRadius.circular(tickH),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
