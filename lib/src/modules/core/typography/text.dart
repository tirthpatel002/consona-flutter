/// Consona Text — Semantic role-driven typography component
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';

class ConsonaText extends StatelessWidget {
  const ConsonaText(
    this.text, {
    super.key,
    this.role = ConsonaTextRole.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  });

  final String text;
  final ConsonaTextRole role;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? tabularFigures;
  final TextStyle? style;

  const ConsonaText.hero(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.hero;

  const ConsonaText.titleLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.titleLarge;

  const ConsonaText.titleMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.titleMedium;

  const ConsonaText.body(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.body;

  const ConsonaText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.caption;

  const ConsonaText.label(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tabularFigures,
    this.style,
  }) : role = ConsonaTextRole.label;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    var resolvedStyle = theme.typography.resolve(
      role,
      colors: theme.colors,
      context: context,
    );

    if (color != null) {
      resolvedStyle = resolvedStyle.copyWith(color: color);
    }

    if (tabularFigures ?? theme.typography.tabularFigures) {
      resolvedStyle = resolvedStyle.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
    }

    if (style != null) {
      resolvedStyle = resolvedStyle.merge(style);
    }

    return Text(
      text,
      style: resolvedStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      textScaler: TextScaler.noScaling,
    );
  }
}
