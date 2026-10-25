/// Consona Size Context — Optical size inheritance down the widget tree
library;

import 'package:flutter/widgets.dart';
import 'types.dart';

/// An [InheritedWidget] providing ambient [ConsonaOpticalSize] to descendants.
class ConsonaSizeScope extends InheritedWidget {
  const ConsonaSizeScope({
    super.key,
    required this.size,
    required super.child,
  });

  /// The active optical size in this subtree.
  final ConsonaOpticalSize size;

  /// Retrieves the ambient [ConsonaOpticalSize], or [ConsonaOpticalSize.sm] if none is set.
  static ConsonaOpticalSize of(BuildContext context) {
    return maybeOf(context) ?? ConsonaOpticalSize.sm;
  }

  /// Retrieves the ambient [ConsonaOpticalSize], or null if none is found.
  static ConsonaOpticalSize? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConsonaSizeScope>()?.size;
  }

  @override
  bool updateShouldNotify(ConsonaSizeScope oldWidget) => size != oldWidget.size;
}
