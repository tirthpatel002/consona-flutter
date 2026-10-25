/// Consona SwipeableTabPager — Soft horizontal pager for sibling tabs/screens.
///
/// Inspired by Kalein's swipeable tab pager: adjacent swipes keep ballistics;
/// non-adjacent programmatic jumps fade without scrolling through middle pages.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/types.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../feedback/context/feedback_scope.dart';
import '../feedback/models/feedback_event.dart';

/// Swipe left/right between sibling pages with soft settling motion.
class ConsonaSwipeableTabPager extends StatefulWidget {
  const ConsonaSwipeableTabPager({
    super.key,
    required this.index,
    required this.onIndexChanged,
    required this.itemCount,
    required this.itemBuilder,
    this.pageGap = ConsonaSpacing.md,
    this.physics,
    this.selection,
    this.enableSwipeSound = true,
  });

  /// Half of [pageGap] — subtract from parent horizontal padding to keep
  /// content edge-aligned with the screen.
  static double sideInsetForGap(double pageGap) => pageGap / 2;

  final int index;
  final ValueChanged<int> onIndexChanged;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double pageGap;
  final ScrollPhysics? physics;

  /// Continuous page position (`0…itemCount-1`) for driving a tab glider 1:1.
  final ValueNotifier<double>? selection;

  /// Plays the soothing [FeedbackEvent.swipe] cue when a page settles.
  final bool enableSwipeSound;

  @override
  State<ConsonaSwipeableTabPager> createState() =>
      _ConsonaSwipeableTabPagerState();
}

class _ConsonaSwipeableTabPagerState extends State<ConsonaSwipeableTabPager>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _fade;
  var _syncing = false;
  var _fadeActive = false;
  int? _pagerDrivenIndex;

  @override
  void initState() {
    super.initState();
    final initial = _clamp(widget.index);
    _controller = PageController(initialPage: initial);
    _controller.addListener(_tick);
    _fade = AnimationController(vsync: this, value: 1.0);
    _writeSelection(initial.toDouble());
  }

  @override
  void didUpdateWidget(covariant ConsonaSwipeableTabPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection != oldWidget.selection) {
      _writeSelection(_page);
    }
    if (widget.itemCount != oldWidget.itemCount) {
      final next = _clamp(widget.index);
      _jump(next);
      return;
    }
    if (widget.index == oldWidget.index) return;
    final target = _clamp(widget.index);
    if (_pagerDrivenIndex == target || target == _page.round()) return;
    unawaited(_animateTo(target));
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    _fade.dispose();
    super.dispose();
  }

  double get _page {
    if (!_controller.hasClients || !_controller.position.hasContentDimensions) {
      return widget.index.toDouble();
    }
    return _controller.page ?? widget.index.toDouble();
  }

  int _clamp(int i) {
    if (widget.itemCount <= 0) return 0;
    return i.clamp(0, widget.itemCount - 1);
  }

  void _writeSelection(double value) {
    widget.selection?.value = value;
  }

  void _tick() => _writeSelection(_page);

  void _jump(int index) {
    _syncing = true;
    if (_controller.hasClients) {
      _controller.jumpToPage(index);
    }
    _writeSelection(index.toDouble());
    _syncing = false;
  }

  Future<void> _animateTo(int target) async {
    if (!_controller.hasClients) {
      _jump(target);
      return;
    }
    final motion =
        ConsonaTheme.of(context).motion.resolve(ConsonaMotionRole.page, context);
    final current = _page.round();
    final distance = (target - current).abs();
    if (distance <= 1) {
      await _controller.animateToPage(
        target,
        duration: motion.duration,
        curve: motion.curve,
      );
      return;
    }

    // Non-adjacent: fade, jump, fade in — skip middle pages.
    _fadeActive = true;
    final half = motion.duration * 0.5;
    await _fade.animateTo(0.0, duration: half, curve: motion.curve);
    _jump(target);
    await _fade.animateTo(1.0, duration: half, curve: motion.curve);
    _fadeActive = false;
    if (widget.enableSwipeSound && mounted) {
      unawaited(
        ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.swipe),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = ConsonaSwipeableTabPager.sideInsetForGap(widget.pageGap);

    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) {
        final opacity = _fadeActive ? (0.88 + 0.12 * _fade.value) : 1.0;
        return Opacity(opacity: opacity, child: child);
      },
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.itemCount,
        physics: widget.physics ??
            const BouncingScrollPhysics(parent: PageScrollPhysics()),
        onPageChanged: (i) {
          if (_syncing) return;
          _pagerDrivenIndex = i;
          if (widget.enableSwipeSound) {
            unawaited(
              ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.swipe),
            );
          }
          widget.onIndexChanged(i);
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: widget.itemBuilder(context, index),
          );
        },
      ),
    );
  }
}
