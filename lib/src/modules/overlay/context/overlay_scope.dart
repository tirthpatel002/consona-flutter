/// Consona Overlay Scope — ambient [OverlayEngine] for queue coordination.
library;

import 'package:flutter/widgets.dart';

import '../engine/overlay_engine.dart';

class OverlayScope extends InheritedWidget {
  const OverlayScope({
    super.key,
    required this.engine,
    required super.child,
  });

  final OverlayEngine engine;

  static OverlayEngine of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OverlayScope>();
    if (scope == null) {
      throw StateError(
        'No OverlayScope found. Attach ConsonaOverlayPlugin via ConsonaProvider.',
      );
    }
    return scope.engine;
  }

  static OverlayEngine? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OverlayScope>()?.engine;
  }

  @override
  bool updateShouldNotify(OverlayScope oldWidget) => engine != oldWidget.engine;
}

typedef ConsonaOverlayScope = OverlayScope;
