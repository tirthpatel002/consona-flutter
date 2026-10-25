/// Consona Switch — Soft squash-and-stretch thumb animation with bi-tonal cues & labeled variant
library;

import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../../../core/animation.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/models/feedback_event.dart';

class ConsonaSwitch extends StatefulWidget {
  const ConsonaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.showLabels = false,
    this.onLabel = 'ON',
    this.offLabel = 'OFF',
  });

  const ConsonaSwitch.labeled({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.onLabel = 'ON',
    this.offLabel = 'OFF',
  }) : showLabels = true;

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final bool showLabels;
  final String onLabel;
  final String offLabel;

  @override
  State<ConsonaSwitch> createState() => _ConsonaSwitchState();
}

class _ConsonaSwitchState extends State<ConsonaSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _positionAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.value ? 1.0 : 0.0,
    );
    _positionAnimation = CurvedAnimation(
      parent: _controller,
      curve: ConsonaCurves.subtleEase,
      reverseCurve: ConsonaCurves.subtleEase,
    );
  }

  @override
  void didUpdateWidget(ConsonaSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.disabled || widget.onChanged == null) return;
    setState(() => _isPressed = false);
    final newValue = !widget.value;
    FeedbackEngine.of(context).trigger(
      newValue ? FeedbackEvent.toggleOn : FeedbackEvent.toggleOff,
    );
    widget.onChanged!(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !widget.disabled && widget.onChanged != null;

    // The motion knob drives the thumb's speed and curve (crisp / soft / bouncy).
    final motion = theme.motion.resolve(ConsonaMotionRole.toggle, context);
    _controller.duration = motion.duration;
    _positionAnimation.curve = motion.curve;
    _positionAnimation.reverseCurve = motion.curve;

    // Track border
    final border = theme.border.resolve(
      ConsonaBorderRole.inputOutline,
      state: widget.disabled
          ? ConsonaInteractionState.disabled
          : ConsonaInteractionState.idle,
      context: context,
    );

    return Semantics(
      toggled: widget.value,
      enabled: isInteractive,
      child: ConsonaHitTarget(
        child: FocusableActionDetector(
          enabled: isInteractive,
          mouseCursor:
              isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
          actions: <Type, Action<Intent>>{
            if (isInteractive)
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _handleTap();
                  return null;
                },
              ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown:
                isInteractive ? (_) => setState(() => _isPressed = true) : null,
            onTap: isInteractive ? _handleTap : null,
            onTapCancel:
                isInteractive ? () => setState(() => _isPressed = false) : null,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _positionAnimation.value;
                final tc =
                    t.clamp(0.0, 1.0); // curves may overshoot; colors must not

                if (widget.showLabels) {
                  // Sliding Glider Switch: No circular thumb.
                  // A sliding pill glider acts as the background for the active text.
                  const double trackWidth = 70.0;
                  const double trackHeight = 28.0;
                  const double padding = 3.0;
                  const double innerWidth = trackWidth - (padding * 2); // 64.0
                  const double slotWidth = innerWidth / 2.0; // 32.0
                  const double gliderWidth = slotWidth; // 32.0
                  const double gliderHeight =
                      trackHeight - (padding * 2); // 22.0
                  const double gliderTop = padding; // 3.0

                  final double gliderStart = padding + (slotWidth * tc);

                  final gliderColor = theme.colors.primary;
                  final activeTextColor = theme.colors.onPrimary;
                  final inactiveTextColor = theme.colors.mutedFg;

                  final offTextColor = Color.lerp(
                    activeTextColor,
                    inactiveTextColor,
                    tc,
                  )!;

                  final onTextColor = Color.lerp(
                    inactiveTextColor,
                    activeTextColor,
                    tc,
                  )!;

                  return Opacity(
                    opacity: widget.disabled
                        ? ConsonaOpacities.disabled
                        : ConsonaOpacities.opaque,
                    child: SizedBox(
                      width: trackWidth,
                      height: trackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Track background & border (does not inset the Stack coordinates)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colors.surfaceSecondary,
                                borderRadius:
                                    BorderRadius.circular(ConsonaRadii.full),
                                border: border,
                              ),
                            ),
                          ),

                          // 1. Sliding glider background (moves between OFF at start and ON at end)
                          PositionedDirectional(
                            top: gliderTop,
                            start: gliderStart,
                            width: gliderWidth,
                            height: gliderHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: gliderColor,
                                borderRadius:
                                    BorderRadius.circular(ConsonaRadii.full),
                                boxShadow: theme.shadow
                                    .resolve(ConsonaShadowLevel.subtle),
                              ),
                            ),
                          ),

                          // 2. Labels side by side over the glider (in exact same inset coordinate plane)
                          PositionedDirectional(
                            top: padding,
                            start: padding,
                            end: padding,
                            bottom: padding,
                            child: ExcludeSemantics(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        widget.offLabel,
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: tc < 0.5
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: offTextColor,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        widget.onLabel,
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: tc >= 0.5
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: onTextColor,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Standard Switch with circular squash-and-stretch thumb
                const double trackWidth = 48.0;
                const double trackHeight = 28.0;
                const double thumbBaseSize = 22.0;
                const double padding = 3.0;
                const double thumbTop =
                    (trackHeight - thumbBaseSize) / 2.0; // exactly 3.0

                final inactiveTrackColor = theme.colors.surfaceSecondary;
                final activeTrackColor = theme.colors.primary;
                final trackColor =
                    Color.lerp(inactiveTrackColor, activeTrackColor, tc)!;

                // Continuous fluid squash-and-stretch:
                // Thumb elongates at peak velocity mid-flight (smooth sine arc),
                // expanding gently from its moving center, and settles to rest at the stops.
                final flightStretch = math.sin(tc * math.pi) * 3.5;
                final pressStretch = _isPressed ? 4.0 : 0.0;
                final thumbWidth = thumbBaseSize + flightStretch + pressStretch;

                const double maxTravel =
                    trackWidth - thumbBaseSize - (padding * 2);
                final thumbCenter =
                    padding + (thumbBaseSize / 2.0) + (maxTravel * t);
                final thumbStart = thumbCenter - (thumbWidth / 2.0);

                final thumbColor = Color.lerp(
                  theme.colors.foreground,
                  theme.colors.onPrimary,
                  tc,
                )!;

                return Opacity(
                  opacity: widget.disabled
                      ? ConsonaOpacities.disabled
                      : ConsonaOpacities.opaque,
                  child: SizedBox(
                    width: trackWidth,
                    height: trackHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Track background & border (does not inset the Stack coordinate space)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: trackColor,
                              borderRadius:
                                  BorderRadius.circular(ConsonaRadii.full),
                              border: border,
                            ),
                          ),
                        ),
                        // Centered thumb
                        PositionedDirectional(
                          top: thumbTop,
                          start: thumbStart.clamp(
                              padding, trackWidth - thumbWidth - padding),
                          child: Container(
                            width: thumbWidth,
                            height: thumbBaseSize,
                            decoration: BoxDecoration(
                              color: thumbColor,
                              borderRadius:
                                  BorderRadius.circular(ConsonaRadii.full),
                              boxShadow: theme.shadow
                                  .resolve(ConsonaShadowLevel.subtle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
