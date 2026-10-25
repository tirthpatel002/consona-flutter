/// Consona PullToRefresh — Elastic pull-down refresh indicator with haptic threshold.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../loader/loader.dart';

/// Wraps a scrollable [child] with an elastic pull-down refresh indicator
/// that fires a haptic tick when crossing [triggerOffset].
class ConsonaPullToRefresh extends StatefulWidget {
  const ConsonaPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerOffset = 72.0,
    this.maxPullDistance = 120.0,
    this.enabled = true,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double triggerOffset;
  final double maxPullDistance;
  final bool enabled;

  @override
  State<ConsonaPullToRefresh> createState() => _ConsonaPullToRefreshState();
}

class _ConsonaPullToRefreshState extends State<ConsonaPullToRefresh> {
  double _pullExtent = 0.0;
  bool _isRefreshing = false;
  bool _hasTriggeredHaptic = false;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.enabled || _isRefreshing) return false;

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.extentBefore == 0.0 && metrics.pixels < 0.0) {
        final overscroll = (-metrics.pixels).clamp(0.0, widget.maxPullDistance);
        setState(() => _pullExtent = overscroll);
        if (overscroll >= widget.triggerOffset && !_hasTriggeredHaptic) {
          _hasTriggeredHaptic = true;
          ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tick);
        } else if (overscroll < widget.triggerOffset && _hasTriggeredHaptic) {
          _hasTriggeredHaptic = false;
        }
      } else if (_pullExtent > 0.0 && metrics.pixels >= 0.0) {
        setState(() {
          _pullExtent = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0.0 &&
          notification.metrics.extentBefore == 0.0) {
        final next = (_pullExtent - notification.overscroll * 0.5)
            .clamp(0.0, widget.maxPullDistance);
        setState(() => _pullExtent = next);
        if (next >= widget.triggerOffset && !_hasTriggeredHaptic) {
          _hasTriggeredHaptic = true;
          ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.tick);
        }
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullExtent >= widget.triggerOffset && !_isRefreshing) {
        _triggerRefresh();
      } else if (_pullExtent > 0.0) {
        setState(() {
          _pullExtent = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    }
    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _isRefreshing = true;
      _pullExtent = 48.0;
    });
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullExtent = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.reveal, context);
    final progress = (_pullExtent / widget.triggerOffset).clamp(0.0, 1.0);
    final headerHeight = _isRefreshing ? 48.0 : _pullExtent;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedPadding(
            duration: _pullExtent > 0 && !_isRefreshing
                ? Duration.zero
                : motion.duration,
            curve: motion.curve,
            padding: EdgeInsets.only(top: headerHeight),
            child: widget.child,
          ),
          if (headerHeight > 4.0)
            Positioned(
              top: (headerHeight - 28.0).clamp(4.0, 16.0),
              child: Opacity(
                opacity: _isRefreshing ? 1.0 : progress,
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  padding: const EdgeInsets.all(ConsonaSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
                    border: theme.border.resolve(
                      ConsonaBorderRole.subtle,
                      context: context,
                    ),
                    boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
                  ),
                  child: ConsonaLoader(
                    size: 16.0,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
