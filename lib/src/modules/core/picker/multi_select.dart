/// Consona MultiSelect — Chip well + searchable multi-check drawer sheet.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/drawer/drawer.dart';
import '../button/button.dart';
import '../checkbox/checkbox.dart';
import '../chip/chip.dart';
import '../input/search_field.dart';

/// Multi-value picker that surfaces selections as removable chips and opens a
/// searchable checkbox sheet for adding/removing values.
class ConsonaMultiSelect<T> extends StatelessWidget {
  const ConsonaMultiSelect({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    this.label,
    this.placeholder = 'Select…',
    this.itemLabelBuilder,
    this.searchable = true,
    this.enabled = true,
    this.maxVisibleChips = 3,
  });

  final List<T> items;
  final Set<T> values;
  final ValueChanged<Set<T>> onChanged;
  final String? label;
  final String placeholder;
  final String Function(T item)? itemLabelBuilder;
  final bool searchable;
  final bool enabled;
  final int maxVisibleChips;

  String _format(T item) => itemLabelBuilder?.call(item) ?? item.toString();

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    await ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap);
    if (!context.mounted) return;

    final next = await ConsonaDrawer.show<Set<T>>(
      context,
      snapPoints: const [0.55, 0.82],
      initialSnapIndex: 0,
      scrollable: false,
      header: ConsonaDrawerHeader(
        title: label ?? 'Select',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: _MultiSelectSheet<T>(
        items: items,
        initial: values,
        itemLabelBuilder: _format,
        searchable: searchable,
      ),
    );

    if (next != null && context.mounted) {
      onChanged(next);
      await ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final selected = values.toList();
    final overflow = selected.length > maxVisibleChips
        ? selected.length - maxVisibleChips
        : 0;
    final visible = overflow > 0
        ? selected.take(maxVisibleChips).toList()
        : selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: ConsonaSpacing.xxs * scale,
              bottom: ConsonaSpacing.sm * scale,
            ),
            child: Text(
              label!,
              style: theme.typography.labelSmall.copyWith(
                color: colors.mutedFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: selected.isEmpty
              ? placeholder
              : selected.map(_format).join(', '),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(context),
            child: AnimatedOpacity(
              duration: theme.motion
                  .resolve(ConsonaMotionRole.focus, context)
                  .duration,
              opacity: enabled ? 1 : ConsonaOpacities.disabled,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: ConsonaSpacing.md * scale,
                  vertical: ConsonaSpacing.sm * scale,
                ),
                decoration: BoxDecoration(
                  color: enabled ? colors.surface : colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                  border: theme.border.resolve(
                    ConsonaBorderRole.inputOutline,
                    state: enabled
                        ? ConsonaInteractionState.idle
                        : ConsonaInteractionState.disabled,
                    context: context,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: selected.isEmpty
                          ? Text(
                              placeholder,
                              style: theme.typography.body
                                  .copyWith(color: colors.mutedFg),
                            )
                          : Wrap(
                              spacing: ConsonaSpacing.xs * scale,
                              runSpacing: ConsonaSpacing.xs * scale,
                              children: [
                                for (final item in visible)
                                  ConsonaChip(
                                    label: _format(item),
                                    compact: true,
                                    selected: true,
                                    onDelete: enabled
                                        ? () {
                                            final next = Set<T>.of(values)
                                              ..remove(item);
                                            onChanged(next);
                                          }
                                        : null,
                                  ),
                                if (overflow > 0)
                                  ConsonaChip(
                                    label: '+$overflow',
                                    compact: true,
                                    onTap: () => _open(context),
                                  ),
                              ],
                            ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
                      color: colors.mutedFg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  const _MultiSelectSheet({
    required this.items,
    required this.initial,
    required this.itemLabelBuilder,
    required this.searchable,
  });

  final List<T> items;
  final Set<T> initial;
  final String Function(T item) itemLabelBuilder;
  final bool searchable;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late Set<T> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.of(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final filtered = widget.items.where((item) {
      if (_query.isEmpty) return true;
      return widget.itemLabelBuilder(item).toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ConsonaSpacing.md,
              0,
              ConsonaSpacing.md,
              ConsonaSpacing.sm,
            ),
            child: ConsonaSearchField(
              placeholder: 'Filter…',
              size: ConsonaOpticalSize.sm,
              onChanged: (q) => setState(() => _query = q),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.md),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Container(
              height: theme.stroke.resolveWidth(context),
              color: colors.borderLight,
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final checked = _selected.contains(item);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    if (checked) {
                      _selected.remove(item);
                    } else {
                      _selected.add(item);
                    }
                  });
                  ConsonaFeedbackScope.maybeOf(context)
                      ?.trigger(FeedbackEvent.selection);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.sm),
                  child: Row(
                    children: [
                      ConsonaCheckbox(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v) {
                              _selected.add(item);
                            } else {
                              _selected.remove(item);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: ConsonaSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.itemLabelBuilder(item),
                          style: theme.typography.body.copyWith(
                            color: colors.foreground,
                            fontWeight:
                                checked ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(ConsonaSpacing.md),
          child: Row(
            children: [
              ConsonaButton.subtle(
                label: 'Clear',
                size: ConsonaOpticalSize.sm,
                onTap: () => setState(() => _selected.clear()),
              ),
              const Spacer(),
              ConsonaButton.primary(
                label: 'Done (${_selected.length})',
                size: ConsonaOpticalSize.sm,
                onTap: () => Navigator.of(context).pop(Set<T>.of(_selected)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
