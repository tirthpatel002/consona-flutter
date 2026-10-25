/// Consona Divider — Hairline horizontal or vertical separator with optional label.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// A `1 / devicePixelRatio` hairline divider supporting horizontal and vertical
/// orientations and an optional centered label (e.g. `─── OR ───`).
class ConsonaDivider extends StatelessWidget {
  const ConsonaDivider({
    super.key,
    this.label,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.spacing,
  }) : axis = Axis.horizontal,
       height = null;

  const ConsonaDivider.vertical({
    super.key,
    this.height,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.spacing,
  }) : axis = Axis.vertical,
       label = null;

  final Axis axis;
  final String? label;
  final double indent;
  final double endIndent;
  final double? spacing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final strokeW = theme.stroke.resolveWidth(context);
    final pad = spacing ?? (ConsonaSpacing.sm * theme.density.factor);

    if (axis == Axis.vertical) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          top: indent,
          bottom: endIndent,
          start: pad,
          end: pad,
        ),
        child: SizedBox(
          width: strokeW,
          height: height ?? 20.0 * theme.density.factor,
          child: DecoratedBox(
            decoration: BoxDecoration(color: theme.colors.borderLight),
          ),
        ),
      );
    }

    Widget buildLine() {
      return Container(
        height: strokeW,
        decoration: BoxDecoration(
          border: theme.border.resolve(
            ConsonaBorderRole.divider,
            context: context,
          ),
        ),
      );
    }

    if (label == null || label!.isEmpty) {
      return Semantics(
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: indent,
            end: endIndent,
            top: pad,
            bottom: pad,
          ),
          child: buildLine(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: indent,
        end: endIndent,
        top: pad,
        bottom: pad,
      ),
      child: Row(
        children: [
          Expanded(child: buildLine()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.sm),
            child: Text(
              label!,
              style: theme.typography.label.copyWith(
                color: theme.colors.mutedFg,
              ),
            ),
          ),
          Expanded(child: buildLine()),
        ],
      ),
    );
  }
}
