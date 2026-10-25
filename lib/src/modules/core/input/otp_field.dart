/// Consona OtpField — Multi-cell PIN input with auto-advance, backspace handling,
/// paste parsing, and tactile feedback.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

enum ConsonaOtpVariant {
  box,
  underline,
}

/// Tactile OTP / PIN entry component with auto-advance and paste handling.
class ConsonaOtpField extends StatefulWidget {
  const ConsonaOtpField({
    super.key,
    this.length = 6,
    this.value = '',
    this.onChanged,
    this.onCompleted,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = true,
    this.variant = ConsonaOtpVariant.box,
    this.size,
  });

  final int length;
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final ConsonaOtpVariant variant;
  final ConsonaOpticalSize? size;

  @override
  State<ConsonaOtpField> createState() => _ConsonaOtpFieldState();
}

class _ConsonaOtpFieldState extends State<ConsonaOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _initCells();

    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.enabled) return;
        final target = widget.value.length.clamp(0, widget.length - 1);
        _focusNodes[target].requestFocus();
      });
    }
  }

  void _initCells() {
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(
        text: i < widget.value.length ? widget.value[i] : '',
      ),
    );

    _focusNodes = List.generate(
      widget.length,
      (i) => FocusNode(
        onKeyEvent: (node, event) => _handleKeyEvent(i, event),
      ),
    );

    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _disposeCells() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant ConsonaOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      _disposeCells();
      _initCells();
      return;
    }
    if (widget.value == _combinedValue()) return;
    _syncing = true;
    for (var i = 0; i < widget.length; i++) {
      final next = i < widget.value.length ? widget.value[i] : '';
      if (_controllers[i].text != next) {
        _controllers[i].value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    _syncing = false;
  }

  @override
  void dispose() {
    _disposeCells();
    super.dispose();
  }

  String _combinedValue() =>
      _controllers.map((c) => c.text).join().replaceAll(RegExp(r'\D'), '');

  KeyEventResult _handleKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _emit();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onCellChanged(int index, String text) {
    if (_syncing) return;

    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Pasted multiple digits into a cell
      _distributePasted(index, digits);
      return;
    }

    if (digits.isNotEmpty) {
      _controllers[index].text = digits.substring(digits.length - 1);
      ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      _controllers[index].clear();
    }

    _emit();
  }

  void _distributePasted(int startIndex, String digits) {
    _syncing = true;
    // If user pastes a full length OTP, always fill from index 0
    final effectiveStart = digits.length >= widget.length ? 0 : startIndex;

    for (var i = 0; i < widget.length; i++) {
      if (i >= effectiveStart && (i - effectiveStart) < digits.length) {
        _controllers[i].text = digits[i - effectiveStart];
      }
    }
    _syncing = false;

    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);

    final targetFocus = (effectiveStart + digits.length).clamp(0, widget.length - 1);
    if (targetFocus < widget.length - 1) {
      _focusNodes[targetFocus].requestFocus();
    } else {
      _focusNodes[widget.length - 1].unfocus();
    }

    _emit();
  }

  void _emit() {
    final value = _combinedValue();
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.success);
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: ConsonaSpacing.sm),
              _buildCell(context, i, theme),
            ],
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: ConsonaSpacing.sm),
          Text(
            widget.errorText!,
            style: theme.typography.caption.copyWith(
              color: colors.danger,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCell(BuildContext context, int index, ConsonaThemeData theme) {
    final colors = theme.colors;
    final isFocused = _focusNodes[index].hasFocus;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isEnabled = widget.enabled;
    final motion = theme.motion.resolve(ConsonaMotionRole.focus, context);

    final state = !isEnabled
        ? ConsonaInteractionState.disabled
        : hasError
            ? ConsonaInteractionState.error
            : isFocused
                ? ConsonaInteractionState.focused
                : ConsonaInteractionState.idle;

    final border = widget.variant == ConsonaOtpVariant.underline
        ? Border(
            bottom: theme.border.resolveSide(
              ConsonaBorderRole.inputOutline,
              state: state,
              context: context,
            ),
          )
        : theme.border.resolve(ConsonaBorderRole.inputOutline, state: state);

    final borderRadius = widget.variant == ConsonaOtpVariant.underline
        ? BorderRadius.zero
        : theme.radius.resolve(ConsonaRadiusRole.base);

    final focusGlow = isFocused && !hasError && widget.variant == ConsonaOtpVariant.box
        ? theme.shadow.focusGlow(colors.focusRing)
        : theme.shadow.resolve(ConsonaShadowLevel.none);

    final size = widget.size ?? ConsonaSizeScope.of(context);
    final side = ConsonaGeometries.heightFor(size) + ConsonaSpacing.xs;
    final fontSize = ConsonaGeometries.fontSizeFor(size) + 2;

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: isEnabled ? colors.surface : colors.surfaceSecondary,
        borderRadius: borderRadius,
        border: border,
        boxShadow: focusGlow,
      ),
      alignment: Alignment.center,
      child: EditableText(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        readOnly: !isEnabled,
        obscureText: widget.obscureText,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        cursorColor: colors.primary,
        backgroundCursorColor: colors.surface,
        style: theme.typography.titleLarge.copyWith(
          color: isEnabled ? colors.foreground : colors.mutedFg,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          height: 1.0,
        ),
        onChanged: (text) => _onCellChanged(index, text),
      ),
    );
  }
}
