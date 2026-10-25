/// Consona AppBar — Scroll-aware top navigation bar with frosted glass blur.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../../core/types.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';

/// A scroll-aware top navigation bar with optional frosted glass blur,
/// leading/trailing action slots, and hairline divider.
class ConsonaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ConsonaAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    this.frosted = true,
    this.scrolledUnder = false,
    this.centerTitle = false,
    this.height = 56,
    this.showDivider = true,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool frosted;
  final bool scrolledUnder;
  final bool centerTitle;
  final double height;
  final bool showDivider;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final useBlur = frosted && !highContrast;
    final sigma = scrolledUnder ? 16.0 : 10.0;

    final bgAlpha = useBlur ? (scrolledUnder ? 215 : 195) : 255;
    final bgColor = (scrolledUnder
            ? theme.colors.surfaceSecondary
            : theme.colors.surface)
        .withAlpha(bgAlpha);

    final border = showDivider
        ? theme.border.resolve(
            ConsonaBorderRole.divider,
            state: scrolledUnder
                ? ConsonaInteractionState.hovered
                : ConsonaInteractionState.idle,
            context: context,
          )
        : null;

    final titleBlock = titleWidget ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.titleMedium.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption.copyWith(
                  color: theme.colors.mutedFg,
                ),
              ),
          ],
        );

    Widget content = Container(
      height: theme.density.resolveHeight(height),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ConsonaSpacing.base * theme.density.factor,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: ConsonaSpacing.sm),
          ],
          Expanded(
            child: Align(
              alignment: centerTitle
                  ? AlignmentDirectional.center
                  : AlignmentDirectional.centerStart,
              child: titleBlock,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: ConsonaSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: ConsonaSpacing.xs),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (useBlur) {
      content = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        ),
      );
    }

    return Semantics(
      container: true,
      header: true,
      label: title,
      child: content,
    );
  }
}
