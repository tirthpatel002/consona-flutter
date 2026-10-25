/// Consona Stepper — Multi-step progress and wizard navigation indicator.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/types.dart';
import '../../theme/motion.dart';
import '../../theme/theme_data.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../feedback/context/feedback_scope.dart';
import '../feedback/models/feedback_event.dart';

/// A single step definition for [ConsonaStepper].
@immutable
class ConsonaStep {
  const ConsonaStep({
    required this.title,
    this.subtitle,
    this.content,
    this.isCompleted = false,
    this.hasError = false,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final bool isCompleted;
  final bool hasError;
}

/// Multi-step progress and wizard navigation indicator supporting horizontal
/// and vertical orientations.
class ConsonaStepper extends StatelessWidget {
  const ConsonaStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
    this.direction = Axis.horizontal,
  }) : assert(steps.length > 0, 'At least one step is required');

  final List<ConsonaStep> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final motionSpec = theme.motion.resolve(ConsonaMotionRole.toggle, context);

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < steps.length; i++)
            _buildVerticalStep(context, theme, motionSpec, i),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _buildHorizontalStep(context, theme, motionSpec, i),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
                child: AnimatedContainer(
                  duration: motionSpec.duration,
                  height: 2,
                  decoration: BoxDecoration(
                    color: i < currentStep || steps[i].isCompleted
                        ? theme.colors.primary
                        : theme.colors.border,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStepBadge(
    BuildContext context,
    ConsonaThemeData theme,
    ConsonaMotionSpec motionSpec,
    int index,
  ) {
    final step = steps[index];
    final isActive = index == currentStep;
    final isDone = step.isCompleted || index < currentStep;

    final Color bg;
    final Color fg;
    if (step.hasError) {
      bg = theme.colors.danger;
      fg = theme.colors.onDanger;
    } else if (isActive) {
      bg = theme.colors.primary;
      fg = theme.colors.onPrimary;
    } else if (isDone) {
      bg = theme.colors.primary.withAlpha(32);
      fg = theme.colors.primary;
    } else {
      bg = theme.colors.surfaceSecondary;
      fg = theme.colors.mutedFg;
    }

    return AnimatedContainer(
      duration: motionSpec.duration,
      curve: motionSpec.curve,
      width: 28 * theme.density.factor,
      height: 28 * theme.density.factor,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
        border: isActive
            ? theme.border.resolve(
                ConsonaBorderRole.focus,
                context: context,
              )
            : theme.border.resolve(
                ConsonaBorderRole.defaultBorder,
                context: context,
              ),
      ),
      alignment: Alignment.center,
      child: Text(
        isDone && !step.hasError ? '✓' : '${index + 1}',
        style: theme.typography.label.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHorizontalStep(
    BuildContext context,
    ConsonaThemeData theme,
    ConsonaMotionSpec motionSpec,
    int index,
  ) {
    final step = steps[index];
    final isActive = index == currentStep;

    return Semantics(
      button: onStepTapped != null,
      selected: isActive,
      label: 'Step ${index + 1}: ${step.title}',
      child: MouseRegion(
        cursor: onStepTapped != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onStepTapped != null
              ? () {
                  unawaited(
                    ConsonaFeedbackScope.maybeOf(context)?.trigger(
                      FeedbackEvent.selection,
                    ),
                  );
                  onStepTapped!(index);
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepBadge(context, theme, motionSpec, index),
              const SizedBox(width: ConsonaSpacing.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.label.copyWith(
                        color: isActive
                            ? theme.colors.foreground
                            : theme.colors.mutedFg,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (step.subtitle != null)
                      Text(
                        step.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption.copyWith(
                          color: theme.colors.mutedFg,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalStep(
    BuildContext context,
    ConsonaThemeData theme,
    ConsonaMotionSpec motionSpec,
    int index,
  ) {
    final step = steps[index];
    final isActive = index == currentStep;
    final isLast = index == steps.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: onStepTapped != null
                    ? () {
                        unawaited(
                          ConsonaFeedbackScope.maybeOf(context)?.trigger(
                            FeedbackEvent.selection,
                          ),
                        );
                        onStepTapped!(index);
                      }
                    : null,
                child: _buildStepBadge(context, theme, motionSpec, index),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: ConsonaSpacing.xxs,
                    ),
                    color: index < currentStep || step.isCompleted
                        ? theme.colors.primary
                        : theme.colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: ConsonaSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : ConsonaSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title,
                    style: theme.typography.label.copyWith(
                      color: isActive
                          ? theme.colors.foreground
                          : theme.colors.mutedFg,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (step.subtitle != null) ...[
                    const SizedBox(height: ConsonaSpacing.xxs),
                    Text(
                      step.subtitle!,
                      style: theme.typography.caption.copyWith(
                        color: theme.colors.mutedFg,
                      ),
                    ),
                  ],
                  if (isActive && step.content != null) ...[
                    const SizedBox(height: ConsonaSpacing.sm),
                    step.content!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
