/// Consona Carousel — Responsive snap-scrolling card/media pager with pill indicators.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';

/// Snap-scrolling horizontal carousel that adapts item width on wide desktop
/// viewports and provides hover arrow controls + animated pill pagination dots.
class ConsonaCarousel extends StatefulWidget {
  const ConsonaCarousel({
    super.key,
    required this.items,
    this.height = 180.0,
    this.initialPage = 0,
    this.onPageChanged,
    this.showIndicators = true,
    this.showDesktopArrows = true,
    this.responsiveColumns = true,
  }) : assert(items.length > 0, 'At least one item is required');

  final List<Widget> items;
  final double height;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final bool showIndicators;
  final bool showDesktopArrows;
  final bool responsiveColumns;

  @override
  State<ConsonaCarousel> createState() => _ConsonaCarouselState();
}

class _ConsonaCarouselState extends State<ConsonaCarousel> {
  late int _currentIndex;
  PageController? _controller;
  double? _lastFraction;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage.clamp(0, widget.items.length - 1);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _ensureController(double fraction) {
    if (_controller == null || _lastFraction != fraction) {
      _controller?.dispose();
      _lastFraction = fraction;
      _controller = PageController(
        initialPage: _currentIndex,
        viewportFraction: fraction,
      );
    }
    return _controller!;
  }

  void _goToPage(int index) {
    final target = index.clamp(0, widget.items.length - 1);
    if (target == _currentIndex) return;
    final motion = ConsonaTheme.of(context)
        .motion
        .resolve(ConsonaMotionRole.page, context);
    unawaited(
      ConsonaFeedbackScope.maybeOf(context)?.trigger(FeedbackEvent.selection),
    );
    if (motion.duration == Duration.zero) {
      _controller?.jumpToPage(target);
    } else {
      unawaited(
        _controller?.animateToPage(
          target,
          duration: motion.duration,
          curve: motion.curve,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final scale = theme.density.factor;
    final fastMotion = theme.motion.resolve(ConsonaMotionRole.press, context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 360.0;
          final double fraction;
          if (!widget.responsiveColumns) {
            fraction = 0.92;
          } else if (width >= 900) {
            fraction = 0.46;
          } else if (width >= 600) {
            fraction = 0.68;
          } else {
            fraction = 0.92;
          }

          final pageController = _ensureController(fraction);
          final isWide = width >= 600;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: widget.height * scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: pageController,
                      padEnds: false,
                      itemCount: widget.items.length,
                      onPageChanged: (idx) {
                        setState(() => _currentIndex = idx);
                        unawaited(
                          ConsonaFeedbackScope.maybeOf(context)?.trigger(
                            FeedbackEvent.selection,
                          ),
                        );
                        widget.onPageChanged?.call(idx);
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index == widget.items.length - 1
                                ? 0
                                : ConsonaSpacing.sm * scale,
                          ),
                          child: widget.items[index],
                        );
                      },
                    ),
                    if (widget.showDesktopArrows &&
                        (isWide || _hovered) &&
                        widget.items.length > 1) ...[
                      if (_currentIndex > 0)
                        PositionedDirectional(
                          start: ConsonaSpacing.xs,
                          child: _buildArrowButton(
                            context: context,
                            label: 'Previous slide',
                            symbol: '‹',
                            onTap: () => _goToPage(_currentIndex - 1),
                          ),
                        ),
                      if (_currentIndex < widget.items.length - 1)
                        PositionedDirectional(
                          end: ConsonaSpacing.xs,
                          child: _buildArrowButton(
                            context: context,
                            label: 'Next slide',
                            symbol: '›',
                            onTap: () => _goToPage(_currentIndex + 1),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (widget.showIndicators && widget.items.length > 1) ...[
                const SizedBox(height: ConsonaSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < widget.items.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ConsonaSpacing.xxs,
                        ),
                        child: GestureDetector(
                          onTap: () => _goToPage(i),
                          child: AnimatedContainer(
                            duration: fastMotion.duration,
                            curve: fastMotion.curve,
                            width: (i == _currentIndex ? 20.0 : 7.0) * scale,
                            height: 7.0 * scale,
                            decoration: BoxDecoration(
                              color: i == _currentIndex
                                  ? colors.primary
                                  : colors.borderStrong,
                              borderRadius: theme.radius.resolve(
                                ConsonaRadiusRole.full,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrowButton({
    required BuildContext context,
    required String label,
    required String symbol,
    required VoidCallback onTap,
  }) {
    final theme = ConsonaTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colors.surface.withAlpha(230),
              borderRadius: theme.radius.resolve(ConsonaRadiusRole.full),
              border: theme.border.resolve(
                ConsonaBorderRole.defaultBorder,
                context: context,
              ),
              boxShadow: theme.shadow.resolve(ConsonaShadowLevel.subtle),
            ),
            alignment: Alignment.center,
            child: Text(
              symbol,
              style: theme.typography.titleMedium.copyWith(
                color: theme.colors.foreground,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
