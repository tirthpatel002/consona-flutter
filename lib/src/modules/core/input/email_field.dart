/// Consona EmailField — Specialized email input with built-in RFC validation
/// and quick domain completion chips.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import 'text_field.dart';

/// Specialized email field with RFC validation and domain suggestion chips.
class ConsonaEmailField extends StatefulWidget {
  const ConsonaEmailField({
    super.key,
    this.controller,
    this.label = 'Email',
    this.placeholder = 'name@example.com',
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.showDomainSuggestions = true,
    this.domainSuggestions = const ['@gmail.com', '@icloud.com', '@outlook.com'],
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.size,
  });

  final TextEditingController? controller;
  final String label;
  final String placeholder;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showDomainSuggestions;
  final List<String> domainSuggestions;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ConsonaOpticalSize? size;

  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  @override
  State<ConsonaEmailField> createState() => _ConsonaEmailFieldState();
}

class _ConsonaEmailFieldState extends State<ConsonaEmailField> {
  late TextEditingController _effectiveController;
  bool _ownsController = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _ownsController = true;
    } else {
      _effectiveController = widget.controller!;
    }
    _effectiveController.addListener(_validate);
  }

  void _validate() {
    final text = _effectiveController.text.trim();
    if (text.isEmpty) {
      if (_errorText != null) setState(() => _errorText = null);
      return;
    }

    if (text.contains('@') && !ConsonaEmailField.emailRegex.hasMatch(text)) {
      if (_errorText == null) {
        setState(() => _errorText = 'Enter a valid email address');
      }
    } else {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
    }
  }

  void _applyDomain(String domain) {
    final current = _effectiveController.text;
    final prefix = current.contains('@') ? current.split('@').first : current;
    final full = '$prefix$domain';
    _effectiveController.value = TextEditingValue(
      text: full,
      selection: TextSelection.collapsed(offset: full.length),
    );
    widget.onChanged?.call(full);
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_validate);
    if (_ownsController) _effectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final text = _effectiveController.text;
    final showChips = widget.showDomainSuggestions &&
        text.isNotEmpty &&
        !text.contains('@') &&
        widget.enabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConsonaTextField(
          controller: _effectiveController,
          focusNode: widget.focusNode,
          label: widget.label,
          placeholder: widget.placeholder,
          helperText: widget.helperText,
          errorText: _errorText,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          size: widget.size,
          keyboardType: TextInputType.emailAddress,
          clearable: true,
          leading: Icon(
            Icons.mail_outline_rounded,
            size: ConsonaGeometries.iconSizeFor(
              widget.size ?? ConsonaOpticalSize.sm,
            ),
            color: colors.mutedFg,
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
        if (showChips) ...[
          const SizedBox(height: ConsonaSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final domain in widget.domainSuggestions) ...[
                  GestureDetector(
                    onTap: () => _applyDomain(domain),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(right: ConsonaSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: ConsonaSpacing.sm,
                        vertical: ConsonaSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
                        border: theme.border.resolve(ConsonaBorderRole.subtle),
                      ),
                      child: Text(
                        domain,
                        style: theme.typography.caption.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
