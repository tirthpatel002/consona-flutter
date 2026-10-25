/// Picks a real mic backend when the `record` plugin is linked, otherwise mock.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:record/record.dart';

import '../engine/recorder_engine.dart';
import 'record_audio_recorder_backend.dart';

/// Returns a [RecordAudioRecorderBackend] when the native plugin responds,
/// otherwise [MockAudioRecorderBackend] (simulator / stale binary / desktop).
///
/// Call once at engine construction — probes `hasPermission` to detect
/// [MissingPluginException] before the user taps Record.
Future<AudioRecorderBackend> createRecorderBackend({
  int sampleRate = 48000,
  Duration maxDuration = const Duration(minutes: 10),
}) async {
  try {
    final probe = AudioRecorder();
    await probe.hasPermission();
    await probe.dispose();
    return RecordAudioRecorderBackend(
      sampleRate: sampleRate,
      maxDuration: maxDuration,
    );
  } on MissingPluginException catch (e) {
    debugPrint(
      'createRecorderBackend: record plugin missing ($e) — using mock capture.',
    );
    return MockAudioRecorderBackend();
  } catch (e) {
    // Permission denied / other — still use the real backend so the OS
    // permission prompt can surface on the next start().
    debugPrint('createRecorderBackend: probe note: $e');
    return RecordAudioRecorderBackend(
      sampleRate: sampleRate,
      maxDuration: maxDuration,
    );
  }
}
