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

  group('ConsonaCounter', () {
    testWidgets('increments and decrements value', (tester) async {
      int counter = 5;
      await tester.pumpWidget(
        buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return ConsonaCounter(
                value: counter,
                min: 0,
                max: 10,
                onChanged: (val) => setState(() => counter = val),
              );
            },
          ),
        ),
      );

      // Rolling digit strips keep every glyph in the tree — assert via Semantics.
      expect(tester.getSemantics(find.byType(ConsonaCounter)).value, '5');

      // Increment
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byType(ConsonaCounter)).value, '6');

      // Decrement
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byType(ConsonaCounter)).value, '5');
    });
  });

  group('ConsonaRating', () {
    testWidgets('renders star count and updates rating on tap', (tester) async {
      double rating = 3.0;
      await tester.pumpWidget(
        buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return ConsonaRating(
                value: rating,
                maxRating: 5,
                onChanged: (val) => setState(() => rating = val),
              );
            },
          ),
        ),
      );

      expect(find.byType(ConsonaRating), findsOneWidget);

      final box = tester.renderObject<RenderBox>(find.byType(ConsonaRating));
      // Tap the rightmost fifth of the bar → rating 5.
      await tester.tapAt(box.localToGlobal(Offset(box.size.width * 0.9, box.size.height / 2)));
      await tester.pumpAndSettle();
      expect(rating, 5.0);

      // Tap near the left → rating 1.
      await tester.tapAt(box.localToGlobal(Offset(box.size.width * 0.05, box.size.height / 2)));
      await tester.pumpAndSettle();
      expect(rating, 1.0);
    });

    testWidgets('allowHalf: tap snaps whole, drag uses half steps',
        (tester) async {
      double rating = 3.0;
      await tester.pumpWidget(
        buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return ConsonaRating(
                value: rating,
                maxRating: 5,
                allowHalf: true,
                onChanged: (val) => setState(() => rating = val),
              );
            },
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(ConsonaRating));
      final origin = box.localToGlobal(Offset.zero);
      final midY = origin.dy + box.size.height / 2;

      // Tap mid-third star region → whole 3.
      await tester.tapAt(Offset(origin.dx + box.size.width * 0.5, midY));
      await tester.pumpAndSettle();
      expect(rating, 3.0);

      // Drag across into the 4th star at half → 3.5 or 4.0 depending on x.
      final start = Offset(origin.dx + box.size.width * 0.55, midY);
      final end = Offset(origin.dx + box.size.width * 0.68, midY);
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();
      expect(rating % 0.5, 0.0);
      expect(rating, greaterThanOrEqualTo(3.5));
    });
  });

  group('ConsonaWheelPicker', () {
    testWidgets('renders wheel picker items', (tester) async {
      final items = ['Alpha', 'Beta', 'Gamma', 'Delta'];
      int selected = 0;
      await tester.pumpWidget(
        buildApp(
          SizedBox(
            height: 180.0,
            child: ConsonaWheelPicker<String>(
              items: items,
              initialIndex: selected,
              itemBuilder: (context, item, isSelected) {
                return Center(child: Text(item));
              },
              onSelectedItemChanged: (index) => selected = index,
            ),
          ),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}
