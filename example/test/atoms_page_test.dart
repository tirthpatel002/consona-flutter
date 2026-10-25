import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';
import 'package:consona_flutter_example/main.dart';
import 'package:consona_flutter_example/pages/atoms_page.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('Atoms page controls apply state on a phone-sized screen without errors', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ConsonaShowcaseApp());
    await settle(tester);

    await tester.tap(find.text('Atoms'));
    await settle(tester);

    Future<void> tapVisible(Finder f) async {
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          f,
          200,
          scrollable: find.descendant(of: find.byType(AtomsPage), matching: find.byType(Scrollable)).first,
        );
      }
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await settle(tester);
      final e = tester.takeException();
      expect(e, isNull, reason: e is FlutterError ? e.toStringDeep() : '$e');
    }

    // Loading button enters loading and recovers by itself.
    await tester.tap(find.text('Run (2s loading)'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Run (2s loading)'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Run (2s loading)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Radios: select B then A; selected radio shows no text and no errors.
    await tester.scrollUntilVisible(
      find.text('Radio Option B (Pro)'),
      200,
      scrollable: find.descendant(of: find.byType(AtomsPage), matching: find.byType(Scrollable)).first,
    );
    final radios = find.byType(ConsonaRadio<String>);
    expect(radios, findsNWidgets(4)); // A, B + two disabled
    await tapVisible(radios.at(1));
    expect(tester.widget<ConsonaRadio<String>>(radios.at(1)).isSelected, isTrue);
    expect(tester.widget<ConsonaRadio<String>>(radios.at(0)).isSelected, isFalse);
    expect(find.descendant(of: radios.at(0), matching: find.byType(Text)), findsNothing);
    await tapVisible(radios.at(0));
    expect(tester.widget<ConsonaRadio<String>>(radios.at(0)).isSelected, isTrue);

    // Switches / checkboxes toggle.
    final switches = find.byType(ConsonaSwitch);
    final before = tester.widget<ConsonaSwitch>(switches.at(1)).value;
    await tapVisible(switches.at(1));
    expect(tester.widget<ConsonaSwitch>(switches.at(1)).value, !before);

    final checks = find.byType(ConsonaCheckbox);
    final cBefore = tester.widget<ConsonaCheckbox>(checks.at(1)).value;
    await tapVisible(checks.at(1));
    expect(tester.widget<ConsonaCheckbox>(checks.at(1)).value, !cBefore);

    // Disabled controls do not react.
    final disabledSwitch = switches.last;
    await tester.ensureVisible(disabledSwitch);
    await tester.pump();
    await tester.tap(disabledSwitch, warnIfMissed: false);
    await settle(tester);
    expect(tester.widget<ConsonaSwitch>(disabledSwitch).value, isTrue);

    // Chips toggle selected state.
    await tapVisible(find.text('Filter Tag'));
    expect(tester.widget<ConsonaChip>(find.widgetWithText(ConsonaChip, 'Filter Tag')).selected, isTrue);

    // Choice box selection moves.
    await tapVisible(find.text('Pro Enterprise'));
    expect(tester.widget<ConsonaChoiceBox>(find.widgetWithText(ConsonaChoiceBox, 'Pro Enterprise')).selected,
        isTrue);
  });

  testWidgets('every page renders without layout errors at phone width in dark + every preset', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ConsonaShowcaseApp());
    await settle(tester);

    for (final tab in ['Theme', 'Atoms', 'Cells', 'Feedback']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'page $tab');
    }

    await tester.tap(find.text('Theme').last);
    await settle(tester);
    for (final preset in ['Linear', 'iOS Squircle', 'Mechanical', 'Soft & Deep', 'Minimal']) {
      final f = find.text(preset).first;
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'preset $preset');
    }
  });
}
