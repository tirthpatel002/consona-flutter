/// Consona Kbd — Keyboard shortcut chip atom
library;

import 'package:flutter/widgets.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import 'text.dart';

class ConsonaKbd extends StatelessWidget {
  const ConsonaKbd(
    this.keyText, {
    super.key,
  });

  final String keyText;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final radius = theme.radius.resolve(ConsonaRadiusRole.atom);
    final border = theme.border.resolve(ConsonaBorderRole.subtle, context: context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: theme.colors.surfaceSecondary,
        borderRadius: radius,
        border: border,
      ),
      child: ConsonaText.label(
        keyText,
        color: theme.colors.mutedFg,
        tabularFigures: true,
      ),
    );
  }
}
