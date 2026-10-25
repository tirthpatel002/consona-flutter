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

  group('ConsonaSwitch', () {
    testWidgets('toggles value on tap', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return ConsonaSwitch(
                value: value,
                onChanged: (val) => setState(() => value = val),
              );
            },
          ),
        ),
      );

      expect(value, isFalse);
      await tester.tap(find.byType(ConsonaSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('disabled switch does not change value on tap', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        buildApp(
          ConsonaSwitch(
            value: value,
            disabled: true,
            onChanged: (val) => value = val,
          ),
        ),
      );

      await tester.tap(find.byType(ConsonaSwitch));
      await tester.pumpAndSettle();
      expect(value, isFalse);
    });

    testWidgets('labeled switch renders ON/OFF labels and toggles correctly', (tester) async {
      bool value = true;
      await tester.pumpWidget(
        buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return ConsonaSwitch.labeled(
                value: value,
                onChanged: (val) => setState(() => value = val),
              );
            },
          ),
        ),
      );

      expect(find.text('ON'), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);
      expect(value, isTrue);

      await tester.tap(find.byType(ConsonaSwitch));
      await tester.pumpAndSettle();
      expect(value, isFalse);
    });
  });
}
