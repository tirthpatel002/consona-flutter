/// Consona Card — Compound card surface with Rule C8 fail-closed defaults
/// and dual-axis part composition (Card.header, Card.body, Card.footer).
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/radius.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/interaction/spring_press.dart';
import '../../feedback/models/feedback_event.dart';

enum ConsonaCardVariant {
  elevated,
  outlined,
  subtle,
}

/// Compound card container with fail-closed defaults and dual-axis parts.
class ConsonaCard extends StatelessWidget {
  const ConsonaCard({
    super.key,
    this.child,
    this.header,
    this.body,
    this.footer,
    this.variant = ConsonaCardVariant.outlined,
    this.padding,
    this.onTap,
  });

  final Widget? child;
  final Widget? header;
  final Widget? body;
  final Widget? footer;
  final ConsonaCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Creates a standard header part for [ConsonaCard].
  static Widget buildHeader({
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    EdgeInsetsGeometry? padding,
  }) {
    return _CardHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      padding: padding,
    );
  }

  /// Creates a standard body part for [ConsonaCard].
  static Widget buildBody({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return _CardBody(
      padding: padding,
      child: child,
    );
  }

  /// Creates a standard footer part for [ConsonaCard].
  static Widget buildFooter({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return _CardFooter(
      padding: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final cardTheme = theme.components.card;

    final defaultBorderRole = switch (variant) {
      ConsonaCardVariant.outlined => ConsonaBorderRole.defaultBorder,
      ConsonaCardVariant.elevated || ConsonaCardVariant.subtle =>
        ConsonaBorderRole.subtle,
    };
    final borderSide = theme.border.resolveSide(
      cardTheme.borderRole ?? defaultBorderRole,
      context: context,
    );

    final defaultShadowLevel = switch (variant) {
      ConsonaCardVariant.elevated => ConsonaShadowLevel.subtle,
      ConsonaCardVariant.outlined || ConsonaCardVariant.subtle =>
        ConsonaShadowLevel.none,
    };
    final shadow = theme.shadow.resolve(
      cardTheme.shadowLevel ?? defaultShadowLevel,
      isDark: colors.isDark,
    );

    final bg = switch (variant) {
      ConsonaCardVariant.subtle => colors.surfaceSecondary,
      ConsonaCardVariant.elevated || ConsonaCardVariant.outlined => colors.surface,
    };

    Widget content;
    if (child != null) {
      content = child!;
    } else if (header != null || body != null || footer != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          if (body != null) body!,
          if (footer != null) footer!,
        ],
      );
    } else {
      // Fail-closed stock fallback (Rule C8)
      content = const SizedBox(
        height: 64.0,
      );
    }

    final effectivePadding = padding ??
        cardTheme.padding ??
        (header == null && body == null && footer == null
            ? const EdgeInsets.all(ConsonaSpacing.base)
            : EdgeInsets.zero);

    final effectiveRadius = cardTheme.radius != null
        ? ConsonaRadius.fromPreset(cardTheme.radius!)
        : theme.radius;

    final card = Container(
      decoration: ShapeDecoration(
        color: bg,
        shape: effectiveRadius.resolveShape(
          ConsonaRadiusRole.base,
          side: borderSide,
        ),
        shadows: shadow,
      ),
      padding: effectivePadding,
      child: content,
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        child: ConsonaSpringPress(
          onTap: () {
            ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
            onTap!();
          },
          child: card,
        ),
      );
    }

    return card;
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            ConsonaSpacing.base,
            ConsonaSpacing.base,
            ConsonaSpacing.base,
            ConsonaSpacing.xs,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[
                  const SizedBox(height: ConsonaSpacing.xxs),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: ConsonaSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(ConsonaSpacing.base),
      child: child,
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            ConsonaSpacing.base,
            ConsonaSpacing.xs,
            ConsonaSpacing.base,
            ConsonaSpacing.base,
          ),
      child: child,
    );
  }
}
