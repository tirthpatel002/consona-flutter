/// Consona TagInput — Token/chip input well with inline removable pills and suggestions.
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
import '../chip/chip.dart';

/// How selected tags arrange inside the input well.
enum ConsonaTagInputLayout {
  /// Tags flow onto new lines with an inline text field (default).
  wrap,

  /// Single horizontal row. Leading `+N` (when overflowing) and an **Add**
  /// chip sit before the tags; tapping Add expands into a text field and
  /// pushes the selected tags aside.
  row,
}

/// Multi-token input field that renders selected tags as inline removable
/// [ConsonaChip] pills alongside an inline text input and optional quick-add
/// suggestion chips.
class ConsonaTagInput extends StatefulWidget {
  const ConsonaTagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.label,
    this.placeholder = 'Add tag…',
    this.addLabel = 'Add',
    this.suggestions = const <String>[],
    this.maxTags,
    this.enabled = true,
    this.layout = ConsonaTagInputLayout.wrap,
    this.maxVisible = 3,
  });

  final List<String> tags;
  final ValueChanged<List<String>>? onChanged;
  final String? label;
  final String placeholder;

  /// Label for the leading add chip in [ConsonaTagInputLayout.row].
  final String addLabel;

  final List<String> suggestions;
  final int? maxTags;
  final bool enabled;

  /// [wrap] stacks tags; [row] keeps one scrollable line with `+N` / Add first.
  final ConsonaTagInputLayout layout;

  /// Visible-tag budget used for the leading `+N` cue in [ConsonaTagInputLayout.row].
  final int maxVisible;

  @override
  State<ConsonaTagInput> createState() => _ConsonaTagInputState();
}

class _ConsonaTagInputState extends State<ConsonaTagInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final ScrollController _rowScroll = ScrollController();
  bool _focused = false;
  bool _hovered = false;

  /// Row layout: Add chip → expanded text field.
  bool _composing = false;

  static const double _fieldHeight = 28.0;
  static const double _fieldMinWidth = 96.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final hasFocus = _focusNode.hasFocus;
    setState(() {
      _focused = hasFocus;
      if (!hasFocus &&
          widget.layout == ConsonaTagInputLayout.row &&
          _controller.text.trim().isEmpty) {
        _composing = false;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _rowScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConsonaTagInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _composing = false;
      _controller.clear();
    }
  }

  bool get _canAddMore =>
      widget.enabled &&
      widget.onChanged != null &&
      (widget.maxTags == null || widget.tags.length < widget.maxTags!);

  int get _overflowCount {
    final visible = widget.maxVisible.clamp(1, 99);
    return math.max(0, widget.tags.length - visible);
  }

  void _beginComposing() {
    if (!_canAddMore) return;
    setState(() => _composing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _commitTag(String raw, {bool keepComposing = false}) {
    if (!_canAddMore) return;
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) {
      if (widget.layout == ConsonaTagInputLayout.row && !keepComposing) {
        setState(() => _composing = false);
      }
      return;
    }
    if (widget.tags.any((t) => t.toLowerCase() == cleaned.toLowerCase())) {
      _controller.clear();
      setState(() {});
      return;
    }
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    _controller.clear();
    widget.onChanged!(<String>[...widget.tags, cleaned]);
    setState(() {
      if (widget.layout == ConsonaTagInputLayout.row) {
        _composing = keepComposing || _focusNode.hasFocus;
      }
    });
  }

  void _removeTag(String tag) {
    if (!widget.enabled || widget.onChanged == null) return;
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap),
    );
    widget.onChanged!(widget.tags.where((t) => t != tag).toList());
  }

  void _scrollRowForward() {
    if (!_rowScroll.hasClients) return;
    final next = (_rowScroll.offset + 120.0)
        .clamp(0.0, _rowScroll.position.maxScrollExtent);
    _rowScroll.animateTo(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.layout == ConsonaTagInputLayout.row &&
        _composing) {
      _controller.clear();
      _focusNode.unfocus();
      setState(() => _composing = false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty &&
        widget.tags.isNotEmpty &&
        (widget.layout == ConsonaTagInputLayout.wrap || _composing)) {
      _removeTag(widget.tags.last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildTagChip(String tag) {
    return ConsonaChip(
      label: tag,
      selected: true,
      compact: true,
      disabled: !widget.enabled,
      onDelete: widget.enabled ? () => _removeTag(tag) : null,
    );
  }

  Widget _buildInputField({
    required TextStyle textStyle,
    required TextStyle placeholderStyle,
    required Color cursorColor,
    required Color backgroundCursorColor,
    required double scale,
    double minWidth = _fieldMinWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        maxWidth: 200,
      ),
      child: SizedBox(
        height: _fieldHeight * scale,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              if (_controller.text.isEmpty)
                IgnorePointer(
                  child: Text(
                    widget.placeholder,
                    style: placeholderStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              EditableText(
                controller: _controller,
                focusNode: _focusNode,
                style: textStyle,
                cursorColor: cursorColor,
                backgroundCursorColor: backgroundCursorColor,
                maxLines: 1,
                onChanged: (val) {
                  if (val.endsWith(',')) {
                    _commitTag(val, keepComposing: true);
                  } else {
                    setState(() {});
                  }
                },
                onSubmitted: (val) => _commitTag(val, keepComposing: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWrapBody({
    required TextStyle textStyle,
    required TextStyle placeholderStyle,
    required Color cursorColor,
    required Color backgroundCursorColor,
    required double scale,
  }) {
    return Wrap(
      spacing: ConsonaSpacing.xs,
      runSpacing: ConsonaSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in widget.tags) _buildTagChip(tag),
        if (_canAddMore)
          _buildInputField(
            textStyle: textStyle,
            placeholderStyle: placeholderStyle,
            cursorColor: cursorColor,
            backgroundCursorColor: backgroundCursorColor,
            scale: scale,
          ),
      ],
    );
  }

  Widget _buildRowBody({
    required TextStyle textStyle,
    required TextStyle placeholderStyle,
    required Color cursorColor,
    required Color backgroundCursorColor,
    required double scale,
  }) {
    final overflow = _overflowCount;
    final gap = SizedBox(width: ConsonaSpacing.xs * scale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (overflow > 0) ...[
          ConsonaChip(
            label: '+$overflow',
            compact: true,
            selected: false,
            onTap: _scrollRowForward,
          ),
          gap,
        ],
        if (_canAddMore) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: _composing
                ? _buildInputField(
                    textStyle: textStyle,
                    placeholderStyle: placeholderStyle,
                    cursorColor: cursorColor,
                    backgroundCursorColor: backgroundCursorColor,
                    scale: scale,
                    minWidth: 120,
                  )
                : ConsonaChip(
                    label: '+ ${widget.addLabel}',
                    compact: true,
                    selected: false,
                    onTap: _beginComposing,
                  ),
          ),
          gap,
        ],
        Expanded(
          child: SingleChildScrollView(
            controller: _rowScroll,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < widget.tags.length; i++) ...[
                  if (i > 0) gap,
                  _buildTagChip(widget.tags[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    final interactionState = !widget.enabled
        ? ConsonaInteractionState.disabled
        : (_focused || _composing)
            ? ConsonaInteractionState.focused
            : _hovered
                ? ConsonaInteractionState.hovered
                : ConsonaInteractionState.idle;

    final availableSuggestions = widget.suggestions
        .where(
          (s) => !widget.tags.any((t) => t.toLowerCase() == s.toLowerCase()),
        )
        .toList();

    final textStyle = theme.typography.label.copyWith(
      color: colors.foreground,
      height: 1.2,
    );
    final placeholderStyle = theme.typography.label.copyWith(
      color: colors.mutedFg,
      height: 1.2,
    );

    final body = widget.layout == ConsonaTagInputLayout.row
        ? _buildRowBody(
            textStyle: textStyle,
            placeholderStyle: placeholderStyle,
            cursorColor: colors.primary,
            backgroundCursorColor: colors.surfaceSecondary,
            scale: scale,
          )
        : _buildWrapBody(
            textStyle: textStyle,
            placeholderStyle: placeholderStyle,
            cursorColor: colors.primary,
            backgroundCursorColor: colors.surfaceSecondary,
            scale: scale,
          );

    return Opacity(
      opacity: widget.enabled
          ? ConsonaOpacities.opaque
          : ConsonaOpacities.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label!,
                  style: theme.typography.label.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (widget.maxTags != null)
                  Text(
                    '${widget.tags.length}/${widget.maxTags}',
                    style: theme.typography.caption.copyWith(
                      color: colors.mutedFg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            SizedBox(height: ConsonaSpacing.xs * scale),
          ],
          MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: !widget.enabled
                  ? null
                  : () {
                      if (widget.layout == ConsonaTagInputLayout.row) {
                        if (!_composing) _beginComposing();
                      } else {
                        _focusNode.requestFocus();
                      }
                    },
              child: Focus(
                onKeyEvent: _handleKeyEvent,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ConsonaSpacing.xs * scale),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                    border: theme.border.resolve(
                      ConsonaBorderRole.inputOutline,
                      state: interactionState,
                      context: context,
                    ),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
          if (_canAddMore && availableSuggestions.isNotEmpty) ...[
            SizedBox(height: ConsonaSpacing.xs * scale),
            Wrap(
              spacing: ConsonaSpacing.xs,
              runSpacing: ConsonaSpacing.xs,
              children: [
                for (final suggestion in availableSuggestions)
                  ConsonaChip(
                    label: '+ $suggestion',
                    compact: true,
                    onTap: () {
                      if (widget.layout == ConsonaTagInputLayout.row) {
                        setState(() => _composing = false);
                      }
                      _commitTag(suggestion);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
