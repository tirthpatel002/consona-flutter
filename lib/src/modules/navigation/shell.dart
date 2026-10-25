/// Consona Shell — the app frame: adaptive nav + header + persistent pages
library;

import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import '../../core/slot.dart';
import '../../core/slots.dart';
import '../../core/types.dart';
import '../../theme/theme_provider.dart';
import '../../theme/tokens.dart';
import '../core/typography/text.dart';
import 'breakpoints.dart';
import 'destination.dart';
import 'nav.dart';

/// Everything a custom header / nav / page needs to know about the shell.
class ConsonaShellNavContext {
  const ConsonaShellNavContext({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.windowClass,
    this.placement = ConsonaNavPlacement.bottom,
    this.variant = ConsonaNavVariant.section,
    this.compact = false,
    bool? showLabels,
    bool? showTitles,
    this.fitContent,
    this.inverted = false,
    ConsonaNavIndicator? navIndicator,
    ConsonaNavIndicator? indicator,
    ConsonaNavIndicator? selectedIndicator,
  })  : navIndicator = navIndicator ?? indicator ?? selectedIndicator ?? ConsonaNavIndicator.glider,
        showLabels = showTitles ?? showLabels ?? true;

  final List<ConsonaDestination> destinations;

  /// Index of the selected destination, or -1 when there are none.
  final int selectedIndex;

  /// Selects a destination by [ConsonaDestination.id].
  final ValueChanged<String> onSelect;

  final ConsonaWindowClass windowClass;

  /// Where the shell will place the nav for the current window class.
  final ConsonaNavPlacement placement;
  final ConsonaNavVariant variant;

  /// Visual style of the selection indicator.
  final ConsonaNavIndicator navIndicator;

  /// Alias for [navIndicator].
  ConsonaNavIndicator get indicator => navIndicator;

  /// Alias for [navIndicator].
  ConsonaNavIndicator get selectedIndicator => navIndicator;

  /// Whether the shell expects an icon-only nav (medium widths).
  final bool compact;

  /// Whether the nav displays destination labels/titles.
  final bool showLabels;

  /// Alias for [showLabels].
  bool get showTitles => showLabels;

  /// Whether the nav bar hugs its content width.
  final bool? fitContent;

  /// Whether the nav inverts its color scheme.
  final bool inverted;

  /// Whether the nav is floating over the content (bar variant in bottom placement).
  bool get isFloating =>
      placement == ConsonaNavPlacement.bottom &&
      variant == ConsonaNavVariant.bar;

  ConsonaDestination? get selected =>
      selectedIndex >= 0 && selectedIndex < destinations.length
          ? destinations[selectedIndex]
          : null;

  String? get selectedId => selected?.id;
}

/// Exposes the shell state (selected destination, window class) to pages.
class ConsonaShellScope extends InheritedWidget {
  const ConsonaShellScope({super.key, required this.data, required super.child});

  final ConsonaShellNavContext data;

  static ConsonaShellNavContext? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConsonaShellScope>()?.data;

  /// The enclosing shell state; fail-closed (Rule C8): outside a shell this
  /// returns an empty state whose window class is derived from the screen width.
  static ConsonaShellNavContext of(BuildContext context) {
    final found = maybeOf(context);
    if (found != null) return found;
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 0.0;
    return ConsonaShellNavContext(
      destinations: const [],
      selectedIndex: -1,
      onSelect: (_) {},
      windowClass: const ConsonaBreakpoints().classify(width),
    );
  }

  @override
  bool updateShouldNotify(ConsonaShellScope old) =>
      data.selectedIndex != old.data.selectedIndex ||
      data.windowClass != old.data.windowClass ||
      data.destinations != old.data.destinations ||
      data.placement != old.data.placement ||
      data.variant != old.data.variant ||
      data.showLabels != old.data.showLabels ||
      data.fitContent != old.data.fitContent ||
      data.inverted != old.data.inverted ||
      data.navIndicator != old.data.navIndicator;
}

extension ConsonaWindowClassContext on BuildContext {
  /// Window class of the enclosing [ConsonaShell] (compact / medium / expanded).
  ConsonaWindowClass get consonaWindowClass =>
      ConsonaShellScope.of(this).windowClass;
}

class ConsonaShell extends StatefulWidget {
  const ConsonaShell({
    super.key,
    required this.destinations,
    this.initialId,
    this.selectedId,
    this.onSelect,
    this.header,
    this.showDefaultHeader = true,
    this.nav,
    this.navVariant = ConsonaNavVariant.section,
    bool? showNavLabels,
    bool? showNavTitles,
    this.fitNavContent,
    this.navInverted = false,
    ConsonaNavIndicator? navIndicator,
    ConsonaNavIndicator? indicator,
    ConsonaNavIndicator? selectedIndicator,
    this.navLeading,
    this.navTrailing,
    this.wide = ConsonaShellWide.sidebar,
    this.maxContentWidth,
    this.breakpoints = const ConsonaBreakpoints(),
  })  : navIndicator = navIndicator ?? indicator ?? selectedIndicator ?? ConsonaNavIndicator.glider,
        showNavLabels = showNavTitles ?? showNavLabels ?? true;

  final List<ConsonaDestination> destinations;

  /// Uncontrolled selection: the destination shown first.
  final String? initialId;

  /// Controlled selection: when set, only [onSelect] changes the selection.
  final String? selectedId;
  final ValueChanged<String>? onSelect;

  /// Header slot owned by the app: `ConsonaSlot.widget(...)`,
  /// `ConsonaSlot.builder(...)`, `ConsonaSlot.empty` (no header) or null
  /// (library default header when [showDefaultHeader] is true).
  final ConsonaSlot<ConsonaShellNavContext>? header;
  final bool showDefaultHeader;

  /// Replaces the default [ConsonaNav]. The shell still positions the result
  /// according to [ConsonaShellNavContext.placement].
  final Widget Function(ConsonaShellNavContext nav)? nav;

  /// Surface of the default nav: `section` (edge-to-edge) or `bar` (floating).
  final ConsonaNavVariant navVariant;

  /// Visual style of the selection indicator: `glider`, `dot`, or `underline`.
  final ConsonaNavIndicator navIndicator;

  /// Alias for [navIndicator].
  ConsonaNavIndicator get indicator => navIndicator;

  /// Alias for [navIndicator].
  ConsonaNavIndicator get selectedIndicator => navIndicator;

  /// Whether destination labels (titles) are displayed in the default nav.
  final bool showNavLabels;

  /// Alias for [showNavLabels].
  bool get showNavTitles => showNavLabels;

  /// Whether the nav bar hugs its content width. When null, defaults to
  /// true for [ConsonaNavVariant.bar] and false for [ConsonaNavVariant.section].
  final bool? fitNavContent;

  /// Whether the nav inverts its color scheme.
  final bool navInverted;

  /// Logo / profile slots forwarded to the default nav (side and top).
  final Widget? navLeading;
  final Widget? navTrailing;

  /// Layout at expanded widths: side `sidebar` or top nav in the `header`.
  final ConsonaShellWide wide;

  final double? maxContentWidth;
  final ConsonaBreakpoints breakpoints;

  @override
  State<ConsonaShell> createState() => _ConsonaShellState();
}

class _ConsonaShellState extends State<ConsonaShell> {
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'ConsonaShell.content');
  String? _internalId;

  List<ConsonaDestination> get _destinations {
    final seen = <String>{};
    return [
      for (final d in widget.destinations)
        if (seen.add(d.id)) d,
    ];
  }

  int _indexOf(List<ConsonaDestination> dests) {
    if (dests.isEmpty) return -1;
    final id = widget.selectedId ?? _internalId ?? widget.initialId;
    final i = id == null ? 0 : dests.indexWhere((d) => d.id == id);
    return i < 0 ? 0 : i;
  }

  void _select(String id) {
    if (widget.selectedId == null && _internalId != id) {
      setState(() => _internalId = id);
    }
    widget.onSelect?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final dests = _destinations;

    return Material(
      color: theme.colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final windowClass = widget.breakpoints.classify(width);

          if (dests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(ConsonaSpacing.xl),
                child: ConsonaText.body('Nothing to show yet.'),
              ),
            );
          }

          final index = _indexOf(dests);
          final topNav = windowClass == ConsonaWindowClass.expanded &&
              widget.wide == ConsonaShellWide.header;
          final placement = switch (windowClass) {
            ConsonaWindowClass.compact => ConsonaNavPlacement.bottom,
            ConsonaWindowClass.medium => ConsonaNavPlacement.side,
            ConsonaWindowClass.expanded =>
              topNav ? ConsonaNavPlacement.top : ConsonaNavPlacement.side,
          };
          final data = ConsonaShellNavContext(
            destinations: dests,
            selectedIndex: index,
            onSelect: _select,
            windowClass: windowClass,
            placement: placement,
            variant: widget.navVariant,
            compact: windowClass == ConsonaWindowClass.medium,
            showLabels: widget.showNavLabels,
            fitContent: widget.fitNavContent,
            inverted: widget.navInverted,
            navIndicator: widget.navIndicator,
          );

          return ConsonaShellScope(
            data: data,
            child: _layout(context, data),
          );
        },
      ),
    );
  }

  Widget _layout(BuildContext context, ConsonaShellNavContext data) {
    final theme = ConsonaTheme.of(context);
    final placement = data.placement;

    // Header: widget prop → registry override (`shell.header`) → default.
    final slot = widget.header ??
        ConsonaSlots.maybeOf<ConsonaShellNavContext>(context, 'shell.header');
    Widget? customHeader;
    var useDefaultHeader = false;
    if (slot == null) {
      useDefaultHeader = widget.showDefaultHeader;
    } else if (!slot.isEmpty) {
      customHeader = slot.resolve(context, data);
      useDefaultHeader = customHeader == null && widget.showDefaultHeader;
    }

    final title = data.selected?.label ?? '';

    Widget nav;
    final navSlot =
        ConsonaSlots.maybeOf<ConsonaShellNavContext>(context, 'shell.nav');
    final navFromSlot = navSlot?.resolve(context, data);
    if (widget.nav != null) {
      nav = widget.nav!(data);
    } else if (navFromSlot != null) {
      nav = navFromSlot;
    } else {
      nav = ConsonaNav(
        destinations: data.destinations,
        selectedIndex: data.selectedIndex,
        onSelect: data.onSelect,
        placement: placement,
        variant: widget.navVariant,
        compact: data.compact,
        showLabels: data.showLabels,
        fitContent: data.fitContent,
        inverted: data.inverted,
        indicator: data.navIndicator,
        leading: widget.navLeading ??
            (placement == ConsonaNavPlacement.top && useDefaultHeader
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                        end: ConsonaSpacing.xl),
                    child: ConsonaText.titleMedium(title),
                  )
                : null),
        trailing: widget.navTrailing,
      );
    }

    final content = KeyedSubtree(
      key: _contentKey,
      child: _Content(
        destinations: data.destinations,
        selectedIndex: data.selectedIndex,
        maxContentWidth: widget.maxContentWidth,
      ),
    );

    Widget? header;
    if (placement == ConsonaNavPlacement.top) {
      // The top nav lives inside the header area.
      header = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [if (customHeader != null) customHeader, nav],
      );
    } else if (customHeader != null) {
      header = customHeader;
    } else if (useDefaultHeader) {
      header = _DefaultHeader(title: title);
    }

    final isFloatingBottom = placement == ConsonaNavPlacement.bottom &&
        widget.navVariant == ConsonaNavVariant.bar;

    final effectiveContent = isFloatingBottom
        ? Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              final navReserve = 88.0 + media.padding.bottom;
              return MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(bottom: navReserve),
                  viewPadding: media.viewPadding.copyWith(bottom: navReserve),
                ),
                child: content,
              );
            },
          )
        : content;

    final pageBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header,
        Expanded(child: effectiveContent),
      ],
    );

    final Widget main;
    if (isFloatingBottom) {
      main = Stack(
        fit: StackFit.expand,
        children: [
          pageBody,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: nav,
          ),
        ],
      );
    } else {
      main = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          Expanded(child: content),
          if (placement == ConsonaNavPlacement.bottom) nav,
        ],
      );
    }

    if (placement == ConsonaNavPlacement.side) {
      return ColoredBox(
        color: theme.colors.background,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [nav, Expanded(child: main)],
        ),
      );
    }
    return ColoredBox(color: theme.colors.background, child: main);
  }
}

class _DefaultHeader extends StatelessWidget {
  const _DefaultHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final edge =
        theme.border.resolveSide(ConsonaBorderRole.divider, context: context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: theme.colors.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: theme.density.resolvePadding(const EdgeInsets.symmetric(
                horizontal: ConsonaSpacing.base,
                vertical: ConsonaSpacing.md,
              )),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConsonaText.titleMedium(title, maxLines: 1),
              ),
            ),
          ),
        ),
        if (edge.width > 0)
          SizedBox(height: edge.width, child: ColoredBox(color: edge.color)),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.destinations,
    required this.selectedIndex,
    required this.maxContentWidth,
  });

  final List<ConsonaDestination> destinations;
  final int selectedIndex;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final pages = _Pages(destinations: destinations, selectedIndex: selectedIndex);
    if (maxContentWidth == null) return pages;
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth!),
        child: pages,
      ),
    );
  }
}

/// Lazy-builds each page on first visit, then keeps it alive.
class _Pages extends StatefulWidget {
  const _Pages({required this.destinations, required this.selectedIndex});

  final List<ConsonaDestination> destinations;
  final int selectedIndex;

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  final Set<String> _visited = <String>{};

  @override
  Widget build(BuildContext context) {
    final dests = widget.destinations;
    final selected = widget.selectedIndex;
    if (selected >= 0 && selected < dests.length) {
      _visited.add(dests[selected].id);
    }
    return IndexedStack(
      index: selected < 0 ? null : selected,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < dests.length; i++)
          KeyedSubtree(
            key: ValueKey<String>(dests[i].id),
            child: _visited.contains(dests[i].id)
                ? ExcludeFocus(
                    excluding: i != selected,
                    child: ExcludeSemantics(
                      excluding: i != selected,
                      child: TickerMode(
                        enabled: i == selected,
                        child: Builder(builder: dests[i].builder),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}
