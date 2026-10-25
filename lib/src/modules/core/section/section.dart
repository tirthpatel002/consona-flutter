/// Consona Section — Inset grouped list and card container with squircle curvature
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../typography/text.dart';

class ConsonaSection extends StatelessWidget {
  const ConsonaSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final borderRadius = theme.radius.resolve(ConsonaRadiusRole.macro);
    final border = theme.border.resolve(ConsonaBorderRole.subtle, context: context);
    final shadows = theme.shadow.resolve(ConsonaShadowLevel.subtle, isDark: theme.colors.isDark);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
              child: ConsonaText.label(
                header!.toUpperCase(),
                color: theme.colors.mutedFg,
                style: const TextStyle(letterSpacing: 0.5),
              ),
            ),
          ],
          ClipRRect(
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: borderRadius,
                border: border,
                boxShadow: shadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 6.0),
              child: ConsonaText.caption(
                footer!,
                color: theme.colors.mutedFg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
