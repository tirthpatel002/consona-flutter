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

  group('ConsonaListTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConsonaListTile(
            title: 'Account Settings',
            subtitle: 'Manage profile and privacy',
          ),
        ),
      );

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Manage profile and privacy'), findsOneWidget);
    });

    testWidgets('fires onTap on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          ConsonaListTile(
            title: 'Notifications',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
