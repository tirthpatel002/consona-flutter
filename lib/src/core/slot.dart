/// Consona Universal Slot Pipeline
library;

import 'package:flutter/widgets.dart';

typedef ConsonaSlotBuilder<T> = Widget? Function(BuildContext context, T props);

/// Addressable injection point that resolves:
/// 1. A pre-instantiated [Widget].
/// 2. A dynamic [ConsonaSlotBuilder] receiving state payload.
/// 3. An explicit opt-out via [ConsonaSlot.empty] (returns null).
/// 4. Graceful fallback to default stock components.
class ConsonaSlot<T> {
  const ConsonaSlot._({
    this.widget,
    this.builder,
    this.isEmpty = false,
  });

  final Widget? widget;
  final ConsonaSlotBuilder<T>? builder;
  final bool isEmpty;

  /// Injects a static pre-instantiated widget.
  factory ConsonaSlot.widget(Widget widget) => ConsonaSlot._(widget: widget);

  /// Injects a dynamic builder function receiving component props/state.
  factory ConsonaSlot.builder(ConsonaSlotBuilder<T> builder) =>
      ConsonaSlot._(builder: builder);

  /// Explicitly hides this slot address (Rule C5.0 opt-out, renders null).
  static const ConsonaSlot<Never> empty = ConsonaSlot._(isEmpty: true);

  /// Resolves the slot's visual representation.
  Widget? resolve(
    BuildContext context,
    T props, {
    Widget? defaultComponent,
  }) {
    if (isEmpty) return null;
    if (widget != null) return widget;
    if (builder != null) {
      final built = builder!(context, props);
      if (built != null) return built;
    }
    return defaultComponent;
  }
}
