/// Consona Badge — Dot status with harmonic breathing pulse and count pill
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../typography/text.dart';

class ConsonaBadge extends StatefulWidget {
  const ConsonaBadge({
    super.key,
    this.label,
    this.count,
    this.intent = ConsonaIntent.primary,
    this.pulse = false,
    this.isDot = false,
  });

  final String? label;
  final int? count;
  final ConsonaIntent intent;
  final bool pulse;
  final bool isDot;

  const ConsonaBadge.dot({
    super.key,
    this.intent = ConsonaIntent.success,
    this.pulse = true,
  })  : label = null,
        count = null,
        isDot = true;

  @override
  State<ConsonaBadge> createState() => _ConsonaBadgeState();
}

class _ConsonaBadgeState extends State<ConsonaBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _startPulse();
    }
  }

  void _startPulse() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(ConsonaBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) {
      if (widget.pulse) {
        _startPulse();
      } else {
        _pulseController?.dispose();
        _pulseController = null;
        _pulseAnimation = null;
      }
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors.resolveIntent(widget.intent);

    if (widget.isDot) {
      Widget dot = Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
          color: colors.fill,
          shape: BoxShape.circle,
        ),
      );

      if (widget.pulse && _pulseAnimation != null) {
        dot = AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) => Opacity(
            opacity: _pulseAnimation!.value,
            child: child,
          ),
          child: dot,
        );
      }

      return dot;
    }

    final displayText =
        widget.count != null ? widget.count.toString() : (widget.label ?? '');

    return Container(
      padding: theme.density.resolvePadding(
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      ),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
        border:
            theme.border.resolve(ConsonaBorderRole.subtle, context: context),
      ),
      child: ConsonaText.label(
        displayText,
        color: colors.content,
        tabularFigures: true,
      ),
    );
  }
}
