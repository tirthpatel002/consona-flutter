/// Consona SplitView — Responsive draggable 2-pane layout with mobile switcher fallback.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../navigation/segmented_control.dart';

/// Responsive resizable split-pane container.
///
/// - On wide viewports (`>= collapseBreakpoint`), displays [primary] and [secondary]
///   side-by-side (or stacked when `direction == Axis.vertical`) with a draggable
///   hairline resize handle and double-tap-to-reset.
/// - On compact mobile viewports (`< collapseBreakpoint`), automatically adapts
///   into a tabbed [ConsonaSegmentedControl] pane switcher so neither pane is
///   crushed on narrow phone screens.
class ConsonaSplitView extends StatefulWidget {
  const ConsonaSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryLabel = 'Primary',
    this.secondaryLabel = 'Inspector',
    this.initialRatio = 0.38,
    this.minRatio = 0.2,
    this.maxRatio = 0.8,
    this.collapseBreakpoint = 600.0,
    this.direction = Axis.horizontal,
    this.height = 280.0,
    this.onRatioChanged,
  }) : assert(minRatio > 0 && maxRatio < 1 && minRatio <= maxRatio);

  final Widget primary;
  final Widget secondary;
  final String primaryLabel;
  final String secondaryLabel;
  final double initialRatio;
  final double minRatio;
  final double maxRatio;
  final double collapseBreakpoint;
  final Axis direction;
  final double height;
  final ValueChanged<double>? onRatioChanged;

  @override
  State<ConsonaSplitView> createState() => _ConsonaSplitViewState();
}

class _ConsonaSplitViewState extends State<ConsonaSplitView> {
  late double _ratio;
  bool _dragging = false;
  bool _hovered = false;
  int _mobilePaneIndex = 0;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
  }

  void _resetRatio() {
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    setState(() {
      _ratio = widget.initialRatio.clamp(widget.minRatio, widget.maxRatio);
    });
    widget.onRatioChanged?.call(_ratio);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        final isCollapsedMobile =
            widget.direction == Axis.horizontal &&
            totalW < widget.collapseBreakpoint;

        if (isCollapsedMobile) {
          final hasBoundedHeight = constraints.maxHeight.isFinite;
          final paneBox = Container(
            height: hasBoundedHeight ? null : widget.height * scale,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
              border: theme.border.resolve(
                ConsonaBorderRole.surfaceEdge,
                context: context,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _mobilePaneIndex == 0 ? widget.primary : widget.secondary,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize:
                hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              ConsonaSegmentedControl<int>(
                fullWidth: true,
                selected: _mobilePaneIndex,
                onChanged: (idx) => setState(() => _mobilePaneIndex = idx),
                segments: [
                  ConsonaSegment(value: 0, label: widget.primaryLabel),
                  ConsonaSegment(value: 1, label: widget.secondaryLabel),
                ],
              ),
              const SizedBox(height: ConsonaSpacing.sm),
              if (hasBoundedHeight) Expanded(child: paneBox) else paneBox,
            ],
          );
        }

        const handleThickness = 12.0;
        final totalMain = widget.direction == Axis.horizontal
            ? totalW
            : (constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : widget.height * scale);
        final usable = (totalMain - handleThickness).clamp(1.0, totalMain);

        final handleColor = _dragging || _hovered
            ? colors.primary
            : colors.borderStrong;

        final handle = MouseRegion(
          cursor: widget.direction == Axis.horizontal
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _resetRatio,
            onHorizontalDragStart: widget.direction == Axis.horizontal
                ? (_) => setState(() => _dragging = true)
                : null,
            onHorizontalDragUpdate: widget.direction == Axis.horizontal
                ? (d) {
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    final delta = isRtl ? -d.delta.dx : d.delta.dx;
                    final next = (_ratio + delta / usable)
                        .clamp(widget.minRatio, widget.maxRatio);
                    if (next != _ratio) {
                      setState(() => _ratio = next);
                      widget.onRatioChanged?.call(next);
                    }
                  }
                : null,
            onHorizontalDragEnd: widget.direction == Axis.horizontal
                ? (_) => setState(() => _dragging = false)
                : null,
            onVerticalDragStart: widget.direction == Axis.vertical
                ? (_) => setState(() => _dragging = true)
                : null,
            onVerticalDragUpdate: widget.direction == Axis.vertical
                ? (d) {
                    final next = (_ratio + d.delta.dy / usable)
                        .clamp(widget.minRatio, widget.maxRatio);
                    if (next != _ratio) {
                      setState(() => _ratio = next);
                      widget.onRatioChanged?.call(next);
                    }
                  }
                : null,
            onVerticalDragEnd: widget.direction == Axis.vertical
                ? (_) => setState(() => _dragging = false)
                : null,
            child: SizedBox(
              width: widget.direction == Axis.horizontal
                  ? handleThickness
                  : double.infinity,
              height: widget.direction == Axis.vertical
                  ? handleThickness
                  : double.infinity,
              child: Center(
                child: Container(
                  width: widget.direction == Axis.horizontal ? 4.0 : 28.0,
                  height: widget.direction == Axis.horizontal ? 28.0 : 4.0,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  ),
                ),
              ),
            ),
          ),
        );

        return Container(
          height: widget.height * scale,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
            border: theme.border.resolve(
              ConsonaBorderRole.surfaceEdge,
              context: context,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              final innerMain = widget.direction == Axis.horizontal
                  ? (innerConstraints.maxWidth.isFinite
                        ? innerConstraints.maxWidth
                        : totalW)
                  : (innerConstraints.maxHeight.isFinite
                        ? innerConstraints.maxHeight
                        : widget.height * scale);
              final innerUsable =
                  (innerMain - handleThickness).clamp(1.0, innerMain);
              final innerFirst = innerUsable * _ratio;
              final innerSecond = innerUsable - innerFirst;

              return Flex(
                direction: widget.direction,
                children: [
                  SizedBox(
                    width: widget.direction == Axis.horizontal
                        ? innerFirst
                        : double.infinity,
                    height: widget.direction == Axis.vertical
                        ? innerFirst
                        : double.infinity,
                    child: widget.primary,
                  ),
                  handle,
                  SizedBox(
                    width: widget.direction == Axis.horizontal
                        ? innerSecond
                        : double.infinity,
                    height: widget.direction == Axis.vertical
                        ? innerSecond
                        : double.infinity,
                    child: widget.secondary,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
