/// Consona SegmentedControl — Magnetic segmented tab switcher with mid-flight elongation.
library;

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/types.dart';
import '../../theme/motion.dart';
import '../../theme/theme_data.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../feedback/context/feedback_scope.dart';
import '../feedback/models/feedback_event.dart';

/// A single segment definition for [ConsonaSegmentedControl].
@immutable
class ConsonaSegment<T> {
  const ConsonaSegment({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Widget? icon;
  final bool enabled;
}

/// Magnetic segmented tab switcher with a sliding pill indicator that
/// elongates mid-flight (squash-and-stretch) when switching segments.
class ConsonaSegmentedControl<T> extends StatefulWidget {
  const ConsonaSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.fullWidth = false,
    this.semanticLabel,
  }) : assert(segments.length >= 2, 'At least 2 segments are required');

  final List<ConsonaSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final bool fullWidth;
  final String? semanticLabel;

  @override
  State<ConsonaSegmentedControl<T>> createState() =>
      _ConsonaSegmentedControlState<T>();
}

class _ConsonaSegmentedControlState<T> extends State<ConsonaSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight;
  late CurvedAnimation _flightCurve;

  /// Float segment indices for uninterrupted retargeting mid-flight.
  double _fromIdx = 0;
  double _toIdx = 0;

  int? _hoveredIndex;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this);
    _flightCurve = CurvedAnimation(
      parent: _flight,
      curve: Curves.easeInOutCubic,
    );
    final i = _indexOf(widget.selected).toDouble();
    _fromIdx = i;
    _toIdx = i;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion =
        ConsonaTheme.of(context).motion.resolve(ConsonaMotionRole.toggle, context);
    _flight.duration = motion.duration;
    _flightCurve.curve = motion.curve;
  }

  @override
  void didUpdateWidget(covariant ConsonaSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      // Continue from the current visual position — never snap / restart cold.
      final t = _flightCurve.value;
      _fromIdx = lerpDouble(_fromIdx, _toIdx, t)!;
      _toIdx = _indexOf(widget.selected).toDouble();
      unawaited(_flight.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _flightCurve.dispose();
    _flight.dispose();
    super.dispose();
  }

  int _indexOf(T value) {
    final idx = widget.segments.indexWhere((s) => s.value == value);
    return idx >= 0 ? idx : 0;
  }

  int get _selectedIndex => _indexOf(widget.selected);

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.segments.length) return;
    final seg = widget.segments[index];
    if (!seg.enabled || widget.onChanged == null) return;
    if (seg.value == widget.selected) return;

    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    widget.onChanged!(seg.value);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final current = _selectedIndex;

    if (key == LogicalKeyboardKey.arrowRight) {
      final delta = isRtl ? -1 : 1;
      _selectIndex((current + delta).clamp(0, widget.segments.length - 1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      final delta = isRtl ? 1 : -1;
      _selectIndex((current + delta).clamp(0, widget.segments.length - 1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final scale = theme.density.factor;
    final count = widget.segments.length;
    final selectedIdx = _selectedIndex;
    final trackPadding = 3.0 * scale;
    final height = 38.0 * scale;
    final fastMotion = theme.motion.resolve(ConsonaMotionRole.press, context);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: _handleKeyEvent,
        child: Container(
          height: height,
          constraints: widget.fullWidth
              ? const BoxConstraints(minWidth: double.infinity)
              : BoxConstraints(minWidth: count * 88.0 * scale),
          padding: EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: theme.colors.surfaceSecondary,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
            border: _focused
                ? theme.border.resolve(
                    ConsonaBorderRole.focus,
                    context: context,
                  )
                : theme.border.resolve(
                    ConsonaBorderRole.surfaceEdge,
                    context: context,
                  ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : count * 92.0 * scale;
              final segmentWidth = totalWidth / count;
              final isRtl = Directionality.of(context) == TextDirection.rtl;

              return AnimatedBuilder(
                animation: _flightCurve,
                builder: (context, child) {
                  final t = _flightCurve.value;
                  // Continuous float index — retargets mid-flight without jumps.
                  final idx = lerpDouble(_fromIdx, _toIdx, t)!;
                  final visualIdx = isRtl ? (count - 1 - idx) : idx;

                  // Mild mid-flight stretch (does not fight another animator).
                  final stretch = 1.0 + (4.0 * t * (1.0 - t)) * 0.14;
                  final pillWidth = segmentWidth * stretch;
                  final rawLeft =
                      visualIdx * segmentWidth - (pillWidth - segmentWidth) * 0.5;
                  final left = rawLeft.clamp(
                    0.0,
                    (totalWidth - pillWidth).clamp(0.0, totalWidth),
                  );

                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: pillWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colors.surface,
                            borderRadius: theme.radius.resolve(
                              ConsonaRadiusRole.micro,
                            ),
                            border: theme.border.resolve(
                              ConsonaBorderRole.defaultBorder,
                              context: context,
                            ),
                            boxShadow: theme.shadow.resolve(
                              ConsonaShadowLevel.subtle,
                            ),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: Row(
                  children: [
                    for (int i = 0; i < count; i++)
                      Expanded(
                        child: _buildSegmentItem(
                          context,
                          theme,
                          fastMotion,
                          i,
                          i == selectedIdx,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem(
    BuildContext context,
    ConsonaThemeData theme,
    ConsonaMotionSpec fastMotion,
    int index,
    bool isSelected,
  ) {
    final seg = widget.segments[index];
    final isHovered = _hoveredIndex == index;
    final textColor = !seg.enabled
        ? theme.colors.mutedFg
            .withAlpha((255 * ConsonaOpacities.disabled).round())
        : isSelected
            ? theme.colors.foreground
            : isHovered
                ? theme.colors.foreground
                : theme.colors.mutedFg;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: seg.enabled,
      label: seg.label,
      child: MouseRegion(
        cursor: seg.enabled && widget.onChanged != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() {
          if (_hoveredIndex == index) _hoveredIndex = null;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: seg.enabled ? () => _selectIndex(index) : null,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (seg.icon != null) ...[
                    IconTheme(
                      data: IconThemeData(size: 15, color: textColor),
                      child: seg.icon!,
                    ),
                    const SizedBox(width: ConsonaSpacing.xxs),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: fastMotion.duration,
                      style: theme.typography.label.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(
                        seg.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
