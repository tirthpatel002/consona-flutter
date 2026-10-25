/// Consona TextField — Tactile text input with floating label morph,
/// soft focus glow, clear affordance, and 3-cycle damped error shake.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/motion.dart';
import '../../../theme/radius.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Form text field well supporting floating label, error shake, and clear button.
class ConsonaTextField extends StatefulWidget {
  const ConsonaTextField({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.leading,
    this.trailing,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.floatingLabel = false,
    this.size,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final Widget? leading;
  final Widget? trailing;
  final bool clearable;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool floatingLabel;

  /// Optical size — defaults to ambient [ConsonaSizeScope] (sm).
  final ConsonaOpticalSize? size;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final int minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<ConsonaTextField> createState() => _ConsonaTextFieldState();
}

class _ConsonaTextFieldState extends State<ConsonaTextField>
    with TickerProviderStateMixin {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  late AnimationController _shakeController;
  late AnimationController _labelController;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _ownsController = true;
    } else {
      _effectiveController = widget.controller!;
    }

    if (widget.focusNode == null) {
      _effectiveFocusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _effectiveFocusNode = widget.focusNode!;
    }

    _effectiveController.addListener(_handleTextChange);
    _effectiveFocusNode.addListener(_handleFocusChange);

    // 3-cycle damped error shake controller (duration resolved in didChangeDependencies/trigger)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: _shouldFloatLabel ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant ConsonaTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      if (widget.controller == null) {
        _effectiveController = TextEditingController();
        _ownsController = true;
      } else {
        if (_ownsController) {
          _effectiveController.dispose();
          _ownsController = false;
        }
        _effectiveController = widget.controller!;
      }
      _effectiveController.addListener(_handleTextChange);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null) {
        _effectiveFocusNode = FocusNode();
        _ownsFocusNode = true;
      } else {
        if (_ownsFocusNode) {
          _effectiveFocusNode.dispose();
          _ownsFocusNode = false;
        }
        _effectiveFocusNode = widget.focusNode!;
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }

    if (widget.errorText != oldWidget.errorText &&
        widget.errorText != null &&
        widget.errorText!.isNotEmpty) {
      _triggerErrorShake();
    }

    _updateLabelState();
  }

  bool get _shouldFloatLabel {
    if (!widget.floatingLabel || widget.label == null) return false;
    return _effectiveFocusNode.hasFocus || _effectiveController.text.isNotEmpty;
  }

  void _updateLabelState() {
    final shouldFloat = _shouldFloatLabel;
    if (shouldFloat && _labelController.value < 1.0) {
      _labelController.forward();
    } else if (!shouldFloat && _labelController.value > 0.0) {
      _labelController.reverse();
    }
  }

  void _handleTextChange() {
    _updateLabelState();
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    _updateLabelState();
    if (mounted) setState(() {});
  }

  void _triggerErrorShake() {
    _shakeController.forward(from: 0.0);
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.error);
  }

  void _clearText() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    if (!_effectiveFocusNode.hasFocus) {
      _effectiveFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChange);
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (_ownsController) _effectiveController.dispose();
    if (_ownsFocusNode) _effectiveFocusNode.dispose();
    _shakeController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final inputTheme = theme.components.input;
    final motion = theme.motion.resolve(ConsonaMotionRole.focus, context);
    final isFocused = _effectiveFocusNode.hasFocus;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isEnabled = widget.enabled;

    final interactionState = !isEnabled
        ? ConsonaInteractionState.disabled
        : hasError
            ? ConsonaInteractionState.error
            : isFocused
                ? ConsonaInteractionState.focused
                : ConsonaInteractionState.idle;

    final border = theme.border.resolve(
      inputTheme.borderRole ?? ConsonaBorderRole.inputOutline,
      state: interactionState,
    );

    final effectiveRadius = inputTheme.radius != null
        ? ConsonaRadius.fromPreset(inputTheme.radius!)
        : theme.radius;
    final borderRadius = effectiveRadius.resolve(ConsonaRadiusRole.base);
    final focusGlow = isFocused && !hasError
        ? theme.shadow.focusGlow(colors.focusRing)
        : hasError
            ? theme.shadow.focusGlow(colors.danger)
            : theme.shadow.resolve(ConsonaShadowLevel.none);

    final effectiveSize =
        widget.size ?? inputTheme.defaultSize ?? ConsonaSizeScope.of(context);

    // 3-cycle damped sine wave: x(t) = A * exp(-4t) * sin(6 * pi * t)
    final shakeAnimation = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final offset = t == 0.0 || t == 1.0
            ? 0.0
            : 10.0 * math.exp(-4.0 * t) * math.sin(6.0 * math.pi * t);
        return Transform.translate(
          offset: Offset(offset, 0.0),
          child: child,
        );
      },
      child: _buildWell(
        theme: theme,
        border: border,
        borderRadius: borderRadius,
        focusGlow: focusGlow,
        motion: motion,
        size: effectiveSize,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: theme.density.resolvePadding(
              const EdgeInsets.only(
                left: ConsonaSpacing.xxs,
                bottom: ConsonaSpacing.sm,
              ),
            ),
            child: Text(
              widget.label!,
              style: theme.typography.labelSmall.copyWith(
                color: hasError ? colors.danger : colors.mutedFg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shakeAnimation,
        if (hasError || widget.helperText != null) ...[
          const SizedBox(height: ConsonaSpacing.xs),
          Padding(
            padding: theme.density.resolvePadding(
              const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
            ),
            child: Text(
              hasError ? widget.errorText! : widget.helperText!,
              style: theme.typography.caption.copyWith(
                color: hasError ? colors.danger : colors.mutedFg,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWell({
    required ConsonaThemeData theme,
    required BoxBorder? border,
    required BorderRadiusGeometry borderRadius,
    required List<BoxShadow> focusGlow,
    required ConsonaMotionSpec motion,
    required ConsonaOpticalSize size,
  }) {
    final colors = theme.colors;
    final isEnabled = widget.enabled;
    final isFocused = _effectiveFocusNode.hasFocus;
    final hasText = _effectiveController.text.isNotEmpty;
    final height = ConsonaGeometries.heightFor(size);
    final hPad = ConsonaGeometries.horizontalPaddingFor(size);
    final iconSize = ConsonaGeometries.iconSizeFor(size);
    final fontSize = ConsonaGeometries.fontSizeFor(size);
    final multiLine = widget.maxLines > 1;

    final formatters = <TextInputFormatter>[
      if (widget.inputFormatters != null) ...widget.inputFormatters!,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ];

    final inputField = EditableText(
      controller: _effectiveController,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly || !isEnabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: formatters.isEmpty ? null : formatters,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      cursorColor: colors.primary,
      backgroundCursorColor: colors.surface,
      style: theme.typography.body.copyWith(
        color: isEnabled ? colors.foreground : colors.mutedFg,
        fontSize: fontSize,
        height: 1.2,
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
    );

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      decoration: BoxDecoration(
        color: isEnabled ? colors.surface : colors.surfaceSecondary,
        borderRadius: borderRadius,
        border: border,
        boxShadow: focusGlow,
      ),
      padding: hPad.copyWith(
        top: multiLine ? ConsonaSpacing.sm : 0,
        bottom: multiLine ? ConsonaSpacing.sm : 0,
      ),
      constraints: BoxConstraints(
        minHeight: multiLine ? height + ConsonaSpacing.md : height,
      ),
      height: multiLine ? null : height,
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            IconTheme(
              data: IconThemeData(size: iconSize, color: colors.mutedFg),
              child: widget.leading!,
            ),
            SizedBox(width: ConsonaSpacing.sm * (size == ConsonaOpticalSize.xs ? 0.75 : 1)),
          ],
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                if (!hasText && !isFocused && widget.placeholder != null) ...[
                  Text(
                    widget.placeholder!,
                    style: theme.typography.body.copyWith(
                      color: colors.mutedFg,
                      fontSize: fontSize,
                      height: 1.2,
                    ),
                  ),
                ],
                inputField,
              ],
            ),
          ),
          if (widget.clearable && hasText && isEnabled && !widget.readOnly) ...[
            GestureDetector(
              onTap: _clearText,
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
          if (widget.trailing != null) ...[
            const SizedBox(width: ConsonaSpacing.xs),
            IconTheme(
              data: IconThemeData(size: iconSize, color: colors.mutedFg),
              child: widget.trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
