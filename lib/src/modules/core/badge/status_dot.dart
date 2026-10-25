/// Consona StatusDot — Presence / health indicator with harmonic pulse and optional label.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Semantic presence / health states mapped onto [ConsonaIntent] colors.
enum ConsonaStatusKind {
  online,
  offline,
  busy,
  away,
  custom,
}

/// Compact status indicator with optional breathing pulse and adjacent label.
///
/// Distinct from [ConsonaBadge.dot]: this is a first-class presence atom with
/// size roles, ring chrome, and accessible labels — not an overlay badge.
class ConsonaStatusDot extends StatefulWidget {
  const ConsonaStatusDot({
    super.key,
    this.kind = ConsonaStatusKind.custom,
    this.intent,
    this.size = ConsonaOpticalSize.sm,
    this.pulse = false,
    this.ring = false,
    this.label,
    this.semanticsLabel,
  });

  const ConsonaStatusDot.online({
    super.key,
    this.size = ConsonaOpticalSize.sm,
    this.pulse = true,
    this.ring = false,
    this.label,
    this.semanticsLabel = 'Online',
  })  : kind = ConsonaStatusKind.online,
        intent = ConsonaIntent.success;

  const ConsonaStatusDot.offline({
    super.key,
    this.size = ConsonaOpticalSize.sm,
    this.pulse = false,
    this.ring = false,
    this.label,
    this.semanticsLabel = 'Offline',
  })  : kind = ConsonaStatusKind.offline,
        intent = ConsonaIntent.subtle;

  const ConsonaStatusDot.busy({
    super.key,
    this.size = ConsonaOpticalSize.sm,
    this.pulse = true,
    this.ring = false,
    this.label,
    this.semanticsLabel = 'Busy',
  })  : kind = ConsonaStatusKind.busy,
        intent = ConsonaIntent.danger;

  const ConsonaStatusDot.away({
    super.key,
    this.size = ConsonaOpticalSize.sm,
    this.pulse = false,
    this.ring = false,
    this.label,
    this.semanticsLabel = 'Away',
  })  : kind = ConsonaStatusKind.away,
        intent = ConsonaIntent.warning;

  final ConsonaStatusKind kind;
  final ConsonaIntent? intent;
  final ConsonaOpticalSize size;
  final bool pulse;
  final bool ring;
  final String? label;
  final String? semanticsLabel;

  @override
  State<ConsonaStatusDot> createState() => _ConsonaStatusDotState();
}

class _ConsonaStatusDotState extends State<ConsonaStatusDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  ConsonaIntent get _resolvedIntent {
    if (widget.intent != null) return widget.intent!;
    return switch (widget.kind) {
      ConsonaStatusKind.online => ConsonaIntent.success,
      ConsonaStatusKind.busy => ConsonaIntent.danger,
      ConsonaStatusKind.away => ConsonaIntent.warning,
      ConsonaStatusKind.offline || ConsonaStatusKind.custom =>
        ConsonaIntent.subtle,
    };
  }

  double get _dotSize {
    final optical = widget.size.standardEquivalent;
    return switch (optical) {
      ConsonaOpticalSize.xs => 6.0,
      ConsonaOpticalSize.sm => 8.0,
      ConsonaOpticalSize.md => 10.0,
      ConsonaOpticalSize.lg => 12.0,
      _ => 8.0,
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _startPulse();
  }

  void _startPulse() {
    _pulseController?.dispose();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(covariant ConsonaStatusDot oldWidget) {
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
    final colors = theme.colors;
    final intentColors = colors.resolveIntent(_resolvedIntent);
    final scale = theme.density.factor;
    final diameter = _dotSize * scale;
    final ringPad = widget.ring ? 2.0 * scale : 0.0;

    Color fill = intentColors.fill;
    if (widget.kind == ConsonaStatusKind.offline && widget.intent == null) {
      fill = colors.mutedFg.withAlpha((255 * 0.45).round());
    }

    Widget core = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: widget.kind == ConsonaStatusKind.offline
            ? Border.all(
                color: colors.border,
                width: theme.stroke.resolveWidth(context),
              )
            : null,
      ),
    );

    if (widget.pulse && _pulseAnimation != null) {
      core = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1.0 - _pulseAnimation!.value) * 0.55,
                child: Transform.scale(
                  scale: 1.0 + (_pulseAnimation!.value * 0.85),
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Opacity(opacity: 0.55 + (_pulseAnimation!.value * 0.45), child: child),
            ],
          );
        },
        child: core,
      );
    }

    if (widget.ring) {
      core = Container(
        padding: EdgeInsets.all(ringPad),
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: theme.border.resolve(
            ConsonaBorderRole.surfaceEdge,
            context: context,
          ),
        ),
        child: core,
      );
    }

    final label = widget.label;
    final semantics = widget.semanticsLabel ??
        label ??
        widget.kind.name;

    final content = label == null
        ? core
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              core,
              SizedBox(width: ConsonaSpacing.xs * scale),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      label: semantics,
      container: true,
      child: ExcludeSemantics(child: content),
    );
  }
}
