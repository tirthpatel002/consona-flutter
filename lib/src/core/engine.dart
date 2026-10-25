import 'package:flutter/foundation.dart' show Listenable, VoidCallback;
import 'event_bus.dart';
import 'storage.dart';

typedef StateUpdater<TState> = TState Function(TState prev);
typedef StateListener = void Function();

/// Base engine managing reactive state snapshots, batching, event-bus
/// messaging, and storage synchronization completely detached from Flutter widgets.
abstract class ConsonaEngine<TState> implements Listenable {
  ConsonaEngine(this._state, {this.storage, this.eventBus});

  TState _state;
  final ConsonaStorageAdapter? storage;
  final ConsonaEventBus? eventBus;

  final Set<StateListener> _listeners = {};
  bool _isBatching = false;
  bool _hasPendingNotify = false;
  bool _isDisposed = false;

  /// Returns current state snapshot.
  TState get state => _state;

  /// Updates state and notifies subscribers unless batching.
  void setState(StateUpdater<TState> updater) {
    if (_isDisposed) return;
    _state = updater(_state);
    if (_isBatching) {
      _hasPendingNotify = true;
    } else {
      notifyListeners();
    }
  }

  /// Batches multiple state updates into a single notification.
  void batch(void Function() actions) {
    if (_isDisposed) return;
    final wasBatching = _isBatching;
    _isBatching = true;
    try {
      actions();
    } finally {
      _isBatching = wasBatching;
      if (!_isBatching && _hasPendingNotify) {
        _hasPendingNotify = false;
        notifyListeners();
      }
    }
  }

  /// Subscribes a listener callback. Returns an unsubscribe function.
  void Function() subscribe(StateListener listener) {
    if (_isDisposed) return () {};
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  @override
  void addListener(VoidCallback listener) {
    subscribe(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies all active subscribers.
  void notifyListeners() {
    if (_isDisposed) return;
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (err, stack) {
        assert(() {
          // ignore: avoid_print
          print('[ConsonaEngine Error] Subscriber threw: $err\n$stack');
          return true;
        }());
      }
    }
  }

  /// Emits an event on the attached event bus.
  void emit(String event, [Object? payload]) {
    eventBus?.emit(event, payload);
  }

  /// Disposes the engine and clears subscribers.
  void dispose() {
    _isDisposed = true;
    _listeners.clear();
  }
}
