/// Consona Pagination — Responsive page control for tables, lists, and grids.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../button/button.dart';
import '../button/icon_button.dart';

/// Standalone pagination footer with prev/next, optional page numbers, and
/// a compact “Showing X–Y of Z” summary that stacks on narrow viewports.
class ConsonaPagination extends StatelessWidget {
  const ConsonaPagination({
    super.key,
    required this.page,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    this.showPageNumbers = true,
    this.maxPageButtons = 5,
    this.enabled = true,
    this.dense = false,
  })  : assert(page >= 0),
        assert(pageSize > 0),
        assert(totalItems >= 0),
        assert(maxPageButtons >= 3);

  /// Zero-based current page index.
  final int page;

  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  /// When true, renders numeric page buttons (ellipsis when many pages).
  final bool showPageNumbers;

  /// Max numeric buttons including first/last when ellipsized.
  final int maxPageButtons;

  final bool enabled;
  final bool dense;

  int get totalPages => math.max(1, (totalItems / pageSize).ceil());

  int get safePage => page.clamp(0, totalPages - 1);

  int get startItem =>
      totalItems == 0 ? 0 : safePage * pageSize + 1;

  int get endItem => math.min(totalItems, (safePage + 1) * pageSize);

  void _go(BuildContext context, int next) {
    if (!enabled) return;
    final clamped = next.clamp(0, totalPages - 1);
    if (clamped == safePage) return;
    ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection);
    onPageChanged(clamped);
  }

  List<int?> _pageWindow() {
    final total = totalPages;
    if (total <= maxPageButtons) {
      return List<int?>.generate(total, (i) => i);
    }

    final current = safePage;
    final result = <int?>[];
    result.add(0);

    var window = maxPageButtons - 2; // reserve first + last
    if (window < 1) window = 1;
    var start = current - (window ~/ 2);
    var end = start + window - 1;
    if (start < 1) {
      start = 1;
      end = start + window - 1;
    }
    if (end > total - 2) {
      end = total - 2;
      start = math.max(1, end - window + 1);
    }

    if (start > 1) result.add(null);
    for (var i = start; i <= end; i++) {
      result.add(i);
    }
    if (end < total - 2) result.add(null);
    result.add(total - 1);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final canPrev = enabled && safePage > 0;
    final canNext = enabled && safePage < totalPages - 1;
    final size =
        dense ? ConsonaOpticalSize.xs : ConsonaOpticalSize.sm;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final summary = Text(
          totalItems == 0
              ? 'No results'
              : 'Showing $startItem–$endItem of $totalItems',
          style: theme.typography.caption.copyWith(color: colors.mutedFg),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompact || !showPageNumbers) ...[
              ConsonaIconButton.plain(
                icon: const Icon(Icons.chevron_left_rounded),
                size: ConsonaOpticalSize.sqSm,
                disabled: !canPrev,
                onTap: canPrev ? () => _go(context, safePage - 1) : null,
                semanticLabel: 'Previous page',
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs * scale),
                child: Text(
                  '${safePage + 1} / $totalPages',
                  style: theme.typography.caption.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              ConsonaIconButton.plain(
                icon: const Icon(Icons.chevron_right_rounded),
                size: ConsonaOpticalSize.sqSm,
                disabled: !canNext,
                onTap: canNext ? () => _go(context, safePage + 1) : null,
                semanticLabel: 'Next page',
              ),
            ] else ...[
              ConsonaButton.subtle(
                label: 'Prev',
                size: size,
                disabled: !canPrev,
                onTap: canPrev ? () => _go(context, safePage - 1) : null,
              ),
              SizedBox(width: ConsonaSpacing.xs * scale),
              for (final entry in _pageWindow()) ...[
                if (entry == null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ConsonaSpacing.xxs * scale,
                    ),
                    child: Text(
                      '…',
                      style: theme.typography.caption.copyWith(
                        color: colors.mutedFg,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(right: ConsonaSpacing.xxs * scale),
                    child: _PageButton(
                      page: entry,
                      selected: entry == safePage,
                      size: size,
                      enabled: enabled,
                      onTap: () => _go(context, entry),
                    ),
                  ),
              ],
              SizedBox(width: ConsonaSpacing.xs * scale),
              ConsonaButton.subtle(
                label: 'Next',
                size: size,
                disabled: !canNext,
                onTap: canNext ? () => _go(context, safePage + 1) : null,
              ),
            ],
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              summary,
              SizedBox(height: ConsonaSpacing.xs * scale),
              Align(alignment: Alignment.centerRight, child: controls),
            ],
          );
        }

        return Row(
          children: [
            Flexible(child: summary),
            controls,
          ],
        );
      },
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final ConsonaOpticalSize size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return ConsonaButton.primary(
        label: '${page + 1}',
        size: size,
        disabled: !enabled,
        onTap: enabled ? onTap : null,
      );
    }
    return ConsonaButton.subtle(
      label: '${page + 1}',
      size: size,
      disabled: !enabled,
      onTap: enabled ? onTap : null,
    );
  }
}
