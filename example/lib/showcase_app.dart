import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';
import 'pages/atoms_page.dart';
import 'pages/cells_page.dart';
import 'pages/feedback_page.dart';
import 'pages/navigation_page.dart';
import 'pages/showcase_studio_page.dart';
import 'pages/theme_studio_page.dart';

class ShowcaseHome extends StatefulWidget {
  const ShowcaseHome({super.key, required this.controller});

  final ConsonaThemeController controller;

  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome> {
  ConsonaNavVariant _variant = ConsonaNavVariant.section;
  ConsonaShellWide _wide = ConsonaShellWide.sidebar;
  ShowcaseHeaderMode _headerMode = ShowcaseHeaderMode.app;
  bool _showNavLabels = true;
  bool? _fitNavContent;
  bool _navInverted = false;
  ConsonaNavIndicator _navIndicator = ConsonaNavIndicator.glider;

  ConsonaSlot<ConsonaShellNavContext>? get _header => switch (_headerMode) {
        ShowcaseHeaderMode.app =>
          ConsonaSlot.widget(_AppHeader(controller: widget.controller)),
        ShowcaseHeaderMode.custom => ConsonaSlot.builder(
            (context, nav) => _CustomHeader(label: nav.selected?.label ?? ''),
          ),
        ShowcaseHeaderMode.library => null,
        ShowcaseHeaderMode.none => ConsonaSlot.empty,
      };

  @override
  Widget build(BuildContext context) {
    return ConsonaShell(
      header: _header,
      navVariant: _variant,
      showNavLabels: _showNavLabels,
      fitNavContent: _fitNavContent,
      navInverted: _navInverted,
      navIndicator: _navIndicator,
      wide: _wide,
      destinations: [
        ConsonaDestination(
          id: 'theme',
          label: 'Theme',
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette,
          builder: (_) => ThemeStudioPage(controller: widget.controller),
        ),
        ConsonaDestination(
          id: 'atoms',
          label: 'Atoms',
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
          builder: (_) => const AtomsPage(),
        ),
        ConsonaDestination(
          id: 'cells',
          label: 'Cells',
          icon: Icons.table_rows_outlined,
          selectedIcon: Icons.table_rows,
          builder: (_) => const CellsPage(),
        ),
        ConsonaDestination(
          id: 'feedback',
          label: 'Feedback',
          icon: Icons.hearing_outlined,
          selectedIcon: Icons.hearing,
          builder: (_) => const FeedbackPage(),
        ),
        ConsonaDestination(
          id: 'navigation',
          label: 'Navigation',
          icon: Icons.view_sidebar_outlined,
          selectedIcon: Icons.view_sidebar,
          builder: (_) => NavigationPage(
            variant: _variant,
            wide: _wide,
            headerMode: _headerMode,
            showNavLabels: _showNavLabels,
            fitNavContent: _fitNavContent,
            navInverted: _navInverted,
            indicator: _navIndicator,
            onVariant: (v) => setState(() => _variant = v),
            onWide: (v) => setState(() => _wide = v),
            onHeaderMode: (v) => setState(() => _headerMode = v),
            onShowNavLabels: (v) => setState(() => _showNavLabels = v),
            onFitNavContent: (v) => setState(() => _fitNavContent = v),
            onNavInverted: (v) => setState(() => _navInverted = v),
            onIndicator: (i) => setState(() => _navIndicator = i),
          ),
        ),
        ConsonaDestination(
          id: 'studio',
          label: 'Studio',
          icon: Icons.dashboard_customize_outlined,
          selectedIcon: Icons.dashboard_customize,
          builder: (_) => const ShowcaseStudioPage(),
        ),
      ],
    );
  }
}

/// The showcase app's own header, passed to the shell through the header slot.
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.controller});

  final ConsonaThemeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: theme.border.resolve(ConsonaBorderRole.divider, context: context),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          color: theme.colors.primary,
                          borderRadius: theme.radius.resolve(ConsonaRadiusRole.micro),
                        ),
                        alignment: Alignment.center,
                        child: ConsonaText.label(
                          'C',
                          color: theme.colors.onPrimary,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Flexible(
                        child: ConsonaText.titleMedium(
                          'Consona Flutter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const ConsonaBadge(
                        label: 'Phase 1–5',
                        intent: ConsonaIntent.subtle,
                      ),
                    ],
                  ),
                ),
                ConsonaIconButton.plain(
                  icon: Icon(
                    theme.colors.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: theme.colors.foreground,
                  ),
                  onTap: () {
                    final newMode = theme.colors.isDark
                        ? ConsonaThemeMode.light
                        : ConsonaThemeMode.dark;
                    controller.setThemeMode(newMode);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A second, deliberately different header to show the slot is app-owned.
class _CustomHeader extends StatelessWidget {
  const _CustomHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return ColoredBox(
      color: theme.colors.surfaceSecondary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const ConsonaBadge(label: 'Custom header', intent: ConsonaIntent.primary),
              const SizedBox(width: 12.0),
              Expanded(
                child: ConsonaText.body(
                  '$label · ${context.consonaWindowClass.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
