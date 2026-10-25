/// ConsonaSlots — Ambient slot override resolution from [ConsonaProvider].
library;

import 'package:flutter/widgets.dart';

import 'provider.dart';
import 'registry.dart';
import 'slot.dart';

/// Resolves registry slot overrides from the nearest [ConsonaProvider].
abstract final class ConsonaSlots {
  /// Looks up a slot override, or null if absent / no provider.
  static ConsonaSlot<T>? maybeOf<T>(BuildContext context, String address) {
    final registry = ConsonaProvider.maybeRegistryOf(context);
    return registry?.getSlotOverride<T>(address);
  }

  /// Looks up a slot override; throws if no [ConsonaProvider] is present.
  static ConsonaSlot<T>? of<T>(BuildContext context, String address) {
    final registry = ConsonaProvider.registryOf(context);
    return registry.getSlotOverride<T>(address);
  }

  /// Resolves [address] to a widget, falling back to [defaultComponent].
  static Widget? resolve<T>(
    BuildContext context,
    String address,
    T props, {
    Widget? defaultComponent,
  }) {
    final slot = maybeOf<T>(context, address);
    if (slot == null) return defaultComponent;
    return slot.resolve(context, props, defaultComponent: defaultComponent);
  }

  /// Ambient registry when available.
  static ConsonaRegistry? registryOf(BuildContext context) =>
      ConsonaProvider.maybeRegistryOf(context);
}
