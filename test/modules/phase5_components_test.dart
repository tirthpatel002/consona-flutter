import 'package:consona_flutter/consona_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ConsonaThemeData? theme}) {
  return MaterialApp(
    theme: ThemeData(
      extensions: [theme ?? ConsonaThemeData.minimal()],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Phase 5 & Inventory Components', () {
    testWidgets('ConsonaAppBar renders title, subtitle, and actions',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaAppBar(
            title: 'Studio Inspector',
            subtitle: 'Live Session',
            actions: [Text('Save')],
          ),
        ),
      );

      expect(find.text('Studio Inspector'), findsOneWidget);
      expect(find.text('Live Session'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('ConsonaSegmentedControl switches segments on tap',
        (tester) async {
      String selected = 'a';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaSegmentedControl<String>(
              selected: selected,
              onChanged: (v) => setState(() => selected = v),
              segments: const [
                ConsonaSegment(value: 'a', label: 'Alpha'),
                ConsonaSegment(value: 'b', label: 'Beta'),
                ConsonaSegment(value: 'c', label: 'Gamma'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(selected, 'b');
    });

    testWidgets('ConsonaStepper renders horizontal and vertical steps',
        (tester) async {
      int step = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            ConsonaStepper(
              currentStep: step,
              onStepTapped: (idx) => setState(() => step = idx),
              steps: const [
                ConsonaStep(title: 'First', isCompleted: true),
                ConsonaStep(title: 'Second'),
                ConsonaStep(title: 'Third'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('✓'), findsOneWidget);
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(step, 1);
    });

    testWidgets(
        'ConsonaRangeSlider renders dual horizontal pill thumbs with background fill and primary border',
        (tester) async {
      final theme = ConsonaThemeData.minimal();
      double start = 0.2;
      double end = 0.8;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _wrap(
            SizedBox(
              width: 240,
              child: ConsonaRangeSlider(
                label: 'Bandpass',
                start: start,
                end: end,
                onChanged: (s, e) => setState(() {
                  start = s;
                  end = e;
                }),
              ),
            ),
            theme: theme,
          ),
        ),
      );

      expect(find.text('Bandpass'), findsOneWidget);
      expect(find.text('20% – 80%'), findsOneWidget);

      final pillThumbs = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) {
        final dec = c.decoration;
        if (dec is! BoxDecoration) return false;
        final border = dec.border;
        if (border is! Border) return false;
        return dec.color == theme.colors.background &&
            border.top.color == theme.colors.primary;
      }).toList();

      expect(pillThumbs.length, 2);
    });

    testWidgets('ConsonaAvatar and ConsonaAvatarGroup compute initials and +N',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConsonaAvatarGroup(
            maxVisible: 2,
            avatars: [
              ConsonaAvatar(name: 'Aria Vance', status: ConsonaAvatarStatus.online),
              ConsonaAvatar(name: 'Kaelen Thorne'),
              ConsonaAvatar(name: 'Soren Lind'),
              ConsonaAvatar(name: 'Mira Solis'),
            ],
          ),
        ),
      );

      expect(find.text('AV'), findsOneWidget);
      expect(find.text('KT'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('ConsonaProgress and ConsonaMeter render percentage readouts',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConsonaProgress(
                value: 0.45,
                label: 'Download',
                showPercentage: true,
              ),
              ConsonaMeter(
                value: 0.75,
                label: 'CPU Load',
                segments: 10,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Download'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('CPU Load'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('ConsonaEmptyState and ConsonaSwipeDismiss work as expected',
        (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        _wrap(
          ConsonaSwipeDismiss(
            onDismissed: () => dismissed = true,
            child: const ConsonaEmptyState(
              title: 'Nothing Here',
              description: 'Add an item to get started.',
            ),
          ),
        ),
      );

      expect(find.text('Nothing Here'), findsOneWidget);
      await tester.drag(find.text('Nothing Here'), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  });
}
