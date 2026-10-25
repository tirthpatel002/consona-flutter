import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';
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
  group('ConsonaLink', () {
    testWidgets('renders and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(ConsonaLink(label: 'Docs', onTap: () => tapped = true)),
      );
      await tester.tap(find.text('Docs'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('ConsonaFab', () {
    testWidgets('shows extended label on wide layouts', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaFab(
            icon: Icon(Icons.add),
            label: 'Compose',
            extended: true,
          ),
        ),
      );
      expect(find.text('Compose'), findsOneWidget);
    });
  });

  group('ConsonaShowMore', () {
    testWidgets('expands and collapses text', (tester) async {
      var expanded = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaShowMore(
              text: 'One two three four five six seven eight nine ten.',
              maxLines: 1,
              expanded: expanded,
              onExpandedChanged: (v) => setState(() => expanded = v),
            ),
          ),
        ),
      );
      expect(find.text('Show more'), findsOneWidget);
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();
      expect(expanded, isTrue);
      expect(find.text('Show less'), findsOneWidget);
    });
  });

  group('ConsonaSnippet', () {
    testWidgets('renders language and copy affordance', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaSnippet(
            language: 'dart',
            code: 'print(1);\nprint(2);\nprint(3);',
            maxLines: 1,
          ),
        ),
      );
      expect(find.text('dart'), findsOneWidget);
      expect(find.textContaining('Show'), findsOneWidget);
    });

    testWidgets('switches multi-tab panes and copies active source',
        (tester) async {
      var selected = 'dart';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaSnippet(
              selectedTabId: selected,
              onTabChanged: (id) => setState(() => selected = id),
              maxLines: 8,
              tabs: const [
                ConsonaSnippetTab(
                  id: 'dart',
                  label: 'Dart',
                  code: 'print("dart");',
                ),
                ConsonaSnippetTab(
                  id: 'swift',
                  label: 'Swift',
                  code: 'print("swift")',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('print("dart");'), findsOneWidget);
      await tester.tap(find.text('Swift'));
      await tester.pumpAndSettle();
      expect(selected, 'swift');
      expect(find.text('print("swift")'), findsOneWidget);
      expect(find.text('print("dart");'), findsNothing);
    });
  });

  group('ConsonaActionSheet', () {
    testWidgets('presents actions and returns selected id', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => ConsonaButton.primary(
              label: 'Open',
              onTap: () async {
                selected = await ConsonaActionSheet.show(
                  context,
                  actions: const [
                    ConsonaActionSheetItem(id: 'save', label: 'Save'),
                    ConsonaActionSheetItem(
                      id: 'delete',
                      label: 'Delete',
                      destructive: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(selected, 'save');
    });
  });

  group('ConsonaMultiSelect', () {
    testWidgets('shows chips for selected values', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ConsonaMultiSelect<String>(
            label: 'Roles',
            values: const {'A', 'B'},
            items: const ['A', 'B', 'C'],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('ConsonaToolbar', () {
    testWidgets('renders children and divider', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: ConsonaToolbar(
              children: [
                ConsonaIconButton.plain(
                  icon: const Icon(Icons.crop),
                  onTap: () {},
                ),
                const ConsonaToolbarDivider(),
                ConsonaIconButton.plain(
                  icon: const Icon(Icons.tune),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ConsonaToolbarDivider), findsOneWidget);
      expect(find.byType(ConsonaIconButton), findsNWidgets(2));
    });

    testWidgets('collapses actions behind the handle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: ConsonaToolbar(
              collapsible: true,
              children: [
                ConsonaIconButton.plain(
                  icon: const Icon(Icons.inbox_outlined),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ConsonaIconButton), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ConsonaIconButton), findsNothing);
    });

    testWidgets('scrolls horizontally when constrained', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 180,
            child: ConsonaToolbar(
              scrollable: true,
              trailing: ConsonaButton.primary(
                label: 'Export',
                size: ConsonaOpticalSize.xs,
                onTap: () {},
              ),
              children: [
                for (var i = 0; i < 8; i++)
                  ConsonaIconButton.plain(
                    icon: const Icon(Icons.crop_rounded),
                    size: ConsonaOpticalSize.sqXs,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });
  });

  group('ConsonaMeter', () {
    testWidgets('renders segmented capacity meter', (tester) async {
      await tester.pumpWidget(
        _wrap(const ConsonaMeter(value: 0.75, label: 'Load', segments: 8)),
      );
      expect(find.text('Load'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('ConsonaTree', () {
    testWidgets('expands branch and selects leaf', (tester) async {
      String? selected;
      var expanded = <String>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaTree(
              expandedIds: expanded,
              onExpandedChanged: (ids) => setState(() => expanded = ids),
              selectedId: selected,
              onSelected: (n) => setState(() => selected = n.id),
              nodes: const [
                ConsonaTreeNode(
                  id: 'root',
                  label: 'Root',
                  children: [
                    ConsonaTreeNode(id: 'child', label: 'Child'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Root'));
      await tester.pumpAndSettle();
      expect(expanded.contains('root'), isTrue);
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      expect(selected, 'child');
    });
  });

  group('ConsonaInfiniteScroll', () {
    testWidgets('requests load more near end', (tester) async {
      var loads = 0;
      final items = List.generate(8, (i) => 'Item $i');
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 200,
            child: ConsonaInfiniteScroll<String>(
              items: items,
              hasMore: true,
              loading: false,
              threshold: 400,
              onLoadMore: () {
                loads++;
              },
              itemBuilder: (_, item, __) => SizedBox(
                height: 48,
                child: Text(item),
              ),
            ),
          ),
          size: const Size(400, 600),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(loads, greaterThan(0));
    });
  });

  group('ConsonaColorPicker', () {
    testWidgets('opens editor and shows hex', (tester) async {
      var color = const Color.fromARGB(255, 37, 99, 235);
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaColorPicker(
              label: 'Accent',
              value: color,
              onChanged: (c) => setState(() => color = c),
            ),
          ),
        ),
      );
      expect(find.textContaining('#'), findsOneWidget);
      await tester.tap(find.textContaining('#'));
      await tester.pumpAndSettle();
      expect(find.text('Presets'), findsOneWidget);
    });
  });
}
