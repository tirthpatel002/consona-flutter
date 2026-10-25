import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:consona_flutter/consona_flutter.dart';

/// Records every buffer handed to the player, in order.
class RecordingPlayer implements SoundPlayer {
  final List<Uint8List> played = [];

  @override
  Future<void> playBytes(Uint8List bytes, {double volume = 1.0}) async {
    played.add(bytes);
  }

  @override
  void stop() {}

  @override
  void dispose() {}
}

/// Local pitch estimate (Schmitt-trigger zero crossings per ms) over the
/// first and last third of the audible part of the cue.
({double ms, double rate1, double rate2}) _features(SoundRecipe r) {
  final pcm = Int16List.sublistView(r.toWav(), 44);
  var peak = 1;
  for (final v in pcm) {
    if (v.abs() > peak) peak = v.abs();
  }
  final hi = peak * 0.05;
  final crossings = <int>[];
  var positive = pcm.first >= 0;
  for (var i = 1; i < pcm.length; i++) {
    if (positive && pcm[i] < -hi) {
      positive = false;
      crossings.add(i);
    } else if (!positive && pcm[i] > hi) {
      positive = true;
      crossings.add(i);
    }
  }
  double rate(List<int> c) =>
      c.length < 2 ? 0.0 : (c.length - 1) / ((c.last - c.first) * 1000.0 / 44100.0);
  final third = crossings.length ~/ 3;
  return (
    ms: r.durationMs,
    rate1: rate(crossings.sublist(0, third < 2 ? crossings.length : third)),
    rate2: rate(crossings.sublist(crossings.length - (third < 2 ? crossings.length : third))),
  );
}

bool _differs(double a, double b, {double rel = 0.10}) =>
    (a - b).abs() > rel * (a > b ? a : b);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('default sound cues are really distinct', () {
    test('every cue renders different bytes and a different sound signature', () {
      final cues = DefaultSoundCues.all;
      final names = cues.keys.toList();
      expect(names.toSet(), containsAll(<String>[
        'tap',
        'toggle_on',
        'toggle_off',
        'tick',
        'pop',
        'success_chime',
        'error_blip',
        'swipe',
        'scroll',
      ]));

      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final a = names[i];
          final b = names[j];
          expect(cues[a]!.toWav(), isNot(equals(cues[b]!.toWav())),
              reason: '$a and $b render identical bytes');

          // Perceptual signature: length, pitch in the first half, pitch in the second half.
          final fa = _features(cues[a]!);
          final fb = _features(cues[b]!);
          final distinct = _differs(fa.ms, fb.ms, rel: 0.2) ||
              _differs(fa.rate1, fb.rate1) ||
              _differs(fa.rate2, fb.rate2);
          expect(distinct, isTrue, reason: '$a and $b sound alike: $fa vs $fb');
        }
      }
    });

    test('toggle on rises and toggle off falls in pitch', () {
      final on = _features(DefaultSoundCues.toggleOn);
      final off = _features(DefaultSoundCues.toggleOff);
      expect(on.rate2, greaterThan(on.rate1));
      expect(off.rate2, lessThan(off.rate1));
    });

    test('success chime is a longer two-tone cue', () {
      const chime = DefaultSoundCues.successChime;
      expect(chime.secondFrequency, greaterThan(chime.frequency));
      expect(chime.durationMs, greaterThan(100));
      // The second note really is audible in the render (energy after it starts).
      final pcm = Int16List.sublistView(chime.toWav(), 44);
      final from = (44100 * (chime.secondStartMs + 5) / 1000).round();
      var peakAfter = 0;
      for (var i = from; i < pcm.length; i++) {
        if (pcm[i].abs() > peakAfter) peakAfter = pcm[i].abs();
      }
      expect(peakAfter, greaterThan(1000));
    });

    test('profile variants differ from the tactile base recipe', () {
      for (final entry in DefaultSoundCues.all.entries) {
        final base = entry.value.toWav();
        expect(
          DefaultSoundCues.forProfile(entry.value, FeedbackProfile.mechanical).toWav(),
          isNot(equals(base)),
          reason: '${entry.key} mechanical == tactile',
        );
        expect(
          DefaultSoundCues.forProfile(entry.value, FeedbackProfile.subtle).toWav(),
          isNot(equals(base)),
          reason: '${entry.key} subtle == tactile',
        );
      }
    });
  });

  group('FeedbackEngine routes every event to its own sound', () {
    FeedbackEngine buildEngine(RecordingPlayer player, {FeedbackProfile profile = FeedbackProfile.tactile}) {
      final library = SoundLibrary(ConsonaAssetLibrary());
      return FeedbackEngine(
        config: FeedbackConfig(profile: profile, hapticsEnabled: false),
        soundEngine: SoundEngine(library: library, player: player),
      );
    }

    test('each sounding FeedbackEvent plays a different buffer', () async {
      final player = RecordingPlayer();
      final engine = buildEngine(player);

      final sounding = FeedbackEvent.values
          .where((e) => e != FeedbackEvent.scroll)
          .toList();
      for (final event in sounding) {
        await engine.trigger(event);
      }

      expect(player.played.length, sounding.length);
      final unique = player.played.map((b) => Object.hashAll(b)).toSet();
      expect(unique.length, sounding.length,
          reason: 'some events share the same sound');

      // Scroll is intentionally silent.
      final scrollPlayer = RecordingPlayer();
      await buildEngine(scrollPlayer).trigger(FeedbackEvent.scroll);
      expect(scrollPlayer.played, isEmpty);
    });

    test('profile changes the played sound; silent plays nothing', () async {
      final tactile = RecordingPlayer();
      await buildEngine(tactile).trigger(FeedbackEvent.tap);
      final mechanical = RecordingPlayer();
      await buildEngine(mechanical, profile: FeedbackProfile.mechanical).trigger(FeedbackEvent.tap);
      final subtle = RecordingPlayer();
      await buildEngine(subtle, profile: FeedbackProfile.subtle).trigger(FeedbackEvent.tap);
      final silent = RecordingPlayer();
      await buildEngine(silent, profile: FeedbackProfile.silent).trigger(FeedbackEvent.tap);

      expect(tactile.played.single, isNot(equals(mechanical.played.single)));
      expect(tactile.played.single, isNot(equals(subtle.played.single)));
      expect(mechanical.played.single, isNot(equals(subtle.played.single)));
      expect(silent.played, isEmpty);
    });
  });
}
