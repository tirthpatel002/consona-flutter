import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

/// Reads the corner radius painted by the first Container with a BoxDecoration
/// or ShapeDecoration radius under [of].
double _paintedRadius(WidgetTester tester, Finder of) {
  for (final d in tester.widgetList<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)),
  )) {
    final dec = d.decoration;
    if (dec is BoxDecoration && dec.borderRadius != null) {
      return (dec.borderRadius! as BorderRadius).topLeft.x;
    }
    if (dec is ShapeDecoration) {
      final shape = dec.shape;
      if (shape is ContinuousRectangleBorder) {
        return (shape.borderRadius as BorderRadius).topLeft.x;
      }
      if (shape is RoundedRectangleBorder) {
        return (shape.borderRadius as BorderRadius).topLeft.x;
      }
    }
  }
  throw StateError('No DecoratedBox with borderRadius found under $of');
}

Widget _app(ConsonaThemeController controller, Widget child) {
  return ConsonaProvider(
    controller: controller,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('radius knob reaches components', () {
    testWidgets('setRadius restyles ConsonaButton, ConsonaSection and ConsonaChip', (tester) async {
      final controller = ConsonaThemeController(themeMode: ConsonaThemeMode.light);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(
        controller,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConsonaButton.primary(label: 'Go', onTap: () {}),
            const ConsonaChip(label: 'Chip'),
            const ConsonaSection(children: [SizedBox(width: 100, height: 40)]),
          ],
        ),
      ));
      await tester.pump();

      final button = find.byType(ConsonaButton);
      final chip = find.byType(ConsonaChip);
      final section = find.byType(ConsonaSection);

      expect(_paintedRadius(tester, button), ConsonaRadii.base); // md default
      final chipBefore = _paintedRadius(tester, chip);
      expect(chipBefore, greaterThan(0));

      controller.setRadius(const ConsonaRadius.none());
      await tester.pumpAndSettle(); // chip decoration animates
      expect(_paintedRadius(tester, button), 0.0);
      expect(_paintedRadius(tester, chip), 0.0);
      expect(_paintedRadius(tester, section), 0.0);

      controller.setRadius(const ConsonaRadius.xl());
      await tester.pump();
      expect(_paintedRadius(tester, button), ConsonaRadii.xl);
      expect(_paintedRadius(tester, section), ConsonaRadii.xl * 1.5);

      controller.setRadius(const ConsonaRadius.squircle());
      await tester.pump();
      expect(_paintedRadius(tester, button), ConsonaRadii.macro);
    });

    testWidgets('radius change works in dark mode and keeps the brand seed', (tester) async {
      final controller = ConsonaThemeController(themeMode: ConsonaThemeMode.dark);
      addTearDown(controller.dispose);
      const seed = Color(0xFF4F46E5);
      controller.setSeedColor(seed);

      await tester.pumpWidget(_app(
        controller,
        ConsonaButton.primary(label: 'Go', onTap: () {}),
      ));
      await tester.pump();
      final darkPrimary = ConsonaColorScheme.fromSeed(seed).dark.primary;
      expect(controller.darkTheme.colors.primary, darkPrimary);

      controller.setRadius(const ConsonaRadius.none());
      await tester.pump();
      expect(_paintedRadius(tester, find.byType(ConsonaButton)), 0.0);
      // Both palettes survive a knob change (previously dark mode reset the seed).
      expect(controller.darkTheme.colors.primary, darkPrimary);
      expect(controller.theme.colors.primary,
          ConsonaColorScheme.fromSeed(seed).light.primary);
      expect(controller.theme.colors.isDark, isFalse);
      expect(controller.darkTheme.radius, const ConsonaRadius.none());
      expect(controller.theme.radius, const ConsonaRadius.none());
    });
  });

  group('controller knob setters notify and apply to both themes', () {
    test('every knob setter notifies once and updates light + dark', () {
      final controller = ConsonaThemeController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setRadius(const ConsonaRadius.lg());
      controller.setDensity(const ConsonaDensity.spacious());
      controller.setShadowLevel(ConsonaShadowLevel.strong);
      controller.setStroke(const ConsonaStroke.bold());
      controller.setBorderStrategy(ConsonaBorderStrategy.both);
      controller.setMotion(const ConsonaMotion.bouncy());
      controller.setTypography(const ConsonaTypography(tabularFigures: true));
      expect(notifications, 7);

      for (final t in [controller.theme, controller.darkTheme]) {
        expect(t.radius, const ConsonaRadius.lg());
        expect(t.density.preset, ConsonaDensityPreset.spacious);
        expect(t.shadow.preset, ConsonaShadowLevel.strong);
        expect(t.stroke.preset, ConsonaStrokePreset.bold);
        expect(t.border.strategy, ConsonaBorderStrategy.both);
        expect(t.shadow.strategy, ConsonaBorderStrategy.both);
        expect(t.border.stroke.preset, ConsonaStrokePreset.bold);
        expect(t.motion.softness, ConsonaMotionSoftness.bouncy);
        expect(t.typography.tabularFigures, isTrue);
      }
    });

    test('shadow preset scales component elevation; none flattens', () {
      const none = ConsonaShadow.none();
      const subtle = ConsonaShadow.subtle();
      const strong = ConsonaShadow.strong();
      expect(none.resolve(ConsonaShadowLevel.subtle), isEmpty);
      final s = subtle.resolve(ConsonaShadowLevel.subtle);
      final st = strong.resolve(ConsonaShadowLevel.subtle);
      expect(s, isNotEmpty);
      expect(st.first.blurRadius, greaterThan(s.first.blurRadius));
      // Edge-only strategies still draw a hairline on flat surfaces.
      const edge = ConsonaShadow(
        preset: ConsonaShadowLevel.none,
        strategy: ConsonaBorderStrategy.shadow,
      );
      expect(edge.resolve(ConsonaShadowLevel.none), hasLength(1));
    });

    test('theme lerp lands exactly on the target at t=1', () {
      final a = ConsonaPresets.minimal();
      final b = ConsonaPresets.minimal().copyWith(
        stroke: const ConsonaStroke.standard(),
        radius: const ConsonaRadius.squircle(),
      );
      final end = a.lerp(b, 1.0);
      expect(end.radius, const ConsonaRadius.squircle());
      expect(identical(end, b), isTrue);
    });

    test('ConsonaColors.invert() inverts Mono palette to crisp whitish primary', () {
      final monoColors = ConsonaColorScheme.minimal().light;
      final inverted = monoColors.invert();
      expect(inverted.primary, const Color(0xFFFAFAFA));
      expect(inverted.isDark, isTrue);
    });
  });
}
