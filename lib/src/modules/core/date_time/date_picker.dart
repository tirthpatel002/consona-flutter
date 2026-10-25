/// Consona DatePicker — calendar with month/year surfaces and range selection.
///
/// Sized from width (never from a fragile parent height), so it cannot paint
/// Flutter's yellow/black overflow stripes inside drawers or sheets.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme_data.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/drawer/drawer.dart';
import '../button/button.dart';
import 'picker_chrome.dart';

/// Selection mode for [ConsonaDatePicker].
enum ConsonaDatePickerMode { single, range }

/// Result returned from drawer presentations of the date picker.
class ConsonaDatePickerResult {
  const ConsonaDatePickerResult({this.date, this.start, this.end});

  final DateTime? date;
  final DateTime? start;
  final DateTime? end;

  bool get isEmpty => date == null && start == null && end == null;
}

enum _PickerSurface { calendar, month, year }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Tactile calendar with month/year pickers and optional range selection.
class ConsonaDatePicker extends StatefulWidget {
  const ConsonaDatePicker({
    super.key,
    this.mode = ConsonaDatePickerMode.single,
    this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    this.onDateChanged,
    this.onRangeChanged,
    this.firstDate,
    this.lastDate,
    this.size,
  });

  final ConsonaDatePickerMode mode;
  final DateTime? selectedDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final ValueChanged<DateTime>? onDateChanged;
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Optical size for chrome + capped day cells.
  final ConsonaOpticalSize? size;

  /// Quick single-date drawer — tapping a day confirms immediately.
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
  }) {
    var current = initialDate ?? DateTime.now();

    return ConsonaDrawer.show<DateTime>(
      context,
      snapPoints: const [0.72, 0.92],
      initialSnapIndex: 0,
      scrollable: true,
      header: ConsonaDrawerHeader(
        title: title,
        subtitle: 'Tap a day to confirm',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: StatefulBuilder(
        builder: (drawerContext, setLocal) {
          return ConsonaDatePicker(
            selectedDate: current,
            firstDate: firstDate,
            lastDate: lastDate,
            onDateChanged: (d) {
              setLocal(() => current = d);
              Navigator.of(drawerContext).pop(d);
            },
          );
        },
      ),
    );
  }

  /// Full presentation with Confirm — supports single/range modes.
  static Future<ConsonaDatePickerResult?> present(
    BuildContext context, {
    ConsonaDatePickerMode mode = ConsonaDatePickerMode.single,
    DateTime? initialDate,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
  }) {
    return ConsonaDrawer.show<ConsonaDatePickerResult>(
      context,
      snapPoints: const [0.78, 0.94],
      initialSnapIndex: 0,
      scrollable: true,
      header: ConsonaDrawerHeader(
        title: title,
        subtitle: mode == ConsonaDatePickerMode.range
            ? 'Pick a start and end date'
            : 'Choose a date, then confirm',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: _DatePickerSheet(
        mode: mode,
        initialDate: initialDate,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }

  @override
  State<ConsonaDatePicker> createState() => _ConsonaDatePickerState();
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.mode,
    this.initialDate,
    this.rangeStart,
    this.rangeEnd,
    this.firstDate,
    this.lastDate,
  });

  final ConsonaDatePickerMode mode;
  final DateTime? initialDate;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  DateTime? _selected;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _selected =
        widget.initialDate == null ? null : _dateOnly(widget.initialDate!);
    _rangeStart =
        widget.rangeStart == null ? null : _dateOnly(widget.rangeStart!);
    _rangeEnd = widget.rangeEnd == null ? null : _dateOnly(widget.rangeEnd!);
  }

  String? get _summary {
    if (widget.mode == ConsonaDatePickerMode.range) {
      if (_rangeStart == null) return null;
      final a = _formatDay(_rangeStart!);
      if (_rangeEnd == null) return '$a → …';
      return '$a → ${_formatDay(_rangeEnd!)}';
    }
    if (_selected == null) return null;
    return _formatDay(_selected!);
  }

  String _formatDay(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  bool get _canConfirm {
    if (widget.mode == ConsonaDatePickerMode.range) {
      return _rangeStart != null && _rangeEnd != null;
    }
    return _selected != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_summary != null) ...[
          Text(
            _summary!,
            style: theme.typography.body.copyWith(color: colors.primary),
          ),
          const SizedBox(height: ConsonaSpacing.sm),
        ],
        ConsonaDatePicker(
          mode: widget.mode,
          selectedDate: _selected,
          rangeStart: _rangeStart,
          rangeEnd: _rangeEnd,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateChanged: (d) => setState(() => _selected = d),
          onRangeChanged: (s, e) => setState(() {
            _rangeStart = s;
            _rangeEnd = e;
          }),
        ),
        const SizedBox(height: ConsonaSpacing.md),
        ConsonaButton.primary(
          label: 'Confirm',
          disabled: !_canConfirm,
          onTap: () {
            final result = widget.mode == ConsonaDatePickerMode.range
                ? ConsonaDatePickerResult(
                    start: _rangeStart,
                    end: _rangeEnd,
                  )
                : ConsonaDatePickerResult(date: _selected);
            Navigator.of(context).pop(result);
          },
        ),
      ],
    );
  }
}

class _ConsonaDatePickerState extends State<ConsonaDatePicker> {
  late DateTime _displayedMonth;
  _PickerSurface _surface = _PickerSurface.calendar;
  final ScrollController _yearScrollController = ScrollController();

  static const List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _monthShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const double _gap = ConsonaDateTimeGeometry.gap;
  static const int _rows = ConsonaDateTimeGeometry.dayRows;
  static const int _cols = ConsonaDateTimeGeometry.dayCols;
  static const int _yearColumns = ConsonaDateTimeGeometry.yearCols;

  DateTime get _minDate =>
      widget.firstDate != null
          ? _dateOnly(widget.firstDate!)
          : DateTime(_displayedMonth.year - 120);
  DateTime get _maxDate =>
      widget.lastDate != null
          ? _dateOnly(widget.lastDate!)
          : DateTime(_displayedMonth.year + 120, 12, 31);

  List<int> get _selectableYears => [
        for (var y = _maxDate.year; y >= _minDate.year; y--) y,
      ];

  @override
  void initState() {
    super.initState();
    final anchor = widget.selectedDate ??
        widget.rangeStart ??
        widget.rangeEnd ??
        DateTime.now();
    _displayedMonth = DateTime(anchor.year, anchor.month);
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ConsonaDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selectedDate ?? widget.rangeStart;
    if (next != null &&
        (oldWidget.selectedDate?.year != next.year ||
            oldWidget.selectedDate?.month != next.month ||
            oldWidget.rangeStart?.year != widget.rangeStart?.year ||
            oldWidget.rangeStart?.month != widget.rangeStart?.month) &&
        _surface == _PickerSurface.calendar) {
      // Keep the grid on the newly selected month when the parent drives it.
      if (widget.selectedDate != null &&
          (oldWidget.selectedDate?.year != widget.selectedDate!.year ||
              oldWidget.selectedDate?.month != widget.selectedDate!.month)) {
        _displayedMonth =
            DateTime(widget.selectedDate!.year, widget.selectedDate!.month);
      }
    }
  }

  void _feedback() {
    ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
  }

  bool _isDayEnabled(DateTime day) {
    final d = _dateOnly(day);
    if (d.isBefore(_minDate)) return false;
    if (d.isAfter(_maxDate)) return false;
    return true;
  }

  bool _isMonthEnabled(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return !start.isAfter(_maxDate) && !end.isBefore(_minDate);
  }

  bool _isYearEnabled(int year) =>
      year >= _minDate.year && year <= _maxDate.year;

  void _setDisplayed(DateTime month) {
    setState(() {
      _displayedMonth = DateTime(month.year, month.month);
    });
  }

  void _shiftMonth(int delta) {
    final next =
        DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
    if (!_isMonthEnabled(next.year, next.month)) return;
    _setDisplayed(next);
    _feedback();
  }

  void _openYearSurface() {
    setState(() => _surface = _PickerSurface.year);
    _scrollYearIntoView(
      _displayedMonth.year,
      ConsonaDateTimeGeometry.controlHeightOf(
        ConsonaDateTimeGeometry.opticalOf(context, widget.size),
      ),
    );
    _feedback();
  }

  void _scrollYearIntoView(int year, double rowExtent) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_yearScrollController.hasClients) return;
      final index = _selectableYears.indexOf(year);
      if (index < 0) return;
      final rowHeight = rowExtent + _gap;
      final row = index ~/ _yearColumns;
      final target = row * rowHeight;
      _yearScrollController.animateTo(
        target.clamp(0.0, _yearScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectMonth(int month) {
    if (!_isMonthEnabled(_displayedMonth.year, month)) return;
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, month);
      _surface = _PickerSurface.calendar;
    });
    _feedback();
  }

  void _selectYear(int year) {
    if (!_isYearEnabled(year)) return;
    setState(() {
      _displayedMonth = DateTime(year, _displayedMonth.month);
      _surface = _PickerSurface.month;
    });
    _feedback();
  }

  void _handleDayTap(DateTime date) {
    if (!_isDayEnabled(date)) return;
    final day = _dateOnly(date);
    _feedback();

    if (widget.mode == ConsonaDatePickerMode.range) {
      DateTime? start = widget.rangeStart == null
          ? null
          : _dateOnly(widget.rangeStart!);
      DateTime? end =
          widget.rangeEnd == null ? null : _dateOnly(widget.rangeEnd!);

      if (start == null || end != null) {
        start = day;
        end = null;
      } else if (day.isBefore(start)) {
        end = start;
        start = day;
      } else {
        end = day;
      }

      widget.onRangeChanged?.call(start, end);
      return;
    }

    widget.onDateChanged?.call(day);
  }

  bool _isInRange(DateTime day) {
    final start = widget.rangeStart;
    final end = widget.rangeEnd;
    if (start == null || end == null) return false;
    final d = _dateOnly(day);
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    return (d.isAfter(s) && d.isBefore(e)) ||
        (d.isAfter(e) && d.isBefore(s));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - ConsonaSpacing.base * 2;

        final optical =
            ConsonaDateTimeGeometry.opticalOf(context, widget.size);
        final cell = ConsonaDateTimeGeometry.dayCell(width, optical);
        final gridWidth = ConsonaDateTimeGeometry.dayGridWidth(width, optical);
        final gridHeight = ConsonaDateTimeGeometry.dayGridHeight(width, optical);
        final surfaceHeight =
            ConsonaDateTimeGeometry.calendarSurfaceHeight(width, optical);
        final controlH = ConsonaDateTimeGeometry.controlHeightOf(optical);

        final header = _buildSelectorHeader(theme, colors, optical);
        final bodySurface = SizedBox(
          height: surfaceHeight,
          width: width,
          child: switch (_surface) {
            _PickerSurface.calendar => _buildCalendar(
                theme,
                colors,
                gridWidth,
                cell,
                gridHeight,
                optical,
              ),
            _PickerSurface.month => _buildMonthGrid(width, surfaceHeight),
            _PickerSurface.year => _buildYearGrid(
                width,
                surfaceHeight,
                controlH,
              ),
          },
        );

        final body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: ConsonaSpacing.md),
            bodySurface,
          ],
        );

        final intrinsic = controlH + ConsonaSpacing.md + surfaceHeight;
        final needsScroll = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight + 0.5 < intrinsic;

        if (needsScroll) {
          return ClipRect(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: body,
            ),
          );
        }

        return body;
      },
    );
  }

  Widget _buildSelectorHeader(
    ConsonaThemeData theme,
    ConsonaColors colors,
    ConsonaOpticalSize optical,
  ) {
    final canGoPrev = _surface == _PickerSurface.year
        ? false
        : _surface == _PickerSurface.month
            ? _isYearEnabled(_displayedMonth.year - 1)
            : _isMonthEnabled(
                _displayedMonth.month == 1
                    ? _displayedMonth.year - 1
                    : _displayedMonth.year,
                _displayedMonth.month == 1 ? 12 : _displayedMonth.month - 1,
              );
    final canGoNext = _surface == _PickerSurface.year
        ? false
        : _surface == _PickerSurface.month
            ? _isYearEnabled(_displayedMonth.year + 1)
            : _isMonthEnabled(
                _displayedMonth.month == 12
                    ? _displayedMonth.year + 1
                    : _displayedMonth.year,
                _displayedMonth.month == 12 ? 1 : _displayedMonth.month + 1,
              );

    return Row(
      children: [
        _NavChip(
          icon: Icons.chevron_left_rounded,
          size: optical,
          enabled: canGoPrev,
          onTap: () {
            if (_surface == _PickerSurface.calendar) {
              _shiftMonth(-1);
            } else if (_surface == _PickerSurface.month) {
              _setDisplayed(
                DateTime(_displayedMonth.year - 1, _displayedMonth.month),
              );
              _feedback();
            }
          },
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_surface != _PickerSurface.year) ...[
                _SelectorChip(
                  label: _monthNames[_displayedMonth.month - 1],
                  selected: _surface == _PickerSurface.month,
                  size: optical,
                  onTap: () {
                    setState(() => _surface = _PickerSurface.month);
                    _feedback();
                  },
                ),
                const SizedBox(width: ConsonaSpacing.xs),
              ],
              _SelectorChip(
                label: _surface == _PickerSurface.year
                    ? '${_minDate.year} – ${_maxDate.year}'
                    : '${_displayedMonth.year}',
                selected: _surface == _PickerSurface.year,
                size: optical,
                onTap: _openYearSurface,
              ),
            ],
          ),
        ),
        _NavChip(
          icon: Icons.chevron_right_rounded,
          size: optical,
          enabled: canGoNext,
          onTap: () {
            if (_surface == _PickerSurface.calendar) {
              _shiftMonth(1);
            } else if (_surface == _PickerSurface.month) {
              _setDisplayed(
                DateTime(_displayedMonth.year + 1, _displayedMonth.month),
              );
              _feedback();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCalendar(
    ConsonaThemeData theme,
    ConsonaColors colors,
    double width,
    double cell,
    double gridHeight,
    ConsonaOpticalSize optical,
  ) {
    final firstDayOfMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final now = DateTime.now();

    final fontSize = ConsonaGeometries.fontSizeFor(optical);
    final weekdays = SizedBox(
      height: ConsonaDateTimeGeometry.weekdayHeight,
      child: Row(
        children: [
          for (final day in _weekdays)
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: theme.typography.caption.copyWith(
                    color: colors.mutedFg,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize - 1,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final cells = <Widget>[];
    for (var i = 0; i < _rows * _cols; i++) {
      if (i < firstWeekday || i >= firstWeekday + daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      final day = i - firstWeekday + 1;
      final date =
          DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = widget.mode == ConsonaDatePickerMode.single
          ? _sameDay(date, widget.selectedDate)
          : _sameDay(date, widget.rangeStart) ||
              _sameDay(date, widget.rangeEnd);
      final isRangeStart = _sameDay(date, widget.rangeStart);
      final isRangeEnd = _sameDay(date, widget.rangeEnd);
      final inRange = widget.mode == ConsonaDatePickerMode.range &&
          _isInRange(date);
      final isToday = _sameDay(date, now);
      final isDisabled = !_isDayEnabled(date);

      Color? bg;
      if (isSelected) {
        bg = colors.primary;
      } else if (inRange) {
        bg = colors.primary.withAlpha((255 * 0.14).round());
      } else if (isToday) {
        bg = colors.surfaceSecondary;
      }

      BorderRadius? radius = theme.radius.resolve(ConsonaRadiusRole.atom);
      if (widget.mode == ConsonaDatePickerMode.range &&
          widget.rangeStart != null &&
          widget.rangeEnd != null) {
        if (isRangeStart && !isRangeEnd) {
          radius = BorderRadius.horizontal(
            left: radius.topLeft,
            right: Radius.zero,
          );
        } else if (isRangeEnd && !isRangeStart) {
          radius = BorderRadius.horizontal(
            left: Radius.zero,
            right: radius.topRight,
          );
        } else if (inRange) {
          radius = BorderRadius.zero;
        }
      }

      cells.add(
        GestureDetector(
          onTap: isDisabled ? null : () => _handleDayTap(date),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg ?? colors.surfaceSecondary.withAlpha(0),
              borderRadius: radius,
              border: isToday && !isSelected
                  ? theme.border.resolve(ConsonaBorderRole.subtle)
                  : null,
            ),
            child: Text(
              '$day',
              style: theme.typography.body.copyWith(
                color: isDisabled
                    ? colors.mutedFg.withAlpha((255 * 0.35).round())
                    : isSelected
                        ? colors.onPrimary
                        : colors.foreground,
                fontWeight:
                    isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
                height: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
    }

    final grid = SizedBox(
      width: width,
      height: gridHeight,
      child: Column(
        children: [
          for (var r = 0; r < _rows; r++) ...[
            if (r > 0) const SizedBox(height: _gap),
            SizedBox(
              height: cell,
              child: Row(
                children: [
                  for (var c = 0; c < _cols; c++) ...[
                    if (c > 0) const SizedBox(width: _gap),
                    SizedBox(width: cell, child: cells[r * _cols + c]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            weekdays,
            const SizedBox(height: ConsonaSpacing.xs),
            grid,
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(double width, double surfaceHeight) {
    const cols = ConsonaDateTimeGeometry.monthCols;
    const rows = ConsonaDateTimeGeometry.monthRows;
    final cellW =
        ((width - _gap * (cols - 1)) / cols).floorToDouble().clamp(1.0, width);
    final cellH = ((surfaceHeight - _gap * (rows - 1)) / rows)
        .floorToDouble()
        .clamp(1.0, surfaceHeight);
    final gridW = cellW * cols + _gap * (cols - 1);
    final gridH = cellH * rows + _gap * (rows - 1);

    return Center(
      child: SizedBox(
        width: gridW,
        height: gridH,
        child: Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: _gap),
              SizedBox(
                height: cellH,
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: cellW,
                        height: cellH,
                        child: Builder(
                          builder: (context) {
                            final index = r * cols + c;
                            final month = index + 1;
                            final enabled =
                                _isMonthEnabled(_displayedMonth.year, month);
                            return _MonthYearTile(
                              label: _monthShort[index],
                              selected: _displayedMonth.month == month,
                              enabled: enabled,
                              onTap:
                                  enabled ? () => _selectMonth(month) : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYearGrid(
    double width,
    double surfaceHeight,
    double rowExtent,
  ) {
    final years = _selectableYears;
    final cellW = ((width - _gap * (_yearColumns - 1)) / _yearColumns)
        .floorToDouble()
        .clamp(1.0, width);

    return GridView.builder(
      controller: _yearScrollController,
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _yearColumns,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
        mainAxisExtent: rowExtent,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        return SizedBox(
          width: cellW,
          height: rowExtent,
          child: _MonthYearTile(
            label: '$year',
            selected: _displayedMonth.year == year,
            enabled: true,
            onTap: () => _selectYear(year),
          ),
        );
      },
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.icon,
    required this.onTap,
    required this.size,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ConsonaOpticalSize size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final h = ConsonaDateTimeGeometry.controlHeightOf(size);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: SizedBox(
          width: h,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
            ),
            child: Icon(
              icon,
              size: ConsonaGeometries.iconSizeFor(size),
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorChip extends StatelessWidget {
  const _SelectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ConsonaOpticalSize size;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final h = ConsonaDateTimeGeometry.controlHeightOf(size);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: h,
        padding: ConsonaGeometries.horizontalPaddingFor(size),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
        ),
        child: Text(
          label,
          style: theme.typography.label.copyWith(
            color: selected ? colors.onPrimary : colors.foreground,
            fontWeight: FontWeight.w600,
            fontSize: ConsonaGeometries.fontSizeFor(size),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _MonthYearTile extends StatelessWidget {
  const _MonthYearTile({
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? colors.primary
              : colors.surfaceSecondary,
          borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
          border: selected
              ? null
              : theme.border.resolve(ConsonaBorderRole.subtle),
        ),
        child: Text(
          label,
          style: theme.typography.body.copyWith(
            color: !enabled
                ? colors.mutedFg.withAlpha((255 * 0.35).round())
                : selected
                    ? colors.onPrimary
                    : colors.foreground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
