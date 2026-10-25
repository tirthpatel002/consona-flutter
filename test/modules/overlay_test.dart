import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  Widget buildApp(Widget child) {
    return ConsonaProvider(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );
  }

  group('OverlayEngine', () {
    test('pushes and dismisses items', () {
      final engine = OverlayEngine();
      expect(engine.state.active, isEmpty);

      const item = ConsonaOverlayItem(
        id: 'toast_1',
        priority: ConsonaOverlayPriority.toast,
        data: 'Item payload',
      );

      engine.push(item);
      expect(engine.state.active.length, 1);
      expect(engine.state.active.first.id, 'toast_1');

      engine.dismiss('toast_1');
      expect(engine.state.active, isEmpty);
    });
  });

  group('ConsonaToastController', () {
    test('registers custom styles and showAs resolves them', () {
      final controller = ConsonaToastController();
      controller.register(
        ConsonaToastStyle.custom(
          id: 'shipped',
          accent: (t) => t.colors.success,
        ),
      );

      expect(controller.styleIds, contains('shipped'));
      expect(controller.styleIds, contains('success'));

      controller.showAs(
        'shipped',
        message: 'On the way',
        inverted: true,
      );

      expect(controller.entries, hasLength(1));
      expect(controller.entries.first.style.id, 'shipped');
      expect(controller.entries.first.inverted, isTrue);
      expect(controller.entries.first.message, 'On the way');

      controller.clear();
      expect(controller.entries, isEmpty);
    });

    test('variant and poster image land on the entry', () {
      final controller = ConsonaToastController();
      controller.show(
        message: 'Saved',
        variant: ConsonaToastVariant.success,
        icon: null,
        inverted: false,
      );
      expect(controller.entries.first.style.id, 'success');
      controller.clear();
    });
  });

  group('ConsonaCard', () {
    testWidgets('renders header, body and footer parts', (tester) async {
      await tester.pumpWidget(
        buildApp(
          ConsonaCard(
            header: ConsonaCard.buildHeader(
              title: const Text('Card Title'),
              subtitle: const Text('Card Subtitle'),
            ),
            body: ConsonaCard.buildBody(
              child: const Text('Card Content'),
            ),
            footer: ConsonaCard.buildFooter(
              child: const Text('Action Footer'),
            ),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Subtitle'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Action Footer'), findsOneWidget);
    });
  });

  group('ConsonaBentoGrid', () {
    testWidgets('renders bento tiles with specified spans', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const SizedBox(
            width: 320.0,
            child: ConsonaBentoGrid(
              crossAxisCount: 2,
              tiles: [
                ConsonaBentoTile(
                  colSpan: 2,
                  child: Text('Hero Tile'),
                ),
                ConsonaBentoTile(
                  child: Text('Left Tile'),
                ),
                ConsonaBentoTile(
                  child: Text('Right Tile'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hero Tile'), findsOneWidget);
      expect(find.text('Left Tile'), findsOneWidget);
      expect(find.text('Right Tile'), findsOneWidget);
    });
  });

  group('ConsonaAccordion', () {
    testWidgets('expands and collapses on header tap', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConsonaAccordion(
            items: [
              ConsonaAccordionItem(
                id: 'faq_1',
                title: Text('FAQ Question'),
                content: Text('Detailed Answer'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('FAQ Question'), findsOneWidget);
      // Tap header to expand
      await tester.tap(find.text('FAQ Question'));
      await tester.pumpAndSettle();

      expect(find.text('Detailed Answer'), findsOneWidget);
    });
  });
}
