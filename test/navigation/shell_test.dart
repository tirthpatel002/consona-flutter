import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

class _Counter extends StatefulWidget {
  const _Counter(this.name);
  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    _built.add(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() => count++),
        child: Text('${widget.name}:$count:${context.consonaWindowClass.name}'),
      ),
    );
  }
}

final _built = <String>[];

List<ConsonaDestination> _dests() => [
      ConsonaDestination(
        id: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        builder: (_) => const _Counter('home'),
      ),
      ConsonaDestination(
        id: 'search',
        label: 'Search',
        icon: Icons.search,
        builder: (_) => const _Counter('search'),
      ),
      ConsonaDestination(
        id: 'me',
        label: 'Me',
        icon: Icons.person_outline,
        builder: (_) => const _Counter('me'),
      ),
    ];

Future<void> _size(WidgetTester tester, double w, [double h = 800]) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, h);
  await tester.pump();
}

Future<void> _pump(WidgetTester tester, Widget shell, {double w = 400}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(w, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ConsonaProvider(child: MaterialApp(home: shell)),
  );
  await tester.pumpAndSettle();
}

Iterable<ConsonaNav> _navs(WidgetTester tester) =>
    tester.widgetList<ConsonaNav>(find.byType(ConsonaNav));

bool _has(WidgetTester tester, ConsonaNavPlacement p) =>
    _navs(tester).any((n) => n.placement == p);

void main() {
  setUp(_built.clear);

  group('ConsonaShell layout', () {
    testWidgets('400 -> bottom nav only', (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()), w: 400);
      expect(_has(tester, ConsonaNavPlacement.bottom), isTrue);
      expect(_has(tester, ConsonaNavPlacement.side), isFalse);
      expect(_has(tester, ConsonaNavPlacement.top), isFalse);
      expect(find.text('home:0:compact'), findsOneWidget);
    });

    testWidgets('800 -> compact side nav, no bottom nav', (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()), w: 800);
      expect(_has(tester, ConsonaNavPlacement.bottom), isFalse);
      final nav = _navs(tester).single;
      expect(nav.placement, ConsonaNavPlacement.side);
      expect(nav.compact, isTrue);
      expect(find.text('home:0:medium'), findsOneWidget);
    });

    testWidgets('1400 -> sidebar with labels, no bottom nav', (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()), w: 1400);
      expect(_has(tester, ConsonaNavPlacement.bottom), isFalse);
      final nav = _navs(tester).single;
      expect(nav.placement, ConsonaNavPlacement.side);
      expect(nav.compact, isFalse);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('home:0:expanded'), findsOneWidget);
    });

    testWidgets('1400 + wide:header -> top nav, no bottom nav', (tester) async {
      await _pump(
        tester,
        ConsonaShell(destinations: _dests(), wide: ConsonaShellWide.header),
        w: 1400,
      );
      expect(_has(tester, ConsonaNavPlacement.bottom), isFalse);
      expect(_has(tester, ConsonaNavPlacement.side), isFalse);
      expect(_navs(tester).single.placement, ConsonaNavPlacement.top);
      // The nav sits at the top of the window.
      expect(tester.getTopLeft(find.byType(ConsonaNav)).dy, 0);
    });

    testWidgets('breakpoints are customizable', (tester) async {
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          breakpoints: const ConsonaBreakpoints(medium: 300, expanded: 500),
        ),
        w: 400,
      );
      expect(_navs(tester).single.placement, ConsonaNavPlacement.side);
    });

    testWidgets('bar variant at bottom overlays content in a stack so page extends to screen bottom', (tester) async {
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          navVariant: ConsonaNavVariant.bar,
          showDefaultHeader: false,
        ),
        w: 400,
      );
      // Content extends all the way to the 800-height screen bottom.
      expect(tester.getSize(find.byType(Stack).first).height, 800);
      // Nav is placed at the bottom over the content.
      expect(tester.getBottomLeft(find.byType(ConsonaNav)).dy, 800);
    });
  });

  group('ConsonaShell state', () {
    testWidgets('selection and page state survive 400 -> 1400 -> 400',
        (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()), w: 400);

      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      expect(find.text('search:0:compact'), findsOneWidget);
      await tester.tap(find.text('search:0:compact'));
      await tester.pump();
      expect(find.text('search:1:compact'), findsOneWidget);

      await _size(tester, 1400);
      await tester.pumpAndSettle();
      expect(find.text('search:1:expanded'), findsOneWidget);
      expect(_built.where((e) => e == 'search').length, 1);

      await _size(tester, 400);
      await tester.pumpAndSettle();
      expect(find.text('search:1:compact'), findsOneWidget);
      expect(_built.where((e) => e == 'search').length, 1);
    });

    testWidgets('pages are lazy and kept alive', (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()));
      expect(_built, ['home']);
      await tester.tap(find.text('home:0:compact'));
      await tester.pump();
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      expect(_built, ['home', 'search']);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('home:1:compact'), findsOneWidget);
      expect(_built, ['home', 'search']);
    });

    testWidgets('controlled selection reports onSelect', (tester) async {
      final selected = <String>[];
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          selectedId: 'me',
          onSelect: selected.add,
        ),
      );
      expect(find.text('me:0:compact'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(selected, ['home']);
      expect(find.text('me:0:compact'), findsOneWidget);
    });

    testWidgets('initialId picks the first page', (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests(), initialId: 'me'));
      expect(find.text('me:0:compact'), findsOneWidget);
    });
  });

  group('ConsonaShell slots', () {
    testWidgets('custom header replaces the default', (tester) async {
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          header: ConsonaSlot.widget(const Text('MY HEADER')),
        ),
      );
      expect(find.text('MY HEADER'), findsOneWidget);
      // default header would repeat the selected label as a title
      expect(find.text('Home'), findsOneWidget); // nav label only
    });

    testWidgets('ConsonaSlot.empty removes the header; default shows title',
        (tester) async {
      await _pump(tester, ConsonaShell(destinations: _dests()));
      expect(find.text('Home'), findsNWidgets(2)); // header title + nav label

      await _pump(
        tester,
        ConsonaShell(destinations: _dests(), header: ConsonaSlot.empty),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('showDefaultHeader: false hides the default header',
        (tester) async {
      await _pump(
        tester,
        ConsonaShell(destinations: _dests(), showDefaultHeader: false),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('custom nav replaces the default ConsonaNav', (tester) async {
      ConsonaShellNavContext? seen;
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          nav: (n) {
            seen = n;
            return TextButton(
              onPressed: () => n.onSelect('me'),
              child: const Text('CUSTOM NAV'),
            );
          },
        ),
      );
      expect(find.byType(ConsonaNav), findsNothing);
      expect(find.text('CUSTOM NAV'), findsOneWidget);
      expect(seen!.windowClass, ConsonaWindowClass.compact);
      expect(seen!.placement, ConsonaNavPlacement.bottom);
      await tester.tap(find.text('CUSTOM NAV'));
      await tester.pumpAndSettle();
      expect(find.text('me:0:compact'), findsOneWidget);
    });

    testWidgets('ConsonaShellScope exposes selection to pages', (tester) async {
      await _pump(
        tester,
        ConsonaShell(
          destinations: [
            ConsonaDestination(
              id: 'a',
              label: 'A',
              icon: Icons.add,
              builder: (c) => Text(
                'sel=${ConsonaShellScope.of(c).selected?.id}/${c.consonaWindowClass.name}',
              ),
            ),
          ],
        ),
      );
      expect(find.text('sel=a/compact'), findsOneWidget);
    });

    testWidgets('maxContentWidth constrains the page', (tester) async {
      await _pump(
        tester,
        ConsonaShell(destinations: _dests(), maxContentWidth: 300),
        w: 1400,
      );
      expect(tester.getSize(find.byType(IndexedStack)).width, 300);
    });
  });

  group('ConsonaShell fail-closed', () {
    testWidgets('empty destinations render an empty state without throwing',
        (tester) async {
      await _pump(tester, const ConsonaShell(destinations: []));
      expect(tester.takeException(), isNull);
      expect(find.byType(ConsonaNav), findsNothing);
      expect(find.text('Nothing to show yet.'), findsOneWidget);
      await _size(tester, 1400);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown selectedId falls back to the first destination',
        (tester) async {
      await _pump(
        tester,
        ConsonaShell(destinations: _dests(), selectedId: 'nope'),
      );
      expect(find.text('home:0:compact'), findsOneWidget);
    });

    testWidgets('windowClass outside a shell does not throw', (tester) async {
      late ConsonaWindowClass wc;
      await _pump(
        tester,
        Builder(builder: (c) {
          wc = c.consonaWindowClass;
          return const SizedBox();
        }),
        w: 800,
      );
      expect(wc, ConsonaWindowClass.medium);
    });
  });

  group('ConsonaNav semantics', () {
    testWidgets('selected destination exposes the selected flag',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, ConsonaShell(destinations: _dests(), initialId: 'search'));

      SemanticsNode node(String label) => tester.getSemantics(
            find.descendant(
              of: find.byType(ConsonaNav),
              matching: find.bySemanticsLabel(label),
            ),
          );

      expect(node('Search').flagsCollection.isSelected, Tristate.isTrue);
      expect(node('Home').flagsCollection.isSelected, Tristate.isFalse);
      expect(node('Search').flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('ConsonaShell respects showNavLabels and showNavTitles',
        (tester) async {
      await _pump(
        tester,
        ConsonaShell(
          destinations: _dests(),
          showNavLabels: false,
        ),
      );
      // In bottom nav, destination label texts are hidden when showNavLabels is false
      final nav = find.byType(ConsonaNav);
      expect(
        find.descendant(of: nav, matching: find.text('Home')),
        findsNothing,
      );
      expect(
        find.descendant(of: nav, matching: find.text('Search')),
        findsNothing,
      );

      // Default shell shows destination labels
      await _pump(
        tester,
        ConsonaShell(destinations: _dests()),
      );
      expect(
        find.descendant(of: nav, matching: find.text('Home')),
        findsOneWidget,
      );
    });
  });
}
