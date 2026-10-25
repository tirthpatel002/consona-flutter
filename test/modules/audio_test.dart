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

  group('AudioEngine', () {
    test('loads track and controls playback transitions', () async {
      final engine = AudioEngine();
      expect(engine.state.status, AudioPlaybackStatus.idle);

      const track = AudioTrack(
        id: 'track_1',
        title: 'Cyber Dreams',
        artist: 'Consona Synth',
        duration: Duration(seconds: 180),
        amplitudes: [0.2, 0.5, 0.8, 0.4, 0.9],
      );

      await engine.load(track);
      expect(engine.state.currentTrack?.title, 'Cyber Dreams');
      expect(engine.state.duration, const Duration(seconds: 180));

      await engine.play();
      expect(engine.state.status, AudioPlaybackStatus.playing);

      await engine.pause();
      expect(engine.state.status, AudioPlaybackStatus.paused);

      await engine.seek(const Duration(seconds: 45));
      expect(engine.state.position, const Duration(seconds: 45));

      await engine.stop();
      expect(engine.state.status, AudioPlaybackStatus.idle);
      engine.dispose();
    });

    test('separate engines stay isolated', () async {
      const track = AudioTrack(
        id: 'a',
        title: 'A',
        duration: Duration(seconds: 30),
      );
      final a = AudioEngine(id: 'a');
      final b = AudioEngine(id: 'b');
      await a.load(track);
      await b.load(track);
      await a.play();
      expect(a.state.isPlaying, isTrue);
      expect(b.state.isPlaying, isFalse);
      await b.play();
      await a.pause();
      expect(a.state.isPlaying, isFalse);
      expect(b.state.isPlaying, isTrue);
      a.dispose();
      b.dispose();
    });
  });

  group('ConsonaWaveform', () {
    testWidgets('renders waveform bars without throwing', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const SizedBox(
            width: 200.0,
            height: 48.0,
            child: ConsonaWaveform(
              amplitudes: [0.2, 0.6, 0.9, 0.3, 0.7, 0.4, 0.8],
              progress: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(ConsonaWaveform), findsOneWidget);
    });
  });

  group('ConsonaTimelineScrubber & ConsonaSlider', () {
    testWidgets('renders scrubber track and horizontal pill thumb with background fill and primary border', (tester) async {
      Duration seeked = Duration.zero;
      double sliderVal = 0.5;
      final theme = const ConsonaThemeConfig().toThemeData();

      await tester.pumpWidget(
        ConsonaProvider(
          theme: theme,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 250.0,
                  child: ConsonaTimelineScrubber(
                    position: const Duration(seconds: 30),
                    duration: const Duration(seconds: 120),
                    onSeek: (pos) => seeked = pos,
                  ),
                ),
                SizedBox(
                  width: 250.0,
                  child: ConsonaSlider(
                    value: sliderVal,
                    onChanged: (v) => sliderVal = v,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ConsonaTimelineScrubber), findsOneWidget);
      expect(find.byType(ConsonaSlider), findsOneWidget);
      expect(seeked, Duration.zero);

      for (final finder in [
        find.byType(ConsonaTimelineScrubber),
        find.byType(ConsonaSlider),
      ]) {
        final thumbContainer = tester.widget<AnimatedContainer>(
          find.descendant(
            of: finder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        final size = tester.getSize(
          find.descendant(
            of: finder,
            matching: find.byType(AnimatedContainer),
          ),
        );
        // Horizontal pill shape: width > height
        expect(size.width, greaterThan(size.height));
        final dec = thumbContainer.decoration! as BoxDecoration;
        expect(dec.color, equals(theme.colors.background));
        final border = dec.border! as Border;
        expect(border.top.color, equals(theme.colors.primary));
      }
    });
  });

  group('ConsonaAudioPlayer', () {
    testWidgets('renders track title and play button', (tester) async {
      final engine = AudioEngine();
      const track = AudioTrack(
        id: 'demo',
        title: 'Ambient Echoes',
        artist: 'Consona Sound',
        duration: Duration(seconds: 240),
      );
      await engine.load(track);

      await tester.pumpWidget(
        buildApp(
          SizedBox(
            width: 320.0,
            child: ConsonaAudioPlayer(
              engine: engine,
            ),
          ),
        ),
      );

      expect(find.text('Ambient Echoes'), findsOneWidget);
      expect(find.text('Consona Sound'), findsOneWidget);
      expect(find.byType(ConsonaSpringPress), findsWidgets);

      engine.dispose();
    });
  });

  group('ConsonaAudioPlayerCard / Pill', () {
    testWidgets('card and pill render without throwing', (tester) async {
      final engine = AudioEngine();
      await engine.load(
        const AudioTrack(
          id: 'demo',
          title: 'Neon Odyssey',
          artist: 'Labs',
          duration: Duration(seconds: 90),
        ),
      );

      await tester.pumpWidget(
        buildApp(
          Column(
            children: [
              SizedBox(
                width: 320,
                child: ConsonaAudioPlayerCard(
                  engine: engine,
                  showPoster: true,
                  timeline: ConsonaAudioPlayerTimeline.slider,
                ),
              ),
              ConsonaAudioPlayerPill(engine: engine),
            ],
          ),
        ),
      );

      expect(find.text('Neon Odyssey'), findsWidgets);
      expect(find.byType(ConsonaAudioPlayerPill), findsOneWidget);
      engine.dispose();
    });
  });

  group('AudioRecorderEngine', () {
    test('start pause resume stop and resumeRecording', () async {
      final engine = AudioRecorderEngine();
      expect(engine.state.isIdle, isTrue);

      await engine.start();
      expect(engine.state.isRecording, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(engine.state.duration.inMilliseconds, greaterThan(0));

      await engine.pause();
      expect(engine.state.isPaused, isTrue);

      await engine.resume();
      expect(engine.state.isRecording, isTrue);

      final first = await engine.stop();
      expect(first.duration.inMilliseconds, greaterThan(0));
      expect(first.bytes, isNotNull);
      expect(first.bytes, isNotEmpty);
      expect(engine.state.lastRecording, isNotNull);

      await engine.resumeRecording();
      expect(engine.state.isRecording, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final second = await engine.stop();
      expect(second.duration >= first.duration, isTrue);

      engine.dispose();
    });
  });

  group('ConsonaAudioRecorderCard / Pill', () {
    testWidgets('recorder surfaces render', (tester) async {
      final engine = AudioRecorderEngine();
      await tester.pumpWidget(
        buildApp(
          Column(
            children: [
              SizedBox(
                width: 320,
                child: ConsonaAudioRecorderCard(engine: engine),
              ),
              ConsonaAudioRecorderPill(engine: engine),
            ],
          ),
        ),
      );

      expect(find.text('Voice Recorder'), findsOneWidget);
      expect(find.text('Voice Note'), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);
      engine.dispose();
    });
  });
}
