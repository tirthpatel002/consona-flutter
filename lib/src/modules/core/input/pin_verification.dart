/// Consona PinVerification — Composite OTP verification card with countdown timer.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../button/button.dart';
import 'otp_field.dart';

/// High-level PIN / OTP verification composite combining [ConsonaOtpField],
/// header/subtitle text, a live resend countdown timer, and action buttons.
class ConsonaPinVerification extends StatefulWidget {
  const ConsonaPinVerification({
    super.key,
    this.title = 'Verify Security Code',
    this.subtitle = 'Enter the 6-digit code sent to your device.',
    this.length = 6,
    this.value = '',
    this.onChanged,
    this.onCompleted,
    this.onResend,
    this.resendCooldownSeconds = 30,
    this.errorText,
    this.autofocus = false,
  });

  final String title;
  final String? subtitle;
  final int length;
  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final VoidCallback? onResend;
  final int resendCooldownSeconds;
  final String? errorText;
  final bool autofocus;

  @override
  State<ConsonaPinVerification> createState() => _ConsonaPinVerificationState();
}

class _ConsonaPinVerificationState extends State<ConsonaPinVerification> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.resendCooldownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _handleResend() {
    if (_remainingSeconds > 0) return;
    widget.onResend?.call();
    setState(() => _remainingSeconds = widget.resendCooldownSeconds);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    return Container(
      padding: EdgeInsets.all(ConsonaSpacing.lg * scale),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
        border: theme.border.resolve(
          ConsonaBorderRole.surfaceEdge,
          context: context,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.typography.titleMedium.copyWith(
              color: colors.foreground,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: ConsonaSpacing.xxs),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: theme.typography.caption.copyWith(
                color: colors.mutedFg,
              ),
            ),
          ],
          SizedBox(height: ConsonaSpacing.base * scale),
          ConsonaOtpField(
            length: widget.length,
            value: widget.value,
            autofocus: widget.autofocus,
            errorText: widget.errorText,
            onChanged: widget.onChanged,
            onCompleted: widget.onCompleted,
          ),
          SizedBox(height: ConsonaSpacing.base * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_remainingSeconds > 0)
                Text(
                  'Resend code in ${_remainingSeconds}s',
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )
              else
                ConsonaButton.subtle(
                  label: 'Resend Code',
                  size: ConsonaOpticalSize.sm,
                  onTap: _handleResend,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
