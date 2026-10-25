/// Consona Counter — Tactile stepper with spring-rolling digits and hold-to-repeat.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Compact stepper with minus/plus buttons and hold-to-repeat acceleration.
///
/// The center value uses spring-driven rolling digit columns (same recipe as
/// `@consona/interface` Counter: stiffness 600 / damping 38 / mass 0.3).
class ConsonaCounter extends StatefulWidget {
  const ConsonaCounter({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.enabled = true,
    this.size = ConsonaOpticalSize.sm,
    this.stiffness = 600,
    this.damping = 38,
    this.mass = 0.3,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final ConsonaOpticalSize size;

  /// Spring stiffness for digit rolls. Default matches interface Counter.
  final double stiffness;

  /// Spring damping for digit rolls.
  final double damping;

  /// Spring mass for digit rolls.
  final double mass;

  @override
  State<ConsonaCounter> createState() => _ConsonaCounterState();
}

class _ConsonaCounterState extends State<ConsonaCounter> {
  Timer? _repeatTimer;
  int _repeatSpeedMs = 250;

  void _increment() {
    if (widget.value + widget.step <= widget.max && widget.enabled) {
      widget.onChanged(widget.value + widget.step);
      ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    }
  }

  void _decrement() {
    if (widget.value - widget.step >= widget.min && widget.enabled) {
      widget.onChanged(widget.value - widget.step);
      ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
    }
  }

  void _startRepeat(bool isIncrement) {
    if (!widget.enabled) return;
    _repeatSpeedMs = 250;
    if (isIncrement) {
      _increment();
    } else {
      _decrement();
    }

    _repeatTimer?.cancel();
    void scheduleNext() {
      _repeatTimer =
          Timer.periodic(Duration(milliseconds: _repeatSpeedMs), (timer) {
        if (!mounted || !widget.enabled) {
          timer.cancel();
          return;
        }
        if (isIncrement) {
          if (widget.value + widget.step <= widget.max) {
            _increment();
          } else {
            timer.cancel();
            return;
          }
        } else {
          if (widget.value - widget.step >= widget.min) {
            _decrement();
          } else {
            timer.cancel();
            return;
          }
        }
        if (_repeatSpeedMs > 60) {
          _repeatSpeedMs = (_repeatSpeedMs * 0.85).round();
          timer.cancel();
          scheduleNext();
        }
      });
    }

    scheduleNext();
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  /// Optical recipe locked to [ConsonaGeometries] so counters match inputs/buttons.
  _CounterGeometry _geometryFor(ConsonaOpticalSize size, double density) {
    final optical = size.standardEquivalent;
    final height = density * ConsonaGeometries.heightFor(optical);
    final inset = density *
        switch (optical) {
          ConsonaOpticalSize.xs => 2.0,
          ConsonaOpticalSize.sm => 2.0,
          ConsonaOpticalSize.md => 3.0,
          ConsonaOpticalSize.lg => 4.0,
          _ => 2.0,
        };
    final gap = density *
        switch (optical) {
          ConsonaOpticalSize.xs => 4.0,
          ConsonaOpticalSize.sm => 4.0,
          ConsonaOpticalSize.md => 6.0,
          ConsonaOpticalSize.lg => 8.0,
          _ => ConsonaSpacing.xs,
        };
    final padH = density *
        switch (optical) {
          ConsonaOpticalSize.xs => 4.0,
          ConsonaOpticalSize.sm => 6.0,
          ConsonaOpticalSize.md => 8.0,
          ConsonaOpticalSize.lg => 10.0,
          _ => ConsonaSpacing.sm,
        };
    final buttonSide = height - inset * 2;
    final iconOptical = switch (optical) {
      ConsonaOpticalSize.xs => ConsonaOpticalSize.xs,
      ConsonaOpticalSize.sm => ConsonaOpticalSize.xs,
      ConsonaOpticalSize.md => ConsonaOpticalSize.sm,
      ConsonaOpticalSize.lg => ConsonaOpticalSize.md,
      _ => optical,
    };
    final fontSize = density * ConsonaGeometries.fontSizeFor(optical);
    final btnRadius = optical == ConsonaOpticalSize.lg
        ? ConsonaRadiusRole.base
        : ConsonaRadiusRole.micro;

    return _CounterGeometry(
      height: height.roundToDouble(),
      inset: inset.roundToDouble(),
      gap: gap.roundToDouble(),
      padH: padH.roundToDouble(),
      buttonSide: buttonSide.roundToDouble(),
      iconSize: ConsonaGeometries.iconSizeFor(iconOptical) * density,
      fontSize: fontSize.roundToDouble(),
      buttonRadius: btnRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final isEnabled = widget.enabled;
    final geo = _geometryFor(widget.size, theme.density.factor);

    final canDecrement = isEnabled && widget.value > widget.min;
    final canIncrement = isEnabled && widget.value < widget.max;

    final digitCount = math.max(
      widget.min.abs().toString().length + (widget.min < 0 ? 1 : 0),
      widget.max.abs().toString().length + (widget.max < 0 ? 1 : 0),
    );
    final valueMinWidth =
        (digitCount * geo.fontSize * 0.62 + ConsonaSpacing.sm).roundToDouble();

    final valueStyle = theme.typography.titleMedium.copyWith(
      fontSize: geo.fontSize,
      height: 1.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: isEnabled ? colors.foreground : colors.mutedFg,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      value: '${widget.value}',
      increasedValue: canIncrement ? '${widget.value + widget.step}' : null,
      decreasedValue: canDecrement ? '${widget.value - widget.step}' : null,
      onIncrease: canIncrement ? _increment : null,
      onDecrease: canDecrement ? _decrement : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : ConsonaOpacities.disabled,
        child: Container(
          height: geo.height,
          padding: EdgeInsets.symmetric(horizontal: geo.padH),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
            border: theme.border.resolve(ConsonaBorderRole.subtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.remove_rounded,
                canTap: canDecrement,
                isIncrement: false,
                theme: theme,
                geo: geo,
              ),
              SizedBox(width: geo.gap),
              SizedBox(
                width: valueMinWidth,
                height: geo.buttonSide,
                child: Center(
                  child: ExcludeSemantics(
                    child: _RollingNumber(
                      value: widget.value,
                      style: valueStyle,
                      stiffness: widget.stiffness,
                      damping: widget.damping,
                      mass: widget.mass,
                    ),
                  ),
                ),
              ),
              SizedBox(width: geo.gap),
              _buildButton(
                icon: Icons.add_rounded,
                canTap: canIncrement,
                isIncrement: true,
                theme: theme,
                geo: geo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required bool canTap,
    required bool isIncrement,
    required ConsonaThemeData theme,
    required _CounterGeometry geo,
  }) {
    final colors = theme.colors;

    return GestureDetector(
      onTapDown: canTap ? (_) => _startRepeat(isIncrement) : null,
      onTapUp: (_) => _stopRepeat(),
      onTapCancel: _stopRepeat,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: geo.buttonSide,
        height: geo.buttonSide,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: canTap
                ? colors.surfaceSecondary.withAlpha(
                    (255 * ConsonaOpacities.subtle).round(),
                  )
                : colors.surfaceSecondary.withAlpha(0),
            borderRadius: theme.radius.resolve(geo.buttonRadius),
          ),
          child: Center(
            child: Icon(
              icon,
              size: geo.iconSize,
              color: canTap
                  ? colors.foreground
                  : colors.mutedFg.withAlpha((255 * 0.4).round()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spring-rolling numerical ticker — digit columns keyed from the right so
/// place-value identity is preserved when the digit count grows or shrinks.
class _RollingNumber extends StatelessWidget {
  const _RollingNumber({
    required this.value,
    required this.style,
    required this.stiffness,
    required this.damping,
    required this.mass,
  });

  final int value;
  final TextStyle style;
  final double stiffness;
  final double damping;
  final double mass;

  @override
  Widget build(BuildContext context) {
    final chars = value.toString().split('');
    final total = chars.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < chars.length; i++)
          _DigitColumn(
            key: ValueKey<int>(total - 1 - i),
            digit: chars[i],
            style: style,
            stiffness: stiffness,
            damping: damping,
            mass: mass,
          ),
      ],
    );
  }
}

class _DigitColumn extends StatefulWidget {
  const _DigitColumn({
    super.key,
    required this.digit,
    required this.style,
    required this.stiffness,
    required this.damping,
    required this.mass,
  });

  final String digit;
  final TextStyle style;
  final double stiffness;
  final double damping;
  final double mass;

  @override
  State<_DigitColumn> createState() => _DigitColumnState();
}

class _DigitColumnState extends State<_DigitColumn>
    with TickerProviderStateMixin {
  late final AnimationController _roll;
  late final AnimationController _enter;

  int? get _parsed => int.tryParse(widget.digit);

  SpringDescription get _spring => SpringDescription(
        mass: widget.mass,
        stiffness: widget.stiffness,
        damping: widget.damping,
      );

  @override
  void initState() {
    super.initState();
    _roll = AnimationController.unbounded(vsync: this)
      ..value = (_parsed ?? 0).toDouble();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _DigitColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _parsed;
    if (next == null) return;
    if (oldWidget.digit == widget.digit) return;

    _roll.animateWith(
      SpringSimulation(
        _spring,
        _roll.value,
        next.toDouble(),
        _roll.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _roll.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final em = widget.style.fontSize ?? 16.0;
    final width = em * 0.6;
    final parsed = _parsed;

    final enter = CurvedAnimation(parent: _enter, curve: Curves.easeOut);

    if (parsed == null) {
      return FadeTransition(
        opacity: enter,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(enter),
          child: SizedBox(
            height: em,
            child: Center(
              child: Text(
                widget.digit == ' ' ? '\u00A0' : widget.digit,
                style: widget.style,
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: enter,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(enter),
        child: SizedBox(
          width: width,
          height: em,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _roll,
              child: OverflowBox(
                maxHeight: em * 10,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var n = 0; n < 10; n++)
                      SizedBox(
                        width: width,
                        height: em,
                        child: Center(
                          child: Text('$n', style: widget.style),
                        ),
                      ),
                  ],
                ),
              ),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_roll.value * em),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterGeometry {
  const _CounterGeometry({
    required this.height,
    required this.inset,
    required this.gap,
    required this.padH,
    required this.buttonSide,
    required this.iconSize,
    required this.fontSize,
    required this.buttonRadius,
  });

  final double height;
  final double inset;
  final double gap;
  final double padH;
  final double buttonSide;
  final double iconSize;
  final double fontSize;
  final ConsonaRadiusRole buttonRadius;
}
