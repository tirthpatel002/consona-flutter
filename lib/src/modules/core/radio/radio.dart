/// Consona Radio — Radial contraction and spring bloom dot animation
library;

import 'package:flutter/widgets.dart';
import '../../../core/hit_target.dart';
import '../../../core/types.dart';
import '../../../theme/tokens.dart';
import '../../../theme/theme_provider.dart';
import '../../feedback/engine/feedback_engine.dart';
import '../../feedback/models/feedback_event.dart';

class ConsonaRadio<T> extends StatelessWidget {
  const ConsonaRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.disabled = false,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final bool disabled;

  bool get isSelected => value == groupValue;

  void _handleTap(BuildContext context) {
    if (disabled || onChanged == null) return;
    FeedbackEngine.of(context).trigger(FeedbackEvent.selection);
    onChanged!(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final isInteractive = !disabled && onChanged != null;

    const double outerSize = 22.0;
    const double dotSize = 8.0;

    final border = theme.border.resolve(
      ConsonaBorderRole.inputOutline,
      state: disabled
          ? ConsonaInteractionState.disabled
          : isSelected
              ? ConsonaInteractionState.selected
              : ConsonaInteractionState.idle,
      context: context,
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
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
                  _handleTap(context);
                  return null;
                },
              ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isInteractive ? () => _handleTap(context) : null,
            child: Opacity(
              opacity:
                  disabled ? ConsonaOpacities.disabled : ConsonaOpacities.opaque,
              child: Container(
                width: outerSize,
                height: outerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.surfaceSecondary,
                  border: isSelected ? null : border,
                ),
                alignment: Alignment.center,
                // The dot has a constant size and is scaled with AnimatedScale.
                // The previous implementation animated `width`/`height` through
                // AnimatedContainer with `Curves.easeOutBack`; when unchecking, that
                // curve overshoots below zero, producing a negative BoxConstraints
                // that throws during build and flashes Flutter's error text inside
                // the radio for a few frames.
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: theme.motion
                      .resolve(ConsonaMotionRole.toggle, context)
                      .duration,
                  curve: isSelected ? Curves.easeOutBack : Curves.easeOutCubic,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
