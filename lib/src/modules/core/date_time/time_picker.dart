/// Consona TimePicker — Tactile time wheel picker for hours, minutes, and period.
library;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/widgets.dart';

import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../core/button/button.dart';
import '../../overlay/drawer/drawer.dart';
import '../picker/wheel_picker.dart';

/// Tactile multi-wheel time picker for hours, minutes, and AM/PM.
class ConsonaTimePicker extends StatefulWidget {
  const ConsonaTimePicker({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    this.is24Hour = false,
    this.minuteInterval = 1,
  });

  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool is24Hour;
  final int minuteInterval;

  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
    bool is24Hour = false,
  }) {
    var current = initialTime ?? TimeOfDay.now();

    return ConsonaDrawer.show<TimeOfDay>(
      context,
      snapPoints: const [0.48, 0.58],
      initialSnapIndex: 0,
      scrollable: false,
      header: ConsonaDrawerHeader(
        title: 'Select Time',
        subtitle: 'Scroll the wheels, then confirm',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: StatefulBuilder(
        builder: (drawerContext, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 180,
                child: ConsonaTimePicker(
                  selectedTime: current,
                  is24Hour: is24Hour,
                  onTimeChanged: (t) => setLocal(() => current = t),
                ),
              ),
              const SizedBox(height: ConsonaSpacing.md),
              ConsonaButton.primary(
                label: 'Confirm',
                onTap: () => Navigator.of(drawerContext).pop(current),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  State<ConsonaTimePicker> createState() => _ConsonaTimePickerState();
}

class _ConsonaTimePickerState extends State<ConsonaTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isPm;

  late final List<int> _hours;
  late final List<int> _minutes;

  @override
  void initState() {
    super.initState();
    if (widget.is24Hour) {
      _hours = List.generate(24, (i) => i);
      _selectedHour = widget.selectedTime.hour;
      _isPm = false;
    } else {
      _hours = List.generate(12, (i) => i + 1);
      final h = widget.selectedTime.hour;
      _isPm = h >= 12;
      _selectedHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    }

    _minutes = [
      for (var i = 0; i < 60; i += widget.minuteInterval) i,
    ];
    _selectedMinute = widget.selectedTime.minute;
    if (!_minutes.contains(_selectedMinute)) {
      _selectedMinute = _minutes.first;
    }
  }

  void _emit() {
    int hour;
    if (widget.is24Hour) {
      hour = _selectedHour;
    } else {
      if (_isPm) {
        hour = _selectedHour == 12 ? 12 : _selectedHour + 12;
      } else {
        hour = _selectedHour == 12 ? 0 : _selectedHour;
      }
    }
    widget.onTimeChanged(TimeOfDay(hour: hour, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final hourIndex = _hours.indexOf(_selectedHour);
    final minuteIndex = _minutes.indexOf(_selectedMinute);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hour Wheel
        Expanded(
          child: ConsonaWheelPicker<int>(
            items: _hours,
            initialIndex: hourIndex >= 0 ? hourIndex : 0,
            looping: true,
            onSelectedItemChanged: (index) {
              setState(() => _selectedHour = _hours[index]);
              _emit();
            },
            itemBuilder: (context, hour, isSelected) {
              return Text(
                '$hour'.padLeft(2, '0'),
                style: theme.typography.titleLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.primary : colors.mutedFg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ),
        // Divider Colon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xs),
          child: Text(
            ':',
            style: theme.typography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.mutedFg,
            ),
          ),
        ),
        // Minute Wheel
        Expanded(
          child: ConsonaWheelPicker<int>(
            items: _minutes,
            initialIndex: minuteIndex >= 0 ? minuteIndex : 0,
            looping: true,
            onSelectedItemChanged: (index) {
              setState(() => _selectedMinute = _minutes[index]);
              _emit();
            },
            itemBuilder: (context, minute, isSelected) {
              return Text(
                '$minute'.padLeft(2, '0'),
                style: theme.typography.titleLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colors.primary : colors.mutedFg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ),
        // AM / PM Column if not 24h
        if (!widget.is24Hour) ...[
          const SizedBox(width: ConsonaSpacing.sm),
          Expanded(
            child: ConsonaWheelPicker<String>(
              items: const ['AM', 'PM'],
              initialIndex: _isPm ? 1 : 0,
              looping: false,
              onSelectedItemChanged: (index) {
                setState(() => _isPm = index == 1);
                _emit();
              },
              itemBuilder: (context, period, isSelected) {
                return Text(
                  period,
                  style: theme.typography.titleMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? colors.primary : colors.mutedFg,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
