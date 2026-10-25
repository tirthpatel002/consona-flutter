/// Consona Registry — Extensibility contract for engines, assets, theme, events, slots
library;

import 'package:flutter/material.dart';
import 'slot.dart';

abstract class ConsonaRegistry {
  /// Registers a headless logic engine instance.
  void registerEngine<T extends Object>(T engine, {bool replace = false});

  /// Retrieves an engine by type if present.
  T? engine<T extends Object>();

  /// Retrieves an engine by type or throws an error.
  T requireEngine<T extends Object>();

  /// Contributes asset manifest entries.
  void contributeAssets(Map<String, dynamic> entries);

  /// Adds a theme extension into the global theme extensions list.
  void addThemeExtension(ThemeExtension<dynamic> extension);

  /// Theme extensions contributed by plugins (for Material [ThemeData.extensions]).
  List<ThemeExtension<dynamic>> get themeExtensions;

  /// Hooks into event bus events. Returns an unregister callback.
  void Function() onEvent(String pattern, void Function(Object? payload) handler);

  /// Emits an event on the event bus.
  void emit(String event, [Object? payload]);

  /// Registers a global slot override.
  void overrideSlot<T>(String address, ConsonaSlot<T> slot);

  /// Retrieves a registered slot override if present.
  ConsonaSlot<T>? getSlotOverride<T>(String address);

  /// Whether [attachAll] has finished successfully.
  bool get isReady;
}
