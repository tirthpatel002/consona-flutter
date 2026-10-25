/// Consona SearchField — Debounced search input with leading icon, clear button,
/// and trailing filter slot.
library;

import 'dart:async';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Search field well with debounced emission, clear affordance, and filter pill slot.
class ConsonaSearchField extends StatefulWidget {
  const ConsonaSearchField({
    super.key,
    this.controller,
    this.placeholder = 'Search...',
    this.initialValue = '',
    this.debounceDuration = const Duration(milliseconds: 250),
    this.onChanged,
    this.onDebouncedChanged,
    this.onSubmitted,
    this.filterSlot,
    this.size,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String placeholder;
  final String initialValue;
  final Duration debounceDuration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onDebouncedChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? filterSlot;
  final ConsonaOpticalSize? size;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<ConsonaSearchField> createState() => _ConsonaSearchFieldState();
}

class _ConsonaSearchFieldState extends State<ConsonaSearchField> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    } else {
      _effectiveController = widget.controller!;
      if (widget.initialValue.isNotEmpty && _effectiveController.text.isEmpty) {
        _effectiveController.text = widget.initialValue;
      }
    }

    if (widget.focusNode == null) {
      _effectiveFocusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _effectiveFocusNode = widget.focusNode!;
    }

    _effectiveController.addListener(_handleUpdate);
    _effectiveFocusNode.addListener(_handleUpdate);
  }

  void _handleUpdate() {
    if (mounted) setState(() {});
  }

  void _onTextChanged(String text) {
    widget.onChanged?.call(text);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (mounted) {
        widget.onDebouncedChanged?.call(text);
      }
    });
  }

  void _clear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    _debounceTimer?.cancel();
    widget.onDebouncedChanged?.call('');
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    if (!_effectiveFocusNode.hasFocus) {
      _effectiveFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _effectiveController.removeListener(_handleUpdate);
    _effectiveFocusNode.removeListener(_handleUpdate);
    if (_ownsController) _effectiveController.dispose();
    if (_ownsFocusNode) _effectiveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.focus, context);
    final isFocused = _effectiveFocusNode.hasFocus;
    final isEnabled = widget.enabled;
    final hasText = _effectiveController.text.isNotEmpty;

    final state = !isEnabled
        ? ConsonaInteractionState.disabled
        : isFocused
            ? ConsonaInteractionState.focused
            : ConsonaInteractionState.idle;

    final border = theme.border.resolve(
      ConsonaBorderRole.inputOutline,
      state: state,
    );

    final borderRadius = theme.radius.resolve(ConsonaRadiusRole.base);
    final focusGlow = isFocused
        ? theme.shadow.focusGlow(colors.focusRing)
        : theme.shadow.resolve(ConsonaShadowLevel.none);
    final size = widget.size ?? ConsonaSizeScope.of(context);
    final height = ConsonaGeometries.heightFor(size);
    final hPad = ConsonaGeometries.horizontalPaddingFor(size);
    final iconSize = ConsonaGeometries.iconSizeFor(size);
    final fontSize = ConsonaGeometries.fontSizeFor(size);

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      height: height,
      decoration: BoxDecoration(
        color: isEnabled ? colors.surface : colors.surfaceSecondary,
        borderRadius: borderRadius,
        border: border,
        boxShadow: focusGlow,
      ),
      padding: hPad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: iconSize,
            color: isFocused ? colors.primary : colors.mutedFg,
          ),
          const SizedBox(width: ConsonaSpacing.sm),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (!hasText && !isFocused) ...[
                  Text(
                    widget.placeholder,
                    style: theme.typography.body.copyWith(
                      color: colors.mutedFg,
                      fontSize: fontSize,
                      height: 1.2,
                    ),
                  ),
                ],
                EditableText(
                  controller: _effectiveController,
                  focusNode: _effectiveFocusNode,
                  autofocus: widget.autofocus,
                  readOnly: !isEnabled,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  cursorColor: colors.primary,
                  backgroundCursorColor: colors.surface,
                  style: theme.typography.body.copyWith(
                    color: isEnabled ? colors.foreground : colors.mutedFg,
                    fontSize: fontSize,
                    height: 1.2,
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ],
            ),
          ),
          if (hasText && isEnabled) ...[
            GestureDetector(
              onTap: _clear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                child: Icon(
                  Icons.close_rounded,
                  size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.xs),
                  color: colors.mutedFg,
                ),
              ),
            ),
          ],
          if (widget.filterSlot != null) ...[
            const SizedBox(width: ConsonaSpacing.xs),
            IconTheme(
              data: IconThemeData(size: iconSize, color: colors.mutedFg),
              child: widget.filterSlot!,
            ),
          ],
        ],
      ),
    );
  }
}
