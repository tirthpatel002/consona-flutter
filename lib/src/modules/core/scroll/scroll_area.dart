/// Consona Scroll Area — Pass-through host for nested scrollables.
library;

import 'package:flutter/widgets.dart';

import '../../../theme/tokens.dart';

/// Wraps a scrollable. Scroll sound is intentionally disabled — only swipe
/// cues play elsewhere (e.g. [ConsonaSwipeableTabPager]).
///
/// ```dart
/// ConsonaScrollArea(
///   child: ListView(...),
/// )
/// ```
class ConsonaScrollArea extends StatelessWidget {
  const ConsonaScrollArea({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  /// Kept for API compatibility; sound is never emitted.
  final bool enabled;

  @override
  Widget build(BuildContext context) => child;
}

/// Convenience [ListView] already wrapped in [ConsonaScrollArea].
class ConsonaScrollView extends StatelessWidget {
  const ConsonaScrollView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.enableSound = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Axis scrollDirection;

  /// Kept for API compatibility; scroll sound is never emitted.
  final bool enableSound;

  @override
  Widget build(BuildContext context) {
    return ConsonaScrollArea(
      enabled: enableSound,
      child: ListView(
        controller: controller,
        padding: padding ??
            const EdgeInsets.symmetric(vertical: ConsonaSpacing.sm),
        physics: physics ??
            const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
        scrollDirection: scrollDirection,
        children: children,
      ),
    );
  }
}
