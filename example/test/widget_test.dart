import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter_example/main.dart';

void main() {
  testWidgets('ConsonaShowcaseApp mounts without error', (tester) async {
    await tester.pumpWidget(const ConsonaShowcaseApp());
    await tester.pumpAndSettle();

    expect(find.text('Consona Mobile'), findsOneWidget);
    expect(find.text('Theme Studio'), findsOneWidget);
  });
}
