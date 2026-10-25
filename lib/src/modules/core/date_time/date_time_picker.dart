/// Consona DateTimePicker — date + time drawer with swipeable step pager.
library;

import 'package:flutter/material.dart' show DayPeriod, TimeOfDay;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../navigation/swipeable_tab_pager.dart';
import '../../overlay/drawer/drawer.dart';
import '../button/button.dart';
import 'date_picker.dart';
import 'picker_chrome.dart';
import 'time_picker.dart';

enum _TimeEditTarget { synced, start, end }

/// Combined date and time picker presented as a multi-step drawer.
abstract final class ConsonaDateTimePicker {
  /// Present a date-time picker. Returns a [ConsonaDatePickerResult] with
  /// times merged into the selected date(s).
  static Future<ConsonaDatePickerResult?> present(
    BuildContext context, {
    ConsonaDatePickerMode mode = ConsonaDatePickerMode.single,
    DateTime? initialDateTime,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime? firstDate,
    DateTime? lastDate,
    bool is24Hour = false,
    int minuteInterval = 5,
    String title = 'Select Date & Time',
  }) {
    return ConsonaDrawer.show<ConsonaDatePickerResult>(
      context,
      snapPoints: const [0.86, 0.96],
      initialSnapIndex: 0,
      scrollable: true,
      header: ConsonaDrawerHeader(
        title: title,
        subtitle: mode == ConsonaDatePickerMode.range
            ? 'Swipe between date and time'
            : 'Swipe between date and time',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: _DateTimePickerSheet(
        mode: mode,
        initialDateTime: initialDateTime,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        firstDate: firstDate,
        lastDate: lastDate,
        is24Hour: is24Hour,
        minuteInterval: minuteInterval,
      ),
    );
  }

  /// Convenience for a single [DateTime] with time.
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDateTime,
    DateTime? firstDate,
    DateTime? lastDate,
    bool is24Hour = false,
    int minuteInterval = 5,
    String title = 'Select Date & Time',
  }) async {
    final result = await present(
      context,
      initialDateTime: initialDateTime,
      firstDate: firstDate,
      lastDate: lastDate,
      is24Hour: is24Hour,
      minuteInterval: minuteInterval,
      title: title,
    );
    return result?.date;
  }
}

class _DateTimePickerSheet extends StatefulWidget {
  const _DateTimePickerSheet({
    required this.mode,
    this.initialDateTime,
    this.rangeStart,
    this.rangeEnd,
    this.firstDate,
    this.lastDate,
    this.is24Hour = false,
    this.minuteInterval = 5,
  });

  final ConsonaDatePickerMode mode;
  final DateTime? initialDateTime;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool is24Hour;
  final int minuteInterval;

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  int _stepIndex = 0; // 0 = date, 1 = time
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  _TimeEditTarget _timeTarget = _TimeEditTarget.synced;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    if (widget.mode == ConsonaDatePickerMode.range) {
      _rangeStart = widget.rangeStart == null
          ? null
          : DateTime(
              widget.rangeStart!.year,
              widget.rangeStart!.month,
              widget.rangeStart!.day,
            );
      _rangeEnd = widget.rangeEnd == null
          ? null
          : DateTime(
              widget.rangeEnd!.year,
              widget.rangeEnd!.month,
              widget.rangeEnd!.day,
            );
      _startTime = widget.rangeStart != null
          ? TimeOfDay.fromDateTime(widget.rangeStart!)
          : const TimeOfDay(hour: 9, minute: 0);
      _endTime = widget.rangeEnd != null
          ? TimeOfDay.fromDateTime(widget.rangeEnd!)
          : const TimeOfDay(hour: 17, minute: 0);
      _timeTarget = _TimeEditTarget.start;
    } else {
      final initial = widget.initialDateTime ?? now;
      _selectedDay = DateTime(initial.year, initial.month, initial.day);
      _startTime = TimeOfDay.fromDateTime(initial);
      _endTime = _startTime;
      _timeTarget = _TimeEditTarget.synced;
    }
  }

  TimeOfDay get _activeTime => switch (_timeTarget) {
        _TimeEditTarget.synced => _startTime,
        _TimeEditTarget.start => _startTime,
        _TimeEditTarget.end => _endTime,
      };

  void _applyActiveTime(TimeOfDay time) {
    setState(() {
      switch (_timeTarget) {
        case _TimeEditTarget.synced:
          _startTime = time;
          _endTime = time;
        case _TimeEditTarget.start:
          _startTime = time;
        case _TimeEditTarget.end:
          _endTime = time;
      }
    });
  }

  DateTime _merge(DateTime day, TimeOfDay time) => DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );

  bool get _canAdvanceDate {
    if (widget.mode == ConsonaDatePickerMode.range) {
      return _rangeStart != null && _rangeEnd != null;
    }
    return _selectedDay != null;
  }

  String? get _summary {
    if (widget.mode == ConsonaDatePickerMode.range) {
      if (_rangeStart == null) return null;
      final a = _fmt(_rangeStart!, _startTime);
      if (_rangeEnd == null) return '$a → …';
      return '$a → ${_fmt(_rangeEnd!, _endTime)}';
    }
    if (_selectedDay == null) return null;
    return _fmt(_selectedDay!, _startTime);
  }

  String _fmt(DateTime d, TimeOfDay t) {
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
    final h = widget.is24Hour
        ? '${t.hour}'.padLeft(2, '0')
        : '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}';
    final m = '${t.minute}'.padLeft(2, '0');
    final period =
        widget.is24Hour ? '' : (t.period == DayPeriod.pm ? ' PM' : ' AM');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$m$period';
  }

  void _setStep(int index) {
    if (index == 1 && !_canAdvanceDate) return;
    setState(() => _stepIndex = index);
  }

  void _confirm() {
    if (widget.mode == ConsonaDatePickerMode.range) {
      if (_rangeStart == null || _rangeEnd == null) return;
      Navigator.of(context).pop(
        ConsonaDatePickerResult(
          start: _merge(_rangeStart!, _startTime),
          end: _merge(_rangeEnd!, _endTime),
        ),
      );
      return;
    }
    if (_selectedDay == null) return;
    Navigator.of(context).pop(
      ConsonaDatePickerResult(date: _merge(_selectedDay!, _startTime)),
    );
  }

  double _pageHeight(double width, ConsonaOpticalSize optical) {
    final control = ConsonaDateTimeGeometry.controlHeightOf(optical);
    final surface =
        ConsonaDateTimeGeometry.calendarSurfaceHeight(width, optical);
    // Date page: month header + surface. Time page fills the same box.
    return control + ConsonaSpacing.md + surface;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final isRange = widget.mode == ConsonaDatePickerMode.range;
    final optical = ConsonaDateTimeGeometry.opticalOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - ConsonaSpacing.base * 2;
        final pageH = _pageHeight(width, optical);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConsonaPickerSegmented(
              labels: const ['Date', 'Time'],
              selectedIndex: _stepIndex,
              size: optical,
              enabledIndexes: {
                0,
                if (_canAdvanceDate) 1,
              },
              onSelected: _setStep,
            ),
            if (_summary != null) ...[
              const SizedBox(height: ConsonaSpacing.sm),
              SizedBox(
                height: ConsonaDateTimeGeometry.controlHeightOf(optical),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _summary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: colors.primary,
                      fontSize: ConsonaGeometries.fontSizeFor(optical),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: ConsonaSpacing.md),
            SizedBox(
              height: pageH,
              child: ConsonaSwipeableTabPager(
                index: _stepIndex,
                onIndexChanged: (i) {
                  if (i == 1 && !_canAdvanceDate) {
                    // Bounce back — date not ready.
                    setState(() => _stepIndex = 0);
                    return;
                  }
                  setState(() => _stepIndex = i);
                },
                itemCount: 2,
                pageGap: 0,
                enableSwipeSound: true,
                physics: _canAdvanceDate
                    ? const BouncingScrollPhysics(
                        parent: PageScrollPhysics(),
                      )
                    : const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ConsonaDatePicker(
                      mode: widget.mode,
                      size: optical,
                      selectedDate: _selectedDay,
                      rangeStart: _rangeStart,
                      rangeEnd: _rangeEnd,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      onDateChanged: (d) => setState(() => _selectedDay = d),
                      onRangeChanged: (s, e) => setState(() {
                        _rangeStart = s;
                        _rangeEnd = e;
                      }),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isRange) ...[
                        ConsonaPickerSegmented(
                          labels: const ['Synced', 'Start', 'End'],
                          selectedIndex: _timeTarget.index,
                          size: optical,
                          onSelected: (i) => setState(
                            () => _timeTarget = _TimeEditTarget.values[i],
                          ),
                        ),
                        const SizedBox(height: ConsonaSpacing.md),
                      ],
                      Expanded(
                        child: ConsonaTimePicker(
                          key: ValueKey(_timeTarget),
                          selectedTime: _activeTime,
                          is24Hour: widget.is24Hour,
                          minuteInterval: widget.minuteInterval,
                          onTimeChanged: _applyActiveTime,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: ConsonaSpacing.md),
            if (_stepIndex == 0)
              ConsonaButton.primary(
                label: 'Next',
                disabled: !_canAdvanceDate,
                onTap: () => _setStep(1),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ConsonaButton.subtle(
                      label: 'Back',
                      onTap: () => _setStep(0),
                    ),
                  ),
                  const SizedBox(width: ConsonaSpacing.sm),
                  Expanded(
                    child: ConsonaButton.primary(
                      label: 'Confirm',
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
