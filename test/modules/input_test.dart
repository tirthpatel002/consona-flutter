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

  group('ConsonaTextField', () {
    testWidgets('renders placeholder and handles input change', (tester) async {
      String value = '';
      await tester.pumpWidget(
        buildApp(
          ConsonaTextField(
            placeholder: 'Enter username',
            onChanged: (val) => value = val,
          ),
        ),
      );

      expect(find.text('Enter username'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'alice');
      await tester.pumpAndSettle();
      expect(value, 'alice');
    });

    testWidgets('renders error text in error state', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConsonaTextField(
            label: 'Email',
            errorText: 'Invalid email address',
          ),
        ),
      );

      expect(find.text('Invalid email address'), findsOneWidget);
    });
  });

  group('ConsonaTextArea', () {
    testWidgets('renders multiline text well and tracks length', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConsonaTextArea(
            label: 'Notes',
            placeholder: 'Write your thoughts...',
            maxLength: 100,
          ),
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('0 / 100'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Hello world');
      await tester.pumpAndSettle();
      expect(find.text('11 / 100'), findsOneWidget);
    });
  });

  group('ConsonaOtpField', () {
    testWidgets('auto-advances digits and triggers onCompleted', (tester) async {
      String completedPin = '';
      await tester.pumpWidget(
        buildApp(
          ConsonaOtpField(
            length: 4,
            onCompleted: (pin) => completedPin = pin,
          ),
        ),
      );

      expect(find.byType(EditableText), findsNWidgets(4));

      await tester.enterText(find.byType(EditableText).at(0), '1');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '2');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(2), '3');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(3), '4');
      await tester.pumpAndSettle();

      expect(completedPin, '1234');
    });
  });

  group('ConsonaSearchField', () {
    testWidgets('fires onDebouncedChanged after delay', (tester) async {
      String debounced = '';
      await tester.pumpWidget(
        buildApp(
          ConsonaSearchField(
            debounceDuration: const Duration(milliseconds: 100),
            onDebouncedChanged: (val) => debounced = val,
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), 'query');
      await tester.pump(const Duration(milliseconds: 50));
      expect(debounced, '');

      await tester.pump(const Duration(milliseconds: 100));
      expect(debounced, 'query');
    });
  });

  group('ConsonaPasswordField', () {
    testWidgets('toggles obscured text visibility', (tester) async {
      final controller = TextEditingController(text: 'secret123');
      await tester.pumpWidget(
        buildApp(
          ConsonaPasswordField(
            controller: controller,
          ),
        ),
      );

      final editableBefore = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableBefore.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();

      final editableAfter = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableAfter.obscureText, isFalse);
    });
  });

  group('ConsonaPhoneField', () {
    testWidgets('renders dial code and phone input well', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ConsonaPhoneField(
            label: 'Phone Number',
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
    });
  });
}
