/// Consona Table — Unified responsive table & data-table with sorting, selection, search, pagination, horizontal scroll, and column resizing.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Icon, Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../checkbox/checkbox.dart';
import '../chip/chip.dart';
import '../empty_state/empty_state.dart';
import '../input/search_field.dart';
import 'pagination.dart';

/// Column definition for [ConsonaTable].
class ConsonaTableColumn<T> {
  const ConsonaTableColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.valueText,
    this.comparator,
    this.sortable = false,
    this.numeric = false,
    this.flex = 1,
    this.width,
    this.minWidth = 72.0,
    this.maxWidth,
    this.resizable = true,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;

  /// Optional plain-text extractor used for built-in search filtering and
  /// default alphabetical/numeric sorting when [comparator] is omitted.
  final String Function(T row)? valueText;
  final int Function(T a, T b)? comparator;
  final bool sortable;
  final bool numeric;
  final int flex;

  /// Initial or fixed column width. When null, the column derives its width
  /// from available width and [flex], or [ConsonaTable.defaultColumnWidth].
  final double? width;

  /// Minimum width during drag-resize. Defaults to 72.0.
  final double minWidth;

  /// Maximum width during drag-resize. Optional.
  final double? maxWidth;

  /// Whether this column can be interactively resized by the user.
  final bool resizable;
}

/// Unified, token-driven Table & DataTable component.
///
/// Supports simple static tables as well as full DataTable capabilities:
/// - Column sorting (ascending / descending / unsorted)
/// - Multi-row checkbox selection with "Select All" header
/// - Live search query filtering
/// - Client-side pagination footer (`rowsPerPage`)
/// - **Interactive Column Resizing**: drag handles between headers to resize columns.
/// - **Horizontal Scrolling**: when columns exceed viewport width (especially on mobile),
///   the table remains a true tabular grid and scrolls smoothly horizontally.
/// - **Optional Card Adaptation**: opt-in `responsiveCards: true` for stacked mobile card mode.
class ConsonaTable<T> extends StatefulWidget {
  const ConsonaTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowKey,
    this.title,
    this.searchable = false,
    this.searchPlaceholder = 'Filter rows…',
    this.selectable = false,
    this.selectedRows = const <Object>{},
    this.onSelectionChanged,
    this.onRowTap,
    this.rowsPerPage,
    this.resizableColumns = true,
    this.onColumnResized,
    this.horizontalScroll = true,
    this.defaultColumnWidth = 140.0,
    this.responsiveCards = false,
    this.mobileCardBreakpoint = 560.0,
    this.emptyTitle = 'No matching records',
    this.emptyDescription = 'Try adjusting your search or filter criteria.',
  }) : assert(columns.length > 0, 'At least one column is required');

  final List<ConsonaTableColumn<T>> columns;
  final List<T> rows;
  final Object Function(T row)? rowKey;
  final String? title;
  final bool searchable;
  final String searchPlaceholder;
  final bool selectable;
  final Set<Object> selectedRows;
  final ValueChanged<Set<Object>>? onSelectionChanged;
  final ValueChanged<T>? onRowTap;
  final int? rowsPerPage;

  /// Enables interactive drag-to-resize handles on column headers.
  final bool resizableColumns;

  /// Callback fired when a column is interactively resized.
  final void Function(String columnId, double width)? onColumnResized;

  /// Enables horizontal scrolling when total column widths exceed available width.
  final bool horizontalScroll;

  /// Default column width used when no explicit width or flex sizing is set.
  final double defaultColumnWidth;

  /// When true, renders stacked key-value cards on viewports narrower than [mobileCardBreakpoint].
  /// Defaults to false (favoring authentic horizontally scrollable tabular layout).
  final bool responsiveCards;

  final double mobileCardBreakpoint;
  final String emptyTitle;
  final String emptyDescription;

  @override
  State<ConsonaTable<T>> createState() => _ConsonaTableState<T>();
}

class _ConsonaTableState<T> extends State<ConsonaTable<T>> {
  String _query = '';
  String? _sortColumnId;
  bool _sortAscending = true;
  int _currentPage = 0;
  int? _hoveredRowIndex;

  /// Dynamic widths for interactively resized columns.
  final Map<String, double> _columnWidths = <String, double>{};
  String? _resizingColumnId;
  String? _hoveredResizeHandleId;

  Object _keyFor(T row) => widget.rowKey != null ? widget.rowKey!(row) : row as Object;

  void _toggleSort(ConsonaTableColumn<T> col) {
    if (!col.sortable) return;
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    setState(() {
      if (_sortColumnId != col.id) {
        _sortColumnId = col.id;
        _sortAscending = true;
      } else if (_sortAscending) {
        _sortAscending = false;
      } else {
        _sortColumnId = null;
        _sortAscending = true;
      }
      _currentPage = 0;
    });
  }

  List<T> get _processedRows {
    Iterable<T> list = widget.rows;
    final trimmed = _query.trim().toLowerCase();
    if (trimmed.isNotEmpty) {
      list = list.where((row) {
        for (final col in widget.columns) {
          final txt = col.valueText?.call(row) ?? '';
          if (txt.toLowerCase().contains(trimmed)) return true;
        }
        return row.toString().toLowerCase().contains(trimmed);
      });
    }

    final result = List<T>.of(list);
    if (_sortColumnId != null) {
      final col = widget.columns.cast<ConsonaTableColumn<T>?>().firstWhere(
            (c) => c?.id == _sortColumnId,
            orElse: () => null,
          );
      if (col != null) {
        result.sort((a, b) {
          int cmp;
          if (col.comparator != null) {
            cmp = col.comparator!(a, b);
          } else if (col.valueText != null) {
            cmp = col.valueText!(a).compareTo(col.valueText!(b));
          } else {
            cmp = 0;
          }
          return _sortAscending ? cmp : -cmp;
        });
      }
    }
    return result;
  }

  void _toggleRowSelection(T row, bool checked) {
    if (widget.onSelectionChanged == null) return;
    final k = _keyFor(row);
    final next = Set<Object>.of(widget.selectedRows);
    if (checked) {
      next.add(k);
    } else {
      next.remove(k);
    }
    widget.onSelectionChanged!(next);
  }

  Icon _sortIcon(ConsonaTableColumn<T> col, ConsonaColors colors) {
    final active = _sortColumnId == col.id;
    final IconData data;
    if (!active) {
      data = Icons.sort_outlined;
    } else if (_sortAscending) {
      data = Icons.arrow_upward_outlined;
    } else {
      data = Icons.arrow_downward_outlined;
    }
    return Icon(
      data,
      size: 14,
      color: active ? colors.primary : colors.mutedFg,
    );
  }

  void _toggleAll(List<T> visibleRows, bool selectAll) {
    if (widget.onSelectionChanged == null) return;
    final next = Set<Object>.of(widget.selectedRows);
    for (final r in visibleRows) {
      final k = _keyFor(r);
      if (selectAll) {
        next.add(k);
      } else {
        next.remove(k);
      }
    }
    widget.onSelectionChanged!(next);
  }

  /// Resolves the concrete width for a given column based on interactive resize,
  /// explicit [ConsonaTableColumn.width], or distributed flex fraction.
  double _resolveColumnWidth(
    ConsonaTableColumn<T> col,
    double availableWidth,
    int totalFlex,
  ) {
    final resized = _columnWidths[col.id];
    if (resized != null) return resized;
    if (col.width != null) return col.width!;

    if (totalFlex > 0 && availableWidth > 0) {
      final flexShare = (availableWidth / totalFlex) * col.flex;
      return math.max(col.minWidth, flexShare);
    }
    return math.max(col.minWidth, widget.defaultColumnWidth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;

    final filtered = _processedRows;
    final pageSize = widget.rowsPerPage;
    final totalRows = filtered.length;
    final totalPages = pageSize != null && pageSize > 0
        ? math.max(1, (totalRows / pageSize).ceil())
        : 1;
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final startIdx =
        pageSize != null && pageSize > 0 ? safePage * pageSize : 0;
    final endIdx = pageSize != null && pageSize > 0
        ? math.min(totalRows, startIdx + pageSize)
        : totalRows;
    final pageRows = filtered.sublist(startIdx, endIdx);

    final allPageSelected = pageRows.isNotEmpty &&
        pageRows.every((r) => widget.selectedRows.contains(_keyFor(r)));

    final sortableCols = widget.columns.where((c) => c.sortable).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < widget.mobileCardBreakpoint;
        final isCompactMobile =
            widget.responsiveCards && isNarrow;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
            border: theme.border.resolve(
              ConsonaBorderRole.subtle,
              context: context,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null ||
                  widget.searchable ||
                  (isCompactMobile && sortableCols.isNotEmpty))
                _buildToolbar(
                  context,
                  scale: scale,
                  isNarrow: isNarrow,
                  showSortChips: isCompactMobile && sortableCols.isNotEmpty,
                  sortableCols: sortableCols,
                ),

              // Body: True Tabular Grid (with horizontal scroll & resizing) OR Cards
              if (pageRows.isEmpty)
                Padding(
                  padding: EdgeInsets.all(ConsonaSpacing.xl * scale),
                  child: ConsonaEmptyState(
                    title: widget.emptyTitle,
                    description: widget.emptyDescription,
                  ),
                )
              else if (isCompactMobile)
                _buildMobileCardList(context, pageRows, scale)
              else
                _buildScrollableTableGrid(
                  context,
                  pageRows,
                  allPageSelected,
                  scale,
                  constraints.maxWidth,
                ),

              // Pagination Footer
              if (pageSize != null && totalRows > pageSize)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ConsonaSpacing.md * scale,
                    vertical: ConsonaSpacing.sm * scale,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    border: theme.border.resolve(
                      ConsonaBorderRole.divider,
                      context: context,
                    ),
                  ),
                  child: ConsonaPagination(
                    page: safePage,
                    totalItems: totalRows,
                    pageSize: pageSize,
                    dense: true,
                    onPageChanged: (next) =>
                        setState(() => _currentPage = next),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Title + search chrome. Narrow viewports stack a compact search under the
  /// title so the field can use the full width; wide viewports keep them inline.
  Widget _buildToolbar(
    BuildContext context, {
    required double scale,
    required bool isNarrow,
    required bool showSortChips,
    required List<ConsonaTableColumn<T>> sortableCols,
  }) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final hasTitleRow = widget.title != null ||
        (widget.selectable && widget.selectedRows.isNotEmpty);

    Widget? titleRow;
    if (hasTitleRow) {
      titleRow = Row(
        children: [
          if (widget.title != null)
            Flexible(
              child: Text(
                widget.title!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0,
                  height: 1.25,
                ),
              ),
            ),
          if (widget.selectable && widget.selectedRows.isNotEmpty) ...[
            if (widget.title != null)
              const SizedBox(width: ConsonaSpacing.sm),
            Text(
              '${widget.selectedRows.length} selected',
              style: theme.typography.caption.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    final searchField = widget.searchable
        ? ConsonaSearchField(
            placeholder: widget.searchPlaceholder,
            size: isNarrow ? ConsonaOpticalSize.xs : ConsonaOpticalSize.sm,
            onChanged: (val) {
              setState(() {
                _query = val;
                _currentPage = 0;
              });
            },
          )
        : null;

    Widget? sortRow;
    if (showSortChips) {
      sortRow = Row(
        children: [
          Text(
            'Sort:',
            style: theme.typography.caption.copyWith(
              color: colors.mutedFg,
            ),
          ),
          const SizedBox(width: ConsonaSpacing.xs),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final col in sortableCols)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: ConsonaSpacing.xxs,
                      ),
                      child: ConsonaChip(
                        label: col.label,
                        selected: _sortColumnId == col.id,
                        trailing: col.sortable
                            ? _sortIcon(col, colors)
                            : null,
                        onTap: () => _toggleSort(col),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final Widget chrome;
    if (isNarrow) {
      chrome = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleRow != null) titleRow,
          if (titleRow != null && searchField != null)
            SizedBox(height: ConsonaSpacing.sm * scale),
          if (searchField != null) searchField,
          if (sortRow != null) ...[
            SizedBox(height: ConsonaSpacing.sm * scale),
            sortRow,
          ],
        ],
      );
    } else {
      chrome = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (titleRow != null) Expanded(child: titleRow),
              if (titleRow != null && searchField != null)
                SizedBox(width: ConsonaSpacing.sm * scale),
              if (searchField != null)
                SizedBox(
                  width: 240.0,
                  child: searchField,
                ),
            ],
          ),
          if (sortRow != null) ...[
            SizedBox(height: ConsonaSpacing.sm * scale),
            sortRow,
          ],
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.md * scale,
        vertical: ConsonaSpacing.sm * scale,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: chrome,
    );
  }

  /// Builds the table grid, calculating column widths, rendering interactive resize handles,
  /// and automatically wrapping in horizontal scroll when total width exceeds viewport.
  Widget _buildScrollableTableGrid(
    BuildContext context,
    List<T> pageRows,
    bool allPageSelected,
    double scale,
    double availableWidth,
  ) {
    // Visual box only — the standalone checkbox hit target is 44pt and
    // would blow the row up. Layout hugs the painted box.
    const checkboxBox = 16.0;
    const checkboxWidth = checkboxBox + ConsonaSpacing.sm;
    final rowPaddingHorizontal = (ConsonaSpacing.md * scale) * 2;

    // Fixed widths allocated for columns
    var fixedSum = 0.0;
    var totalFlex = 0;

    for (final col in widget.columns) {
      if (_columnWidths.containsKey(col.id)) {
        fixedSum += _columnWidths[col.id]!;
      } else if (col.width != null) {
        fixedSum += col.width!;
      } else {
        totalFlex += col.flex;
      }
    }

    final remainingForFlex = math.max(
      0.0,
      availableWidth - (widget.selectable ? checkboxWidth : 0.0) - rowPaddingHorizontal - fixedSum,
    );

    // Compute concrete width map
    final resolvedWidths = <String, double>{};
    var totalTableWidth = (widget.selectable ? checkboxWidth : 0.0) + rowPaddingHorizontal;

    for (final col in widget.columns) {
      final w = _resolveColumnWidth(col, remainingForFlex, totalFlex);
      resolvedWidths[col.id] = w;
      totalTableWidth += w;
    }

    final gridWidth = math.max(availableWidth, totalTableWidth);

    final gridColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Row
        _buildHeaderRow(
          context,
          pageRows,
          allPageSelected,
          scale,
          resolvedWidths,
          checkboxWidth,
        ),

        // Data Rows
        for (int r = 0; r < pageRows.length; r++)
          _buildTableRow(
            context,
            pageRows[r],
            r,
            r == pageRows.length - 1,
            scale,
            resolvedWidths,
            checkboxWidth,
          ),
      ],
    );

    if (widget.horizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: gridWidth,
          child: gridColumn,
        ),
      );
    }

    return gridColumn;
  }

  Widget _buildHeaderRow(
    BuildContext context,
    List<T> pageRows,
    bool allPageSelected,
    double scale,
    Map<String, double> resolvedWidths,
    double checkboxWidth,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ConsonaSpacing.md * scale,
        vertical: ConsonaSpacing.sm * scale,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: theme.border.resolve(
          ConsonaBorderRole.divider,
          context: context,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.selectable)
            SizedBox(
              width: checkboxWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConsonaCheckbox(
                  value: allPageSelected,
                  boxSize: 16.0,
                  inflateLayout: false,
                  onChanged: (v) => _toggleAll(pageRows, v),
                ),
              ),
            ),
          for (int c = 0; c < widget.columns.length; c++) ...[
            _buildHeaderCell(
              context,
              widget.columns[c],
              resolvedWidths[widget.columns[c].id] ?? 120.0,
              scale,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    ConsonaTableColumn<T> col,
    double width,
    double scale,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final isResizing = _resizingColumnId == col.id;
    final isHovered = _hoveredResizeHandleId == col.id;
    final canResize = widget.resizableColumns && col.resizable;

    final labelStyle = theme.typography.label.copyWith(
      color: _sortColumnId == col.id ? colors.primary : colors.mutedFg,
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.centerStart,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: col.sortable ? () => _toggleSort(col) : null,
              child: MouseRegion(
                cursor: col.sortable
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: col.numeric
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        col.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign:
                            col.numeric ? TextAlign.end : TextAlign.start,
                        style: labelStyle,
                      ),
                    ),
                    if (col.sortable) ...[
                      const SizedBox(width: ConsonaSpacing.xxs),
                      _sortIcon(col, colors),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Interactive Column Resize Drag Handle
          if (canResize)
            PositionedDirectional(
              end: -6.0,
              top: -8.0,
              bottom: -8.0,
              width: 14.0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _hoveredResizeHandleId = col.id),
                onExit: (_) => setState(() {
                  if (_hoveredResizeHandleId == col.id) {
                    _hoveredResizeHandleId = null;
                  }
                }),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    setState(() => _resizingColumnId = col.id);
                    ConsonaFeedbackScope.maybeOf(context)
                        ?.trigger(FeedbackEvent.selection);
                  },
                  onHorizontalDragUpdate: (details) {
                    final isRtl = Directionality.of(context) == TextDirection.rtl;
                    final delta = isRtl ? -details.delta.dx : details.delta.dx;
                    final current = _columnWidths[col.id] ?? width;
                    final next = (current + delta).clamp(
                      col.minWidth,
                      col.maxWidth ?? 800.0,
                    );
                    setState(() {
                      _columnWidths[col.id] = next;
                    });
                    widget.onColumnResized?.call(col.id, next);
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _resizingColumnId = null);
                  },
                  child: Center(
                    child: Container(
                      width: (isResizing || isHovered) ? 2.5 : 1.0,
                      height: double.infinity,
                      color: (isResizing || isHovered)
                          ? colors.primary
                          : colors.borderLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    T row,
    int index,
    bool isLast,
    double scale,
    Map<String, double> resolvedWidths,
    double checkboxWidth,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final key = _keyFor(row);
    final isSelected = widget.selectedRows.contains(key);
    final isHovered = _hoveredRowIndex == index;

    final rowBg = isSelected
        ? colors.primary.withAlpha(22)
        : isHovered
            ? colors.surfaceSecondary
            : colors.surface;

    return MouseRegion(
      cursor: widget.onRowTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredRowIndex == index) _hoveredRowIndex = null;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onRowTap != null ? () => widget.onRowTap!(row) : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ConsonaSpacing.md * scale,
            vertical: ConsonaSpacing.sm * scale,
          ),
          decoration: BoxDecoration(
            color: rowBg,
            border: isLast
                ? null
                : theme.border.resolve(
                    ConsonaBorderRole.divider,
                    context: context,
                  ),
          ),
          child: Row(
            children: [
              if (widget.selectable)
                SizedBox(
                  width: checkboxWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConsonaCheckbox(
                      value: isSelected,
                      boxSize: 16.0,
                      inflateLayout: false,
                      onChanged: (v) => _toggleRowSelection(row, v),
                    ),
                  ),
                ),
              for (final col in widget.columns)
                SizedBox(
                  width: resolvedWidths[col.id] ?? 120.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ConsonaSpacing.xs,
                    ),
                    child: Align(
                      alignment: col.numeric
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: DefaultTextStyle(
                        style: theme.typography.body.copyWith(
                          color: colors.foreground,
                          fontFeatures: col.numeric
                              ? const [FontFeature.tabularFigures()]
                              : null,
                        ),
                        child: col.cellBuilder(context, row),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    List<T> pageRows,
    double scale,
  ) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < pageRows.length; r++) ...[
          Builder(
            builder: (context) {
              final row = pageRows[r];
              final key = _keyFor(row);
              final isSelected = widget.selectedRows.contains(key);
              final isLast = r == pageRows.length - 1;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onRowTap != null
                    ? () => widget.onRowTap!(row)
                    : null,
                child: Container(
                  padding: EdgeInsets.all(ConsonaSpacing.md * scale),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withAlpha(20)
                        : colors.surface,
                    border: isLast
                        ? null
                        : theme.border.resolve(
                            ConsonaBorderRole.divider,
                            context: context,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.selectable) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select row',
                              style: theme.typography.caption.copyWith(
                                color: colors.mutedFg,
                              ),
                            ),
                            ConsonaCheckbox(
                              value: isSelected,
                              boxSize: 16.0,
                              inflateLayout: false,
                              onChanged: (v) =>
                                  _toggleRowSelection(row, v),
                            ),
                          ],
                        ),
                        const SizedBox(height: ConsonaSpacing.xs),
                      ],
                      for (int c = 0; c < widget.columns.length; c++) ...[
                        if (c > 0) const SizedBox(height: ConsonaSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.columns[c].label,
                              style: theme.typography.caption.copyWith(
                                color: colors.mutedFg,
                              ),
                            ),
                            const SizedBox(width: ConsonaSpacing.sm),
                            Flexible(
                              child: DefaultTextStyle(
                                style: theme.typography.body.copyWith(
                                  color: colors.foreground,
                                ),
                                child: widget.columns[c]
                                    .cellBuilder(context, row),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
