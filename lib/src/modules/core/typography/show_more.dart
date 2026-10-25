/// Consona ShowMore — Expandable text clamp and divider toggle for long content.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../button/button.dart';
import '../separator/divider.dart';

/// Expandable content control — clamp long copy, or a divider with a toggle.
class ConsonaShowMore extends StatefulWidget {
  /// Text that clamps to [maxLines] until expanded.
  const ConsonaShowMore({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.expanded,
    this.onExpandedChanged,
    this.expandLabel = 'Show more',
    this.collapseLabel = 'Show less',
    this.style,
  })  : asDivider = false,
        orientation = Axis.horizontal,
        dividerLabel = null;

  /// Hairline divider with a centered outline toggle (web show-more pattern).
  const ConsonaShowMore.divider({
    super.key,
    this.expanded,
    this.onExpandedChanged,
    this.expandLabel = 'Show more',
    this.collapseLabel = 'Show less',
    this.orientation = Axis.horizontal,
    this.dividerLabel,
  })  : asDivider = true,
        text = '',
        maxLines = 3,
        style = null;

  final String text;
  final int maxLines;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final String expandLabel;
  final String collapseLabel;
  final TextStyle? style;
  final bool asDivider;
  final Axis orientation;
  final String? dividerLabel;

  @override
  State<ConsonaShowMore> createState() => _ConsonaShowMoreState();
}

class _ConsonaShowMoreState extends State<ConsonaShowMore>
    with SingleTickerProviderStateMixin {
  bool _localExpanded = false;
  late final AnimationController _chevron;

  bool get _expanded => widget.expanded ?? _localExpanded;

  @override
  void initState() {
    super.initState();
    _chevron = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _expanded ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant ConsonaShowMore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expanded) {
      _chevron.forward();
    } else {
      _chevron.reverse();
    }
  }

  @override
  void dispose() {
    _chevron.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _localExpanded = next);
    widget.onExpandedChanged?.call(next);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    if (next) {
      _chevron.forward();
    } else {
      _chevron.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asDivider) return _buildDivider(context);
    return _buildText(context);
  }

  Widget _buildDivider(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final label = _expanded
        ? widget.collapseLabel
        : (widget.dividerLabel ?? widget.expandLabel);

    final button = ConsonaButton.outline(
      label: label,
      size: ConsonaOpticalSize.xs,
      shapeVariant: ConsonaShapeVariant.pill,
      trailing: RotationTransition(
        turns: Tween<double>(begin: 0, end: 0.5).animate(
          CurvedAnimation(parent: _chevron, curve: Curves.easeOutCubic),
        ),
        child: const Icon(Icons.expand_more_rounded, size: 16),
      ),
      onTap: _toggle,
    );

    if (widget.orientation == Axis.vertical) {
      return SizedBox(
        height: 160 * theme.density.factor,
        child: Column(
          children: [
            const Expanded(child: ConsonaDivider.vertical()),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ConsonaSpacing.sm * theme.density.factor,
              ),
              child: button,
            ),
            const Expanded(child: ConsonaDivider.vertical()),
          ],
        ),
      );
    }

    return Row(
      children: [
        const Expanded(child: ConsonaDivider()),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ConsonaSpacing.sm * theme.density.factor,
          ),
          child: button,
        ),
        const Expanded(child: ConsonaDivider()),
      ],
    );
  }

  Widget _buildText(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    final baseStyle = widget.style ??
        theme.typography.body.copyWith(color: colors.foreground, height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topLeft,
          child: Text(
            widget.text,
            maxLines: _expanded ? null : widget.maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: baseStyle,
          ),
        ),
        SizedBox(height: ConsonaSpacing.xs * theme.density.factor),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? widget.collapseLabel : widget.expandLabel,
                style: theme.typography.label.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: ConsonaSpacing.xxs * theme.density.factor),
              RotationTransition(
                turns: Tween<double>(begin: 0, end: 0.5).animate(
                  CurvedAnimation(parent: _chevron, curve: Curves.easeOutCubic),
                ),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 16 * theme.density.factor,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
