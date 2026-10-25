import 'dart:io';

import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Token-Only & Production Readiness Tests', () {
    test('No widget module under lib/src/modules/ uses raw Color(0x...) literals', () {
      final modulesDir = Directory('lib/src/modules');
      expect(modulesDir.existsSync(), isTrue);

      final colorRegex = RegExp(r'Color\(\s*0x[0-9A-Fa-f]+');
      final violations = <String>[];

      for (final entity in modulesDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.startsWith('//')) continue;
            if (colorRegex.hasMatch(line)) {
              violations.add('${entity.path}:${i + 1}: $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found raw Color(0x...) literals in lib/src/modules/:\n'
            '${violations.join('\n')}',
      );
    });

    test('ConsonaThemeData.dark() preserves brand primary across presets and custom themes', () {
      final presets = <ConsonaThemeData>[
        ConsonaPresets.linear(),
        ConsonaPresets.ios(),
        ConsonaPresets.mechanical(),
        ConsonaPresets.soft(),
      ];
      for (final light in presets) {
        final dark = light.dark();
        expect(dark.colors.isDark, isTrue);
        expect(
          dark.colors.primary,
          equals(light.colors.invert().primary),
          reason:
              'Preset should invert its own brand primary for dark mode rather than falling back to Linear dark',
        );
      }
    });

    test('ConsonaRadius.resolveShape returns ContinuousRectangleBorder when squircle is enabled', () {
      final squircleRadius = ConsonaRadius.fromPreset(ConsonaRadiusPreset.squircle);
      final shape = squircleRadius.resolveShape(ConsonaRadiusRole.base);
      expect(shape, isA<ContinuousRectangleBorder>());

      final roundedRadius = ConsonaRadius.fromPreset(ConsonaRadiusPreset.md);
      final roundedShape = roundedRadius.resolveShape(ConsonaRadiusRole.base);
      expect(roundedShape, isA<RoundedRectangleBorder>());
    });

    test('ConsonaAssetLibrary 3-tier fallback falls back network -> synth when network fails', () async {
      final library = ConsonaAssetLibrary(
        networkFetcher: (_) async => throw Exception('offline'),
      );
      library.registerFallback(
        'tap',
        const SynthAsset(SoundRecipe(frequency: 800.0)),
      );
      library.register(
        'tap',
        const NetworkAsset('https://cdn.example.com/tap.wav'),
      );

      final resolved = await library.loadBytes('tap');
      expect(resolved, isNotNull);
      expect(resolved!.isNotEmpty, isTrue);
    });

    testWidgets('ConsonaComponentThemes overrides apply to ConsonaButton and ConsonaCard', (tester) async {
      final theme = const ConsonaThemeConfig(
        components: ConsonaComponentThemes(
          button: ConsonaButtonThemeData(
            defaultSize: ConsonaOpticalSize.lg,
            shape: ConsonaShapeVariant.pill,
          ),
          card: ConsonaCardThemeData(
            padding: EdgeInsets.all(24.0),
          ),
        ),
      ).toThemeData();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ConsonaProvider(
            theme: theme,
            child: Column(
              children: [
                ConsonaButton(
                  label: 'Test Button',
                  onTap: () {},
                ),
                const ConsonaCard(
                  child: Text('Card Child'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.text('Card Child'), findsOneWidget);
    });
  });
}
