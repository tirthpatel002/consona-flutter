/// Consona PasswordField — Password input with animated eye toggle,
/// password strength indicator, and caps-lock detection.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import 'text_field.dart';

enum PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong,
}

/// Password field with eye visibility toggle and password strength bar.
class ConsonaPasswordField extends StatefulWidget {
  const ConsonaPasswordField({
    super.key,
    this.controller,
    this.label = 'Password',
    this.placeholder = '••••••••',
    this.helperText,
    this.errorText,
    this.showStrengthMeter = false,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.size,
  });

  final TextEditingController? controller;
  final String label;
  final String placeholder;
  final String? helperText;
  final String? errorText;
  final bool showStrengthMeter;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ConsonaOpticalSize? size;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<ConsonaPasswordField> createState() => _ConsonaPasswordFieldState();
}

class _ConsonaPasswordFieldState extends State<ConsonaPasswordField> {
  late TextEditingController _effectiveController;
  late FocusNode _effectiveFocusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _obscure = true;
  bool _capsLock = false;

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
      _effectiveFocusNode = FocusNode(
        onKeyEvent: _handleKeyEvent,
      );
      _ownsFocusNode = true;
    } else {
      _effectiveFocusNode = widget.focusNode!;
    }

    _effectiveController.addListener(_handleUpdate);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isCapsLock = HardwareKeyboard.instance.lockModesEnabled
        .contains(KeyboardLockMode.capsLock);
    if (isCapsLock != _capsLock) {
      setState(() => _capsLock = isCapsLock);
    }
    return KeyEventResult.ignored;
  }

  void _handleUpdate() {
    if (mounted) setState(() {});
  }

  void _toggleObscure() {
    setState(() => _obscure = !_obscure);
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
  }

  PasswordStrength _evaluateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~-]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score == 2 || score == 3) return PasswordStrength.fair;
    if (score == 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleUpdate);
    if (_ownsController) _effectiveController.dispose();
    if (_ownsFocusNode) _effectiveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final text = _effectiveController.text;
    final strength = _evaluateStrength(text);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConsonaTextField(
          controller: _effectiveController,
          focusNode: _effectiveFocusNode,
          label: widget.label,
          placeholder: widget.placeholder,
          helperText: widget.helperText,
          errorText: widget.errorText,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          size: widget.size,
          obscureText: _obscure,
          keyboardType: TextInputType.visiblePassword,
          leading: Icon(
            Icons.lock_outline_rounded,
            size: ConsonaGeometries.iconSizeFor(
              widget.size ?? ConsonaOpticalSize.sm,
            ),
            color: colors.mutedFg,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_capsLock) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ConsonaSpacing.xs,
                    vertical: ConsonaSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning.withAlpha((255 * 0.15).round()),
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
                  ),
                  child: Text(
                    'CAPS',
                    style: theme.typography.caption.copyWith(
                      color: colors.warning,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: ConsonaSpacing.xs),
              ],
              GestureDetector(
                onTap: _toggleObscure,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: ConsonaGeometries.iconSizeFor(ConsonaOpticalSize.sm),
                    color: colors.mutedFg,
                  ),
                ),
              ),
            ],
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
        if (widget.showStrengthMeter && text.isNotEmpty) ...[
          const SizedBox(height: ConsonaSpacing.sm),
          _buildStrengthMeter(theme, strength),
        ],
      ],
    );
  }

  Widget _buildStrengthMeter(ConsonaThemeData theme, PasswordStrength strength) {
    final colors = theme.colors;
    final (strengthText, strengthColor, activeCount) = switch (strength) {
      PasswordStrength.none => ('', colors.mutedFg, 0),
      PasswordStrength.weak => ('Weak', colors.danger, 1),
      PasswordStrength.fair => ('Fair', colors.warning, 2),
      PasswordStrength.good => ('Good', colors.primary, 3),
      PasswordStrength.strong => ('Strong', colors.success, 4),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: ConsonaSpacing.xs),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 3.0,
                  decoration: BoxDecoration(
                    color: i < activeCount ? strengthColor : colors.borderLight,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ConsonaSpacing.xxs),
        Text(
          strengthText,
          style: theme.typography.caption.copyWith(
            color: strengthColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
