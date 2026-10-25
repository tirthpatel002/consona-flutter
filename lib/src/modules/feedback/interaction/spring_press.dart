/// Consona Spring Press — Micro-spring tactile press interaction wrapper
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/motion.dart';
import '../../../theme/theme_provider.dart';
import '../engine/feedback_engine.dart';
import '../models/feedback_event.dart';

class ConsonaSpringPress extends StatefulWidget {
  const ConsonaSpringPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onPressedChanged,
    this.onHoverChanged,
    this.onFocusChanged,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.enabled = true,
    this.pressedScale = 0.975,
    this.feedbackEvent = FeedbackEvent.tap,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called with `true` on touch-down and `false` on release/cancel so the
  /// wrapped component can render its `pressed` interaction state.
  final ValueChanged<bool>? onPressedChanged;

  /// Called when pointer hover state changes on desktop/web.
  final ValueChanged<bool>? onHoverChanged;

  /// Called when keyboard focus highlight state changes.
  final ValueChanged<bool>? onFocusChanged;

  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final bool enabled;
  final double pressedScale;
  final FeedbackEvent? feedbackEvent;

  @override
  State<ConsonaSpringPress> createState() => _ConsonaSpringPressState();
}

class _ConsonaSpringPressState extends State<ConsonaSpringPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _bouncy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _buildAnimation();
  }

  void _buildAnimation() {
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: _bouncy ? Curves.easeOutBack : Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(ConsonaSpringPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressedScale != widget.pressedScale) {
      _buildAnimation();
    }
    if (oldWidget.enabled && !widget.enabled && _isPressed) {
      _release();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_isPressed == pressed) return;
    _isPressed = pressed;
    widget.onPressedChanged?.call(pressed);
  }

  void _release() {
    _setPressed(false);
    if (_controller.status != AnimationStatus.dismissed) {
      _controller.reverse();
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _setPressed(true);
    _controller.forward();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    _release();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    // Prefer GestureDetector.onTap (arena-winner) over onTapUp — inside
    // ListView/PageView, onTapUp often never fires after a cancel.
    _release();
    if (widget.feedbackEvent != null) {
      final engine = FeedbackEngine.maybeOf(context);
      if (engine != null) {
        unawaited(engine.trigger(widget.feedbackEvent!));
      }
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (!widget.enabled) return;
    _release();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final motion = theme.motion.resolve(ConsonaMotionRole.press, context);
    final reduced = motion.duration == Duration.zero;
    final isInteractive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    // The motion knob drives both press speed and the release character
    // (bouncy overshoots, crisp/soft settle without overshoot).
    final bouncy = theme.motion.softness == ConsonaMotionSoftness.bouncy;
    if (bouncy != _bouncy) {
      _bouncy = bouncy;
      _buildAnimation();
    }
    if (!reduced) {
      _controller.duration = motion.duration;
      _controller.reverseDuration = motion.duration * 1.8;
    }

    return FocusableActionDetector(
      enabled: isInteractive,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: widget.mouseCursor ??
          (isInteractive ? SystemMouseCursors.click : MouseCursor.defer),
      onShowHoverHighlight: widget.onHoverChanged,
      onShowFocusHighlight: widget.onFocusChanged,
      actions: <Type, Action<Intent>>{
        if (widget.enabled && widget.onTap != null)
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: isInteractive ? _handleTapDown : null,
        onTapUp: isInteractive && widget.onTap == null
            ? (_) => _release()
            : null,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled && widget.onTap != null ? _handleTap : null,
        onLongPress:
            widget.enabled && widget.onLongPress != null ? _handleLongPress : null,
        child: reduced
            ? widget.child
            : AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: widget.child,
              ),
      ),
    );
  }
}

/// Tracks a `pressed` flag for a component and hands it to [builder] together
/// with the callback to wire into [ConsonaSpringPress.onPressedChanged].
class ConsonaPressStateBuilder extends StatefulWidget {
  const ConsonaPressStateBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    bool pressed,
    ValueChanged<bool> onPressedChanged,
  ) builder;

  @override
  State<ConsonaPressStateBuilder> createState() =>
      _ConsonaPressStateBuilderState();
}

class _ConsonaPressStateBuilderState extends State<ConsonaPressStateBuilder> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _pressed, _set);
}

/// Tracks `pressed`, `hovered`, and `focused` flags for a component and
/// resolves the effective [ConsonaInteractionState].
class ConsonaInteractionStateBuilder extends StatefulWidget {
  const ConsonaInteractionStateBuilder({
    super.key,
    this.disabled = false,
    this.interactive = true,
    required this.builder,
  });

  final bool disabled;
  final bool interactive;
  final Widget Function(
    BuildContext context,
    ConsonaInteractionState state,
    ValueChanged<bool> onPressedChanged,
    ValueChanged<bool> onHoverChanged,
    ValueChanged<bool> onFocusChanged,
  ) builder;

  @override
  State<ConsonaInteractionStateBuilder> createState() =>
      _ConsonaInteractionStateBuilderState();
}

class _ConsonaInteractionStateBuilderState
    extends State<ConsonaInteractionStateBuilder> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value || !mounted) return;
    setState(() => _hovered = value);
  }

  void _setFocused(bool value) {
    if (_focused == value || !mounted) return;
    setState(() => _focused = value);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.disabled
        ? ConsonaInteractionState.disabled
        : !widget.interactive
            ? ConsonaInteractionState.idle
            : _pressed
                ? ConsonaInteractionState.pressed
                : _focused
                    ? ConsonaInteractionState.focused
                    : _hovered
                        ? ConsonaInteractionState.hovered
                        : ConsonaInteractionState.idle;
    return widget.builder(
      context,
      state,
      _setPressed,
      _setHovered,
      _setFocused,
    );
  }
}

