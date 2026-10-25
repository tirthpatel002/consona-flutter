/// Consona Waveform — Dynamic tactile audio visualizer bars with frame-by-frame LERP smoothing.
library;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Interactive audio waveform bar visualizer with touch scrubbing.
class ConsonaWaveform extends StatefulWidget {
  const ConsonaWaveform({
    super.key,
    required this.amplitudes,
    required this.progress,
    this.onSeek,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.height = 48.0,
    this.interactive = true,
  });

  final List<double> amplitudes;
  final double progress; // 0.0 to 1.0
  final ValueChanged<double>? onSeek;
  final double barWidth;
  final double barSpacing;
  final double height;
  final bool interactive;

  @override
  State<ConsonaWaveform> createState() => _ConsonaWaveformState();
}

class _ConsonaWaveformState extends State<ConsonaWaveform> {
  double? _scrubProgress;

  double get _effectiveProgress => _scrubProgress ?? widget.progress;

  void _handleScrub(Offset localPosition, double totalWidth) {
    if (!widget.interactive || totalWidth <= 0) return;
    final progress = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    setState(() => _scrubProgress = progress);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    widget.onSeek?.call(progress);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final samples = widget.amplitudes.isEmpty
        ? const [0.3, 0.5, 0.8, 0.4, 0.6, 0.9, 0.7, 0.5, 0.3, 0.6, 0.8, 0.4, 0.7, 0.5, 0.3]
        : widget.amplitudes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          onTapDown: (d) => _handleScrub(d.localPosition, totalWidth),
          onHorizontalDragUpdate: (d) => _handleScrub(d.localPosition, totalWidth),
          onHorizontalDragEnd: (_) => setState(() => _scrubProgress = null),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              size: Size(totalWidth, widget.height),
              painter: _WaveformPainter(
                samples: samples,
                progress: _effectiveProgress,
                activeColor: colors.primary,
                inactiveColor: colors.borderLight,
                barWidth: widget.barWidth,
                barSpacing: widget.barSpacing,
                borderRadius: theme.radius.resolveRaw(ConsonaRadiusRole.atom),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.barWidth,
    required this.barSpacing,
    required this.borderRadius,
  });

  final List<double> samples;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double barSpacing;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final pitch = barWidth + barSpacing;
    final totalBars = (size.width / pitch).floor();
    if (totalBars <= 0) return;

    final activePaint = Paint()..color = activeColor;
    final inactivePaint = Paint()..color = inactiveColor;

    final activeWidth = size.width * progress;

    for (var i = 0; i < totalBars; i++) {
      final sampleIndex = (i / totalBars * samples.length).floor().clamp(0, samples.length - 1);
      final amplitude = samples[sampleIndex].clamp(0.1, 1.0);
      final barHeight = size.height * amplitude;

      final x = i * pitch;
      final y = (size.height - barHeight) / 2;

      final isPast = x <= activeWidth;
      final paint = isPast ? activePaint : inactivePaint;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing ||
        !listEquals(oldDelegate.samples, samples);
  }
}
