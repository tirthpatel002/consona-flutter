/// Consona EmptyState — Structured zero-data placeholder card.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Structured empty/zero-data placeholder card with icon badge, title,
/// description, and optional primary action slot.
class ConsonaEmptyState extends StatelessWidget {
  const ConsonaEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
  });

  final String title;
  final String? description;
  final Widget? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final scale = theme.density.factor;

    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ConsonaSpacing.xl * scale),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
          border: theme.border.resolve(
            ConsonaBorderRole.surfaceEdge,
            context: context,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 48 * scale,
                height: 48 * scale,
                decoration: BoxDecoration(
                  color: theme.colors.primary.withAlpha(32),
                  borderRadius: theme.radius.resolve(ConsonaRadiusRole.base),
                ),
                alignment: Alignment.center,
                child: IconTheme(
                  data: IconThemeData(
                    size: 24 * scale,
                    color: theme.colors.primary,
                  ),
                  child: icon!,
                ),
              ),
              SizedBox(height: ConsonaSpacing.base * scale),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.titleMedium.copyWith(
                color: theme.colors.foreground,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: ConsonaSpacing.xs * scale),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.typography.body.copyWith(
                  color: theme.colors.mutedFg,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: ConsonaSpacing.lg * scale),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
