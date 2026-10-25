/// Consona Toolbar — Thin pill action rail with horizontal overflow scroll.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';

/// Marker for a vertical hairline between toolbar groups.
class ConsonaToolbarDivider extends StatelessWidget {
  const ConsonaToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final scale = theme.density.factor;
    return Container(
      width: theme.stroke.resolveWidth(context),
      height: 14 * scale,
      margin: EdgeInsets.symmetric(horizontal: 4 * scale),
      color: theme.colors.border,
    );
  }
}

/// Thin floating capsule action chrome — short vertically, scrolls horizontally.
///
/// Actions sit in a single dense row. When they overflow, the row scrolls;
/// [trailing] (e.g. Export) stays pinned on the right when provided.
class ConsonaToolbar extends StatefulWidget {
  const ConsonaToolbar({
    super.key,
    required this.children,
    this.leading,
    this.trailing,
    this.density = ConsonaOpticalSize.xs,
    this.scrollable = true,
    this.background = true,
    this.pill = true,
    this.collapsible = false,
    this.expanded = true,
    this.onExpandedChanged,
    this.draggable = false,
    this.offset,
    this.onOffsetChanged,
  });

  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;

  /// Controls chrome padding; default [xs] keeps the rail thin.
  final ConsonaOpticalSize density;
  final bool scrollable;

  /// When false, renders the action row without the pill chrome.
  final bool background;

  /// Full stadium / capsule curvature.
  final bool pill;

  /// Optional trailing circular chevron that collapses the action strip.
  final bool collapsible;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  /// Enables drag-to-reposition.
  final bool draggable;
  final Offset? offset;
  final ValueChanged<Offset>? onOffsetChanged;

  @override
  State<ConsonaToolbar> createState() => _ConsonaToolbarState();
}

class _ConsonaToolbarState extends State<ConsonaToolbar> {
  late bool _expanded = widget.expanded;
  Offset _localOffset = Offset.zero;
  Offset? _dragOrigin;
  Offset? _offsetAtDragStart;

  Offset get _offset => widget.offset ?? _localOffset;

  @override
  void didUpdateWidget(covariant ConsonaToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      _expanded = widget.expanded;
    }
  }

  void _toggleExpanded() {
    final next = !_expanded;
    setState(() => _expanded = next);
    widget.onExpandedChanged?.call(next);
  }

  void _setOffset(Offset next) {
    if (widget.offset == null) setState(() => _localOffset = next);
    widget.onOffsetChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    final showActions = !widget.collapsible || _expanded;

    // Chrome hugs the controls — almost no inset (screenshot rail).
    final padH = switch (widget.density.standardEquivalent) {
          ConsonaOpticalSize.xs => 3.0,
          ConsonaOpticalSize.sm => 4.0,
          ConsonaOpticalSize.md => 5.0,
          _ => 4.0,
        } *
        scale;
    final padV = 2.0 * scale;
    final handleSize = 22.0 * scale;
    final gap = 1.0 * scale;

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          widget.children[i],
        ],
      ],
    );

    Widget actionStrip;
    if (!showActions) {
      actionStrip = const SizedBox.shrink();
    } else if (widget.scrollable) {
      actionStrip = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        child: actions,
      );
    } else {
      actionStrip = actions;
    }

    final row = Row(
      children: [
        if (widget.leading != null && showActions) ...[
          widget.leading!,
          SizedBox(width: gap),
        ],
        Expanded(
          child: AnimatedSize(
            duration: motion.duration,
            curve: motion.curve,
            alignment: Alignment.centerLeft,
            child: Align(
              alignment: Alignment.centerLeft,
              child: actionStrip,
            ),
          ),
        ),
        if (widget.trailing != null && showActions) ...[
          SizedBox(width: padH * 0.5),
          widget.trailing!,
        ],
        if (widget.collapsible) ...[
          SizedBox(width: gap),
          _ToolbarHandle(
            size: handleSize,
            expanded: _expanded,
            onTap: _toggleExpanded,
          ),
        ],
      ],
    );

    Widget chrome = row;
    if (widget.background) {
      final radius = widget.pill
          ? theme.radius.resolve(ConsonaRadiusRole.full)
          : theme.radius.resolve(ConsonaRadiusRole.base);
      chrome = AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          // `defaultBorder` uses `border` (not borderLight) so the edge reads
          // clearly on both light and dark surfaces.
          border: theme.border.resolve(
            ConsonaBorderRole.defaultBorder,
            context: context,
          ),
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
        ),
        child: row,
      );
    }

    if (!widget.draggable) return chrome;

    return Transform.translate(
      offset: _offset,
      filterQuality: FilterQuality.medium,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanStart: (details) {
          _dragOrigin = details.globalPosition;
          _offsetAtDragStart = _offset;
        },
        onPanUpdate: (details) {
          final origin = _dragOrigin;
          final start = _offsetAtDragStart;
          if (origin == null || start == null) return;
          _setOffset(start + (details.globalPosition - origin));
        },
        onPanEnd: (_) {
          _dragOrigin = null;
          _offsetAtDragStart = null;
        },
        onPanCancel: () {
          _dragOrigin = null;
          _offsetAtDragStart = null;
        },
        child: chrome,
      ),
    );
  }
}

class _ToolbarHandle extends StatelessWidget {
  const _ToolbarHandle({
    required this.size,
    required this.expanded,
    required this.onTap,
  });

  final double size;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);

    return ConsonaSpringPress(
      onTap: onTap,
      feedbackEvent: FeedbackEvent.tap,
      child: AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          shape: BoxShape.circle,
          boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
        ),
        alignment: Alignment.center,
        child: AnimatedRotation(
          turns: expanded ? 0 : 0.5,
          duration: motion.duration,
          curve: motion.curve,
          child: Icon(
            Icons.chevron_right_rounded,
            size: size * 0.55,
            color: colors.mutedFg,
          ),
        ),
      ),
    );
  }
}
