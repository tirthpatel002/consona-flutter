/// Consona PhoneField — Dual-cell international phone number input
/// with country flag anchor and masked number entry.
library;

import 'package:flutter/widgets.dart';

import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import 'country_picker.dart';

/// International phone number input well with country picker and vertical divider.
class ConsonaPhoneField extends StatefulWidget {
  const ConsonaPhoneField({
    super.key,
    this.initialCountry = const CountryCode(
      name: 'United States',
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
    ),
    this.controller,
    this.label = 'Phone Number',
    this.placeholder = '(555) 000-0000',
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onCountryChanged,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.size,
  });

  final CountryCode initialCountry;
  final TextEditingController? controller;
  final String label;
  final String placeholder;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<CountryCode>? onCountryChanged;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ConsonaOpticalSize? size;

  @override
  State<ConsonaPhoneField> createState() => _ConsonaPhoneFieldState();
}

class _ConsonaPhoneFieldState extends State<ConsonaPhoneField> {
  late CountryCode _selectedCountry = widget.initialCountry;
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

  Future<void> _openCountryPicker() async {
    if (!widget.enabled) return;
    final feedback = ConsonaFeedbackScope.of(context);
    await feedback.trigger(FeedbackEvent.tap);
    if (!mounted) return;
    final currentCountry = _selectedCountry;
    final selected = await ConsonaCountryPickerSheet.show(
      context,
      current: currentCountry,
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
      widget.onCountryChanged?.call(selected);
      await feedback.trigger(FeedbackEvent.selection);
    }
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
    final text = _effectiveController.text;

    final state = !isEnabled
        ? ConsonaInteractionState.disabled
        : hasError
            ? ConsonaInteractionState.error
            : isFocused
                ? ConsonaInteractionState.focused
                : ConsonaInteractionState.idle;

    final border = theme.border.resolve(
      ConsonaBorderRole.inputOutline,
      state: state,
    );

    final borderRadius = theme.radius.resolve(ConsonaRadiusRole.base);
    final focusGlow = isFocused && !hasError
        ? theme.shadow.focusGlow(colors.focusRing)
        : hasError
            ? theme.shadow.focusGlow(colors.danger)
            : theme.shadow.resolve(ConsonaShadowLevel.none);
    final size = widget.size ?? ConsonaSizeScope.of(context);
    final height = ConsonaGeometries.heightFor(size);
    final hPad = ConsonaGeometries.horizontalPaddingFor(size);
    final fontSize = ConsonaGeometries.fontSizeFor(size);
    final dividerH = ConsonaGeometries.iconSizeFor(size) + 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: ConsonaSpacing.xxs,
              bottom: ConsonaSpacing.sm,
            ),
            child: Text(
              widget.label,
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
          height: height,
          decoration: BoxDecoration(
            color: isEnabled ? colors.surface : colors.surfaceSecondary,
            borderRadius: borderRadius,
            border: border,
            boxShadow: focusGlow,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openCountryPicker,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: hPad,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: TextStyle(fontSize: fontSize + 2),
                      ),
                      const SizedBox(width: ConsonaSpacing.xs),
                      Text(
                        _selectedCountry.dialCode,
                        style: theme.typography.body.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w500,
                          fontSize: fontSize,
                          height: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: dividerH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      end: theme.border.resolveSide(
                        ConsonaBorderRole.divider,
                        context: context,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: hPad,
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      if (text.isEmpty && !isFocused) ...[
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
                        keyboardType: TextInputType.phone,
                        cursorColor: colors.primary,
                        backgroundCursorColor: colors.surface,
                        style: theme.typography.body.copyWith(
                          color: isEnabled ? colors.foreground : colors.mutedFg,
                          fontSize: fontSize,
                          height: 1.2,
                        ),
                        onChanged: widget.onChanged,
                      ),
                    ],
                  ),
                ),
              ),
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
