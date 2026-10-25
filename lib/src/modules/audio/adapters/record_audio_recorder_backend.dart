import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:record/record.dart';

import '../engine/recorder_engine.dart';
import 'io_support.dart';

/// Mic-backed [AudioRecorderBackend] using the `record` package.
///
/// Uses **file WAV capture** (not PCM stream). On macOS, `startStream` +
/// echo-cancel / sample-rate conversion often produces zero chunks with no
/// error — file recording via AVCapture is reliable there.
class RecordAudioRecorderBackend implements AudioRecorderBackend {
  RecordAudioRecorderBackend({
    this.sampleRate = 48000,
    this.maxDuration = const Duration(minutes: 10),
  });

  final int sampleRate;
  final Duration maxDuration;
  final AudioRecorder _recorder = AudioRecorder();

  final List<double> _levels = <double>[];
  double _lastLevel = 0.2;
  bool _ampBusy = false;

  Timer? _meterTimer;
  TempAudioDirectory? _dir;

  Duration _baseDuration = Duration.zero;
  Duration _segmentElapsed = Duration.zero;
  DateTime? _segmentStartedAt;
  bool _active = false;
  String? _path;
  Uint8List? _priorPcm;

  void Function(Duration)? _onDuration;
  void Function(double)? _onLevel;
  void Function(AudioRecorderStatus)? _onStatus;
  void Function(Object)? _onError;

  @override
  void attach({
    required void Function(Duration duration) onDuration,
    required void Function(double level) onLevel,
    required void Function(AudioRecorderStatus status) onStatus,
    void Function(Object error)? onError,
  }) {
    _onDuration = onDuration;
    _onLevel = onLevel;
    _onStatus = onStatus;
    _onError = onError;
  }

  Future<void> _ensurePermission() async {
    try {
      final ok = await _recorder.hasPermission();
      if (!ok) {
        throw StateError(
          'Microphone permission denied. '
          'Enable Microphone for this app in system Settings.',
        );
      }
    } on MissingPluginException {
      throw StateError(
        'Record plugin not linked in this binary. '
        'Stop the app fully, then: flutter clean && cd ios && pod install && flutter run. '
        'Hot restart is not enough after adding native plugins.',
      );
    }
  }

  RecordConfig get _config => RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        numChannels: 1,
        // Voice processing breaks AVAudioEngine taps on many macOS setups.
        echoCancel: false,
        autoGain: false,
        noiseSuppress: false,
      );

  Future<String> _nextPath() async {
    final dir = _dir ??= await createTempAudioDirectory('consona_rec_');
    return dir.nextFilePath('take_${DateTime.now().microsecondsSinceEpoch}.wav');
  }

  Future<void> _beginCapture({Uint8List? priorPcm}) async {
    await _tearDownCapture(deleteFile: true);
    _priorPcm = priorPcm;
    _levels.clear();
    _segmentElapsed = Duration.zero;

    final wavSupported = await _recorder.isEncoderSupported(AudioEncoder.wav);
    if (!wavSupported) {
      throw StateError('WAV recording is not supported on this device');
    }

    final path = kIsWeb ? '' : await _nextPath();
    debugPrint('RecordAudioRecorderBackend: start → $path');
    await _recorder.start(_config, path: path);
    _path = path;
    _active = true;
    _segmentStartedAt = DateTime.now();
    _onStatus?.call(AudioRecorderStatus.recording);
    _emitDuration();

    _meterTimer?.cancel();
    _meterTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_active || _segmentStartedAt == null) return;
      _segmentElapsed = DateTime.now().difference(_segmentStartedAt!);
      _onDuration?.call(_baseDuration + _segmentElapsed);
      _onLevel?.call(_lastLevel);
      _sampleAmplitude();
      if (_baseDuration + _segmentElapsed >= maxDuration) {
        unawaited(stop());
      }
    });
  }

  /// One in-flight native amplitude read — never stack platform calls.
  /// macOS runs a merged UI/platform thread; piled-up getAmplitude()
  /// calls freeze the whole app after a couple of seconds.
  void _sampleAmplitude() {
    if (_ampBusy || !_active) return;
    _ampBusy = true;
    unawaited(() async {
      try {
        final amp = await _recorder
            .getAmplitude()
            .timeout(const Duration(milliseconds: 80));
        if (!_active) return;
        final level = ((amp.current + 50) / 50).clamp(0.05, 1.0);
        _lastLevel = level;
        _levels.add(level);
        if (_levels.length > 64) _levels.removeAt(0);
      } catch (_) {
      } finally {
        _ampBusy = false;
      }
    }());
  }

  void _emitDuration() {
    _onDuration?.call(_baseDuration + _segmentElapsed);
  }

  Future<void> _tearDownCapture({required bool deleteFile}) async {
    _active = false;
    _meterTimer?.cancel();
    _meterTimer = null;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    if (deleteFile) {
      final path = _path;
      _path = null;
      if (path != null && path.isNotEmpty) {
        await deleteFileIfExists(path);
      }
    }
    _segmentStartedAt = null;
  }

  @override
  Future<void> start({String? deviceId}) async {
    await _ensurePermission();
    _baseDuration = Duration.zero;
    _priorPcm = null;
    await _beginCapture();
  }

  @override
  Future<void> pause() async {
    if (!_active) return;
    _active = false;
    if (_segmentStartedAt != null) {
      _segmentElapsed = DateTime.now().difference(_segmentStartedAt!);
      _baseDuration += _segmentElapsed;
      _segmentElapsed = Duration.zero;
      _segmentStartedAt = null;
    }
    try {
      await _recorder.pause();
    } catch (e) {
      _onError?.call(e);
    }
    _onStatus?.call(AudioRecorderStatus.paused);
    _emitDuration();
  }

  @override
  Future<void> resume() async {
    try {
      await _recorder.resume();
    } catch (e) {
      _onError?.call(e);
      rethrow;
    }
    _active = true;
    _segmentStartedAt = DateTime.now();
    _onStatus?.call(AudioRecorderStatus.recording);
  }

  @override
  Future<AudioRecordingResult> stop() async {
    if (_segmentStartedAt != null) {
      _baseDuration += DateTime.now().difference(_segmentStartedAt!);
      _segmentStartedAt = null;
    }
    _active = false;
    _meterTimer?.cancel();
    _meterTimer = null;

    String? path = _path;
    try {
      if (await _recorder.isRecording() || await _recorder.isPaused()) {
        path = await _recorder.stop() ?? path;
      }
    } catch (e, st) {
      debugPrint('RecordAudioRecorderBackend.stop: $e\n$st');
      _onError?.call(e);
    }
    _path = null;

    if (path == null || path.isEmpty) {
      _resetSession();
      throw StateError(
        'Recording produced no file. Check Microphone permission for this app.',
      );
    }

    final fileBytes = await readFileBytesIfExists(path);
    if (fileBytes == null) {
      _resetSession();
      throw StateError(
        'Recording produced no file. Check Microphone permission for this app.',
      );
    }
    debugPrint(
      'RecordAudioRecorderBackend: stopped $path (${fileBytes.length} bytes)',
    );

    if (fileBytes.length < 44) {
      _resetSession();
      throw StateError('Recording file too small (${fileBytes.length} bytes)');
    }

    final prior = _priorPcm;
    final Uint8List bytes;
    final int durationMs;
    if (prior != null && prior.isNotEmpty) {
      final segmentPcm = _wavToPcm16(fileBytes) ?? Uint8List(0);
      final pcm = (BytesBuilder(copy: false)
            ..add(prior)
            ..add(segmentPcm))
          .toBytes();
      if (pcm.isEmpty) {
        _resetSession();
        throw StateError('No microphone samples captured');
      }
      durationMs = math.max(
        120,
        (pcm.length / (sampleRate * 2) * 1000).round(),
      );
      // Re-wrap only when appending — keep rate consistent with prior takes.
      bytes = _pcm16ToWav(pcm, sampleRate: sampleRate);
    } else {
      // Prefer the native WAV as-is (correct header / sample rate from OS).
      bytes = fileBytes;
      final pcmLen = _wavToPcm16(bytes)?.length ?? (bytes.length - 44);
      durationMs = math.max(
        120,
        (pcmLen / (sampleRate * 2) * 1000).round(),
      );
    }

    final result = AudioRecordingResult(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      duration: Duration(milliseconds: durationMs),
      amplitudes: List<double>.from(_levels),
      bytes: bytes,
      filePath: path,
      uri: Uri.file(path),
    );

    _resetSession();
    _onStatus?.call(AudioRecorderStatus.idle);
    _onDuration?.call(result.duration);
    return result;
  }

  @override
  Future<void> cancel() async {
    await _tearDownCapture(deleteFile: true);
    _resetSession();
    _onDuration?.call(Duration.zero);
    _onStatus?.call(AudioRecorderStatus.idle);
  }

  void _resetSession() {
    _levels.clear();
    _lastLevel = 0.2;
    _ampBusy = false;
    _baseDuration = Duration.zero;
    _segmentElapsed = Duration.zero;
    _priorPcm = null;
    _path = null;
  }

  @override
  Future<void> resumeRecording(
    AudioRecordingResult previous, {
    String? deviceId,
  }) async {
    await _ensurePermission();
    final prior = _wavToPcm16(previous.bytes);
    _baseDuration = previous.duration;
    _levels
      ..clear()
      ..addAll(previous.amplitudes);
    await _beginCapture(priorPcm: prior);
  }

  @override
  void dispose() {
    unawaited(_tearDownCapture(deleteFile: true));
    unawaited(_recorder.dispose());
    _dir?.dispose();
    _dir = null;
  }
}

Uint8List _pcm16ToWav(Uint8List pcm16le, {required int sampleRate}) {
  const numChannels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  const blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = pcm16le.length;
  final bytes = Uint8List(44 + dataSize);
  final out = ByteData.sublistView(bytes);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      out.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  out.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little);
  out.setUint16(22, numChannels, Endian.little);
  out.setUint32(24, sampleRate, Endian.little);
  out.setUint32(28, byteRate, Endian.little);
  out.setUint16(32, blockAlign, Endian.little);
  out.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  out.setUint32(40, dataSize, Endian.little);
  bytes.setRange(44, 44 + dataSize, pcm16le);
  return bytes;
}

/// Strip WAV header when present; otherwise treat [bytes] as raw PCM16.
Uint8List? _wavToPcm16(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  if (data.length >= 44 &&
      data[0] == 0x52 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x46) {
    for (var i = 12; i + 8 < data.length; i++) {
      if (data[i] == 0x64 &&
          data[i + 1] == 0x61 &&
          data[i + 2] == 0x74 &&
          data[i + 3] == 0x61) {
        final size = data[i + 4] |
            (data[i + 5] << 8) |
            (data[i + 6] << 16) |
            (data[i + 7] << 24);
        final start = i + 8;
        final end = math.min(start + size, data.length);
        return data.sublist(start, end);
      }
    }
    return data.sublist(44);
  }
  return data;
}
