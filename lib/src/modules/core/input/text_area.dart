/// Consona TextArea — Auto-expanding multiline text well with character counter.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Multiline text area with auto-expanding lines and character counter.
class ConsonaTextArea extends StatefulWidget {
  const ConsonaTextArea({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 3,
    this.maxLines = 8,
    this.maxLength,
    this.showCounter = true,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  State<ConsonaTextArea> createState() => _ConsonaTextAreaState();
}

class _ConsonaTextAreaState extends State<ConsonaTextArea> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
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

    _effectiveController.addListener(_handleUpdate);
    _effectiveFocusNode.addListener(_handleUpdate);
  }

  void _handleUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
      ConsonaBorderRole.inputOutline,
      state: interactionState,
    );

    final borderRadius = theme.radius.resolve(ConsonaRadiusRole.base);
    final focusGlow = isFocused && !hasError
        ? theme.shadow.focusGlow(colors.focusRing)
        : hasError
            ? theme.shadow.focusGlow(colors.danger)
            : theme.shadow.resolve(ConsonaShadowLevel.none);

    final text = _effectiveController.text;
    final length = text.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: ConsonaSpacing.xxs,
              bottom: ConsonaSpacing.sm,
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
        AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          decoration: BoxDecoration(
            color: isEnabled ? colors.surface : colors.surfaceSecondary,
            borderRadius: borderRadius,
            border: border,
            boxShadow: focusGlow,
          ),
          padding: const EdgeInsets.all(ConsonaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.topLeft,
                children: [
                  if (text.isEmpty && !isFocused && widget.placeholder != null) ...[
                    Text(
                      widget.placeholder!,
                      style: theme.typography.body.copyWith(
                        color: colors.mutedFg,
                      ),
                    ),
                  ],
                  EditableText(
                    controller: _effectiveController,
                    focusNode: _effectiveFocusNode,
                    readOnly: widget.readOnly || !isEnabled,
                    keyboardType: TextInputType.multiline,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    cursorColor: colors.primary,
                    backgroundCursorColor: colors.surface,
                    style: theme.typography.body.copyWith(
                      color: isEnabled ? colors.foreground : colors.mutedFg,
                    ),
                    onChanged: widget.onChanged,
                  ),
                ],
              ),
              if (widget.showCounter && widget.maxLength != null) ...[
                const SizedBox(height: ConsonaSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$length / ${widget.maxLength}',
                    style: theme.typography.caption.copyWith(
                      color: length > (widget.maxLength ?? 0)
                          ? colors.danger
                          : colors.mutedFg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError || widget.helperText != null) ...[
          const SizedBox(height: ConsonaSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
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
}
