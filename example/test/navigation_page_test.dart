import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';
import 'package:consona_flutter_example/main.dart';

Future<void> setWidth(WidgetTester tester, double w) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, 900);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('example shell adapts bottom -> side -> sidebar and back',
      (tester) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 400);
    await tester.pumpWidget(const ConsonaShowcaseApp());
    await setWidth(tester, 400);

    ConsonaNav nav() => tester.widget<ConsonaNav>(find.byType(ConsonaNav));
    expect(nav().placement, ConsonaNavPlacement.bottom);

    await tester.tap(find.text('Navigation').last);
    await setWidth(tester, 400);
    expect(find.text('compact'), findsOneWidget);

    await setWidth(tester, 800);
    expect(nav().placement, ConsonaNavPlacement.side);
    expect(nav().compact, isTrue);
    expect(find.text('medium'), findsOneWidget);

    await setWidth(tester, 1400);
    expect(nav().placement, ConsonaNavPlacement.side);
    expect(nav().compact, isFalse);
    expect(find.text('expanded'), findsOneWidget);

    // wide: header -> top nav
    await tester.scrollUntilVisible(find.text('header'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('header'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().placement, ConsonaNavPlacement.top);

    // variant: bar
    await tester.scrollUntilVisible(find.text('bar'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('bar'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().variant, ConsonaNavVariant.bar);
    expect(nav().effectiveFitContent, isTrue);

    // nav width: full width / fit content
    await tester.scrollUntilVisible(find.text('Full width'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Full width'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().effectiveFitContent, isFalse);

    await tester.tap(find.text('Fit content'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().effectiveFitContent, isTrue);

    // nav labels: icons only / with titles
    await tester.scrollUntilVisible(find.text('Icons only'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Icons only'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().showLabels, isFalse);

    await tester.tap(find.text('With titles'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().showLabels, isTrue);

    // nav colors inverted
    await tester.scrollUntilVisible(find.text('Inverted'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Inverted'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().inverted, isTrue);

    await tester.tap(find.text('Standard'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().inverted, isFalse);

    // nav indicator: dot / underline / glider
    await tester.scrollUntilVisible(find.text('dot'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('dot'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().indicator, ConsonaNavIndicator.dot);

    await tester.tap(find.text('underline'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().indicator, ConsonaNavIndicator.underline);

    await tester.tap(find.text('glider'));
    await tester.pump(const Duration(seconds: 1));
    expect(nav().indicator, ConsonaNavIndicator.glider);

    // custom header
    await tester.scrollUntilVisible(find.text('custom'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('custom'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Custom header'), findsOneWidget);
    expect(find.text('Consona Mobile'), findsNothing);

    await setWidth(tester, 400);
    expect(nav().placement, ConsonaNavPlacement.bottom);
    expect(tester.takeException(), isNull);
  });
}
