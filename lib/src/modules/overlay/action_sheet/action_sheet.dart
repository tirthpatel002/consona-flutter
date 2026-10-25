/// Consona ActionSheet — Mobile action list presented as a compact bottom drawer.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';
import '../drawer/drawer.dart';

/// Optical icon box — sized to sit near the action label x-height, not dominate it.
const double _kActionIconOptical = 17.0;

/// One action row inside [ConsonaActionSheet].
class ConsonaActionSheetItem {
  const ConsonaActionSheetItem({
    required this.id,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
    this.onTap,
  });

  final String id;
  final String label;
  final Widget? icon;
  final bool destructive;
  final bool enabled;
  final VoidCallback? onTap;
}

/// iOS-style action sheet built on [ConsonaDrawer] with grouped actions + cancel.
class ConsonaActionSheet {
  ConsonaActionSheet._();

  /// Presents an action sheet and returns the selected item [id], or null.
  static Future<String?> show(
    BuildContext context, {
    required List<ConsonaActionSheetItem> actions,
    String? title,
    String? message,
    String cancelLabel = 'Cancel',
    bool showCancel = true,
  }) {
    assert(actions.isNotEmpty, 'ActionSheet requires at least one action');

    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tap) ??
          Future<void>.value(),
    );

    // Hug typical title + 3–5 actions + cancel; avoid a tall empty cavity under
    // Cancel. Secondary snaps still leave room for longer lists.
    return ConsonaDrawer.show<String>(
      context,
      snapPoints: const [0.44, 0.60, 0.82],
      initialSnapIndex: 0,
      scrollable: true,
      showHandle: true,
      child: _ActionSheetBody(
        actions: actions,
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        showCancel: showCancel,
      ),
    );
  }
}

class _ActionSheetBody extends StatelessWidget {
  const _ActionSheetBody({
    required this.actions,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.showCancel,
  });

  final List<ConsonaActionSheetItem> actions;
  final String? title;
  final String? message;
  final String cancelLabel;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        ConsonaSpacing.md * scale,
        ConsonaSpacing.xs * scale,
        ConsonaSpacing.md * scale,
        ConsonaSpacing.md * scale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || message != null) ...[
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.typography.titleMedium.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 16 * scale,
                  height: 1.25,
                  letterSpacing: -0.25,
                ),
              ),
            if (message != null) ...[
              SizedBox(height: 4 * scale),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.typography.caption.copyWith(
                  color: colors.mutedFg,
                  fontWeight: FontWeight.w400,
                  fontSize: 13 * scale,
                  height: 1.35,
                ),
              ),
            ],
            SizedBox(height: ConsonaSpacing.md * scale),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
              border: theme.border.resolve(
                ConsonaBorderRole.subtle,
                context: context,
              ),
            ),
            child: ClipRRect(
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: theme.stroke.resolveWidth(context),
                        color: colors.borderLight,
                      ),
                    _ActionRow(item: actions[i]),
                  ],
                ],
              ),
            ),
          ),
          if (showCancel) ...[
            SizedBox(height: ConsonaSpacing.sm * scale),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                border: theme.border.resolve(
                  ConsonaBorderRole.defaultBorder,
                  context: context,
                ),
              ),
              child: ClipRRect(
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
                child: _ActionRow(
                  item: ConsonaActionSheetItem(
                    id: '__cancel__',
                    label: cancelLabel,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  emphasize: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item, this.emphasize = false});

  final ConsonaActionSheetItem item;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final enabled = item.enabled;
    final color = !enabled
        ? colors.mutedFg.withAlpha(120)
        : item.destructive
            ? colors.danger
            : colors.foreground;
    // Optical box — callers' explicit Icon(size:) is scaled into this so
    // every glyph lands at the same visual footprint next to the label.
    final iconBox = _kActionIconOptical * scale;

    return ConsonaSpringPress(
      enabled: enabled,
      pressedScale: 0.985,
      feedbackEvent:
          item.destructive ? FeedbackEvent.error : FeedbackEvent.selection,
      onTap: enabled
          ? () {
              item.onTap?.call();
              if (item.id != '__cancel__') {
                Navigator.of(context).maybePop(item.id);
              }
            }
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ConsonaSpacing.md * scale,
          vertical: 11.0 * scale,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              SizedBox(
                width: iconBox,
                height: iconBox,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: IconTheme(
                    data: IconThemeData(
                      size: iconBox,
                      color: color,
                    ),
                    child: item.icon!,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
            ],
            Flexible(
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.copyWith(
                  color: color,
                  // Regular actions stay light; only Cancel carries weight.
                  // Destructive relies on color, not extra bold.
                  fontSize: 15 * scale,
                  height: 1.25,
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
