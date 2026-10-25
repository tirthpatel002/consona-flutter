/// Consona Select — Tap-to-sheet select picker with search option and token styling.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/drawer/drawer.dart';
import '../input/search_field.dart';

/// Tap-to-sheet picker well that opens a modal list sheet.
class ConsonaSelect<T> extends StatelessWidget {
  const ConsonaSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder = 'Select an option...',
    this.itemLabelBuilder,
    this.searchable = false,
    this.enabled = true,
  });

  final List<T> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? label;
  final String placeholder;
  final String Function(T item)? itemLabelBuilder;
  final bool searchable;
  final bool enabled;

  String _format(T item) => itemLabelBuilder?.call(item) ?? item.toString();

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final feedback = ConsonaFeedbackScope.of(context);
    await feedback.trigger(FeedbackEvent.tap);

    if (!context.mounted) return;
    final selected = await ConsonaDrawer.show<T>(
      context,
      snapPoints: const [0.55, 0.78],
      initialSnapIndex: 0,
      scrollable: false,
      header: ConsonaDrawerHeader(
        title: label ?? 'Select',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: _SelectSheet<T>(
        items: items,
        selected: value,
        itemLabelBuilder: _format,
        searchable: searchable,
        title: label ?? 'Select',
        embedded: true,
      ),
    );

    if (selected != null) {
      onChanged(selected);
      await feedback.trigger(FeedbackEvent.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final border = theme.border.resolve(
      ConsonaBorderRole.inputOutline,
      state: enabled ? ConsonaInteractionState.idle : ConsonaInteractionState.disabled,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: ConsonaSpacing.xxs,
              bottom: ConsonaSpacing.sm,
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
          value: value != null ? _format(value as T) : placeholder,
          child: FocusableActionDetector(
            enabled: enabled,
            mouseCursor:
                enabled ? SystemMouseCursors.click : MouseCursor.defer,
            actions: <Type, Action<Intent>>{
              if (enabled)
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _openPicker(context);
                    return null;
                  },
                ),
            },
            child: GestureDetector(
              onTap: () => _openPicker(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ConsonaSpacing.md,
                  vertical: ConsonaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: enabled ? colors.surface : colors.surfaceSecondary,
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                  border: border,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value != null ? _format(value as T) : placeholder,
                        style: theme.typography.body.copyWith(
                          color: value != null
                              ? colors.foreground
                              : colors.mutedFg,
                        ),
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

class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({
    required this.items,
    required this.selected,
    required this.itemLabelBuilder,
    required this.searchable,
    required this.title,
    this.embedded = false,
  });

  final List<T> items;
  final T? selected;
  final String Function(T item) itemLabelBuilder;
  final bool searchable;
  final String title;
  final bool embedded;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final filtered = widget.items.where((item) {
      if (_query.isEmpty) return true;
      final label = widget.itemLabelBuilder(item).toLowerCase();
      return label.contains(_query.toLowerCase());
    }).toList();

    final list = ListView.separated(
      shrinkWrap: !widget.embedded,
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 0 : ConsonaSpacing.md,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          border: theme.border.resolve(
            ConsonaBorderRole.divider,
            context: context,
          ),
        ),
      ),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final isSelected = widget.selected == item;
        final label = widget.itemLabelBuilder(item);

        return GestureDetector(
          onTap: () => Navigator.of(context).pop(item),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: isSelected ? colors.primary : colors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.all(ConsonaSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: theme.typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                        child: Icon(
                          Icons.close_rounded,
                          size: ConsonaGeometries.iconSizeFor(
                            ConsonaOpticalSize.sm,
                          ),
                          color: colors.mutedFg,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.searchable) ...[
                  const SizedBox(height: ConsonaSpacing.sm),
                  ConsonaSearchField(
                    placeholder: 'Search options...',
                    onChanged: (text) => setState(() => _query = text),
                  ),
                ],
              ],
            ),
          )
        else if (widget.searchable)
          Padding(
            padding: const EdgeInsets.only(bottom: ConsonaSpacing.sm),
            child: ConsonaSearchField(
              placeholder: 'Search options...',
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
        Expanded(child: list),
      ],
    );

    if (widget.embedded) {
      // Fill the drawer body (parent is SizedBox.expand when scrollable:false).
      return body;
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 500.0),
      margin: const EdgeInsets.all(ConsonaSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
        border: theme.border.resolve(ConsonaBorderRole.surfaceEdge),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
      ),
      child: SizedBox(height: 500, child: body),
    );
  }
}
