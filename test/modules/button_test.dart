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

  group('ConsonaButton', () {
    testWidgets('renders button label and fires onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          ConsonaButton.primary(
            label: 'Submit',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('disabled button does not trigger onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          ConsonaButton.subtle(
            label: 'Disabled Action',
            disabled: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Disabled Action'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('enforces minimum hit target boundary (>= 44)', (tester) async {
      await tester.pumpWidget(
        buildApp(
          ConsonaButton.outline(
            label: 'Small',
            size: ConsonaOpticalSize.xs,
            onTap: () {},
          ),
        ),
      );

      final finder = find.byType(ConsonaHitTarget);
      expect(finder, findsOneWidget);
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(44.0));
      expect(size.width, greaterThanOrEqualTo(44.0));
    });

    testWidgets('renders loading spinner when loading is true', (tester) async {
      await tester.pumpWidget(
        buildApp(
          ConsonaButton.primary(
            label: 'Saving',
            loading: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(ConsonaLoader), findsOneWidget);
      expect(find.text('Saving'), findsNothing);
    });
  });
}
