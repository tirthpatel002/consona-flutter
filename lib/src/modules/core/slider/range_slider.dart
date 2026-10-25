/// Consona RangeSlider — Dual-thumb range slider with horizontal pill thumbs.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/motion.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// A dual-thumb continuous or discrete range slider with horizontal pill-shaped
/// thumbs using `theme.colors.background` fill and `theme.colors.primary` border.
class ConsonaRangeSlider extends StatefulWidget {
  const ConsonaRangeSlider({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(min < max, 'min must be strictly less than max'),
       assert(start <= end, 'start must be less than or equal to end');

  final double start;
  final double end;
  final void Function(double start, double end)? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<ConsonaRangeSlider> createState() => _ConsonaRangeSliderState();
}

enum _ActiveThumb { none, start, end }

class _ConsonaRangeSliderState extends State<ConsonaRangeSlider> {
  _ActiveThumb _activeThumb = _ActiveThumb.none;
  bool _hovered = false;
  int? _lastQuantizedStep;

  double get _normalizedStart =>
      ((widget.start - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double get _normalizedEnd =>
      ((widget.end - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _quantize(double normalized) {
    final clamped = normalized.clamp(0.0, 1.0);
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (clamped * widget.divisions!).round();
      return step / widget.divisions!;
    }
    return clamped;
  }

  /// Picks which thumb to drag. When thumbs overlap, the side of the pointer
  /// relative to the stack decides min (left) vs max (right).
  void _pickActiveThumb(double q) {
    const overlapEpsilon = 1e-9;
    final left = _normalizedStart;
    final right = _normalizedEnd;
    if ((right - left).abs() <= overlapEpsilon) {
      if (q > left) {
        _activeThumb = _ActiveThumb.end;
      } else if (q < left) {
        _activeThumb = _ActiveThumb.start;
      } else {
        // Collapsed at an edge — nudge toward the only free direction.
        _activeThumb =
            left >= 1.0 - overlapEpsilon ? _ActiveThumb.start : _ActiveThumb.end;
      }
      return;
    }

    final distStart = (q - left).abs();
    final distEnd = (q - right).abs();
    _activeThumb =
        distStart < distEnd ? _ActiveThumb.start : _ActiveThumb.end;
  }

  void _updateFromLocalDx(
    double dx,
    double width, {
    bool isStartGesture = false,
  }) {
    if (!widget.enabled || widget.onChanged == null || width <= 0) return;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final raw = isRtl ? 1.0 - (dx / width) : (dx / width);
    final q = _quantize(raw);

    if (isStartGesture || _activeThumb == _ActiveThumb.none) {
      _pickActiveThumb(q);
    }

    final span = widget.max - widget.min;
    final value = (widget.min + q * span).clamp(widget.min, widget.max);
    var nextStart = widget.start;
    var nextEnd = widget.end;

    if (_activeThumb == _ActiveThumb.start) {
      nextStart = value;
    } else {
      nextEnd = value;
    }

    // Always emit ordered (min, max); swap active thumb when handles cross so
    // the dragged pill stays under the finger.
    if (nextStart > nextEnd) {
      final low = nextEnd;
      final high = nextStart;
      nextStart = low;
      nextEnd = high;
      _activeThumb = _activeThumb == _ActiveThumb.start
          ? _ActiveThumb.end
          : _ActiveThumb.start;
    }

    final bucket = widget.divisions != null && widget.divisions! > 0
        ? (q * widget.divisions!).round()
        : (q * 20).round();

    if (_lastQuantizedStep != bucket) {
      _lastQuantizedStep = bucket;
      unawaited(
        ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
      );
    }

    if (nextStart != widget.start || nextEnd != widget.end) {
      widget.onChanged!(nextStart, nextEnd);
    }
  }

  Widget _buildPillThumb({
    required ConsonaThemeData theme,
    required ConsonaMotionSpec fastMotion,
    required bool isActive,
    required double thumbW,
    required double thumbH,
    required double borderWidth,
    required Color primary,
  }) {
    return AnimatedContainer(
      duration: fastMotion.duration,
      curve: fastMotion.curve,
      width: thumbW,
      height: thumbH,
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
        border: Border.all(
          color: primary,
          width: borderWidth,
        ),
        boxShadow: theme.shadow.resolve(
          isActive ? ConsonaShadowLevel.soft : ConsonaShadowLevel.subtle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final scale = theme.density.factor;
    final isDragging = _activeThumb != _ActiveThumb.none;
    final fastMotion = theme.motion.resolve(ConsonaMotionRole.press, context);

    final trackHeight = (isDragging || _hovered ? 6.0 : 4.0) * scale;
    // Elongated pill thumbs — wider capsule than the single slider baseline.
    final baseThumbW = 30.0 * scale;
    final baseThumbH = 14.0 * scale;
    const borderWidth = 2.2;

    final primary =
        widget.enabled ? theme.colors.primary : theme.colors.mutedFg;
    final trackBg = theme.colors.borderLight;

    final startPct = (_normalizedStart * 100).round();
    final endPct = (_normalizedEnd * 100).round();

    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.label,
      value: '$startPct% – $endPct%',
      child: Opacity(
        opacity: widget.enabled
            ? ConsonaOpacities.opaque
            : ConsonaOpacities.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label!,
                    style: theme.typography.label.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                  Text(
                    '$startPct% – $endPct%',
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.mutedFg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.xs),
            ],
            MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 200.0;
                  final maxThumbW = baseThumbW + 6.0 * scale;
                  final usableWidth = math.max(0.0, width - maxThumbW);
                  final isRtl = Directionality.of(context) == TextDirection.rtl;

                  final startNorm =
                      isRtl ? (1.0 - _normalizedEnd) : _normalizedStart;
                  final endNorm =
                      isRtl ? (1.0 - _normalizedStart) : _normalizedEnd;

                  final startLeft = startNorm * usableWidth;
                  final endLeft = endNorm * usableWidth;

                  final startActive = _activeThumb == _ActiveThumb.start;
                  final endActive = _activeThumb == _ActiveThumb.end;

                  final startW =
                      startActive ? baseThumbW + 6.0 * scale : baseThumbW;
                  final startH =
                      startActive ? baseThumbH + 2.0 * scale : baseThumbH;
                  final endW =
                      endActive ? baseThumbW + 6.0 * scale : baseThumbW;
                  final endH =
                      endActive ? baseThumbH + 2.0 * scale : baseThumbH;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: widget.enabled
                        ? (d) {
                            setState(() {});
                            _updateFromLocalDx(
                              d.localPosition.dx,
                              width,
                              isStartGesture: true,
                            );
                            setState(() => _activeThumb = _ActiveThumb.none);
                          }
                        : null,
                    onHorizontalDragStart: widget.enabled
                        ? (d) {
                            _updateFromLocalDx(
                              d.localPosition.dx,
                              width,
                              isStartGesture: true,
                            );
                            setState(() {});
                          }
                        : null,
                    onHorizontalDragUpdate: widget.enabled
                        ? (d) => _updateFromLocalDx(d.localPosition.dx, width)
                        : null,
                    onHorizontalDragEnd: widget.enabled
                        ? (_) => setState(() {
                              _activeThumb = _ActiveThumb.none;
                              _lastQuantizedStep = null;
                            })
                        : null,
                    onHorizontalDragCancel: widget.enabled
                        ? () => setState(() {
                              _activeThumb = _ActiveThumb.none;
                              _lastQuantizedStep = null;
                            })
                        : null,
                    child: SizedBox(
                      height: 32 * scale,
                      width: width,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track background
                          Container(
                            height: trackHeight,
                            width: width,
                            decoration: BoxDecoration(
                              color: trackBg,
                              borderRadius: theme.radius.resolve(
                                ConsonaRadiusRole.full,
                              ),
                            ),
                          ),
                          // Active range bar
                          Positioned(
                            left: startLeft + startW * 0.5,
                            width: math.max(
                              0.0,
                              (endLeft + endW * 0.5) -
                                  (startLeft + startW * 0.5),
                            ),
                            child: Container(
                              height: trackHeight,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: theme.radius.resolve(
                                  ConsonaRadiusRole.full,
                                ),
                              ),
                            ),
                          ),
                          // Start horizontal pill thumb
                          Positioned(
                            left: startLeft,
                            child: _buildPillThumb(
                              theme: theme,
                              fastMotion: fastMotion,
                              isActive: startActive,
                              thumbW: startW,
                              thumbH: startH,
                              borderWidth: borderWidth,
                              primary: primary,
                            ),
                          ),
                          // End horizontal pill thumb
                          Positioned(
                            left: endLeft,
                            child: _buildPillThumb(
                              theme: theme,
                              fastMotion: fastMotion,
                              isActive: endActive,
                              thumbW: endW,
                              thumbH: endH,
                              borderWidth: borderWidth,
                              primary: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
