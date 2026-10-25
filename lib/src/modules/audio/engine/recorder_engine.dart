/// Consona AudioRecorderEngine — Reactive capture state machine (mock-capable).
library;

import 'dart:async';
import 'dart:math' as math;

import '../../../core/engine.dart';
import '../../../core/event_bus.dart';
import '../../assets/synth/sound_recipe.dart';

enum AudioRecorderStatus {
  idle,
  recording,
  paused,
}

class AudioRecordingResult {
  const AudioRecordingResult({
    required this.id,
    required this.duration,
    this.amplitudes = const [],
    this.bytes,
    this.filePath,
    this.uri,
  });

  final String id;
  final Duration duration;
  final List<double> amplitudes;
  final List<int>? bytes;

  /// Local filesystem path when the backend persists a capture file.
  final String? filePath;

  /// Optional URI for the capture (file://, content://, …).
  final Uri? uri;

  bool get hasAudio =>
      (bytes != null && bytes!.isNotEmpty) ||
      (filePath != null && filePath!.isNotEmpty) ||
      uri != null;
}

class AudioRecorderState {
  const AudioRecorderState({
    this.status = AudioRecorderStatus.idle,
    this.duration = Duration.zero,
    this.levels = const [],
    this.lastRecording,
    this.errorMessage,
  });

  final AudioRecorderStatus status;
  final Duration duration;
  final List<double> levels;
  final AudioRecordingResult? lastRecording;
  final String? errorMessage;

  bool get isRecording => status == AudioRecorderStatus.recording;
  bool get isPaused => status == AudioRecorderStatus.paused;
  bool get isIdle => status == AudioRecorderStatus.idle;
  bool get hasRecording => lastRecording != null;
  bool get hasError => errorMessage != null;

  AudioRecorderState copyWith({
    AudioRecorderStatus? status,
    Duration? duration,
    List<double>? levels,
    AudioRecordingResult? lastRecording,
    String? errorMessage,
    bool clearRecording = false,
    bool clearError = false,
  }) {
    return AudioRecorderState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      levels: levels ?? this.levels,
      lastRecording:
          clearRecording ? null : (lastRecording ?? this.lastRecording),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Abstract capture backend — one instance per [AudioRecorderEngine].
abstract interface class AudioRecorderBackend {
  void attach({
    required void Function(Duration duration) onDuration,
    required void Function(double level) onLevel,
    required void Function(AudioRecorderStatus status) onStatus,
    void Function(Object error)? onError,
  });

  Future<void> start({String? deviceId});
  Future<void> pause();
  Future<void> resume();
  Future<AudioRecordingResult> stop();

  /// Discard the in-progress capture without producing a result.
  Future<void> cancel();

  /// Continue capturing onto [previous] (append).
  Future<void> resumeRecording(
    AudioRecordingResult previous, {
    String? deviceId,
  });

  void dispose();
}

/// Simulated mic for previews / tests — no platform permissions.
class MockAudioRecorderBackend implements AudioRecorderBackend {
  Timer? _timer;
  Duration _duration = Duration.zero;
  Duration _baseDuration = Duration.zero;
  final List<double> _levels = <double>[];
  final _rng = math.Random(7);
  bool _active = false;

  void Function(Duration)? _onDuration;
  void Function(double)? _onLevel;
  void Function(AudioRecorderStatus)? _onStatus;

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
  }

  void _tick() {
    _duration += const Duration(milliseconds: 100);
    final level = 0.25 + _rng.nextDouble() * 0.7;
    _levels.add(level);
    if (_levels.length > 64) _levels.removeAt(0);
    _onDuration?.call(_baseDuration + _duration);
    _onLevel?.call(level);
  }

  @override
  Future<void> start({String? deviceId}) async {
    _timer?.cancel();
    _duration = Duration.zero;
    _baseDuration = Duration.zero;
    _levels.clear();
    _active = true;
    _onStatus?.call(AudioRecorderStatus.recording);
    _onDuration?.call(Duration.zero);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_active) _tick();
    });
  }

  @override
  Future<void> pause() async {
    _active = false;
    _timer?.cancel();
    _onStatus?.call(AudioRecorderStatus.paused);
  }

  @override
  Future<void> resume() async {
    _active = true;
    _onStatus?.call(AudioRecorderStatus.recording);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_active) _tick();
    });
  }

  @override
  Future<AudioRecordingResult> stop() async {
    _active = false;
    _timer?.cancel();
    final total = _baseDuration + _duration;
    final ms = math.max(120, total.inMilliseconds).toDouble();
    final bytes = SoundRecipe(
      waveform: SoundWaveform.noise,
      frequency: 900.0,
      sweepTo: 900.0,
      durationMs: ms,
      gain: 0.16,
      envelope: const SoundEnvelope(
        attackMs: 20,
        decayMs: 0,
        sustain: 1.0,
        releaseMs: 40,
      ),
      harmonics: const [],
    ).toWav();
    final result = AudioRecordingResult(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      duration: total,
      amplitudes: List<double>.from(_levels),
      bytes: bytes,
    );
    _onStatus?.call(AudioRecorderStatus.idle);
    _duration = Duration.zero;
    _baseDuration = Duration.zero;
    return result;
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _timer?.cancel();
    _duration = Duration.zero;
    _baseDuration = Duration.zero;
    _levels.clear();
    _onDuration?.call(Duration.zero);
    _onStatus?.call(AudioRecorderStatus.idle);
  }

  @override
  Future<void> resumeRecording(
    AudioRecordingResult previous, {
    String? deviceId,
  }) async {
    _timer?.cancel();
    _baseDuration = previous.duration;
    _duration = Duration.zero;
    _levels
      ..clear()
      ..addAll(previous.amplitudes);
    _active = true;
    _onStatus?.call(AudioRecorderStatus.recording);
    _onDuration?.call(_baseDuration);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_active) _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}

/// Pure Dart recorder engine — one instance per recorder surface.
///
/// Do **not** share an [AudioRecorderEngine] (or its backend) across widgets
/// unless those widgets intentionally mirror the same capture session.
class AudioRecorderEngine extends ConsonaEngine<AudioRecorderState> {
  AudioRecorderEngine({
    AudioRecorderBackend? backend,
    ConsonaEventBus? eventBus,
    this.id,
  })  : _backend = backend ?? MockAudioRecorderBackend(),
        super(const AudioRecorderState(), eventBus: eventBus) {
    _backend.attach(
      onDuration: (d) {
        if (_disposed) return;
        _pendingDuration = d;
        _scheduleMeterFlush();
      },
      onLevel: (level) {
        if (_disposed) return;
        _pendingLevel = level;
        _scheduleMeterFlush();
      },
      onStatus: (status) {
        if (_disposed) return;
        setState(
          (prev) => prev.copyWith(status: status, clearError: true),
        );
      },
      onError: (error) {
        if (_disposed) return;
        setState(
          (prev) => prev.copyWith(errorMessage: error.toString()),
        );
      },
    );
  }

  /// Optional stable id for logging / multi-recorder debugging.
  final String? id;

  final AudioRecorderBackend _backend;
  AudioRecordingResult? _stashForResume;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  Duration? _pendingDuration;
  double? _pendingLevel;
  bool _meterFlushScheduled = false;

  /// Coalesce duration + level from the same tick into one notify.
  /// Status / errors stay immediate — never wait on this flush.
  void _scheduleMeterFlush() {
    if (_meterFlushScheduled || _disposed) return;
    _meterFlushScheduled = true;
    scheduleMicrotask(_flushMeter);
  }

  void _flushMeter() {
    _meterFlushScheduled = false;
    if (_disposed) return;
    final d = _pendingDuration;
    final l = _pendingLevel;
    _pendingDuration = null;
    _pendingLevel = null;
    if (d == null && l == null) return;
    setState((prev) {
      var next = prev;
      if (d != null) next = next.copyWith(duration: d);
      if (l != null) {
        final levels = List<double>.of(next.levels)..add(l);
        if (levels.length > 48) levels.removeRange(0, levels.length - 48);
        next = next.copyWith(levels: levels);
      }
      return next;
    });
  }

  AudioRecorderBackend get backend => _backend;
  bool get isDisposed => _disposed;

  Future<T> _run<T>(Future<T> Function() op) {
    if (_disposed) {
      return Future.error(
        StateError('AudioRecorderEngine(${id ?? 'anon'}) disposed'),
      );
    }
    final done = Completer<T>();
    _queue = _queue.catchError((_) {}).then((_) async {
      if (_disposed) {
        done.completeError(
          StateError('AudioRecorderEngine(${id ?? 'anon'}) disposed'),
        );
        return;
      }
      try {
        done.complete(await op());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

  Future<void> start({String? deviceId}) => _run(() async {
        final kept = state.lastRecording;
        _stashForResume = null;
        setState(
          (prev) => prev.copyWith(
            status: AudioRecorderStatus.recording,
            duration: Duration.zero,
            levels: const [],
            clearRecording: true,
            clearError: true,
          ),
        );
        try {
          await _backend.start(deviceId: deviceId);
          eventBus?.emit('audio:record:start', {'id': id});
        } catch (e) {
          setState(
            (prev) => prev.copyWith(
              status: AudioRecorderStatus.idle,
              lastRecording: kept,
              duration: kept?.duration ?? Duration.zero,
              levels: kept?.amplitudes ?? const [],
              errorMessage: e.toString(),
            ),
          );
          _stashForResume = kept;
          rethrow;
        }
      });

  Future<void> pause() => _run(() async {
        await _backend.pause();
        setState((prev) => prev.copyWith(status: AudioRecorderStatus.paused));
        eventBus?.emit('audio:record:pause', {'id': id});
      });

  Future<void> resume() => _run(() async {
        await _backend.resume();
        setState(
          (prev) => prev.copyWith(status: AudioRecorderStatus.recording),
        );
        eventBus?.emit('audio:record:resume', {'id': id});
      });

  Future<AudioRecordingResult> stop() => _run(() async {
        final kept = state.lastRecording ?? _stashForResume;
        try {
          final result = await _backend.stop();
          _stashForResume = result;
          setState(
            (prev) => prev.copyWith(
              status: AudioRecorderStatus.idle,
              lastRecording: result,
              duration: result.duration,
              clearError: true,
            ),
          );
          eventBus?.emit('audio:record:stop', {
            'id': id,
            'ms': result.duration.inMilliseconds,
          });
          return result;
        } catch (e) {
          setState(
            (prev) => prev.copyWith(
              status: AudioRecorderStatus.idle,
              lastRecording: kept,
              duration: kept?.duration ?? prev.duration,
              errorMessage: e.toString(),
            ),
          );
          rethrow;
        }
      });

  /// Discard the in-progress capture; keeps [lastRecording] untouched.
  Future<void> cancel() => _run(() async {
        await _backend.cancel();
        final kept = state.lastRecording ?? _stashForResume;
        setState(
          (prev) => prev.copyWith(
            status: AudioRecorderStatus.idle,
            duration: kept?.duration ?? Duration.zero,
            levels: kept?.amplitudes ?? const [],
            lastRecording: kept,
            clearError: true,
          ),
        );
        eventBus?.emit('audio:record:cancel', {'id': id});
      });

  /// Append onto the last take (or [previous]).
  ///
  /// Keeps [AudioRecorderState.lastRecording] until the next successful
  /// [stop] replaces it — discard via [clear] is the only remove path.
  Future<void> resumeRecording({
    AudioRecordingResult? previous,
    String? deviceId,
  }) async {
    final base = previous ?? _stashForResume ?? state.lastRecording;
    if (base == null) {
      await start(deviceId: deviceId);
      return;
    }
    return _run(() async {
      _stashForResume = base;
      setState(
        (prev) => prev.copyWith(
          status: AudioRecorderStatus.recording,
          duration: base.duration,
          levels: base.amplitudes,
          lastRecording: base,
          clearError: true,
        ),
      );
      try {
        await _backend.resumeRecording(base, deviceId: deviceId);
        eventBus?.emit('audio:record:resumeRecording', {'id': id});
      } catch (e) {
        setState(
          (prev) => prev.copyWith(
            status: AudioRecorderStatus.idle,
            lastRecording: base,
            duration: base.duration,
            errorMessage: e.toString(),
          ),
        );
        rethrow;
      }
    });
  }

  /// Remove the kept take from this engine instance.
  void clear() {
    if (_disposed) return;
    _stashForResume = null;
    setState(
      (prev) => prev.copyWith(
        status: AudioRecorderStatus.idle,
        duration: Duration.zero,
        levels: const [],
        clearRecording: true,
        clearError: true,
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _backend.dispose();
    super.dispose();
  }
}
