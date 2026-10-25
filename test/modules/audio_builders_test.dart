import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

void main() {
  Widget app(Widget child) => ConsonaProvider(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      );

  testWidgets('onEnded fires once on status transition', (tester) async {
    final engine = AudioEngine();
    var ended = 0;
    await tester.pumpWidget(
      app(
        ConsonaAudioPlayerCard(
          engine: engine,
          onEnded: () => ended++,
        ),
      ),
    );

    await engine.load(
      const AudioTrack(
        id: 't1',
        title: 'Demo',
        duration: Duration(milliseconds: 200),
      ),
    );
    await engine.play();
    await tester.pump(const Duration(milliseconds: 50));
    expect(ended, 0);

    // Drive mock backend to completion.
    await tester.pump(const Duration(seconds: 1));
    expect(ended, 1);

    // Rebuilds must not re-fire.
    await tester.pump();
    await tester.pump();
    expect(ended, 1);

    engine.dispose();
  });

  testWidgets('titleBuilder overrides default title chrome', (tester) async {
    final engine = AudioEngine();
    await engine.load(
      const AudioTrack(id: 't1', title: 'Hidden', duration: Duration(seconds: 3)),
    );
    await tester.pumpWidget(
      app(
        ConsonaAudioPlayerCard(
          engine: engine,
          titleBuilder: (context, state, title, artist) =>
              const Text('CUSTOM_TITLE'),
        ),
      ),
    );
    expect(find.text('CUSTOM_TITLE'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
    engine.dispose();
  });

  test('AudioTrack equality is by id', () {
    const a = AudioTrack(id: 'x', title: 'A');
    const b = AudioTrack(id: 'x', title: 'B');
    const c = AudioTrack(id: 'y', title: 'A');
    expect(a, equals(b));
    expect(a, isNot(equals(c)));
    expect(a.copyWith(title: 'Z').title, 'Z');
  });
}
