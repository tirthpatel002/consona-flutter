/// Consona Event Bus — Decoupled pub/sub with wildcard support
library;

typedef ConsonaEventListener = void Function(Object? payload);

/// Domain event bus supporting exact and wildcard subscriptions.
class ConsonaEventBus {
  final Map<String, Set<ConsonaEventListener>> _listeners = {};

  /// Subscribes to events. Supports exact names (e.g. 'audio:play') or
  /// wildcards (e.g. '*' or 'audio:*').
  ///
  /// Returns a cancel callback function.
  void Function() on(String pattern, ConsonaEventListener listener) {
    _listeners.putIfAbsent(pattern, () => {}).add(listener);
    return () {
      final set = _listeners[pattern];
      if (set != null) {
        set.remove(listener);
        if (set.isEmpty) {
          _listeners.remove(pattern);
        }
      }
    };
  }

  /// Emits an event with optional payload to all matching subscribers.
  void emit(String event, [Object? payload]) {
    final matched = <ConsonaEventListener>{};

    // 1. Exact matches
    if (_listeners.containsKey(event)) {
      matched.addAll(_listeners[event]!);
    }

    // 2. Global wildcard
    if (_listeners.containsKey('*')) {
      matched.addAll(_listeners['*']!);
    }

    // 3. Domain wildcards (e.g. 'domain:*')
    final colonIdx = event.indexOf(':');
    if (colonIdx > 0) {
      final domainWildcard = '${event.substring(0, colonIdx)}:*';
      if (_listeners.containsKey(domainWildcard)) {
        matched.addAll(_listeners[domainWildcard]!);
      }
    }

    for (final listener in matched) {
      try {
        listener(payload);
      } catch (err, stack) {
        // Fail-closed: Never crash event pipeline
        assert(() {
          // ignore: avoid_print
          print('[ConsonaEventBus Error] $err\n$stack');
          return true;
        }());
      }
    }
  }

  /// Clears all registered listeners.
  void clear() {
    _listeners.clear();
  }
}
