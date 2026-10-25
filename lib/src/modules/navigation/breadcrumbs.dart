/// Consona Breadcrumbs — Responsive hierarchical path bar with automatic ellipsis collapse.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/types.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../feedback/context/feedback_scope.dart';
import '../feedback/models/feedback_event.dart';

/// A single node in a [ConsonaBreadcrumbs] trail.
@immutable
class ConsonaBreadcrumbItem {
  const ConsonaBreadcrumbItem({
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;
  final Widget? icon;
  final VoidCallback? onTap;
}

/// Hierarchical path bar (`Workspace / Projects / Audio Synth`) that
/// automatically collapses middle items into an interactive `…` pill on
/// narrow mobile viewports (`< collapseWidth`).
class ConsonaBreadcrumbs extends StatefulWidget {
  const ConsonaBreadcrumbs({
    super.key,
    required this.items,
    this.separator = '/',
    this.collapseWidth = 480.0,
  }) : assert(items.length > 0, 'At least one breadcrumb item is required');

  final List<ConsonaBreadcrumbItem> items;
  final String separator;
  final double collapseWidth;

  @override
  State<ConsonaBreadcrumbs> createState() => _ConsonaBreadcrumbsState();
}

class _ConsonaBreadcrumbsState extends State<ConsonaBreadcrumbs> {
  bool _expandedManually = false;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Semantics(
      container: true,
      label: 'Breadcrumbs',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < widget.collapseWidth;
          final shouldCollapse =
              isNarrow && !_expandedManually && widget.items.length > 3;

          final children = <Widget>[];

          void addSeparator() {
            children.add(
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
                child: Text(
                  widget.separator,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                  ),
                ),
              ),
            );
          }

          if (shouldCollapse) {
            children.add(_buildCrumb(context, 0, isCurrent: false));
            addSeparator();
            children.add(
              Semantics(
                button: true,
                label: 'Show all breadcrumbs',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      unawaited(
                        ConsonaFeedbackScope.maybeOf(context)?.trigger(
                          FeedbackEvent.tap,
                        ),
                      );
                      setState(() => _expandedManually = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ConsonaSpacing.xs,
                        vertical: ConsonaSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius:
                            theme.radius.resolve(ConsonaRadiusRole.micro),
                        border: theme.border.resolve(
                          ConsonaBorderRole.subtle,
                          context: context,
                        ),
                      ),
                      child: Text(
                        '…',
                        style: theme.typography.caption.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            addSeparator();
            final lastIdx = widget.items.length - 1;
            children.add(_buildCrumb(context, lastIdx, isCurrent: true));
          } else {
            for (int i = 0; i < widget.items.length; i++) {
              if (i > 0) addSeparator();
              children.add(
                _buildCrumb(
                  context,
                  i,
                  isCurrent: i == widget.items.length - 1,
                ),
              );
            }
          }

          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: ConsonaSpacing.xxs,
            children: children,
          );
        },
      ),
    );
  }

  Widget _buildCrumb(
    BuildContext context,
    int index, {
    required bool isCurrent,
  }) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final item = widget.items[index];
    final isHovered = _hoveredIndex == index;
    final isInteractive = !isCurrent && item.onTap != null;

    final fg = isCurrent
        ? colors.foreground
        : isHovered
            ? colors.primary
            : colors.mutedFg;

    return Semantics(
      button: isInteractive,
      selected: isCurrent,
      label: item.label,
      child: MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() {
          if (_hoveredIndex == index) _hoveredIndex = null;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isInteractive
              ? () {
                  unawaited(
                    ConsonaFeedbackScope.maybeOf(context)?.trigger(
                      FeedbackEvent.selection,
                    ),
                  );
                  item.onTap!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ConsonaSpacing.xxs,
              vertical: ConsonaSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(size: 14, color: fg),
                    child: item.icon!,
                  ),
                  const SizedBox(width: ConsonaSpacing.xxs),
                ],
                Text(
                  item.label,
                  style: theme.typography.label.copyWith(
                    color: fg,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
