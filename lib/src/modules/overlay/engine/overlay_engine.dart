/// Consona OverlayEngine — Pure Dart state engine managing overlay queues,
/// stacking priorities, and timeouts.
library;

import 'dart:async';
import '../../../core/engine.dart';
import '../../../core/event_bus.dart';

enum ConsonaOverlayPriority {
  toast,
  banner,
  sheet,
  dialog,
  alert,
}

class ConsonaOverlayItem {
  const ConsonaOverlayItem({
    required this.id,
    required this.priority,
    required this.data,
    this.timeout,
  });

  final String id;
  final ConsonaOverlayPriority priority;
  final Object data;
  final Duration? timeout;
}

class ConsonaOverlayState {
  const ConsonaOverlayState({
    this.active = const [],
    this.queue = const [],
  });

  final List<ConsonaOverlayItem> active;
  final List<ConsonaOverlayItem> queue;

  ConsonaOverlayState copyWith({
    List<ConsonaOverlayItem>? active,
    List<ConsonaOverlayItem>? queue,
  }) {
    return ConsonaOverlayState(
      active: active ?? this.active,
      queue: queue ?? this.queue,
    );
  }
}

/// Pure Dart overlay state machine and priority manager.
class OverlayEngine extends ConsonaEngine<ConsonaOverlayState> {
  OverlayEngine({
    ConsonaEventBus? eventBus,
    this.maxActive = 3,
  }) : super(
          const ConsonaOverlayState(),
          eventBus: eventBus,
        );

  final int maxActive;
  final Map<String, Timer> _timers = {};

  void push(ConsonaOverlayItem item) {
    if (state.active.length < maxActive) {
      final newActive = [...state.active, item];
      setState((prev) => prev.copyWith(active: newActive));
      _scheduleTimeout(item);
    } else {
      // Insert by priority into queue
      final newQueue = [...state.queue, item]..sort(
          (a, b) => b.priority.index.compareTo(a.priority.index),
        );
      setState((prev) => prev.copyWith(queue: newQueue));
    }
    eventBus?.emit('overlay:pushed', {'id': item.id, 'priority': item.priority.name});
  }

  void dismiss(String id) {
    _timers.remove(id)?.cancel();

    final nextActive = state.active.where((item) => item.id != id).toList();
    var nextQueue = state.queue;

    if (nextActive.length < maxActive && nextQueue.isNotEmpty) {
      final promoted = nextQueue.first;
      nextQueue = nextQueue.sublist(1);
      nextActive.add(promoted);
      _scheduleTimeout(promoted);
    }

    setState((prev) => prev.copyWith(active: nextActive, queue: nextQueue));
    eventBus?.emit('overlay:dismissed', {'id': id});
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    setState((_) => const ConsonaOverlayState());
    eventBus?.emit('overlay:cleared', {});
  }

  void _scheduleTimeout(ConsonaOverlayItem item) {
    if (item.timeout != null) {
      _timers[item.id] = Timer(item.timeout!, () => dismiss(item.id));
    }
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
