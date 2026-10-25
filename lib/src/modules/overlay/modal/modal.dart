/// Consona Modal — Centered confirm surface.
///
/// Opens/closes with a short **upward slide only** (no fade, no scale).
/// Content is fully overflow-safe.
library;

import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

/// Centered modal dialog with slide open/close motion.
class ConsonaModal extends StatelessWidget {
  const ConsonaModal({
    super.key,
    required this.title,
    this.description,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.showCancel = true,
    this.maxWidth = 360.0,
  });

  final String title;
  final String? description;
  final Widget? content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool showCancel;
  final double maxWidth;

  /// Presents a centered modal — barrier fixed, card slides up.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? description,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    bool showCancel = true,
    bool barrierDismissible = true,
  }) {
    return showConsonaOverlay<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (overlayContext, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: ConsonaCurves.subtleEase,
          reverseCurve: ConsonaCurves.easeOut,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                return ConsonaOverlayBackdrop(
                  progress: curved.value,
                  blurSigma: 16.0,
                  tintOpacity: 0.40,
                  onTap: barrierDismissible
                      ? () => Navigator.of(overlayContext).maybePop(false)
                      : null,
                );
              },
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ConsonaSpacing.xl,
                  vertical: ConsonaSpacing.xxl,
                ),
                child: consonaModalSlideTransition(
                  animation: animation,
                  child: ConsonaModal(
                    title: title,
                    description: description,
                    content: content,
                    confirmLabel: confirmLabel,
                    cancelLabel: cancelLabel,
                    isDestructive: isDestructive,
                    showCancel: showCancel,
                    onConfirm: () => Navigator.of(overlayContext).pop(true),
                    onCancel: () => Navigator.of(overlayContext).pop(false),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: Material(
        color: colors.surface,
        elevation: 0,
        shape: theme.radius.resolveShape(
          ConsonaRadiusRole.macro,
          side: theme.border.resolveSide(
            ConsonaBorderRole.surfaceEdge,
            context: context,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(ConsonaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConsonaOverlayText(
                title,
                textAlign: TextAlign.center,
                style: theme.typography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: ConsonaSpacing.sm),
                ConsonaOverlayText(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.copyWith(
                    color: colors.mutedFg,
                    height: 1.45,
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: ConsonaSpacing.md),
                content!,
              ],
              const SizedBox(height: ConsonaSpacing.lg),
              if (showCancel && onCancel != null) ...[
                ConsonaButton.subtle(
                  label: cancelLabel,
                  fullWidth: true,
                  onTap: () {
                    ConsonaFeedbackScope.maybeOf(context)
                        ?.trigger(FeedbackEvent.tap);
                    onCancel!();
                  },
                ),
                const SizedBox(height: ConsonaSpacing.sm),
              ],
              if (onConfirm != null)
                isDestructive
                    ? ConsonaButton.danger(
                        label: confirmLabel,
                        fullWidth: true,
                        onTap: () {
                          ConsonaFeedbackScope.maybeOf(context)
                              ?.trigger(FeedbackEvent.error);
                          onConfirm!();
                        },
                      )
                    : ConsonaButton.primary(
                        label: confirmLabel,
                        fullWidth: true,
                        onTap: () {
                          ConsonaFeedbackScope.maybeOf(context)
                              ?.trigger(FeedbackEvent.success);
                          onConfirm!();
                        },
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
