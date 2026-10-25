/// Consona ContextMenu — Anchored floating popup with slide reveal.
library;

import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../common/overlay_host.dart';

class ConsonaContextMenuItem {
  const ConsonaContextMenuItem({
    required this.id,
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.onTap,
  });

  final String id;
  final String label;
  final IconData? icon;
  final bool isDestructive;
  final VoidCallback? onTap;
}

/// Anchored popup context menu.
class ConsonaContextMenu extends StatelessWidget {
  const ConsonaContextMenu({
    super.key,
    required this.items,
  });

  final List<ConsonaContextMenuItem> items;

  static Future<T?> show<T>(
    BuildContext context, {
    required Offset position,
    required List<ConsonaContextMenuItem> items,
  }) {
    final size = MediaQuery.sizeOf(context);
    final left = position.dx.clamp(16.0, size.width - 220.0);
    final top = position.dy.clamp(16.0, size.height - 280.0);

    return showConsonaOverlay<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
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
                  blurSigma: 8.0,
                  tintOpacity: 0.22,
                  onTap: () => Navigator.of(overlayContext).maybePop(),
                );
              },
            ),
            Positioned(
              left: left,
              top: top,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(curved),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 240,
                    maxHeight: size.height - top - 24,
                  ),
                  child: ConsonaContextMenu(items: items),
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

    return Material(
      color: colors.surface,
      elevation: 0,
      shape: theme.radius.resolveShape(
        ConsonaRadiusRole.base,
        side: theme.border.resolveSide(
          ConsonaBorderRole.surfaceEdge,
          context: context,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180.0, maxWidth: 240.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                GestureDetector(
                  onTap: () {
                    ConsonaFeedbackScope.maybeOf(context)?.trigger(
                      item.isDestructive
                          ? FeedbackEvent.error
                          : FeedbackEvent.selection,
                    );
                    Navigator.of(context).pop();
                    item.onTap?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ConsonaSpacing.md,
                      vertical: ConsonaSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: ConsonaGeometries.iconSizeFor(
                              ConsonaOpticalSize.sm,
                            ),
                            color: item.isDestructive
                                ? colors.danger
                                : colors.mutedFg,
                          ),
                          const SizedBox(width: ConsonaSpacing.sm),
                        ],
                        Expanded(
                          child: ConsonaOverlayText(
                            item.label,
                            maxLines: 2,
                            style: theme.typography.body.copyWith(
                              color: item.isDestructive
                                  ? colors.danger
                                  : colors.foreground,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
