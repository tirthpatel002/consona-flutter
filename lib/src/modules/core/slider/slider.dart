/// Consona Slider — Tactile slider with modern horizontal pill thumb (app bg fill + primary border).
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Tactile continuous or discrete slider with a horizontal pill-shaped thumb
/// (`theme.colors.background` fill + `theme.colors.primary` border).
class ConsonaSlider extends StatefulWidget {
  const ConsonaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.enabled = true,
    this.compact = false,
    this.semanticLabel,
  }) : assert(min <= max, 'min must be less than or equal to max');

  final double value;
  final ValueChanged<double>? onChanged;
  /// Called when the user finishes a drag or tap scrub (not on programmatic updates).
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final bool enabled;
  final bool compact;
  final String? semanticLabel;

  @override
  State<ConsonaSlider> createState() => _ConsonaSliderState();
}

class _ConsonaSliderState extends State<ConsonaSlider> {
  double? _dragFraction;
  bool _isHovered = false;

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  double _valueToFraction(double val) {
    final range = widget.max - widget.min;
    if (range <= 0) return 0.0;
    return ((val - widget.min) / range).clamp(0.0, 1.0);
  }

  double _fractionToValue(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    final effectiveFraction = widget.divisions != null && widget.divisions! > 0
        ? (clamped * widget.divisions!).round() / widget.divisions!
        : clamped;
    return widget.min + effectiveFraction * (widget.max - widget.min);
  }

  void _updateFromDx(double dx, double totalWidth, double inset) {
    if (!_isInteractive || totalWidth <= 0) return;
    final railW = (totalWidth - inset * 2).clamp(1.0, totalWidth);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final rawFraction = ((dx - inset) / railW).clamp(0.0, 1.0);
    final fraction = isRtl ? 1.0 - rawFraction : rawFraction;
    final snappedFraction = widget.divisions != null && widget.divisions! > 0
        ? (fraction * widget.divisions!).round() / widget.divisions!
        : fraction;

    final nextValue = _fractionToValue(snappedFraction);
    setState(() => _dragFraction = snappedFraction);

    if (nextValue != widget.value) {
      ConsonaFeedbackScope.maybeOf(context)?.trigger(
        widget.divisions != null ? FeedbackEvent.tick : FeedbackEvent.selection,
      );
      widget.onChanged?.call(nextValue);
    }
  }

  void _endDrag() {
    final fraction = _dragFraction;
    if (fraction != null) {
      widget.onChangeEnd?.call(_fractionToValue(fraction));
      setState(() => _dragFraction = null);
    }
  }

  String _formatPercent(double fraction) => '${(fraction * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final progress = _valueToFraction(widget.value);
    final effectiveProgress = _dragFraction ?? progress;
    final isActive = _dragFraction != null || _isHovered;

    final trackH = widget.compact ? 22.0 : 28.0;
    final railH = widget.compact ? 4.0 : 5.0;
    // Horizontal pill thumb — elongated capsule (longer than tall).
    final thumbW = isActive
        ? (widget.compact ? 28.0 : 34.0)
        : (widget.compact ? 24.0 : 30.0);
    final thumbH = isActive
        ? (widget.compact ? 14.0 : 16.0)
        : (widget.compact ? 12.0 : 14.0);
    final borderWidth = widget.compact ? 2.0 : 2.2;

    final stepFraction = widget.divisions != null && widget.divisions! > 0
        ? 1.0 / widget.divisions!
        : 0.05;
    final nextFraction = (effectiveProgress + stepFraction).clamp(0.0, 1.0);
    final prevFraction = (effectiveProgress - stepFraction).clamp(0.0, 1.0);

    return Semantics(
      slider: true,
      enabled: _isInteractive,
      label: widget.semanticLabel,
      value: _formatPercent(effectiveProgress),
      increasedValue: _formatPercent(nextFraction),
      decreasedValue: _formatPercent(prevFraction),
      onIncrease: _isInteractive
          ? () => widget.onChanged?.call(_fractionToValue(nextFraction))
          : null,
      onDecrease: _isInteractive
          ? () => widget.onChanged?.call(_fractionToValue(prevFraction))
          : null,
      child: Opacity(
        opacity:
            _isInteractive ? ConsonaOpacities.opaque : ConsonaOpacities.disabled,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final inset = thumbW / 2;
            final railW = (width - inset * 2).clamp(0.0, width);
            final thumbStart = inset + railW * effectiveProgress - thumbW / 2;

            return MouseRegion(
              cursor: _isInteractive
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              onEnter: (_) {
                if (_isInteractive) setState(() => _isHovered = true);
              },
              onExit: (_) {
                if (_isHovered) setState(() => _isHovered = false);
              },
              child: GestureDetector(
                onTapDown: _isInteractive
                    ? (d) => _updateFromDx(d.localPosition.dx, width, inset)
                    : null,
                onTapUp: _isInteractive ? (_) => _endDrag() : null,
                onTapCancel: _isInteractive ? _endDrag : null,
                onHorizontalDragUpdate: _isInteractive
                    ? (d) => _updateFromDx(d.localPosition.dx, width, inset)
                    : null,
                onHorizontalDragEnd: _isInteractive ? (_) => _endDrag() : null,
                onHorizontalDragCancel: _isInteractive ? _endDrag : null,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: trackH,
                  width: width,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      // Inactive rail
                      PositionedDirectional(
                        start: inset,
                        end: inset,
                        child: Container(
                          height: railH,
                          decoration: BoxDecoration(
                            color: colors.borderLight,
                            borderRadius:
                                theme.radius.resolve(ConsonaRadiusRole.full),
                          ),
                        ),
                      ),
                      // Active primary fill
                      PositionedDirectional(
                        start: inset,
                        child: Container(
                          height: railH,
                          width: railW * effectiveProgress,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius:
                                theme.radius.resolve(ConsonaRadiusRole.full),
                          ),
                        ),
                      ),
                      // Modern horizontal pill thumb: theme background fill + primary border
                      PositionedDirectional(
                        start: thumbStart.clamp(
                          0.0,
                          (width - thumbW).clamp(0.0, double.infinity),
                        ),
                        top: (trackH - thumbH) / 2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: thumbW,
                          height: thumbH,
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius:
                                theme.radius.resolve(ConsonaRadiusRole.full),
                            border: Border.all(
                              color: colors.primary,
                              width: borderWidth,
                            ),
                            boxShadow: theme.shadow
                                .resolve(ConsonaShadowLevel.subtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
