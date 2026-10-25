/// Inherited semantic tone for buttons nested in alerts/banners.
library;

import 'package:flutter/widgets.dart';

import '../../../core/types.dart';

/// Applies a parent [ConsonaIntent] (e.g. warning) to descendant [ConsonaButton]s.
class ConsonaButtonToneScope extends InheritedWidget {
  const ConsonaButtonToneScope({
    super.key,
    required this.intent,
    required super.child,
  });

  final ConsonaIntent intent;

  static ConsonaIntent? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ConsonaButtonToneScope>()
        ?.intent;
  }

  @override
  bool updateShouldNotify(ConsonaButtonToneScope oldWidget) =>
      oldWidget.intent != intent;
}
