/// Consona Theme Provider — Ambient theme accessor and scoped override widget
library;

import 'package:flutter/material.dart';
import 'presets.dart';
import 'theme_data.dart';

abstract final class ConsonaTheme {
  /// Resolves the ambient [ConsonaThemeData] from the widget tree.
  /// Falls back cleanly to [ConsonaPresets.minimal] if none is installed (fail-closed, Rule C8).
  static ConsonaThemeData of(BuildContext context) {
    return Theme.of(context).extension<ConsonaThemeData>() ??
        ConsonaThemeScope.maybeOf(context) ??
        ConsonaPresets.minimal();
  }

  /// Returns the ambient [ConsonaThemeData] or null if not registered.
  static ConsonaThemeData? maybeOf(BuildContext context) {
    return Theme.of(context).extension<ConsonaThemeData>() ??
        ConsonaThemeScope.maybeOf(context);
  }
}

/// An [InheritedWidget] to locally override or provide [ConsonaThemeData]
/// for a specific subtree without modifying the global [ThemeData].
class ConsonaThemeScope extends InheritedWidget {
  const ConsonaThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final ConsonaThemeData theme;

  static ConsonaThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConsonaThemeScope>()?.theme;
  }

  @override
  bool updateShouldNotify(ConsonaThemeScope oldWidget) => theme != oldWidget.theme;
}
