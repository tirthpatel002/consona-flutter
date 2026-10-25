/// Shared painted chrome + geometry for Consona date/time pickers.
library;

import 'package:flutter/widgets.dart';

import '../../../core/size_context.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';

/// Pixel-snapped layout constants shared by calendar, month/year, and step tabs.
abstract final class ConsonaDateTimeGeometry {
  static const double gap = 4.0;
  static const int dayCols = 7;
  static const int dayRows = 6;
  static const double weekdayHeight = 18.0;
  static const int monthCols = 3;
  static const int monthRows = 4;
  static const int yearCols = 3;

  static ConsonaOpticalSize opticalOf(BuildContext context,
          [ConsonaOpticalSize? size]) =>
      size ?? ConsonaSizeScope.of(context);

  static double controlHeightOf(ConsonaOpticalSize size) =>
      ConsonaGeometries.heightFor(size);

  /// Whole-pixel day cell, capped so wide layouts stay compact.
  static double dayCell(double width, ConsonaOpticalSize size) {
    final usable = width - gap * (dayCols - 1);
    final raw = (usable / dayCols).floorToDouble().clamp(1.0, double.infinity);
    return raw.clamp(1.0, ConsonaGeometries.maxDayCellFor(size));
  }

  static double dayGridHeight(double width, ConsonaOpticalSize size) {
    final cell = dayCell(width, size);
    return cell * dayRows + gap * (dayRows - 1);
  }

  /// Weekday strip + day grid — month/year surfaces match this exactly.
  static double calendarSurfaceHeight(double width, ConsonaOpticalSize size) =>
      weekdayHeight + ConsonaSpacing.xs + dayGridHeight(width, size);

  static double dayGridWidth(double width, ConsonaOpticalSize size) {
    final cell = dayCell(width, size);
    return cell * dayCols + gap * (dayCols - 1);
  }

  // --- Back-compat getters (sm) for call sites without a size ---
  static ConsonaOpticalSize get optical => ConsonaOpticalSize.sm;
  static double get controlHeight => controlHeightOf(optical);
}

/// Fixed-height segmented control matching the active optical control height.
class ConsonaPickerSegmented extends StatelessWidget {
  const ConsonaPickerSegmented({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.enabledIndexes,
    this.size,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Set<int>? enabledIndexes;
  final ConsonaOpticalSize? size;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final optical = ConsonaDateTimeGeometry.opticalOf(context, size);
    final h = ConsonaDateTimeGeometry.controlHeightOf(optical);
    const inset = 2.0;
    final segmentH = h - inset * 2;
    final fontSize = ConsonaGeometries.fontSizeFor(optical);

    return SizedBox(
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
          border: theme.border.resolve(ConsonaBorderRole.subtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(inset),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: inset),
                Expanded(
                  child: _Segment(
                    label: labels[i],
                    height: segmentH,
                    fontSize: fontSize,
                    selected: selectedIndex == i,
                    enabled:
                        enabledIndexes == null || enabledIndexes!.contains(i),
                    onTap: () => onSelected(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final double height;
  final double fontSize;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.primary : null,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
          ),
          child: Text(
            label,
            style: theme.typography.label.copyWith(
              color: selected ? colors.onPrimary : colors.mutedFg,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
