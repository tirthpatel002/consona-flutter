import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

List<ConsonaDestination> _dests() => [
      ConsonaDestination(
        id: 'a',
        label: 'Alpha',
        icon: Icons.add,
        builder: (_) => const SizedBox(),
      ),
      ConsonaDestination(
        id: 'b',
        label: 'Beta',
        icon: Icons.remove,
        builder: (_) => const SizedBox(),
      ),
    ];

Future<void> _pumpNav(
  WidgetTester tester, {
  required ConsonaNavVariant variant,
  ConsonaNavPlacement placement = ConsonaNavPlacement.bottom,
  bool compact = false,
  bool? showLabels,
  bool? showTitles,
  bool? fitContent,
  bool inverted = false,
  TextDirection dir = TextDirection.ltr,
  ValueChanged<String>? onSelect,
  String? selectedId,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ConsonaProvider(
      child: MaterialApp(
        builder: (c, child) => Directionality(textDirection: dir, child: child!),
        home: Material(
          child: Align(
            alignment: switch (placement) {
              ConsonaNavPlacement.bottom => Alignment.bottomCenter,
              ConsonaNavPlacement.top => Alignment.topCenter,
              ConsonaNavPlacement.side => AlignmentDirectional.centerStart,
            },
            child: ConsonaNav(
              destinations: _dests(),
              selectedId: selectedId ?? 'a',
              onSelect: onSelect ?? (_) {},
              placement: placement,
              variant: variant,
              compact: compact,
              showLabels: showLabels,
              showTitles: showTitles,
              fitContent: fitContent,
              inverted: inverted,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _surface => find.byKey(ConsonaNav.surfaceKey);

void main() {
  group('ConsonaNav variants', () {
    testWidgets('section is edge-to-edge and flush with the bottom',
        (tester) async {
      await _pumpNav(tester, variant: ConsonaNavVariant.section);
      final r = tester.getRect(_surface);
      expect(r.left, 0);
      expect(r.right, 400);
      expect(r.bottom, 800);
      final theme = ConsonaTheme.of(tester.element(_surface));
      final box = tester.widget<ColoredBox>(_surface);
      expect(box.color, theme.colors.surface);
      // Section edge uses theme defaultBorder (not hairline divider / borderLight).
      final expected = theme.border
          .resolveSide(ConsonaBorderRole.defaultBorder, context: tester.element(_surface));
      expect(expected.width, greaterThan(0));
      expect(expected.color, theme.colors.border);
      final edgeBox = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == expected.color && w != box,
      );
      expect(edgeBox, findsOneWidget);
      expect(tester.getSize(edgeBox).height, expected.width);
    });

    testWidgets('bar is inset, rounded and elevated', (tester) async {
      await _pumpNav(tester, variant: ConsonaNavVariant.bar);
      final r = tester.getRect(_surface);
      expect(r.left, greaterThan(0));
      expect(r.right, lessThan(400));
      expect(r.bottom, lessThan(800));
      final deco =
          tester.widget<DecoratedBox>(_surface).decoration as BoxDecoration;
      expect(deco.borderRadius, isNotNull);
      expect((deco.borderRadius! as BorderRadius).topLeft.x, greaterThan(0));
      // Children are clipped to the pill; soft shadow sits on the outer wrapper.
      expect(
        find.ancestor(of: _surface, matching: find.byType(ClipRRect)),
        findsOneWidget,
      );
      final theme = ConsonaTheme.of(tester.element(_surface));
      final shadowHost = tester.widget<DecoratedBox>(
        find.ancestor(
          of: find.ancestor(of: _surface, matching: find.byType(ClipRRect)),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (shadowHost.decoration as BoxDecoration).boxShadow,
        theme.shadow.resolve(ConsonaShadowLevel.soft),
      );
    });

    testWidgets('bar hugs content width (fitContent: true) compared to full width',
        (tester) async {
      await _pumpNav(tester, variant: ConsonaNavVariant.bar, fitContent: true);
      final fitWidth = tester.getSize(_surface).width;
      expect(fitWidth, lessThan(360));

      await _pumpNav(tester, variant: ConsonaNavVariant.bar, fitContent: false);
      final fullWidth = tester.getSize(_surface).width;
      expect(fullWidth, greaterThan(fitWidth));
    });

    testWidgets('bar variant has equal horizontal and vertical inner padding',
        (tester) async {
      await _pumpNav(tester, variant: ConsonaNavVariant.bar, fitContent: true);
      final surfaceRect = tester.getRect(_surface);
      final gliderFinder = find.byKey(ConsonaNav.gliderKey);
      final gliderRect = tester.getRect(gliderFinder);

      final leftPadding = gliderRect.left - surfaceRect.left;
      final topPadding = gliderRect.top - surfaceRect.top;
      final bottomPadding = surfaceRect.bottom - gliderRect.bottom;

      expect(leftPadding, equals(topPadding));
      expect(leftPadding, equals(bottomPadding));
    });

    testWidgets('section side nav is flush with top, bottom and leading edge',
        (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.side,
      );
      final r = tester.getRect(_surface);
      expect(r.left, 0);
      expect(r.top, 0);
      expect(r.bottom, 800);
    });

    testWidgets('bar side nav is inset from every edge', (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        placement: ConsonaNavPlacement.side,
        compact: true,
      );
      final r = tester.getRect(_surface);
      expect(r.left, greaterThan(0));
      expect(r.top, greaterThan(0));
      expect(r.bottom, lessThan(800));
    });

    testWidgets('compact side nav is icon-only; full side shows labels',
        (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.side,
        compact: true,
      );
      expect(find.text('Alpha'), findsNothing);
      final compactWidth = tester.getSize(_surface).width;

      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.side,
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(tester.getSize(_surface).width, greaterThan(compactWidth));
    });

    testWidgets('showLabels and showTitles toggles text visibility across placements',
        (tester) async {
      // Bottom nav with showLabels: false hides labels
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.bottom,
        showLabels: false,
      );
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);

      // Bottom nav with default showLabels: true shows labels
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.bottom,
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      // Top nav with showTitles: false hides labels
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        placement: ConsonaNavPlacement.top,
        showTitles: false,
      );
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);

      // Top nav with default showLabels: true shows labels
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        placement: ConsonaNavPlacement.top,
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('RTL: section side nav sits on the right edge', (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        placement: ConsonaNavPlacement.side,
        dir: TextDirection.rtl,
      );
      expect(tester.getRect(_surface).right, 400);
    });
  });

  group('ConsonaNav interaction', () {
    testWidgets('items meet the minimum hit target and select on tap',
        (tester) async {
      final tapped = <String>[];
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.section,
        onSelect: tapped.add,
      );
      // Layout hugs the pill; hit slop still expands (inflateLayout: false).
      expect(find.byType(ConsonaHitTarget), findsWidgets);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(tapped, ['b']);
    });

    testWidgets('selected item is distinguished by more than colour',
        (tester) async {
      await _pumpNav(tester, variant: ConsonaNavVariant.section);
      final texts = tester.widgetList<Text>(find.text('Alpha').evaluate().isEmpty
          ? find.byType(Text)
          : find.text('Alpha'));
      final alpha = texts.first.style!.fontWeight;
      final beta = tester.widget<Text>(find.text('Beta')).style!.fontWeight;
      expect(alpha, isNot(beta));
    });

    testWidgets('empty destinations render nothing', (tester) async {
      await tester.pumpWidget(
        ConsonaProvider(
          child: MaterialApp(
            home: ConsonaNav(destinations: const [], onSelect: (_) {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_surface, findsNothing);
    });

    testWidgets('inverted: true inverts surface and foreground colors',
        (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        inverted: true,
      );
      final decorated = tester.widget<DecoratedBox>(_surface);
      final decoration = decorated.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF18181B));
    });

    testWidgets('selected nav tab has glider opposite in polarity to nav surface',
        (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        inverted: false,
      );
      final gliderFinder = find.byKey(ConsonaNav.gliderKey);
      expect(gliderFinder, findsOneWidget);
      final positioned = tester.widget<AnimatedPositioned>(gliderFinder);
      final gliderDeco = (positioned.child as DecoratedBox).decoration as BoxDecoration;
      // In light mode, nav surface is light (~0xFFFFFFFF), glider is dark (opposite)
      expect(gliderDeco.color!.computeLuminance(), lessThan(0.5));
    });

    testWidgets('inverted nav tab glider is opposite to dark nav surface',
        (tester) async {
      await _pumpNav(
        tester,
        variant: ConsonaNavVariant.bar,
        inverted: true,
      );
      final gliderFinder = find.byKey(ConsonaNav.gliderKey);
      expect(gliderFinder, findsOneWidget);
      final positioned = tester.widget<AnimatedPositioned>(gliderFinder);
      final gliderDeco = (positioned.child as DecoratedBox).decoration as BoxDecoration;
      // In inverted mode, nav surface is dark (~0xFF18181B), glider is light (opposite)
      expect(gliderDeco.color!.computeLuminance(), greaterThan(0.5));
    });

    testWidgets('glider slides smoothly between tabs when selection changes',
        (tester) async {
      String selected = 'a';
      late StateSetter setStateCallback;
      await tester.pumpWidget(
        ConsonaProvider(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setStateCallback = setState;
                return ConsonaNav(
                  destinations: _dests(),
                  selectedId: selected,
                  onSelect: (id) => setState(() => selected = id),
                  variant: ConsonaNavVariant.bar,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gliderFinder = find.byKey(ConsonaNav.gliderKey);
      expect(gliderFinder, findsOneWidget);
      final rectA = tester.getRect(gliderFinder);

      // Select 'b'
      setStateCallback(() => selected = 'b');
      await tester.pump(); // Start animation frame

      // Mid-flight check
      await tester.pump(const Duration(milliseconds: 100));
      final rectMid = tester.getRect(gliderFinder);
      expect(rectMid.left, greaterThan(rectA.left));

      // Settle
      await tester.pumpAndSettle();
      final rectB = tester.getRect(gliderFinder);
      expect(rectB.left, greaterThan(rectA.left));
    });

    testWidgets('dot indicator renders as a small dot and slides smoothly',
        (tester) async {
      String selected = 'a';
      late StateSetter setStateCallback;
      await tester.pumpWidget(
        ConsonaProvider(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setStateCallback = setState;
                return ConsonaNav(
                  destinations: _dests(),
                  selectedId: selected,
                  onSelect: (id) => setState(() => selected = id),
                  variant: ConsonaNavVariant.bar,
                  indicator: ConsonaNavIndicator.dot,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final indicatorFinder = find.byKey(ConsonaNav.indicatorKey);
      expect(indicatorFinder, findsOneWidget);
      final sizeA = tester.getSize(indicatorFinder);
      expect(sizeA.width, equals(ConsonaSpacing.xs));
      expect(sizeA.height, equals(ConsonaSpacing.xs));
      final rectA = tester.getRect(indicatorFinder);

      // Select 'b'
      setStateCallback(() => selected = 'b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rectMid = tester.getRect(indicatorFinder);
      expect(rectMid.left, greaterThan(rectA.left));

      await tester.pumpAndSettle();
      final rectB = tester.getRect(indicatorFinder);
      expect(rectB.left, greaterThan(rectA.left));
    });

    testWidgets('underline indicator renders as a horizontal bar and slides smoothly',
        (tester) async {
      String selected = 'a';
      late StateSetter setStateCallback;
      await tester.pumpWidget(
        ConsonaProvider(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setStateCallback = setState;
                return ConsonaNav(
                  destinations: _dests(),
                  selectedId: selected,
                  onSelect: (id) => setState(() => selected = id),
                  variant: ConsonaNavVariant.bar,
                  indicator: ConsonaNavIndicator.underline,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final indicatorFinder = find.byKey(ConsonaNav.indicatorKey);
      expect(indicatorFinder, findsOneWidget);
      final sizeA = tester.getSize(indicatorFinder);
      expect(sizeA.height, equals(3.0));
      // Underline spans the selected tab (not a short centered stub).
      final tabA = tester.getSize(find.text('Alpha').hitTestable());
      expect(sizeA.width, greaterThan(tabA.width * 0.7));
      final rectA = tester.getRect(indicatorFinder);

      // Select 'b'
      setStateCallback(() => selected = 'b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final rectMid = tester.getRect(indicatorFinder);
      expect(rectMid.left, greaterThan(rectA.left));

      await tester.pumpAndSettle();
      final rectB = tester.getRect(indicatorFinder);
      expect(rectB.left, greaterThan(rectA.left));
    });
  });

  group('navigation token-only sanity', () {
    test('navigation sources use no hardcoded colors/durations/curves/borders',
        () {
      final dir = Directory('lib/src/modules/navigation');
      final banned = <RegExp>[
        RegExp(r'Color\(0x'),
        RegExp(r'Colors\.'),
        RegExp(r'Duration\('),
        RegExp(r'Curves\.'),
        RegExp(r'BorderRadius\.(circular|all|only)'),
        RegExp(r'Radius\.circular'),
        RegExp(r'\bBorderSide\('),
        RegExp(r'\bBorder(Directional)?\(|\bBorder\.all'),
        RegExp(r'\bBoxShadow\('),
      ];
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final re in banned) {
          expect(re.hasMatch(src), isFalse, reason: '${f.path} matches $re');
        }
      }
    });
  });
}
