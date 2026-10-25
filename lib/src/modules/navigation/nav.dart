/// Consona Nav — one navigation component: bottom / side / top, bar / section
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/hit_target.dart';
import '../../core/size_context.dart';
import '../../core/types.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../core/typography/text.dart';
import '../feedback/interaction/spring_press.dart';
import '../feedback/models/feedback_event.dart';
import 'destination.dart';

/// Custom builder for a single nav destination item.
typedef ConsonaNavItemBuilder = Widget Function(
  BuildContext context,
  ConsonaDestination destination,
  bool selected,
  VoidCallback onTap,
);

/// Which screen edge the nav is laid out for.
enum ConsonaNavPlacement { bottom, side, top }

/// Surface treatment of the nav.
enum ConsonaNavVariant {
  /// Floating: inset from the edges, rounded and elevated.
  bar,

  /// Edge-to-edge, packed to the screen edges with a theme-resolved edge border.
  section,
}

/// Visual style of the selection indicator.
enum ConsonaNavIndicator {
  /// Solid capsule/pill glider sliding behind the selected tab.
  glider,

  /// Geometric circular dot sliding below the icon / icon + text.
  dot,

  /// Sleek horizontal line sliding below the icon / icon + text.
  underline,
}

class ConsonaNav extends StatefulWidget {
  const ConsonaNav({
    super.key,
    required this.destinations,
    required this.onSelect,
    this.selectedIndex,
    this.selectedId,
    this.placement = ConsonaNavPlacement.bottom,
    this.variant = ConsonaNavVariant.section,
    this.compact = false,
    bool? showLabels,
    bool? showTitles,
    this.fitContent,
    this.inverted = false,
    this.safeArea = true,
    ConsonaNavIndicator? indicator,
    ConsonaNavIndicator? selectedIndicator,
    this.leading,
    this.trailing,
    this.size,
    this.dense = false,
    this.pill = true,
    this.borderRole = ConsonaBorderRole.defaultBorder,
    this.itemBuilder,
    this.semanticLabel,
  })  : indicator = indicator ?? selectedIndicator ?? ConsonaNavIndicator.glider,
        showLabels = showTitles ?? showLabels ?? true,
        assert(selectedIndex == null || selectedId == null,
            'Pass either selectedIndex or selectedId, not both.');

  final List<ConsonaDestination> destinations;

  /// Called with the tapped destination's [ConsonaDestination.id].
  final ValueChanged<String> onSelect;

  final int? selectedIndex;
  final String? selectedId;
  final ConsonaNavPlacement placement;
  final ConsonaNavVariant variant;

  /// Visual style of the selection indicator.
  ///
  /// Defaults to [ConsonaNavIndicator.glider]. Also supports [dot] and
  /// [underline] (underline spans the full tab width).
  final ConsonaNavIndicator indicator;

  /// Alias for [indicator].
  ConsonaNavIndicator get selectedIndicator => indicator;

  /// Icon-only items (meaningful for [ConsonaNavPlacement.side]).
  final bool compact;

  /// Whether destination labels (titles) are displayed.
  ///
  /// Defaults to `true`. When set to `false`, destinations are displayed
  /// as icons only across bottom, top, and side placements.
  final bool showLabels;

  /// Alias for [showLabels].
  bool get showTitles => showLabels;

  /// Whether the nav bar hugs its content width rather than stretching
  /// across the full available width.
  ///
  /// For [ConsonaNavVariant.bar], this defaults to `true` (floating pill dock).
  /// For [ConsonaNavVariant.section], this defaults to `false` (edge-to-edge).
  final bool? fitContent;

  /// Resolved fit-content behavior: true for [ConsonaNavVariant.bar] by default.
  bool get effectiveFitContent =>
      fitContent ?? (variant == ConsonaNavVariant.bar);

  /// Slots (logo / profile) shown before / after the items in the side and top
  /// placements. Ignored for the bottom placement.
  final Widget? leading;
  final Widget? trailing;

  /// Optical size for icons/labels — ambient [ConsonaSizeScope] or sm.
  final ConsonaOpticalSize? size;

  /// Tightens vertical item padding only — does not shrink icons or type.
  final bool dense;

  /// When [variant] is [ConsonaNavVariant.bar], paints the floating rounded
  /// pill chrome. Defaults to `true`. Ignored for [ConsonaNavVariant.section].
  final bool pill;

  /// Border role for nav chrome (bar outline / section edge).
  ///
  /// Defaults to [ConsonaBorderRole.defaultBorder] so width and color follow
  /// the theme stroke — not a hairline [ConsonaBorderRole.divider] strip.
  final ConsonaBorderRole borderRole;

  /// Full custom item chrome. When set, replaces the stock [_NavItem] paint.
  final ConsonaNavItemBuilder? itemBuilder;

  /// Whether the nav inverts its color scheme (e.g. dark dock in light mode,
  /// light dock in dark mode).
  final bool inverted;

  /// When `false`, skips [SafeArea] and shrinks the bar outer margin — use for
  /// in-page tab bars that already sit below an app header / safe content.
  final bool safeArea;

  final String? semanticLabel;

  int get selected {
    final int i;
    if (selectedId != null) {
      i = destinations.indexWhere((d) => d.id == selectedId);
    } else {
      i = selectedIndex ?? 0;
    }
    return (i >= 0 && i < destinations.length) ? i : -1;
  }

  /// Key on the visible nav surface (useful for layout assertions in tests).
  static const ValueKey<String> surfaceKey = ValueKey('consona-nav-surface');

  /// Key on the sliding glider indicator.
  static const ValueKey<String> gliderKey = ValueKey('consona-nav-glider');

  /// Alias for [gliderKey] representing the active selection indicator.
  static const ValueKey<String> indicatorKey = gliderKey;

  static const double _compactSideWidth =
      ConsonaSpacing.xxxl + ConsonaSpacing.xxl; // 80
  static const double _fullSideWidth = ConsonaSpacing.xxxl * 5; // 240

  @override
  State<ConsonaNav> createState() => _ConsonaNavState();
}

class _ConsonaNavState extends State<ConsonaNav> {
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};
  final Map<int, Rect> _itemRects = <int, Rect>{};
  final GlobalKey _stackKey = GlobalKey();
  Rect? _gliderRect;
  bool _firstMeasurement = true;

  _ItemLayout get _layout {
    if (!widget.showLabels) return _ItemLayout.iconOnly;
    return switch (widget.placement) {
      ConsonaNavPlacement.bottom => _ItemLayout.stacked,
      ConsonaNavPlacement.top => _ItemLayout.row,
      ConsonaNavPlacement.side =>
        widget.compact ? _ItemLayout.iconOnly : _ItemLayout.sideRow,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGlider(initial: true));
  }

  @override
  void didUpdateWidget(ConsonaNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement ||
        oldWidget.compact != widget.compact ||
        oldWidget.variant != widget.variant ||
        oldWidget.indicator != widget.indicator ||
        oldWidget.showLabels != widget.showLabels ||
        oldWidget.dense != widget.dense ||
        oldWidget.pill != widget.pill ||
        oldWidget.size != widget.size) {
      _firstMeasurement = true;
      _itemRects.clear();
      _gliderRect = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateGlider(initial: true));
    } else if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.destinations != widget.destinations) {
      final newSelected = widget.selected;
      if (_itemRects.containsKey(newSelected)) {
        _gliderRect = _itemRects[newSelected];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateGlider();
        _scrollSelectedIntoView();
      });
    }
  }

  void _updateGlider({bool initial = false}) {
    if (!mounted) return;
    final stackContext = _stackKey.currentContext;
    if (stackContext == null) return;
    final stackBox = stackContext.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    for (var i = 0; i < widget.destinations.length; i++) {
      final itemContext = _itemKeys[i]?.currentContext;
      if (itemContext != null) {
        final itemBox = itemContext.findRenderObject() as RenderBox?;
        if (itemBox != null && itemBox.hasSize) {
          final offset = itemBox.localToGlobal(Offset.zero, ancestor: stackBox);
          _itemRects[i] = offset & itemBox.size;
        }
      }
    }

    final selected = widget.selected;
    final newRect = _itemRects[selected];
    if (newRect != null && _gliderRect != newRect) {
      setState(() {
        _gliderRect = newRect;
        if (initial) _firstMeasurement = false;
      });
    } else if (initial && _firstMeasurement) {
      setState(() => _firstMeasurement = false);
    }
  }

  /// Scrolls the tab strip so the selected item is revealed when clipped.
  void _scrollSelectedIntoView() {
    if (!mounted) return;
    final selected = widget.selected;
    if (selected < 0) return;
    final itemContext = _itemKeys[selected]?.currentContext;
    if (itemContext == null) return;

    final scrollable = Scrollable.maybeOf(itemContext);
    if (scrollable == null) return;

    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final viewport = scrollable.context.findRenderObject() as RenderBox?;
    if (itemBox == null || viewport == null || !itemBox.hasSize) return;

    final origin = itemBox.localToGlobal(Offset.zero, ancestor: viewport);
    final axis = scrollable.widget.axis;
    final double leading;
    final double extent;
    final double viewportExtent;
    if (axis == Axis.horizontal) {
      leading = origin.dx;
      extent = itemBox.size.width;
      viewportExtent = viewport.size.width;
    } else {
      leading = origin.dy;
      extent = itemBox.size.height;
      viewportExtent = viewport.size.height;
    }

    // Already fully visible — don't jostle the strip.
    if (leading >= -0.5 && leading + extent <= viewportExtent + 0.5) return;

    final alignment = leading < 0 ? 0.15 : 0.85;
    final motion =
        ConsonaTheme.of(context).motion.resolve(ConsonaMotionRole.toggle, context);
    Scrollable.ensureVisible(
      itemContext,
      alignment: alignment,
      duration: motion.duration,
      curve: motion.curve,
    );
  }

  void _onItemTap(int index) {
    widget.onSelect(widget.destinations[index].id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGlider();
      _scrollSelectedIntoView();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();

    final rawTheme = ConsonaTheme.of(context);
    final theme = widget.inverted ? rawTheme.invert() : rawTheme;
    final motion = theme.motion.resolve(ConsonaMotionRole.toggle, context);
    final selected = widget.selected;
    final layout = _layout;
    final placement = widget.placement;
    final variant = widget.variant;
    final compact = widget.compact;
    final showLabels = widget.showLabels;
    final effectiveFit = widget.effectiveFitContent;

    final isNavDark = theme.colors.surface.computeLuminance() < 0.5;
    final isGlider = widget.indicator == ConsonaNavIndicator.glider;

    // Glider background is opposite to nav surface.
    // Dot and Underline use the theme's primary color directly on the nav surface.
    final Color gliderBg = isNavDark ? theme.colors.foreground : theme.colors.primary;
    final Color selectedFg = isGlider
        ? (isNavDark ? theme.colors.background : theme.colors.onPrimary)
        : theme.colors.primary;
    final Color unselectedFg = theme.colors.mutedFg;

    final currentRect = _gliderRect ?? _itemRects[selected];

    Rect? targetIndicatorRect;
    BorderRadiusGeometry? targetRadius;
    Color? targetColor;
    List<BoxShadow>? targetShadow;

    if (currentRect != null) {
      switch (widget.indicator) {
        case ConsonaNavIndicator.glider:
          targetIndicatorRect = currentRect;
          // Match bar chrome: stadium when pill, softer rect when not.
          targetRadius = theme.radius.resolve(
            widget.pill ? ConsonaRadiusRole.full : ConsonaRadiusRole.base,
          );
          targetColor = gliderBg;
          targetShadow = theme.shadow.resolve(
            ConsonaShadowLevel.subtle,
            isDark: isNavDark,
          );
        case ConsonaNavIndicator.dot:
          const dotSize = ConsonaSpacing.xs;
          final left = currentRect.left + (currentRect.width - dotSize) / 2;
          final top = currentRect.bottom - dotSize - ConsonaSpacing.xs;
          targetIndicatorRect = Rect.fromLTWH(left, top, dotSize, dotSize);
          targetRadius = theme.radius.resolve(ConsonaRadiusRole.full);
          targetColor = theme.colors.primary;
          targetShadow = null;
        case ConsonaNavIndicator.underline:
          // Full width of the tab hit target (hairline inset so it doesn't
          // kiss neighboring tabs when they sit flush).
          const lineThickness = 3.0;
          const inset = ConsonaSpacing.xxs;
          final lineWidth = math.max(12.0, currentRect.width - inset * 2);
          final left = currentRect.left + inset;
          final top = currentRect.bottom - lineThickness - ConsonaSpacing.xxs;
          targetIndicatorRect =
              Rect.fromLTWH(left, top, lineWidth, lineThickness);
          targetRadius = theme.radius.resolve(ConsonaRadiusRole.atom);
          targetColor = theme.colors.primary;
          targetShadow = null;
      }
    }

    final optical = widget.size ?? ConsonaSizeScope.of(context);
    final items = <Widget>[
      for (var i = 0; i < widget.destinations.length; i++)
        widget.itemBuilder != null
            ? KeyedSubtree(
                key: _itemKeys.putIfAbsent(i, GlobalKey.new),
                child: widget.itemBuilder!(
                  context,
                  widget.destinations[i],
                  i == selected,
                  () => _onItemTap(i),
                ),
              )
            : _NavItem(
                // Key the visual chip — not the 48pt hit shell — so the glider
                // matches equal padding and can form a true horizontal pill.
                visualKey: _itemKeys.putIfAbsent(i, GlobalKey.new),
                destination: widget.destinations[i],
                selected: i == selected,
                layout: layout,
                placement: placement,
                indicator: widget.indicator,
                selectedFg: selectedFg,
                unselectedFg: unselectedFg,
                size: optical,
                dense: widget.dense,
                pill: widget.pill,
                onTap: () => _onItemTap(i),
              ),
    ];

    Widget buildGliderStack(Widget itemsContent) {
      final animatedIndicator = (targetIndicatorRect != null)
          ? AnimatedPositioned(
              key: ConsonaNav.gliderKey,
              duration: _firstMeasurement ? Duration.zero : motion.duration,
              curve: motion.curve,
              left: targetIndicatorRect.left,
              top: targetIndicatorRect.top,
              width: targetIndicatorRect.width,
              height: targetIndicatorRect.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: targetColor,
                  borderRadius: targetRadius,
                  boxShadow: targetShadow,
                ),
              ),
            )
          : null;

      return Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          if (isGlider && animatedIndicator != null) animatedIndicator,
          itemsContent,
          if (!isGlider && animatedIndicator != null) animatedIndicator,
        ],
      );
    }

    // Bar chrome: equal H/V inset. Option chips own their own (asymmetric) pad.
    final EdgeInsets barInnerPad = variant == ConsonaNavVariant.bar
        ? const EdgeInsets.all(ConsonaSpacing.xs)
        : switch (placement) {
            ConsonaNavPlacement.bottom => const EdgeInsets.symmetric(
                horizontal: ConsonaSpacing.sm,
                vertical: ConsonaSpacing.xs,
              ),
            ConsonaNavPlacement.side =>
              const EdgeInsets.all(ConsonaSpacing.sm),
            ConsonaNavPlacement.top => const EdgeInsets.symmetric(
                horizontal: ConsonaSpacing.base,
                vertical: ConsonaSpacing.xs,
              ),
          };

    final Widget body = switch (placement) {
      ConsonaNavPlacement.bottom => Padding(
          padding: theme.density.resolvePadding(barInnerPad),
          child: effectiveFit
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: buildGliderStack(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(width: ConsonaSpacing.xxs),
                          items[i],
                        ],
                      ],
                    ),
                  ),
                )
              : buildGliderStack(
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(child: items[i]),
                    ],
                  ),
                ),
        ),
      ConsonaNavPlacement.side => Padding(
          padding: theme.density.resolvePadding(
            variant == ConsonaNavVariant.bar
                ? const EdgeInsets.all(ConsonaSpacing.xs)
                : barInnerPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(height: ConsonaSpacing.md),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: buildGliderStack(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: ConsonaSpacing.xxs),
                          items[i],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(height: ConsonaSpacing.md),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ConsonaNavPlacement.top => Padding(
          padding: theme.density.resolvePadding(barInnerPad),
          child: Row(
            mainAxisSize: effectiveFit ? MainAxisSize.min : MainAxisSize.max,
            children: [
              if (widget.leading != null) widget.leading!,
              if (effectiveFit)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: buildGliderStack(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: ConsonaSpacing.xxs),
                            items[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: buildGliderStack(
                      Row(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: ConsonaSpacing.xxs),
                            items[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
    };

    final sideWidth =
        (compact || !showLabels) ? ConsonaNav._compactSideWidth : ConsonaNav._fullSideWidth;

    Widget framed;
    if (variant == ConsonaNavVariant.bar) {
      // Floating dock inset — snug to the safe area, not a fat frame.
      final margin = theme.density.resolvePadding(
        widget.safeArea
            ? const EdgeInsets.symmetric(
                horizontal: ConsonaSpacing.xs,
                vertical: ConsonaSpacing.xs,
              )
            : const EdgeInsets.symmetric(horizontal: ConsonaSpacing.xxs),
      );
      // Pill = stadium corners (full), not merely macro rounding.
      final radius = theme.radius.resolve(
        widget.pill ? ConsonaRadiusRole.full : ConsonaRadiusRole.base,
      );
      // Shadow outside, clip children to the rounded chrome (glider/items
      // must not paint past the pill edge).
      Widget surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: theme.shadow.resolve(
            ConsonaShadowLevel.soft,
            isDark: theme.colors.isDark,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            key: ConsonaNav.surfaceKey,
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: radius,
              border: theme.border.resolve(widget.borderRole, context: context),
            ),
            child: body,
          ),
        ),
      );
      if (placement == ConsonaNavPlacement.side) {
        surface = SizedBox(width: sideWidth, child: surface);
      }
      Widget padded = Padding(
        padding: margin,
        child: Align(
          alignment: placement == ConsonaNavPlacement.top
              ? Alignment.topCenter
              : (placement == ConsonaNavPlacement.side
                  ? AlignmentDirectional.centerStart
                  : Alignment.bottomCenter),
          child: surface,
        ),
      );
      framed = widget.safeArea
          ? SafeArea(
              top: placement != ConsonaNavPlacement.bottom,
              bottom: placement != ConsonaNavPlacement.top,
              child: padded,
            )
          : padded;
    } else {
      // Theme-resolved edge (role + stroke width + color). Painted as a strip
      // so only the facing edge is drawn.
      final edge = theme.border
          .resolveSide(widget.borderRole, context: context);
      final hasEdge = edge.width > 0;
      Widget surfaceBody = body;
      if (widget.safeArea) {
        surfaceBody = SafeArea(
          top: placement != ConsonaNavPlacement.bottom,
          bottom: placement != ConsonaNavPlacement.top,
          child: body,
        );
      }
      Widget surface = ColoredBox(
        key: ConsonaNav.surfaceKey,
        color: theme.colors.surface,
        child: surfaceBody,
      );
      final edgeStrip = hasEdge
          ? ColoredBox(color: edge.color)
          : const SizedBox.shrink();
      switch (placement) {
        case ConsonaNavPlacement.bottom:
          framed = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasEdge) SizedBox(height: edge.width, child: edgeStrip),
              surface,
            ],
          );
        case ConsonaNavPlacement.top:
          framed = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              surface,
              if (hasEdge) SizedBox(height: edge.width, child: edgeStrip),
            ],
          );
        case ConsonaNavPlacement.side:
          framed = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: sideWidth, child: surface),
              if (hasEdge) SizedBox(width: edge.width, child: edgeStrip),
            ],
          );
      }
    }

    final Widget framedWithTheme = ConsonaThemeScope(
      theme: theme,
      child: framed,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: framedWithTheme,
    );
  }
}

enum _ItemLayout { stacked, row, sideRow, iconOnly }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.visualKey,
    required this.destination,
    required this.selected,
    required this.layout,
    required this.placement,
    required this.indicator,
    required this.selectedFg,
    required this.unselectedFg,
    required this.size,
    required this.dense,
    required this.pill,
    required this.onTap,
  });

  final GlobalKey visualKey;
  final ConsonaDestination destination;
  final bool selected;
  final _ItemLayout layout;
  final ConsonaNavPlacement placement;
  final ConsonaNavIndicator indicator;
  final Color selectedFg;
  final Color unselectedFg;
  final ConsonaOpticalSize size;
  final bool dense;
  final bool pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;
    final motion = theme.motion.resolve(ConsonaMotionRole.toggle, context);
    final fg = selected ? selectedFg : unselectedFg;
    // Nav icons run larger than chrome controls — icon-only especially.
    final iconSize = layout == _ItemLayout.iconOnly
        ? switch (size) {
            ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 20.0,
            ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 24.0,
            ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 28.0,
            ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 30.0,
          }
        : switch (size) {
            ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 16.0,
            ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 20.0,
            ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 22.0,
            ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 24.0,
          };
    final fontSize = ConsonaGeometries.fontSizeFor(size);
    final padScale = switch (size) {
      ConsonaOpticalSize.xs || ConsonaOpticalSize.sqXs => 0.7,
      ConsonaOpticalSize.sm || ConsonaOpticalSize.sqSm => 0.85,
      ConsonaOpticalSize.md || ConsonaOpticalSize.sqMd => 1.0,
      ConsonaOpticalSize.lg || ConsonaOpticalSize.sqLg => 1.1,
    };
    double p(double v) => (v * padScale).roundToDouble();
    final chipRadius = theme.radius.resolve(
      pill ? ConsonaRadiusRole.full : ConsonaRadiusRole.base,
    );

    // Options are horizontal stadiums (H ≥ V). Bar equal-pad lives on the
    // surface, not here. Dense keeps H-pad tight so tabs don't balloon.
    final EdgeInsets chipPadding = switch (layout) {
      _ItemLayout.stacked => EdgeInsets.symmetric(
          horizontal: dense ? p(ConsonaSpacing.sm) : p(ConsonaSpacing.md),
          vertical: dense ? p(ConsonaSpacing.xs) : p(ConsonaSpacing.sm),
        ),
      _ItemLayout.iconOnly => EdgeInsets.symmetric(
          horizontal: dense ? p(ConsonaSpacing.sm) : p(ConsonaSpacing.md),
          vertical: dense ? p(ConsonaSpacing.xs) : p(ConsonaSpacing.sm),
        ),
      _ItemLayout.row => EdgeInsets.symmetric(
          horizontal: dense ? p(ConsonaSpacing.sm) : p(ConsonaSpacing.md),
          vertical: dense ? p(ConsonaSpacing.xs) : p(ConsonaSpacing.sm),
        ),
      _ItemLayout.sideRow => EdgeInsets.symmetric(
          horizontal: dense ? p(ConsonaSpacing.md) : p(ConsonaSpacing.lg),
          vertical: dense ? p(ConsonaSpacing.sm) : p(ConsonaSpacing.md),
        ),
    };

    return ConsonaPressStateBuilder(
      builder: (context, pressed, setPressed) {
        final rest = colors.surface.withAlpha(0);
        final fill = pressed
            ? colors.stateTint(rest, ConsonaInteractionState.pressed)
            : rest;

        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fg),
          duration: motion.duration,
          curve: motion.curve,
          builder: (context, activeColor, _) {
            final activeFg = activeColor ?? fg;

            final icon = Icon(
              selected
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
              size: iconSize,
              color: activeFg,
            );
            final badge = destination.badge;
            final label = ConsonaText.label(
              destination.label,
              color: activeFg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
                height: 1.1,
              ),
            );

            final overlayIcon = badge == null
                ? icon
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      icon,
                      PositionedDirectional(
                        top: -ConsonaSpacing.xs,
                        end: -ConsonaSpacing.sm,
                        child: badge,
                      ),
                    ],
                  );

            final Widget content;
            switch (layout) {
              case _ItemLayout.stacked:
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    overlayIcon,
                    SizedBox(height: p(ConsonaSpacing.xxs)),
                    label,
                    if (indicator == ConsonaNavIndicator.dot)
                      SizedBox(height: p(ConsonaSpacing.xs))
                    else if (indicator == ConsonaNavIndicator.underline)
                      SizedBox(height: p(ConsonaSpacing.xxs)),
                  ],
                );
              case _ItemLayout.iconOnly:
                content = overlayIcon;
              case _ItemLayout.row:
                content = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    SizedBox(width: p(ConsonaSpacing.sm)),
                    Flexible(child: label),
                    if (badge != null) ...[
                      SizedBox(width: p(ConsonaSpacing.sm)),
                      badge,
                    ],
                  ],
                );
              case _ItemLayout.sideRow:
                content = Row(
                  children: [
                    icon,
                    SizedBox(width: p(ConsonaSpacing.md)),
                    Expanded(child: label),
                    if (badge != null) ...[
                      SizedBox(width: p(ConsonaSpacing.sm)),
                      badge,
                    ],
                  ],
                );
            }

            // Full-radius + square content = circle. Slight H>V keeps stadium tips.
            final estOuterH = switch (layout) {
              _ItemLayout.stacked =>
                iconSize + fontSize * 1.1 + p(ConsonaSpacing.xxs) + chipPadding.vertical,
              _ItemLayout.iconOnly => iconSize + chipPadding.vertical,
              _ => 0.0,
            };
            final pillMinWidth = estOuterH > 0
                ? estOuterH + p(ConsonaSpacing.xxs)
                : 0.0;

            Widget chipBody = AnimatedContainer(
              duration: motion.duration,
              curve: motion.curve,
              padding: theme.density.resolvePadding(chipPadding),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: chipRadius,
              ),
              alignment: pillMinWidth > 0 ? Alignment.center : null,
              child: content,
            );
            if (layout == _ItemLayout.sideRow) {
              chipBody = SizedBox(width: double.infinity, child: chipBody);
            } else if (pillMinWidth > 0) {
              chipBody = ConstrainedBox(
                constraints: BoxConstraints(minWidth: pillMinWidth),
                child: chipBody,
              );
            }

            final chip = KeyedSubtree(key: visualKey, child: chipBody);

            // Layout hugs the pill; hit slop expands without fattening the bar.
            return Semantics(
              container: true,
              button: true,
              selected: selected,
              label: destination.label,
              onTap: onTap,
              child: ExcludeSemantics(
                child: ConsonaHitTarget(
                  inflateLayout: false,
                  child: ConsonaSpringPress(
                    onTap: onTap,
                    onPressedChanged: setPressed,
                    feedbackEvent: FeedbackEvent.selection,
                    child: chip,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
