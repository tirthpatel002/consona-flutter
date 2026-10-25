/// Consona Rating — Scrubbable tactile rating with micro-haptics.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Tactile star or heart rating bar with drag scrubbing and haptic ticks.
///
/// When [allowHalf] is true: a **tap** snaps to a whole star; a **drag**
/// scrubs in 0.5 increments.
class ConsonaRating extends StatefulWidget {
  const ConsonaRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxRating = 5,
    this.allowHalf = false,
    this.size = ConsonaOpticalSize.md,
    this.enabled = true,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final int maxRating;

  /// Enables half-star precision while dragging. Taps still set whole stars.
  final bool allowHalf;
  final ConsonaOpticalSize size;
  final bool enabled;

  @override
  State<ConsonaRating> createState() => _ConsonaRatingState();
}

class _ConsonaRatingState extends State<ConsonaRating> {
  double? _dragValue;
  Offset? _tapDownLocal;

  double get _currentValue => _dragValue ?? widget.value;

  double _valueFromPosition(Offset localPosition, {required bool halfSteps}) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _currentValue;

    final totalWidth = box.size.width;
    if (totalWidth <= 0) return _currentValue;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final rawFraction = (localPosition.dx / totalWidth).clamp(0.0, 1.0);
    final fraction = isRtl ? 1.0 - rawFraction : rawFraction;

    double computed;
    if (halfSteps && widget.allowHalf) {
      // Drag: 0.5 increments across the bar.
      computed = ((fraction * widget.maxRating) * 2).round() / 2;
      computed = computed.clamp(0.5, widget.maxRating.toDouble());
    } else {
      // Tap (or whole-star mode): which star was hit → full rating.
      computed = (fraction * widget.maxRating).ceilToDouble();
      if (computed < 1.0 && fraction > 0) computed = 1.0;
      computed = computed.clamp(1.0, widget.maxRating.toDouble());
    }
    return computed;
  }

  void _commit(double computed) {
    if (!widget.enabled) return;
    if (_currentValue == computed) return;
    setState(() => _dragValue = computed);
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    widget.onChanged(computed);
  }

  void _endInteraction() {
    if (_dragValue != null) setState(() => _dragValue = null);
    _tapDownLocal = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final iconSize = ConsonaGeometries.ratingIconSizeFor(widget.size);
    final step = widget.allowHalf ? 0.5 : 1.0;
    final minVal = widget.allowHalf ? 0.5 : 1.0;
    final maxVal = widget.maxRating.toDouble();

    final nextVal = (_currentValue + step).clamp(minVal, maxVal);
    final prevVal = (_currentValue - step).clamp(minVal, maxVal);

    return Semantics(
      slider: true,
      enabled: widget.enabled,
      value: '$_currentValue of ${widget.maxRating}',
      increasedValue: '$nextVal of ${widget.maxRating}',
      decreasedValue: '$prevVal of ${widget.maxRating}',
      onIncrease: widget.enabled && _currentValue < maxVal
          ? () => widget.onChanged(nextVal)
          : null,
      onDecrease: widget.enabled && _currentValue > minVal
          ? () => widget.onChanged(prevVal)
          : null,
      child: GestureDetector(
        // Tap → whole star. Drag → half steps when [allowHalf].
        onTapDown: widget.enabled
            ? (details) => _tapDownLocal = details.localPosition
            : null,
        onTap: widget.enabled
            ? () {
                final pos = _tapDownLocal;
                if (pos == null) return;
                _commit(_valueFromPosition(pos, halfSteps: false));
                _endInteraction();
              }
            : null,
        onTapCancel: widget.enabled ? _endInteraction : null,
        onHorizontalDragStart: widget.enabled
            ? (details) {
                _commit(
                  _valueFromPosition(
                    details.localPosition,
                    halfSteps: widget.allowHalf,
                  ),
                );
              }
            : null,
        onHorizontalDragUpdate: widget.enabled
            ? (details) {
                _commit(
                  _valueFromPosition(
                    details.localPosition,
                    halfSteps: widget.allowHalf,
                  ),
                );
              }
            : null,
        onHorizontalDragEnd:
            widget.enabled ? (_) => _endInteraction() : null,
        onHorizontalDragCancel: widget.enabled ? _endInteraction : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= widget.maxRating; i++) ...[
              if (i > 1) const SizedBox(width: ConsonaSpacing.xs),
              _buildStar(i, iconSize, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStar(int index, double size, ConsonaColors colors) {
    final value = _currentValue;
    final isFull = value >= index;
    final isHalf = widget.allowHalf && !isFull && (value >= index - 0.5);

    return Icon(
      isFull
          ? Icons.star_rounded
          : isHalf
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
      size: size,
      color: isFull || isHalf
          ? colors.warning
          : colors.mutedFg.withAlpha((255 * 0.4).round()),
    );
  }
}
