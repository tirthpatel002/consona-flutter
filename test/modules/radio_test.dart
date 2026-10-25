import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  testWidgets('unchecking a radio never renders text or throws mid-animation', (tester) async {
    final group = ValueNotifier<String>('a');

    await tester.pumpWidget(
      ConsonaProvider(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ValueListenableBuilder<String>(
              valueListenable: group,
              builder: (context, value, _) => ConsonaRadio<String>(
                value: 'a',
                groupValue: value,
                onChanged: (v) => group.value = v!,
              ),
            ),
          ),
        ),
      ),
    );

    final radio = find.byType(ConsonaRadio<String>);
    expect(find.descendant(of: radio, matching: find.byType(Text)), findsNothing);

    // Uncheck, then step through the whole transition frame by frame.
    group.value = 'b';
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.takeException(), isNull, reason: 'frame $i threw');
      expect(find.byType(ErrorWidget), findsNothing, reason: 'error widget at frame $i');
      expect(find.descendant(of: radio, matching: find.byType(Text)), findsNothing,
          reason: 'text rendered inside radio at frame $i');
      expect(find.descendant(of: radio, matching: find.byType(RichText)), findsNothing);
    }

    // And re-check (bloom) the same way.
    group.value = 'a';
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    }
  });
}
