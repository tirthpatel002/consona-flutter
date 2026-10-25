import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  group('ConsonaProvider', () {
    testWidgets('attaches plugins before child builds', (tester) async {
      await tester.pumpWidget(
        ConsonaProvider(
          child: Builder(
            builder: (context) {
              expect(ConsonaProvider.isReadyOf(context), isTrue);
              expect(FeedbackScope.maybeOf(context), isNotNull);
              expect(OverlayScope.maybeOf(context), isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('resolves slot overrides via ConsonaSlots', (tester) async {
      await tester.pumpWidget(
        ConsonaProvider(
          plugins: [
            ConsonaAssetsPlugin(),
            ConsonaFeedbackPlugin(),
            ConsonaOverlayPlugin(),
            _HeaderSlotPlugin(),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final slot = ConsonaSlots.of<void>(context, 'test.header');
                expect(slot, isNotNull);
                final widget = slot!.resolve(context, null);
                expect(widget, isA<Text>());
                return widget ?? const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(find.text('SLOT'), findsOneWidget);
    });

    testWidgets('materialExtensionsOf includes ConsonaThemeData', (tester) async {
      await tester.pumpWidget(
        ConsonaProvider(
          child: Builder(
            builder: (context) {
              final exts = ConsonaProvider.materialExtensionsOf(context);
              expect(exts.whereType<ConsonaThemeData>(), isNotEmpty);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('FeedbackScope', () {
    testWidgets('of throws without scope', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => FeedbackScope.of(context), throwsStateError);
            expect(FeedbackScope.maybeOf(context), isNull);
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('ConsonaToastLayer', () {
    testWidgets('provides ambient controller without global singleton',
        (tester) async {
      late ConsonaToastController controller;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ConsonaToastLayer(
            child: child ?? const SizedBox.shrink(),
          ),
          home: Builder(
            builder: (context) {
              controller = ConsonaToastController.of(context);
              return TextButton(
                onPressed: () => controller.show(message: 'Hi'),
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      expect(ConsonaToastController.maybeOf, isNotNull);
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(controller.entries, hasLength(1));
      expect(find.text('Hi'), findsOneWidget);
    });
  });
}

class _HeaderSlotPlugin extends ConsonaPlugin {
  @override
  String get id => 'test.header_slot';

  @override
  void onAttach(ConsonaRegistry registry) {
    registry.overrideSlot<void>(
      'test.header',
      ConsonaSlot.widget(const Text('SLOT')),
    );
  }
}
