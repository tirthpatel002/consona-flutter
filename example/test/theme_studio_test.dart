import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';
import 'package:consona_flutter_example/main.dart';
import 'package:consona_flutter_example/pages/theme_studio_page.dart';

/// Lets the MaterialApp theme animation (200ms) run to completion.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

ConsonaThemeData currentTheme(WidgetTester tester) =>
    ConsonaTheme.of(tester.element(find.byType(ConsonaSection).first));

Future<void> tapText(WidgetTester tester, String label) async {
  final finder = find.text(label).first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ConsonaShowcaseApp());
    await settle(tester);
  }

  testWidgets('color seed buttons show a selected ring/check and restyle the app', (tester) async {
    await pumpApp(tester);

    // Nothing selected initially: no check marks in any swatch.
    expect(find.descendant(of: find.byType(ColorSeedButton), matching: find.byIcon(Icons.check)),
        findsNothing);
    final before = currentTheme(tester).colors.primary;

    await tapText(tester, 'Indigo');

    final indigo = find.widgetWithText(ColorSeedButton, 'Indigo');
    expect(tester.widget<ColorSeedButton>(indigo).selected, isTrue);
    expect(find.descendant(of: indigo, matching: find.byIcon(Icons.check)), findsOneWidget);
    // Exactly one swatch is selected.
    expect(
      tester.widgetList<ColorSeedButton>(find.byType(ColorSeedButton)).where((b) => b.selected),
      hasLength(1),
    );
    expect(
      tester.getSemantics(indigo),
      matchesSemantics(
        label: 'Indigo seed color',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: false,
      ),
    );

    // The seed really restyles the theme (primary color changes).
    final after = currentTheme(tester).colors.primary;
    expect(after, isNot(before));
    expect(after, ConsonaColorScheme.fromSeed(const Color(0xFF4F46E5)).light.primary);

    await tapText(tester, 'Rose');
    expect(tester.widget<ColorSeedButton>(find.widgetWithText(ColorSeedButton, 'Rose')).selected, isTrue);
    expect(tester.widget<ColorSeedButton>(find.widgetWithText(ColorSeedButton, 'Indigo')).selected, isFalse);
    expect(currentTheme(tester).colors.primary,
        ConsonaColorScheme.fromSeed(const Color(0xFFE11D48)).light.primary);
  });

  testWidgets('radius control changes corners app-wide and shows its selected state', (tester) async {
    await pumpApp(tester);

    double sectionRadius() {
      final clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(ConsonaSection).first, matching: find.byType(ClipRRect)).first,
      );
      return (clip.borderRadius as BorderRadius).topLeft.x;
    }

    ConsonaChip chip(String label) =>
        tester.widget<ConsonaChip>(find.widgetWithText(ConsonaChip, label).first);

    expect(sectionRadius(), 15.0); // minimal / md
    expect(chip('Medium').selected, isTrue);

    await tapText(tester, 'Square');
    expect(sectionRadius(), 0.0);
    expect(chip('Square').selected, isTrue);
    expect(chip('Medium').selected, isFalse);

    await tapText(tester, 'XL');
    expect(sectionRadius(), 33.0);
    expect(chip('XL').selected, isTrue);

    await tapText(tester, 'iOS');
    expect(sectionRadius(), 24.0);
    expect(currentTheme(tester).radius.isSquircle, isTrue);

    // Same control in dark mode must also work (and not reset the seed).
    await tapText(tester, 'Indigo');
    await tapText(tester, 'Dark');
    await tapText(tester, 'Square');
    expect(sectionRadius(), 0.0);
    expect(currentTheme(tester).colors.isDark, isTrue);
    expect(currentTheme(tester).colors.primary,
        ConsonaColorScheme.fromSeed(const Color(0xFF4F46E5)).dark.primary);
  });

  testWidgets('every Theme-page knob applies its change and marks the option selected', (tester) async {
    await pumpApp(tester);
    ConsonaChip chip(String label) =>
        tester.widget<ConsonaChip>(find.widgetWithText(ConsonaChip, label).first);

    await tapText(tester, 'Spacious');
    expect(currentTheme(tester).density.preset, ConsonaDensityPreset.spacious);
    expect(chip('Spacious').selected && !chip('Normal').selected, isTrue);

    await tapText(tester, 'Strong');
    expect(currentTheme(tester).shadow.preset, ConsonaShadowLevel.strong);
    expect(chip('Strong').selected, isTrue);

    await tapText(tester, 'Bold');
    expect(currentTheme(tester).stroke.preset, ConsonaStrokePreset.bold);
    expect(chip('Bold').selected, isTrue);

    await tapText(tester, 'Both');
    expect(currentTheme(tester).border.strategy, ConsonaBorderStrategy.both);
    expect(chip('Both').selected, isTrue);

    await tapText(tester, 'Bouncy');
    expect(currentTheme(tester).motion.softness, ConsonaMotionSoftness.bouncy);
    expect(chip('Bouncy').selected, isTrue);

    await tapText(tester, 'Tabular figures');
    expect(currentTheme(tester).typography.tabularFigures, isTrue);
    expect(chip('Tabular figures').selected, isTrue);

    await tapText(tester, 'Dark');
    expect(currentTheme(tester).colors.isDark, isTrue);
    expect(chip('Dark').selected, isTrue);
    // Knobs survive the light/dark switch.
    expect(currentTheme(tester).density.preset, ConsonaDensityPreset.spacious);

    await tapText(tester, 'Light');
    expect(currentTheme(tester).colors.isDark, isFalse);
    expect(chip('Light').selected, isTrue);

    await tapText(tester, 'iOS Squircle');
    expect(currentTheme(tester).radius.isSquircle, isTrue);
    expect(chip('iOS Squircle').selected, isTrue);
    expect(chip('Minimal').selected, isFalse);
  });
}
