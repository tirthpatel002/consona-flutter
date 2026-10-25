/// Shared overlay presentation — slide-only surfaces, static barriers,
/// overflow-safe content shells.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../../core/animation.dart';
import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../context/overlay_scope.dart';
import '../engine/overlay_engine.dart';

/// Edge a sheet/drawer may enter from.
enum ConsonaOverlayEdge {
  bottom,
  top,
  left,
  right,
}

/// Keeps a reveal long enough to read on open and on close.
/// A zero duration (reduced motion) stays instant.
Duration consonaOverlayMotionDuration(Duration duration) {
  if (duration == Duration.zero) return Duration.zero;
  return Duration(milliseconds: duration.inMilliseconds.clamp(260, 420));
}

/// Production [showGeneralDialog] wrapper.
///
/// Motion is applied **inside** [builder] via the route [Animation] so the
/// barrier never slides with the surface. [transitionBuilder] is identity.
///
/// When an [OverlayEngine] is ambient, the host registers a queue item for
/// the lifetime of the route (priority defaults to [ConsonaOverlayPriority.sheet]).
Future<T?> showConsonaOverlay<T>({
  required BuildContext context,
  required Widget Function(
    BuildContext overlayContext,
    Animation<double> animation,
  ) builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Dismiss',
  Duration? transitionDuration,
  bool useRootNavigator = true,
  RouteSettings? settings,
  ConsonaOverlayPriority priority = ConsonaOverlayPriority.sheet,
}) {
  final theme = ConsonaTheme.of(context);
  final motion = theme.motion.resolve(ConsonaMotionRole.page, context);
  final duration = motion.duration == Duration.zero
      ? Duration.zero
      : (transitionDuration ??
          Duration(
            milliseconds: motion.duration.inMilliseconds.clamp(260, 420),
          ));

  // Capture theme from the caller — the dialog route is outside the normal
  // Material/text style inheritance, which paints double yellow underlines
  // under every Text in debug without an explicit Material + DefaultTextStyle.
  final colors = theme.colors;
  final transparent = colors.background.withAlpha(0);
  final bodyStyle = theme.typography.body.copyWith(
    color: colors.foreground,
    decoration: TextDecoration.none,
    decorationColor: transparent,
  );

  final overlayEngine = OverlayScope.maybeOf(context);
  final itemId =
      'overlay_${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(context)}';
  if (overlayEngine != null) {
    overlayEngine.push(
      ConsonaOverlayItem(
        id: itemId,
        priority: priority,
        data: settings?.name ?? 'consona.overlay',
      ),
    );
  }

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: transparent,
    transitionDuration: duration,
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
    routeSettings: settings,
    pageBuilder: (overlayContext, animation, secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: bodyStyle,
          child: IconTheme(
            data: IconThemeData(color: colors.foreground),
            child: builder(overlayContext, animation),
          ),
        ),
      );
    },
  ).whenComplete(() {
    overlayEngine?.dismiss(itemId);
  });
}

/// Pure slide — no fade, no scale. Full off-screen → settled.
Widget consonaSlideTransition({
  required Animation<double> animation,
  required ConsonaOverlayEdge edge,
  required Widget child,
  Curve curve = ConsonaCurves.subtleEase,
  Curve reverseCurve = ConsonaCurves.easeOut,
}) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: curve,
    reverseCurve: reverseCurve,
  );
  final begin = switch (edge) {
    ConsonaOverlayEdge.bottom => const Offset(0, 1),
    ConsonaOverlayEdge.top => const Offset(0, -1),
    ConsonaOverlayEdge.left => const Offset(-1, 0),
    ConsonaOverlayEdge.right => const Offset(1, 0),
  };

  return SlideTransition(
    position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
    child: child,
  );
}

/// Fade, scale, and short slide that reverses on dismiss.
///
/// Owns its [CurvedAnimation] so a rebuild during the route pop does not
/// drop the close motion.
class ConsonaSurfaceReveal extends StatefulWidget {
  const ConsonaSurfaceReveal({
    super.key,
    required this.animation,
    required this.child,
    this.alignment = Alignment.center,
    this.beginScale = 0.94,
    this.beginOffset = Offset.zero,
  });

  final Animation<double> animation;
  final Widget child;
  final Alignment alignment;
  final double beginScale;
  final Offset beginOffset;

  @override
  State<ConsonaSurfaceReveal> createState() => _ConsonaSurfaceRevealState();
}

class _ConsonaSurfaceRevealState extends State<ConsonaSurfaceReveal> {
  late CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _curved = _curve(widget.animation);
  }

  @override
  void didUpdateWidget(ConsonaSurfaceReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _curve(widget.animation);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  CurvedAnimation _curve(Animation<double> parent) {
    return CurvedAnimation(
      parent: parent,
      curve: ConsonaCurves.subtleEase,
      reverseCurve: ConsonaCurves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.beginOffset,
          end: Offset.zero,
        ).animate(_curved),
        child: ScaleTransition(
          alignment: widget.alignment,
          scale: Tween<double>(begin: widget.beginScale, end: 1.0).animate(_curved),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Centered modal — short upward slide only.
Widget consonaModalSlideTransition({
  required Animation<double> animation,
  required Widget child,
  Curve curve = ConsonaCurves.subtleEase,
  Curve reverseCurve = ConsonaCurves.easeOut,
}) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: curve,
    reverseCurve: reverseCurve,
  );
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curved),
    child: child,
  );
}

/// Dim/blur barrier that tracks [progress] but never translates with the panel.
class ConsonaOverlayBackdrop extends StatelessWidget {
  const ConsonaOverlayBackdrop({
    super.key,
    required this.progress,
    this.onTap,
    this.blurSigma = 14.0,
    this.tintOpacity = 0.32,
  });

  final double progress;
  final VoidCallback? onTap;
  final double blurSigma;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.001) return const SizedBox.expand();

    final sigma = blurSigma * t;
    final tint =
        theme.colors.foreground.withAlpha((255 * tintOpacity * t).round());

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(color: tint),
      ),
    );
  }
}

/// Overflow-safe body for drawer / sheet content.
class ConsonaOverlayBody extends StatelessWidget {
  const ConsonaOverlayBody({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
    this.safeArea = true,
    this.physics,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool safeArea;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? EdgeInsets.zero;

    Widget content = child;
    if (safeArea) {
      content = SafeArea(top: false, maintainBottomViewPadding: true, child: content);
    }

    if (scrollable) {
      return ClipRect(
        child: SingleChildScrollView(
          physics: physics ??
              const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
          padding: pad,
          child: content,
        ),
      );
    }

    return ClipRect(
      child: Padding(
        padding: pad,
        child: SizedBox.expand(child: content),
      ),
    );
  }
}

/// Slim grabber used by bottom drawers.
class ConsonaDrawerHandle extends StatelessWidget {
  const ConsonaDrawerHandle({
    super.key,
    this.edge = ConsonaOverlayEdge.bottom,
  });

  final ConsonaOverlayEdge edge;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.sm),
      child: Center(
        child: Container(
          width: 36.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: theme.colors.mutedFg.withAlpha((255 * 0.35).round()),
            borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
          ),
        ),
      ),
    );
  }
}

/// Text that never paints overflow stripes inside overlay chrome.
class ConsonaOverlayText extends StatelessWidget {
  const ConsonaOverlayText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.softWrap = true,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final resolved = baseStyle.copyWith(
      decoration: TextDecoration.none,
      decorationColor: baseStyle.color?.withAlpha(0),
    );
    return Text(
      data,
      style: resolved,
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
