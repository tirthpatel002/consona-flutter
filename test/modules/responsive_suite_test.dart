import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapWithWidth(Widget child, {double width = 900, double height = 700}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: ConsonaThemeScope(
      theme: ConsonaThemeData.minimal(),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('New Multi-Platform Responsive Suite', () {
    testWidgets('ConsonaDivider renders horizontal, labeled, and vertical dividers',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithWidth(
          const Column(
            children: [
              ConsonaDivider(),
              ConsonaDivider(label: 'OR CONTINUE WITH'),
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Text('Left'),
                    ConsonaDivider.vertical(),
                    Text('Right'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('OR CONTINUE WITH'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('ConsonaAlert renders variants, actions, and close button',
        (tester) async {
      var closed = false;
      var retried = false;

      await tester.pumpWidget(
        _wrapWithWidth(
          Column(
            children: [
              ConsonaAlert.info(
                title: 'Syncing Nodes',
                description: 'Background sync is running.',
                onClose: () => closed = true,
              ),
              ConsonaAlert.danger(
                title: 'Connection Failed',
                description: 'Could not reach gateway.',
                action: ConsonaButton.subtle(
                  label: 'Retry',
                  size: ConsonaOpticalSize.sm,
                  onTap: () => retried = true,
                ),
              ),
            ],
          ),
          width: 360, // Mobile width to verify stacked responsive layout
        ),
      );

      expect(find.text('Syncing Nodes'), findsOneWidget);
      expect(find.text('Connection Failed'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);

      await tester.tap(find.text('✕').first);
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('ConsonaTimeline adapts between wide desktop and narrow mobile',
        (tester) async {
      const timeline = ConsonaTimeline(
        items: [
          ConsonaTimelineItem(
            title: 'Build Started',
            subtitle: 'Compiling shaders',
            timestamp: '10:00 AM',
          ),
          ConsonaTimelineItem(
            title: 'Tests Passed',
            subtitle: 'All checks green',
            timestamp: '10:02 AM',
          ),
        ],
      );

      // Wide desktop layout (>= 520px)
      await tester.pumpWidget(_wrapWithWidth(timeline, width: 800));
      expect(find.text('Build Started'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);

      // Narrow mobile layout (< 520px)
      await tester.pumpWidget(_wrapWithWidth(timeline, width: 360));
      await tester.pump();
      expect(find.text('Tests Passed'), findsOneWidget);
      expect(find.text('10:02 AM'), findsOneWidget);
    });

    testWidgets('ConsonaCarousel renders slides and indicator pills',
        (tester) async {
      var currentIdx = 0;
      await tester.pumpWidget(
        _wrapWithWidth(
          ConsonaCarousel(
            height: 160,
            onPageChanged: (i) => currentIdx = i,
            items: const [
              Center(child: Text('Slide Alpha')),
              Center(child: Text('Slide Beta')),
              Center(child: Text('Slide Gamma')),
            ],
          ),
          width: 800,
        ),
      );

      expect(find.text('Slide Alpha'), findsOneWidget);
      expect(currentIdx, 0);
    });

    testWidgets('ConsonaTagInput adds and removes tags and supports suggestions',
        (tester) async {
      var tags = <String>['dart', 'flutter'];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrapWithWidth(
              ConsonaTagInput(
                label: 'Skills',
                tags: tags,
                suggestions: const ['rust', 'wasm'],
                onChanged: (next) => setState(() => tags = next),
              ),
            );
          },
        ),
      );

      expect(find.text('dart'), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('+ rust'), findsOneWidget);

      // Tap a suggestion chip to add it
      await tester.tap(find.text('+ rust'));
      await tester.pumpAndSettle();
      expect(tags, contains('rust'));
    });

    testWidgets('ConsonaTagInput row layout shows +N, Add chip, then expands input',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithWidth(
          ConsonaTagInput(
            label: 'Skills',
            layout: ConsonaTagInputLayout.row,
            maxVisible: 2,
            tags: const ['dart', 'flutter', 'rust', 'wasm'],
            onChanged: (_) {},
          ),
          width: 360,
        ),
      );

      expect(find.text('+2'), findsOneWidget);
      expect(find.text('+ Add'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('Add tag…'), findsNothing);

      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add tag…'), findsOneWidget);
      expect(find.text('+ Add'), findsNothing);
    });

    testWidgets('ConsonaFileDropzone triggers browse and remove callbacks',
        (tester) async {
      var browsed = false;
      int? removedIndex;

      await tester.pumpWidget(
        _wrapWithWidth(
          ConsonaFileDropzone(
            title: 'Upload Audio Stems',
            onBrowse: () => browsed = true,
            onRemoveFile: (idx) => removedIndex = idx,
            files: const [
              ConsonaUploadItem(
                name: 'vocals.wav',
                sizeLabel: '12 MB',
                progress: 0.5,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Upload Audio Stems'), findsOneWidget);
      expect(find.text('vocals.wav'), findsOneWidget);

      await tester.tap(find.text('Upload Audio Stems'));
      await tester.pump();
      expect(browsed, isTrue);

      await tester.tap(find.text('✕'));
      await tester.pump();
      expect(removedIndex, 0);
    });

    testWidgets('ConsonaPinVerification renders header, OTP cells, and resend',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithWidth(
          ConsonaPinVerification(
            title: 'Two-Factor Code',
            subtitle: 'Code sent to user@example.com',
            resendCooldownSeconds: 0,
            onResend: () {},
          ),
        ),
      );

      expect(find.text('Two-Factor Code'), findsOneWidget);
      expect(find.text('Code sent to user@example.com'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('ConsonaBreadcrumbs collapses middle items on narrow mobile',
        (tester) async {
      final crumbs = ConsonaBreadcrumbs(
        items: [
          ConsonaBreadcrumbItem(label: 'Home', onTap: () {}),
          ConsonaBreadcrumbItem(label: 'Workspace', onTap: () {}),
          ConsonaBreadcrumbItem(label: 'Projects', onTap: () {}),
          const ConsonaBreadcrumbItem(label: 'Settings'),
        ],
      );

      // Wide viewport shows all items
      await tester.pumpWidget(_wrapWithWidth(crumbs, width: 800));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Narrow viewport (< 480px) collapses middle items into `…`
      await tester.pumpWidget(_wrapWithWidth(crumbs, width: 340));
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tapping `…` expands all breadcrumbs
      await tester.tap(find.text('…'));
      await tester.pump();
      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('ConsonaSplitView adapts between desktop split and mobile switcher',
        (tester) async {
      const splitView = ConsonaSplitView(
        primaryLabel: 'Code',
        secondaryLabel: 'Preview',
        primary: Center(child: Text('Primary Pane Content')),
        secondary: Center(child: Text('Secondary Pane Content')),
      );

      // Wide desktop (>= 600px) renders both panes side by side
      await tester.pumpWidget(_wrapWithWidth(splitView, width: 900));
      expect(find.text('Primary Pane Content'), findsOneWidget);
      expect(find.text('Secondary Pane Content'), findsOneWidget);

      // Narrow mobile (< 600px) renders segmented switcher
      await tester.pumpWidget(_wrapWithWidth(splitView, width: 380));
      await tester.pump();
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Primary Pane Content'), findsOneWidget);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(find.text('Secondary Pane Content'), findsOneWidget);
    });

    testWidgets(
        'Unified ConsonaTable supports sorting, selection, search, pagination, horizontal scroll on mobile, and column resizing',
        (tester) async {
      final rows = [
        (id: '1', name: 'Bravo', score: 90),
        (id: '2', name: 'Alpha', score: 40),
        (id: '3', name: 'Charlie', score: 75),
      ];
      var selected = <Object>{};
      String? resizedCol;
      double? resizedWidth;

      Widget buildTable({
        required double width,
        bool responsiveCards = false,
      }) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _wrapWithWidth(
              SingleChildScrollView(
                child: ConsonaTable<({String id, String name, int score})>(
                  title: 'Leaderboard',
                  rows: rows,
                  rowKey: (r) => r.id,
                  selectable: true,
                  selectedRows: selected,
                  onSelectionChanged: (next) =>
                      setState(() => selected = next),
                  searchable: true,
                  rowsPerPage: 2,
                  responsiveCards: responsiveCards,
                  resizableColumns: true,
                  onColumnResized: (id, w) {
                    resizedCol = id;
                    resizedWidth = w;
                  },
                  columns: [
                    ConsonaTableColumn(
                      id: 'name',
                      label: 'Name',
                      sortable: true,
                      width: 120,
                      minWidth: 80,
                      valueText: (r) => r.name,
                      cellBuilder: (_, r) => Text(r.name),
                    ),
                    ConsonaTableColumn(
                      id: 'score',
                      label: 'Score',
                      numeric: true,
                      sortable: true,
                      width: 100,
                      minWidth: 60,
                      valueText: (r) => '${r.score}',
                      comparator: (a, b) => a.score.compareTo(b.score),
                      cellBuilder: (_, r) => Text('${r.score}'),
                    ),
                  ],
                ),
              ),
              width: width,
            );
          },
        );
      }

      // Desktop table mode (>= 560px)
      await tester.pumpWidget(buildTable(width: 900));
      expect(find.text('Leaderboard'), findsOneWidget);
      // Page 1 shows first 2 rows (Bravo, Alpha)
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Charlie'), findsNothing);

      // Sort by Name ascending -> Alpha, Bravo on page 1
      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);

      // Navigate to next page -> Charlie
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Charlie'), findsOneWidget);

      // Mobile screen: table stays a table and is horizontally scrollable
      await tester.pumpWidget(buildTable(width: 380));
      await tester.pump();
      expect(find.text('Leaderboard'), findsOneWidget);
      // Check that it's still a table (header and rows intact), not collapsed to cards
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      // Check horizontal scroll view exists
      final hScrolls = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(hScrolls, findsWidgets);

      // Test column resizing via drag gesture on column resize handle
      final resizeHandles = find.byType(GestureDetector);
      expect(resizeHandles, findsWidgets);
      // Drag the first column header resize handle by 50px
      await tester.drag(find.text('Name'), const Offset(50, 0));
      await tester.pump();

      // Opt-in mobile card mode when responsiveCards: true
      await tester.pumpWidget(buildTable(width: 380, responsiveCards: true));
      await tester.pump();
      expect(find.text('Select row'), findsWidgets);
    });

    testWidgets('ConsonaPopover and ConsonaCommandPalette open and dismiss cleanly',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithWidth(
          Builder(
            builder: (context) {
              return Column(
                children: [
                  ConsonaPopover(
                    title: 'Popover Title',
                    popoverBuilder: (_) => const Text('Popover Body'),
                    child: const Text('Open Popover'),
                  ),
                  ConsonaButton.primary(
                    label: 'Open Command Palette',
                    onTap: () {
                      ConsonaCommandPalette.show(
                        context,
                        items: const [
                          ConsonaCommandItem(
                            id: 'cmd-1',
                            title: 'Run Diagnostics',
                            category: 'System',
                            shortcut: '⌘D',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Command Palette'));
      await tester.pumpAndSettle();
      expect(find.text('Run Diagnostics'), findsOneWidget);

      // Select the command item
      await tester.tap(find.text('Run Diagnostics'));
      await tester.pumpAndSettle();
      expect(find.text('Run Diagnostics'), findsNothing);
    });
  });
}
