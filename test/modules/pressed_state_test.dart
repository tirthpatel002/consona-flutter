import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

Color? _fill(WidgetTester tester, Finder of) {
  final box = tester.widgetList<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)),
  ).first;
  return (box.decoration as BoxDecoration).color;
}

void main() {
  Widget app(Widget child) => ConsonaProvider(
        child: Directionality(textDirection: TextDirection.ltr, child: Center(child: child)),
      );

  testWidgets('button shows pressed and disabled feedback', (tester) async {
    await tester.pumpWidget(app(Column(mainAxisSize: MainAxisSize.min, children: [
      ConsonaButton.primary(label: 'Go', onTap: () {}),
      const ConsonaButton.primary(label: 'Off', disabled: true),
    ])));

    final go = find.widgetWithText(ConsonaButton, 'Go');
    final idle = _fill(tester, go);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
    await tester.pump(const Duration(milliseconds: 50));
    final pressed = _fill(tester, go);
    expect(pressed, isNot(idle), reason: 'pressed fill must differ from idle');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_fill(tester, go), idle);

    expect(_fill(tester, find.widgetWithText(ConsonaButton, 'Off')), isNot(idle));
  });
}
