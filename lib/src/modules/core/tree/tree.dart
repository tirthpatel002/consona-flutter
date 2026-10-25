/// Consona Tree — Nested disclosure list with animated expand and optional selection.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Node model for [ConsonaTree].
class ConsonaTreeNode {
  const ConsonaTreeNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.icon,
    this.data,
  });

  final String id;
  final String label;
  final List<ConsonaTreeNode> children;
  final Widget? icon;
  final Object? data;

  bool get isLeaf => children.isEmpty;
}

/// Hierarchical disclosure tree with springy expand rows and optional selection.
class ConsonaTree extends StatefulWidget {
  const ConsonaTree({
    super.key,
    required this.nodes,
    this.expandedIds,
    this.onExpandedChanged,
    this.selectedId,
    this.onSelected,
    this.indent = 14.0,
    this.dense = true,
  });

  final List<ConsonaTreeNode> nodes;

  /// Controlled expanded set. When null, the tree manages expansion locally.
  final Set<String>? expandedIds;
  final ValueChanged<Set<String>>? onExpandedChanged;
  final String? selectedId;
  final ValueChanged<ConsonaTreeNode>? onSelected;
  final double indent;
  final bool dense;

  @override
  State<ConsonaTree> createState() => _ConsonaTreeState();
}

class _ConsonaTreeState extends State<ConsonaTree> {
  late Set<String> _localExpanded;

  @override
  void initState() {
    super.initState();
    _localExpanded = {};
  }

  Set<String> get _expanded => widget.expandedIds ?? _localExpanded;

  void _toggle(String id) {
    final next = Set<String>.of(_expanded);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    if (widget.expandedIds == null) setState(() => _localExpanded = next);
    widget.onExpandedChanged?.call(next);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final node in widget.nodes)
          _TreeBranch(
            node: node,
            depth: 0,
            indent: widget.indent,
            dense: widget.dense,
            expanded: _expanded,
            selectedId: widget.selectedId,
            onToggle: _toggle,
            onSelected: widget.onSelected,
          ),
      ],
    );
  }
}

class _TreeBranch extends StatelessWidget {
  const _TreeBranch({
    required this.node,
    required this.depth,
    required this.indent,
    required this.dense,
    required this.expanded,
    required this.selectedId,
    required this.onToggle,
    required this.onSelected,
  });

  final ConsonaTreeNode node;
  final int depth;
  final double indent;
  final bool dense;
  final Set<String> expanded;
  final String? selectedId;
  final ValueChanged<String> onToggle;
  final ValueChanged<ConsonaTreeNode>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final isOpen = expanded.contains(node.id);
    final isSelected = selectedId == node.id;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    final rowPad = (dense ? 4.5 : 6.5) * scale;
    final chevronSize = (dense ? 14.0 : 16.0) * scale;
    final iconSize = (dense ? 14.0 : 15.0) * scale;
    final fontSize = (dense ? 13.0 : 14.0) * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!node.isLeaf) onToggle(node.id);
            onSelected?.call(node);
            if (node.isLeaf) {
              ConsonaFeedbackScope.maybeOf(context)
                  ?.trigger(FeedbackEvent.selection);
            }
          },
          child: AnimatedContainer(
            duration: motion.duration,
            curve: motion.curve,
            margin: EdgeInsets.only(left: depth * indent * scale),
            padding: EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.xs * scale,
              vertical: rowPad,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withAlpha(colors.isDark ? 48 : 28)
                  : const Color.fromARGB(0, 0, 0, 0),
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: chevronSize + 2,
                  child: node.isLeaf
                      ? const SizedBox.shrink()
                      : AnimatedRotation(
                          turns: isOpen ? 0.25 : 0,
                          duration: motion.duration,
                          curve: motion.curve,
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: chevronSize,
                            color: colors.mutedFg,
                          ),
                        ),
                ),
                if (node.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: iconSize,
                      color: isSelected ? colors.primary : colors.mutedFg,
                    ),
                    child: node.icon!,
                  ),
                  SizedBox(width: ConsonaSpacing.xxs * scale),
                ],
                Expanded(
                  child: Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: isSelected ? colors.primary : colors.foreground,
                      fontWeight: FontWeight.w400,
                      fontSize: fontSize,
                      height: 1.25,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!node.isLeaf)
          ClipRect(
            child: AnimatedAlign(
              duration: motion.duration,
              curve: motion.curve,
              alignment: Alignment.topCenter,
              heightFactor: isOpen ? 1 : 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final child in node.children)
                    _TreeBranch(
                      node: child,
                      depth: depth + 1,
                      indent: indent,
                      dense: dense,
                      expanded: expanded,
                      selectedId: selectedId,
                      onToggle: onToggle,
                      onSelected: onSelected,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
