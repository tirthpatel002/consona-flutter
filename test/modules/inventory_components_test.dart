import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(800, 1200)}) {
  return MaterialApp(
    theme: ThemeData(extensions: [ConsonaThemeData.minimal()]),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ConsonaStatusDot', () {
    testWidgets('renders online label and semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const ConsonaStatusDot.online(label: 'Live', ring: true)),
      );
      expect(find.text('Live'), findsOneWidget);
      expect(tester.getSemantics(find.byType(ConsonaStatusDot)).label, 'Online');
      handle.dispose();
    });

    testWidgets('pulse animation starts when enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(const ConsonaStatusDot.busy(pulse: true, label: 'Busy')),
      );
      expect(find.text('Busy'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  });

  group('ConsonaPill', () {
    testWidgets('renders label and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          ConsonaPill(
            label: 'Beta',
            intent: ConsonaIntent.primary,
            onTap: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Beta'), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('ConsonaNumberField', () {
    testWidgets('types values, clamps on blur, and nudges via steppers',
        (tester) async {
      num? value = 5;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaNumberField(
              label: 'Qty',
              value: value,
              min: 0,
              max: 10,
              step: 1,
              showSteppers: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      expect(find.text('Qty'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump();
      // Still shows typed text while focused; blur clamps.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(value, 10);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(value, 9);
    });

    testWidgets('rejects excess decimals', (tester) async {
      num? value = 1.2;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaNumberField(
              value: value,
              decimalPlaces: 1,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '1.25');
      await tester.pump();
      // Formatter should keep previous valid value text pattern.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text.contains('1.25'), isFalse);
    });
  });

  group('ConsonaAutocomplete', () {
    testWidgets('filters suggestions and selects on tap', (tester) async {
      String? selected;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaAutocomplete<String>(
              label: 'City',
              items: const ['Berlin', 'Bergen', 'Paris', 'Tokyo'],
              onSelected: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Ber');
      await tester.pumpAndSettle();

      expect(find.text('Berlin'), findsWidgets);
      expect(find.text('Bergen'), findsOneWidget);
      expect(find.text('Paris'), findsNothing);

      await tester.tap(find.text('Bergen'));
      await tester.pumpAndSettle();
      expect(selected, 'Bergen');
    });

    testWidgets('keyboard arrows highlight and Enter commits', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          ConsonaAutocomplete<String>(
            items: const ['Alpha', 'Beta', 'Gamma'],
            onSelected: (v) => selected = v,
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
    });
  });

  group('ConsonaBanner', () {
    testWidgets('renders title, action, and dismiss', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        _wrap(
          ConsonaBanner.warning(
            title: 'Maintenance',
            description: 'Tonight at 2am',
            action: const Text('Details'),
            onClose: () => closed = true,
          ),
        ),
      );

      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Tonight at 2am'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      await tester.tap(find.text('✕'));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('stacks action under text on narrow widths', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ConsonaBanner.info(
            title: 'Narrow banner',
            description: 'Should stack',
            action: const Text('Act'),
          ),
          size: const Size(360, 800),
        ),
      );
      expect(find.text('Narrow banner'), findsOneWidget);
      expect(find.text('Act'), findsOneWidget);
    });
  });

  group('ConsonaPagination', () {
    testWidgets('prev/next and page numbers change page', (tester) async {
      var page = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            Padding(
              padding: const EdgeInsets.all(16),
              child: ConsonaPagination(
                page: page,
                totalItems: 48,
                pageSize: 10,
                onPageChanged: (p) => setState(() => page = p),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Showing 1–10 of 48'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(page, 1);
      expect(find.textContaining('Showing 11–20 of 48'), findsOneWidget);

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(page, 2);
    });

    testWidgets('compact mode shows page fraction controls', (tester) async {
      var page = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaPagination(
              page: page,
              totalItems: 30,
              pageSize: 10,
              onPageChanged: (p) => setState(() => page = p),
            ),
            size: const Size(320, 600),
          ),
        ),
      );

      expect(find.text('2 / 3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(page, 2);
    });
  });

  group('ConsonaTable + ConsonaPagination', () {
    testWidgets('table footer uses ConsonaPagination', (tester) async {
      final rows = List.generate(
        6,
        (i) => (id: '$i', name: 'Row $i'),
      );
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: ConsonaTable<({String id, String name})>(
              title: 'Paged',
              rows: rows,
              rowKey: (r) => r.id,
              rowsPerPage: 2,
              columns: [
                ConsonaTableColumn(
                  id: 'name',
                  label: 'Name',
                  valueText: (r) => r.name,
                  cellBuilder: (_, r) => Text(r.name),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ConsonaPagination), findsOneWidget);
      expect(find.textContaining('Showing 1–2 of 6'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Showing 3–4 of 6'), findsOneWidget);
    });
  });
}
