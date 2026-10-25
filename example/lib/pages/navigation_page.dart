import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';

/// Which header the example shell shows (header slot demo).
enum ShowcaseHeaderMode { app, custom, library, none }

/// Demonstrates [ConsonaShell]: variant, wide layout and header slot knobs.
class NavigationPage extends StatelessWidget {
  const NavigationPage({
    super.key,
    required this.variant,
    required this.wide,
    required this.headerMode,
    required this.showNavLabels,
    this.fitNavContent,
    required this.navInverted,
    required this.indicator,
    required this.onVariant,
    required this.onWide,
    required this.onHeaderMode,
    required this.onShowNavLabels,
    required this.onFitNavContent,
    required this.onNavInverted,
    required this.onIndicator,
  });

  final ConsonaNavVariant variant;
  final ConsonaShellWide wide;
  final ShowcaseHeaderMode headerMode;
  final bool showNavLabels;
  final bool? fitNavContent;
  final bool navInverted;
  final ConsonaNavIndicator indicator;
  final ValueChanged<ConsonaNavVariant> onVariant;
  final ValueChanged<ConsonaShellWide> onWide;
  final ValueChanged<ShowcaseHeaderMode> onHeaderMode;
  final ValueChanged<bool> onShowNavLabels;
  final ValueChanged<bool?> onFitNavContent;
  final ValueChanged<bool> onNavInverted;
  final ValueChanged<ConsonaNavIndicator> onIndicator;

  @override
  Widget build(BuildContext context) {
    final shell = ConsonaShellScope.of(context);
    final width = MediaQuery.sizeOf(context).width;

    Widget chips<T extends Enum>(
      List<T> values,
      T current,
      ValueChanged<T> onTap,
    ) {
      return Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          for (final v in values)
            ConsonaChip(
              label: v.name,
              selected: v == current,
              onTap: () => onTap(v),
            ),
        ],
      );
    }

    Widget row(String title, String subtitle, Widget control) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsonaText.titleMedium(title),
              const SizedBox(height: 2.0),
              ConsonaText.caption(subtitle),
              const SizedBox(height: 12.0),
              control,
            ],
          ),
        );

    final bottomInset = shell.isFloating ? 100.0 : 20.0;

    return ListView(
      padding: EdgeInsets.only(top: 20.0, bottom: bottomInset),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConsonaText.hero('Navigation'),
              SizedBox(height: 4.0),
              ConsonaText.caption(
                'ConsonaShell adapts bottom nav, side nav and sidebar. '
                'Resize the window to watch it change.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        ConsonaSection(
          header: 'Current window',
          children: [
            ConsonaListTile(
              title: 'Window class',
              subtitle: '${width.round()} px wide',
              trailing: ConsonaBadge(
                label: shell.windowClass.name,
                intent: ConsonaIntent.primary,
              ),
            ),
            ConsonaListTile(
              title: 'Nav placement',
              subtitle: !shell.showLabels
                  ? 'icons only (labels disabled)'
                  : (shell.compact ? 'icon-only (compact)' : 'full labels'),
              trailing: ConsonaBadge(
                label: shell.placement.name,
                intent: ConsonaIntent.subtle,
              ),
            ),
            ConsonaListTile(
              title: 'Nav labels (titles)',
              subtitle: shell.showLabels ? 'enabled (labels shown)' : 'disabled (icon-only)',
              trailing: ConsonaBadge(
                label: shell.showLabels ? 'visible' : 'hidden',
                intent: shell.showLabels ? ConsonaIntent.success : ConsonaIntent.subtle,
              ),
            ),
            ConsonaListTile(
              title: 'Nav width',
              subtitle: (shell.fitContent ?? (shell.variant == ConsonaNavVariant.bar))
                  ? 'fit-content (hugs destinations)'
                  : 'full width (stretches)',
              trailing: ConsonaBadge(
                label: (shell.fitContent ?? (shell.variant == ConsonaNavVariant.bar))
                    ? 'fit'
                    : 'full',
                intent: ConsonaIntent.subtle,
              ),
              showDivider: true,
            ),
            ConsonaListTile(
              title: 'Nav colors',
              subtitle: shell.inverted ? 'inverted palette' : 'standard palette',
              trailing: ConsonaBadge(
                label: shell.inverted ? 'inverted' : 'standard',
                intent: shell.inverted ? ConsonaIntent.primary : ConsonaIntent.subtle,
              ),
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        ConsonaSection(
          header: 'Shell knobs',
          footer: 'Wide applies at 1000 px and above.',
          children: [
            row(
              'Nav variant',
              'bar floats inset with radius and shadow; '
                  'section is edge-to-edge.',
              chips(ConsonaNavVariant.values, variant, onVariant),
            ),
            row(
              'Nav width (fit content)',
              'Whether the nav hugs its items or spans full available width.',
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaChip(
                    label: 'Fit content',
                    selected: (fitNavContent ?? (variant == ConsonaNavVariant.bar)),
                    onTap: () => onFitNavContent(true),
                  ),
                  ConsonaChip(
                    label: 'Full width',
                    selected: !(fitNavContent ?? (variant == ConsonaNavVariant.bar)),
                    onTap: () => onFitNavContent(false),
                  ),
                ],
              ),
            ),
            row(
              'Nav labels (titles)',
              'Toggle destination text labels under / beside icons across bottom, top, and side.',
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaChip(
                    label: 'With titles',
                    selected: showNavLabels,
                    onTap: () => onShowNavLabels(true),
                  ),
                  ConsonaChip(
                    label: 'Icons only',
                    selected: !showNavLabels,
                    onTap: () => onShowNavLabels(false),
                  ),
                ],
              ),
            ),
            row(
              'Nav colors (inverted)',
              'Invert colors in the nav (dark dock in light mode, light dock in dark mode).',
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ConsonaChip(
                    label: 'Standard',
                    selected: !navInverted,
                    onTap: () => onNavInverted(false),
                  ),
                  ConsonaChip(
                    label: 'Inverted',
                    selected: navInverted,
                    onTap: () => onNavInverted(true),
                  ),
                ],
              ),
            ),
            row(
              'Selected indicator',
              'glider = background pill; dot = minimal circle below; '
                  'underline = horizontal accent line below.',
              chips(ConsonaNavIndicator.values, indicator, onIndicator),
            ),
            row(
              'Wide layout',
              'sidebar = full side nav; header = top nav in the header area.',
              chips(ConsonaShellWide.values, wide, onWide),
            ),
            row(
              'Header slot',
              'app = this app\'s header, custom = another widget, '
                  'library = built-in default, none = ConsonaSlot.empty.',
              chips(ShowcaseHeaderMode.values, headerMode, onHeaderMode),
            ),
          ],
        ),
      ],
    );
  }
}
