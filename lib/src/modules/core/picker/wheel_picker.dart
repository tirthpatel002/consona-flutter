/// Consona WheelPicker — Cylindrical tactile scroll wheel with detent haptic ticks.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Generic cylindrical scroll wheel picker with detent clicks and lens magnification.
class ConsonaWheelPicker<T> extends StatefulWidget {
  const ConsonaWheelPicker({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialIndex = 0,
    this.itemExtent = 40.0,
    this.diameterRatio = 1.3,
    this.magnification = 1.15,
    this.onSelectedItemChanged,
    this.looping = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, bool isSelected) itemBuilder;
  final int initialIndex;
  final double itemExtent;
  final double diameterRatio;
  final double magnification;
  final ValueChanged<int>? onSelectedItemChanged;
  final bool looping;

  @override
  State<ConsonaWheelPicker<T>> createState() => _ConsonaWheelPickerState<T>();
}

class _ConsonaWheelPickerState<T> extends State<ConsonaWheelPicker<T>> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant ConsonaWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != _selectedIndex) {
      _selectedIndex = widget.initialIndex.clamp(0, widget.items.isEmpty ? 0 : widget.items.length - 1);
      _controller.jumpToItem(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemChanged(int index) {
    if (widget.items.isEmpty) return;
    final effectiveIndex = widget.looping
        ? (index % widget.items.length + widget.items.length) % widget.items.length
        : index.clamp(0, widget.items.length - 1);

    if (_selectedIndex != effectiveIndex) {
      setState(() => _selectedIndex = effectiveIndex);
      ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
      widget.onSelectedItemChanged?.call(effectiveIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    if (widget.items.isEmpty) {
      return const SizedBox(height: 120.0);
    }

    return SizedBox(
      height: widget.itemExtent * 5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lens highlight container
          Positioned(
            left: ConsonaSpacing.md,
            right: ConsonaSpacing.md,
            height: widget.itemExtent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceSecondary.withAlpha((255 * 0.5).round()),
                borderRadius: theme.radius.resolve(ConsonaRadiusRole.atom),
                border: theme.border.resolve(ConsonaBorderRole.subtle),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemExtent,
            diameterRatio: widget.diameterRatio,
            magnification: widget.magnification,
            useMagnifier: true,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _onItemChanged,
            childDelegate: widget.looping
                ? ListWheelChildLoopingListDelegate(
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        Center(
                          child: widget.itemBuilder(
                            context,
                            widget.items[i],
                            i == _selectedIndex,
                          ),
                        ),
                    ],
                  )
                : ListWheelChildBuilderDelegate(
                    childCount: widget.items.length,
                    builder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      return Center(
                        child: widget.itemBuilder(
                          context,
                          widget.items[index],
                          isSelected,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
