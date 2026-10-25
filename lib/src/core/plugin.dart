/// Consona Plugin Contract & Lifecycle Management
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'event_bus.dart';
import 'registry.dart';
import 'slot.dart';

/// Contract for extending the Consona library with engines, asset sources,
/// theme extensions, event-bus hooks, and slot overrides.
abstract class ConsonaPlugin {
  const ConsonaPlugin();

  /// Unique identifier, e.g. 'consona.feedback', 'consona.assets'.
  String get id;

  /// IDs of plugins that must attach before this plugin can attach.
  Set<String> get dependsOn => const {};

  /// Called when the plugin is attached to the registry.
  FutureOr<void> onAttach(ConsonaRegistry registry);

  /// Called when the plugin is detached (runs in reverse order).
  FutureOr<void> onDetach() {}
}

/// Concrete implementation of [ConsonaRegistry] supporting plugin lifecycle,
/// topological ordering, and rollback on failure.
class ConsonaPluginRegistry implements ConsonaRegistry {
  ConsonaPluginRegistry({ConsonaEventBus? eventBus})
      : _eventBus = eventBus ?? ConsonaEventBus();

  final ConsonaEventBus _eventBus;
  final Map<Type, Object> _engines = {};
  final List<ConsonaAssetEntry> _assetEntries = [];
  final List<ThemeExtension<dynamic>> _themeExtensions = [];
  final Map<String, ConsonaSlot<dynamic>> _slotOverrides = {};
  final List<ConsonaPlugin> _attachedPlugins = [];
  final List<void Function()> _cleanupCallbacks = [];
  bool _ready = false;

  ConsonaEventBus get eventBus => _eventBus;

  @override
  List<ThemeExtension<dynamic>> get themeExtensions =>
      List.unmodifiable(_themeExtensions);

  @override
  bool get isReady => _ready;

  @override
  void registerEngine<T extends Object>(T engine, {bool replace = false}) {
    if (_engines.containsKey(T) && !replace) {
      throw StateError(
        'Engine of type $T is already registered. '
        'Pass replace: true to override an existing engine.',
      );
    }
    _engines[T] = engine;
  }

  @override
  T? engine<T extends Object>() => _engines[T] as T?;

  @override
  T requireEngine<T extends Object>() {
    final e = engine<T>();
    if (e == null) {
      throw StateError('Required engine of type $T is not registered.');
    }
    return e;
  }

  @override
  void contributeAssets(Map<String, dynamic> entries) {
    for (final entry in entries.entries) {
      _assetEntries.add(ConsonaAssetEntry(key: entry.key, value: entry.value));
    }
  }

  List<ConsonaAssetEntry> get assetEntries => List.unmodifiable(_assetEntries);

  @override
  void addThemeExtension(ThemeExtension<dynamic> extension) {
    _themeExtensions.add(extension);
  }

  @override
  void Function() onEvent(String pattern, void Function(Object? payload) handler) {
    final cancel = _eventBus.on(pattern, (payload) => handler(payload));
    _cleanupCallbacks.add(cancel);
    return cancel;
  }

  @override
  void emit(String event, [Object? payload]) {
    _eventBus.emit(event, payload);
  }

  @override
  void overrideSlot<T>(String address, ConsonaSlot<T> slot) {
    _slotOverrides[address] = slot;
  }

  @override
  ConsonaSlot<T>? getSlotOverride<T>(String address) {
    final slot = _slotOverrides[address];
    if (slot == null) return null;
    return slot as ConsonaSlot<T>;
  }

  /// Sorts plugins topologically based on [ConsonaPlugin.dependsOn].
  static List<ConsonaPlugin> sortPlugins(List<ConsonaPlugin> plugins) {
    final byId = {for (final p in plugins) p.id: p};
    final visited = <String, bool>{}; // false = in progress, true = done
    final sorted = <ConsonaPlugin>[];

    void visit(ConsonaPlugin plugin) {
      final status = visited[plugin.id];
      if (status == false) {
        throw StateError('Circular dependency detected involving plugin "${plugin.id}".');
      }
      if (status == true) return;

      visited[plugin.id] = false;
      for (final depId in plugin.dependsOn) {
        final dep = byId[depId];
        if (dep == null) {
          throw StateError('Plugin "${plugin.id}" depends on missing plugin "$depId".');
        }
        visit(dep);
      }
      visited[plugin.id] = true;
      sorted.add(plugin);
    }

    for (final p in plugins) {
      if (!visited.containsKey(p.id)) {
        visit(p);
      }
    }
    return sorted;
  }

  /// Attaches plugins in topological order with rollback if any plugin fails.
  ///
  /// When every [ConsonaPlugin.onAttach] completes synchronously, this method
  /// sets [isReady] before returning so the first frame can render the tree.
  Future<void> attachAll(
    List<ConsonaPlugin> plugins, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _ready = false;
    final sorted = sortPlugins(plugins);
    final newlyAttached = <ConsonaPlugin>[];

    try {
      for (final plugin in sorted) {
        final result = plugin.onAttach(this);
        if (result is Future) {
          await result.timeout(
            timeout,
            onTimeout: () => throw TimeoutException(
              'Plugin "${plugin.id}" timed out during onAttach.',
            ),
          );
        }
        _attachedPlugins.add(plugin);
        newlyAttached.add(plugin);
      }
      _ready = true;
    } catch (e) {
      // Rollback newly attached in reverse order
      for (final plugin in newlyAttached.reversed) {
        try {
          await plugin.onDetach();
        } catch (_) {}
        _attachedPlugins.remove(plugin);
      }
      _ready = false;
      rethrow;
    }
  }

  /// Detaches all plugins in reverse order.
  Future<void> detachAll() async {
    _ready = false;
    for (final cleanup in _cleanupCallbacks) {
      try {
        cleanup();
      } catch (_) {}
    }
    _cleanupCallbacks.clear();

    for (final plugin in _attachedPlugins.reversed) {
      try {
        await plugin.onDetach();
      } catch (_) {}
    }
    _attachedPlugins.clear();
    _engines.clear();
    _assetEntries.clear();
    _themeExtensions.clear();
    _slotOverrides.clear();
  }
}

class ConsonaAssetEntry {
  const ConsonaAssetEntry({required this.key, required this.value});
  final String key;
  final dynamic value;
}
