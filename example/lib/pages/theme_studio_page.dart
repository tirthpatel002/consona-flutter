import 'package:flutter/material.dart';
import 'package:consona_flutter/consona_flutter.dart';

/// Theme Studio: every knob reads its *selected* state from the controller
/// (single source of truth) and writes through the controller's knob setters,
/// which update both the light and dark themes and notify listeners.
class ThemeStudioPage extends StatelessWidget {
  const ThemeStudioPage({super.key, required this.controller});

  final ConsonaThemeController controller;

  static const _seeds = <(String, Color)>[
    ('Mono', Color(0xFF111827)),
    ('Indigo', Color(0xFF4F46E5)),
    ('Emerald', Color(0xFF059669)),
    ('Rose', Color(0xFFE11D48)),
    ('Amber', Color(0xFFD97706)),
    ('Violet', Color(0xFF7C3AED)),
  ];

  static const _monoTypography = ConsonaTypography(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'monospace', 'Roboto Mono'],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final theme = ConsonaTheme.of(context);
        // Knobs are identical in the light and dark theme, so read the
        // selected state straight from the controller (no animation lag).
        final active = controller.theme;
        final typo = active.typography;
        final typographyMode = typo.fontFamily != null
            ? 'mono'
            : typo.tabularFigures
                ? 'tabular'
                : 'default';

        final shell = ConsonaShellScope.maybeOf(context);
        final bottomInset = (shell?.isFloating ?? false) ? 100.0 : 20.0;

        return ListView(
          padding: EdgeInsets.only(top: 20.0, bottom: bottomInset),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ConsonaText.hero('Theme Studio'),
                  const SizedBox(height: 4.0),
                  ConsonaText.caption(
                    'Tweak whole-theme knobs and watch every atom in the app instantly respond.',
                    color: theme.colors.mutedFg,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // 1. Whole-Theme Named Presets
            ConsonaSection(
              header: 'Presets',
              footer: 'Swaps all knobs simultaneously to achieve an out-of-the-box design language.',
              children: [
                _OptionTile<String>(
                  title: 'Preset',
                  subtitle: controller.activePreset.isEmpty
                      ? 'Custom'
                      : controller.activePreset,
                  showDivider: false,
                  selected: controller.activePreset,
                  onSelect: controller.setPreset,
                  options: const [
                    ('Minimal', 'minimal'),
                    ('Linear', 'linear'),
                    ('iOS Squircle', 'ios'),
                    ('Mechanical', 'mechanical'),
                    ('Soft & Deep', 'soft'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 2. Color Palette & Tonal Seed
            ConsonaSection(
              header: 'Brand Tonal Seed',
              footer: 'Derives WCAG AA-verified light and dark palettes from a single seed color.',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: [
                      for (final (name, color) in _seeds)
                        ColorSeedButton(
                          color: color,
                          name: name,
                          selected: controller.seedColor == color,
                          onTap: () => controller.setSeedColor(color),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 3. Knobs: Radius, Density, Shadow, Stroke, Border strategy, Motion, Typography
            ConsonaSection(
              header: 'Geometry & Stroke Knobs',
              children: [
                _OptionTile<ConsonaRadius>(
                  title: 'Radius (Corners)',
                  subtitle:
                      'Active: ${active.radius.isSquircle ? 'Squircle' : '${active.radius.base.toInt()}pt'}',
                  selected: active.radius,
                  onSelect: controller.setRadius,
                  options: const [
                    ('Square', ConsonaRadius.none()),
                    ('Small', ConsonaRadius.sm()),
                    ('Medium', ConsonaRadius.md()),
                    ('Large', ConsonaRadius.lg()),
                    ('XL', ConsonaRadius.xl()),
                    ('iOS', ConsonaRadius.squircle()),
                  ],
                ),
                _OptionTile<ConsonaDensityPreset>(
                  title: 'Density (Spacing & Scale)',
                  subtitle: 'Preset: ${active.density.preset.name} (${active.density.factor}x)',
                  selected: active.density.preset,
                  onSelect: (p) => controller.setDensity(switch (p) {
                    ConsonaDensityPreset.compact => const ConsonaDensity.compact(),
                    ConsonaDensityPreset.normal => const ConsonaDensity.normal(),
                    ConsonaDensityPreset.spacious => const ConsonaDensity.spacious(),
                  }),
                  options: const [
                    ('Compact', ConsonaDensityPreset.compact),
                    ('Normal', ConsonaDensityPreset.normal),
                    ('Spacious', ConsonaDensityPreset.spacious),
                  ],
                ),
                _OptionTile<ConsonaShadowLevel>(
                  title: 'Shadow & Elevation',
                  subtitle: 'Preset: ${active.shadow.preset.name}',
                  selected: active.shadow.preset,
                  onSelect: controller.setShadowLevel,
                  options: const [
                    ('None', ConsonaShadowLevel.none),
                    ('Subtle', ConsonaShadowLevel.subtle),
                    ('Soft', ConsonaShadowLevel.soft),
                    ('Strong', ConsonaShadowLevel.strong),
                  ],
                ),
                _OptionTile<ConsonaStrokePreset>(
                  title: 'Stroke & Hairlines',
                  subtitle: 'Preset: ${active.stroke.preset.name}',
                  selected: active.stroke.preset,
                  onSelect: (p) => controller.setStroke(switch (p) {
                    ConsonaStrokePreset.flat => const ConsonaStroke.flat(),
                    ConsonaStrokePreset.standard => const ConsonaStroke.standard(),
                    ConsonaStrokePreset.bold => const ConsonaStroke.bold(),
                  }),
                  options: const [
                    ('Flat', ConsonaStrokePreset.flat),
                    ('Standard', ConsonaStrokePreset.standard),
                    ('Bold', ConsonaStrokePreset.bold),
                  ],
                ),
                _OptionTile<ConsonaBorderStrategy>(
                  title: 'Border Strategy',
                  subtitle: 'Edges drawn as: ${active.border.strategy.name}',
                  selected: active.border.strategy,
                  onSelect: controller.setBorderStrategy,
                  options: const [
                    ('Border', ConsonaBorderStrategy.border),
                    ('Shadow', ConsonaBorderStrategy.shadow),
                    ('Both', ConsonaBorderStrategy.both),
                    ('None', ConsonaBorderStrategy.none),
                  ],
                ),
                _OptionTile<String>(
                  title: 'Motion & Springs',
                  subtitle: active.motion.reduced
                      ? 'Softness: instant (reduced)'
                      : 'Softness: ${active.motion.softness.name}',
                  selected: active.motion.reduced ? 'instant' : active.motion.softness.name,
                  onSelect: (m) => controller.setMotion(switch (m) {
                    'crisp' => const ConsonaMotion.crisp(),
                    'bouncy' => const ConsonaMotion.bouncy(),
                    'instant' => const ConsonaMotion.instant(),
                    _ => const ConsonaMotion.soft(),
                  }),
                  options: const [
                    ('Crisp', 'crisp'),
                    ('Soft', 'soft'),
                    ('Bouncy', 'bouncy'),
                    ('Instant', 'instant'),
                  ],
                ),
                _OptionTile<String>(
                  title: 'Typography',
                  subtitle: 'Style: $typographyMode',
                  showDivider: false,
                  selected: typographyMode,
                  onSelect: (m) => controller.setTypography(switch (m) {
                    'tabular' => const ConsonaTypography(tabularFigures: true),
                    'mono' => _monoTypography,
                    _ => const ConsonaTypography(),
                  }),
                  options: const [
                    ('Default', 'default'),
                    ('Tabular figures', 'tabular'),
                    ('Mono', 'mono'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 4. Mode Selection
            ConsonaSection(
              header: 'Appearance Mode',
              children: [
                _OptionTile<ConsonaThemeMode>(
                  title: 'Theme Mode',
                  subtitle: 'Current: ${controller.themeMode.name.toUpperCase()}',
                  showDivider: false,
                  selected: controller.themeMode,
                  onSelect: controller.setThemeMode,
                  options: const [
                    ('Light', ConsonaThemeMode.light),
                    ('Dark', ConsonaThemeMode.dark),
                    ('System', ConsonaThemeMode.system),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A titled row of mutually exclusive options with clear selected state
/// (selected chips are filled with the primary color).
class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final List<(String, T)> options;
  final T selected;
  final ValueChanged<T> onSelect;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Container(
      width: double.infinity,
      padding: theme.density.resolvePadding(
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: showDivider
            ? theme.border.resolve(ConsonaBorderRole.divider, context: context)
            : const Border(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConsonaText.body(title),
          const SizedBox(height: 2.0),
          ConsonaText.caption(subtitle, color: theme.colors.mutedFg),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final (label, value) in options)
                Semantics(
                  selected: value == selected,
                  inMutuallyExclusiveGroup: true,
                  child: ConsonaChip(
                    label: label,
                    selected: value == selected,
                    onTap: () => onSelect(value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seed swatch with an unmistakable selected state: a foreground ring around
/// the swatch plus a check mark, and a bold label.
class ColorSeedButton extends StatelessWidget {
  const ColorSeedButton({
    super.key,
    required this.color,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name seed color',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FeedbackEngine.of(context).trigger(FeedbackEvent.selection);
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? theme.colors.foreground : const Color(0x00000000),
                  width: 2.0,
                ),
              ),
              child: Container(
                key: ValueKey('seed-swatch-$name'),
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha((255 * 0.3).round()),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(Icons.check, size: 20.0, color: Color(0xFFFFFFFF))
                    : null,
              ),
            ),
            const SizedBox(height: 4.0),
            ConsonaText.label(
              name,
              color: selected ? theme.colors.foreground : theme.colors.mutedFg,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
