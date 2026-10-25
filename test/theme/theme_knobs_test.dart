import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  group('Theme Knobs & Presets', () {
    test('presets instantiate with distinct knob settings', () {
      final minimal = ConsonaPresets.minimal();
      final linear = ConsonaPresets.linear();
      final ios = ConsonaPresets.ios();
      final mechanical = ConsonaPresets.mechanical();
      final soft = ConsonaPresets.soft();

      expect(minimal.stroke.preset, equals(ConsonaStrokePreset.standard));
      expect(linear.density.preset, equals(ConsonaDensityPreset.compact));
      expect(ios.radius.isSquircle, isTrue);
      expect(mechanical.stroke.preset, equals(ConsonaStrokePreset.bold));
      expect(soft.stroke.preset, equals(ConsonaStrokePreset.flat));
    });

    test('flat stroke resolves to 0.0 width', () {
      const stroke = ConsonaStroke.flat();
      expect(stroke.resolveWidth(), equals(0.0));
    });

    test('density scales height and padding correctly', () {
      const compact = ConsonaDensity.compact();
      expect(compact.resolveHeight(40.0), equals(34.0)); // 40 * 0.85 = 34
    });

    test('border resolution produces empty border under flat stroke', () {
      const stroke = ConsonaStroke.flat();
      final colors = ConsonaColorScheme.minimal().light;
      final border = ConsonaBorder(stroke: stroke, colors: colors);

      final boxBorder = border.resolve(ConsonaBorderRole.subtle);
      expect(boxBorder.top.width, equals(0.0));
    });
  });
}
