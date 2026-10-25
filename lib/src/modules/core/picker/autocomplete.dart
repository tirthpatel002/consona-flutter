/// Consona Autocomplete — Typeahead combobox with anchored suggestion overlay.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../input/text_field.dart';

/// Typeahead field that filters [items] as the user types and commits a
/// selection via tap or keyboard (↑/↓ + Enter, Escape to dismiss).
class ConsonaAutocomplete<T> extends StatefulWidget {
  const ConsonaAutocomplete({
    super.key,
    required this.items,
    required this.onSelected,
    this.value,
    this.label,
    this.placeholder = 'Search…',
    this.helperText,
    this.errorText,
    this.itemLabelBuilder,
    this.filter,
    this.maxSuggestions = 8,
    this.enabled = true,
    this.clearOnSelect = false,
    this.size,
    this.focusNode,
    this.onQueryChanged,
    this.emptyBuilder,
  });

  final List<T> items;
  final ValueChanged<T> onSelected;
  final T? value;
  final String? label;
  final String placeholder;
  final String? helperText;
  final String? errorText;
  final String Function(T item)? itemLabelBuilder;
  final bool Function(T item, String query)? filter;
  final int maxSuggestions;
  final bool enabled;
  final bool clearOnSelect;
  final ConsonaOpticalSize? size;
  final FocusNode? focusNode;
  final ValueChanged<String>? onQueryChanged;
  final WidgetBuilder? emptyBuilder;

  @override
  State<ConsonaAutocomplete<T>> createState() => _ConsonaAutocompleteState<T>();
}

class _ConsonaAutocompleteState<T> extends State<ConsonaAutocomplete<T>> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsFocus = false;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlay;
  List<T> _filtered = const [];
  int _highlight = -1;
  bool _open = false;

  String _labelOf(T item) =>
      widget.itemLabelBuilder?.call(item) ?? item.toString();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? _labelOf(widget.value as T) : '',
    );
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocus = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ConsonaAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocus) _focusNode.dispose();
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _ownsFocus = true;
      } else {
        _focusNode = widget.focusNode!;
        _ownsFocus = false;
      }
      _focusNode.addListener(_onFocusChange);
    }
    if (widget.value != oldWidget.value &&
        !_focusNode.hasFocus &&
        widget.value != null) {
      final next = _labelOf(widget.value as T);
      if (_controller.text != next) {
        _controller.text = next;
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocus) _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _refreshFilter(_controller.text);
      _showOverlay();
    } else {
      // Delay close so list taps register before focus loss.
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) return;
        _removeOverlay();
      });
    }
  }

  List<T> _computeFiltered(String query) {
    final q = query.trim().toLowerCase();
    final matcher = widget.filter ??
        (T item, String raw) =>
            _labelOf(item).toLowerCase().contains(raw.toLowerCase());
    final results = <T>[];
    for (final item in widget.items) {
      if (q.isEmpty || matcher(item, q)) {
        results.add(item);
        if (results.length >= widget.maxSuggestions) break;
      }
    }
    return results;
  }

  void _refreshFilter(String query) {
    final next = _computeFiltered(query);
    setState(() {
      _filtered = next;
      _highlight = next.isEmpty ? -1 : 0;
    });
    _overlay?.markNeedsBuild();
  }

  void _onChanged(String text) {
    widget.onQueryChanged?.call(text);
    _refreshFilter(text);
    if (!_open) _showOverlay();
  }

  void _select(T item) {
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    if (widget.clearOnSelect) {
      _controller.clear();
    } else {
      _controller.text = _labelOf(item);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    widget.onSelected(item);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    if (!widget.enabled || !mounted) return;
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlay = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlay!);
    setState(() => _open = true);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (_open && mounted) {
      setState(() => _open = false);
    } else {
      _open = false;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_open &&
        (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      _showOverlay();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      return KeyEventResult.handled;
    }
    if (_filtered.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlight = (_highlight + 1).clamp(0, _filtered.length - 1);
      });
      _overlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlight = (_highlight - 1).clamp(0, _filtered.length - 1);
      });
      _overlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlight >= 0 && _highlight < _filtered.length) {
        _select(_filtered[_highlight]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = ConsonaTheme.of(this.context);
    final colors = theme.colors;
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 280.0;
    final maxHeight = math.min(280.0, MediaQuery.sizeOf(this.context).height * 0.4);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, (box?.size.height ?? 44) + 4),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width,
                  minWidth: math.min(width, 200),
                  maxHeight: maxHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                    border: theme.border.resolve(
                      ConsonaBorderRole.surfaceEdge,
                      context: this.context,
                    ),
                    boxShadow: theme.shadow.resolve(ConsonaShadowLevel.soft),
                  ),
                  child: ClipRRect(
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                    child: _filtered.isEmpty
                        ? (widget.emptyBuilder?.call(this.context) ??
                            Padding(
                              padding: const EdgeInsets.all(ConsonaSpacing.md),
                              child: Text(
                                'No matches',
                                style: theme.typography.caption.copyWith(
                                  color: colors.mutedFg,
                                ),
                              ),
                            ))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              vertical: ConsonaSpacing.xs,
                            ),
                            shrinkWrap: true,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final item = _filtered[index];
                              final selected = index == _highlight;
                              return MouseRegion(
                                onEnter: (_) {
                                  setState(() => _highlight = index);
                                  _overlay?.markNeedsBuild();
                                },
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _select(item),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: ConsonaSpacing.md,
                                      vertical: ConsonaSpacing.sm,
                                    ),
                                    color: selected
                                        ? colors.surfaceSecondary
                                        : null,
                                    child: Text(
                                      _labelOf(item),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.typography.body.copyWith(
                                        color: colors.foreground,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: _onKey,
        child: ConsonaTextField(
          key: _fieldKey,
          controller: _controller,
          focusNode: _focusNode,
          label: widget.label,
          placeholder: widget.placeholder,
          helperText: widget.helperText,
          errorText: widget.errorText,
          enabled: widget.enabled,
          size: widget.size,
          clearable: true,
          onChanged: _onChanged,
          onSubmitted: (_) {
            if (_highlight >= 0 && _highlight < _filtered.length) {
              _select(_filtered[_highlight]);
            }
          },
        ),
      ),
    );
  }
}
