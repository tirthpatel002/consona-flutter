/// Consona NumberField — Typed numeric input with clamp, step, decimals, and optional steppers.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../input/text_field.dart';

/// Typed numeric field for amounts, quantities, and measurements.
///
/// Complements [ConsonaCounter] (tactile stepper). Use this when the user
/// needs to type a precise value with validation, prefixes/suffixes, and
/// optional +/- steppers.
class ConsonaNumberField extends StatefulWidget {
  const ConsonaNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.min,
    this.max,
    this.step = 1,
    this.decimalPlaces = 0,
    this.prefix,
    this.suffix,
    this.showSteppers = false,
    this.enabled = true,
    this.size,
    this.allowNegative,
    this.focusNode,
  }) : assert(decimalPlaces >= 0);

  final num? value;
  final ValueChanged<num?> onChanged;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final num? min;
  final num? max;
  final num step;
  final int decimalPlaces;
  final String? prefix;
  final String? suffix;
  final bool showSteppers;
  final bool enabled;
  final ConsonaOpticalSize? size;
  final bool? allowNegative;
  final FocusNode? focusNode;

  @override
  State<ConsonaNumberField> createState() => _ConsonaNumberFieldState();
}

class _ConsonaNumberFieldState extends State<ConsonaNumberField> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsFocus = false;
  String? _localError;
  bool _syncing = false;

  bool get _negativeAllowed =>
      widget.allowNegative ??
      (widget.min == null ? true : widget.min! < 0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocus = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ConsonaNumberField oldWidget) {
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
    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      final next = _format(widget.value);
      if (_controller.text != next) {
        _syncing = true;
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        _syncing = false;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocus) _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(num? value) {
    if (value == null) return '';
    if (widget.decimalPlaces == 0) {
      return value.round().toString();
    }
    return value.toStringAsFixed(widget.decimalPlaces);
  }

  num? _parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-' || trimmed == '.' || trimmed == '-.') {
      return null;
    }
    return num.tryParse(trimmed);
  }

  num? _clamp(num? value) {
    if (value == null) return null;
    var next = value;
    if (widget.min != null) next = math.max(widget.min!.toDouble(), next.toDouble());
    if (widget.max != null) next = math.min(widget.max!.toDouble(), next.toDouble());
    if (widget.decimalPlaces == 0) return next.round();
    final factor = math.pow(10, widget.decimalPlaces);
    return (next * factor).round() / factor;
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final parsed = _parse(_controller.text);
      final clamped = _clamp(parsed);
      final formatted = _format(clamped);
      if (_controller.text != formatted) {
        _syncing = true;
        _controller.text = formatted;
        _syncing = false;
      }
      if (clamped != widget.value) {
        widget.onChanged(clamped);
      }
      _validate(clamped, emitEmptyAsNull: true);
    }
    if (mounted) setState(() {});
  }

  void _validate(num? value, {bool emitEmptyAsNull = false}) {
    String? error;
    if (value == null && _controller.text.trim().isNotEmpty) {
      error = 'Enter a valid number';
    } else if (value != null) {
      if (widget.min != null && value < widget.min!) {
        error = 'Must be ≥ ${widget.min}';
      } else if (widget.max != null && value > widget.max!) {
        error = 'Must be ≤ ${widget.max}';
      }
    }
    if (_localError != error) {
      setState(() => _localError = error);
    }
  }

  void _onTextChanged(String text) {
    if (_syncing) return;
    final parsed = _parse(text);
    _validate(parsed);
    if (parsed != null || text.trim().isEmpty) {
      widget.onChanged(_clamp(parsed));
    }
  }

  void _nudge(num delta) {
    if (!widget.enabled) return;
    final current = _clamp(_parse(_controller.text) ?? widget.value ?? 0) ?? 0;
    final next = _clamp(current + delta);
    final formatted = _format(next);
    _syncing = true;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _syncing = false;
    widget.onChanged(next);
    _validate(next);
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    setState(() {});
  }

  List<TextInputFormatter> get _formatters {
    final pattern = widget.decimalPlaces == 0
        ? (_negativeAllowed ? r'^-?\d*$' : r'^\d*$')
        : (_negativeAllowed
            ? r'^-?\d*\.?\d*$'
            : r'^\d*\.?\d*$');
    return [
      FilteringTextInputFormatter.allow(RegExp(pattern)),
      _DecimalLimiter(widget.decimalPlaces),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final current = widget.value ?? _parse(_controller.text) ?? 0;
    final canDec =
        widget.enabled && (widget.min == null || current > widget.min!);
    final canInc =
        widget.enabled && (widget.max == null || current < widget.max!);
    final optical = (widget.size ?? ConsonaOpticalSize.sm).standardEquivalent;
    final side = ConsonaGeometries.heightFor(optical) * 0.62;

    Widget? trailing;
    if (widget.showSteppers) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.suffix != null) ...[
            Text(
              widget.suffix!,
              style: theme.typography.label.copyWith(color: colors.mutedFg),
            ),
            const SizedBox(width: ConsonaSpacing.xs),
          ],
          _StepperChip(
            icon: Icons.remove_rounded,
            enabled: canDec,
            side: side,
            onTap: () => _nudge(-widget.step),
          ),
          const SizedBox(width: ConsonaSpacing.xxs),
          _StepperChip(
            icon: Icons.add_rounded,
            enabled: canInc,
            side: side,
            onTap: () => _nudge(widget.step),
          ),
        ],
      );
    } else if (widget.suffix != null) {
      trailing = Text(
        widget.suffix!,
        style: theme.typography.label.copyWith(color: colors.mutedFg),
      );
    }

    return ConsonaTextField(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      placeholder: widget.placeholder ?? '0',
      helperText: widget.helperText ??
          (widget.min != null || widget.max != null
              ? [
                  if (widget.min != null) 'min ${widget.min}',
                  if (widget.max != null) 'max ${widget.max}',
                ].join(' · ')
              : null),
      errorText: widget.errorText ?? _localError,
      enabled: widget.enabled,
      size: widget.size,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimalPlaces > 0,
        signed: _negativeAllowed,
      ),
      textInputAction: TextInputAction.done,
      inputFormatters: _formatters,
      onChanged: _onTextChanged,
      leading: widget.prefix != null
          ? Text(
              widget.prefix!,
              style: theme.typography.label.copyWith(color: colors.mutedFg),
            )
          : null,
      trailing: trailing,
    );
  }
}

class _StepperChip extends StatelessWidget {
  const _StepperChip({
    required this.icon,
    required this.enabled,
    required this.side,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final double side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: enabled
                ? colors.surfaceSecondary
                : colors.surfaceSecondary.withAlpha(0),
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
            border: theme.border.resolve(
              ConsonaBorderRole.subtle,
              context: context,
            ),
          ),
          child: Icon(
            icon,
            size: side * 0.55,
            color: enabled ? colors.foreground : colors.mutedFg.withAlpha(100),
          ),
        ),
      ),
    );
  }
}

class _DecimalLimiter extends TextInputFormatter {
  _DecimalLimiter(this.decimalPlaces);

  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (decimalPlaces <= 0) return newValue;
    final text = newValue.text;
    final dot = text.indexOf('.');
    if (dot == -1) return newValue;
    final decimals = text.length - dot - 1;
    if (decimals <= decimalPlaces) return newValue;
    return oldValue;
  }
}
