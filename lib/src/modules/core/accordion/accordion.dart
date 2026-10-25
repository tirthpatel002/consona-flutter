/// Consona Accordion — Height expansion accordion with rotating caret and spring physics.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

class ConsonaAccordionItem {
  const ConsonaAccordionItem({
    required this.id,
    required this.title,
    required this.content,
    this.subtitle,
    this.leading,
  });

  final String id;
  final Widget title;
  final Widget content;
  final Widget? subtitle;
  final Widget? leading;
}

/// Expandable accordion list container.
class ConsonaAccordion extends StatefulWidget {
  const ConsonaAccordion({
    super.key,
    required this.items,
    this.initiallyExpanded = const {},
    this.allowMultiple = false,
    this.onExpandedChanged,
  });

  final List<ConsonaAccordionItem> items;
  final Set<String> initiallyExpanded;
  final bool allowMultiple;
  final ValueChanged<Set<String>>? onExpandedChanged;

  @override
  State<ConsonaAccordion> createState() => _ConsonaAccordionState();
}

class _ConsonaAccordionState extends State<ConsonaAccordion> {
  late Set<String> _expandedIds;

  @override
  void initState() {
    super.initState();
    _expandedIds = Set.from(widget.initiallyExpanded);
  }

  void _toggle(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        if (!widget.allowMultiple) {
          _expandedIds.clear();
        }
        _expandedIds.add(id);
      }
    });
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    widget.onExpandedChanged?.call(_expandedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
        border: theme.border.resolve(ConsonaBorderRole.subtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0)
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: theme.border.resolve(
                      ConsonaBorderRole.divider,
                      context: context,
                    ),
                  ),
                ),
              ),
            _AccordionRow(
              item: widget.items[i],
              isExpanded: _expandedIds.contains(widget.items[i].id),
              onTap: () => _toggle(widget.items[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccordionRow extends StatelessWidget {
  const _AccordionRow({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final ConsonaAccordionItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.toggle, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: isExpanded,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  onTap();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(ConsonaSpacing.md),
                child: Row(
                  children: [
                    if (item.leading != null) ...[
                      item.leading!,
                      const SizedBox(width: ConsonaSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          item.title,
                          if (item.subtitle != null) ...[
                            const SizedBox(height: ConsonaSpacing.xxs),
                            item.subtitle!,
                          ],
                        ],
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: isExpanded ? math.pi / 2 : 0.0),
                      duration: motion.duration,
                      curve: motion.curve,
                      builder: (context, angle, child) {
                        return Transform.rotate(
                          angle: angle,
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: ConsonaGeometries.iconSizeFor(
                            ConsonaOpticalSize.sm),
                        color: colors.mutedFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: ExcludeSemantics(
            excluding: !isExpanded,
            child: ExcludeFocus(
              excluding: !isExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ConsonaSpacing.md,
                  0.0,
                  ConsonaSpacing.md,
                  ConsonaSpacing.md,
                ),
                child: item.content,
              ),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: motion.duration,
          firstCurve: motion.curve,
          secondCurve: motion.curve,
        ),
      ],
    );
  }
}
