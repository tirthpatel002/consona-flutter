/// Consona Feedback Scope — InheritedWidget providing ambient FeedbackEngine
library;

import 'package:flutter/widgets.dart';
import '../engine/feedback_engine.dart';

class FeedbackScope extends InheritedWidget {
  const FeedbackScope({
    super.key,
    required this.engine,
    required super.child,
  });

  final FeedbackEngine engine;

  /// Ambient [FeedbackEngine], or throws if none is in the tree.
  ///
  /// Production apps should wrap with [ConsonaProvider] (which installs this
  /// scope when [ConsonaFeedbackPlugin] is attached). Prefer [maybeOf] in
  /// tests or optional call sites that tolerate a no-op.
  static FeedbackEngine of(BuildContext context) {
    final engine = maybeOf(context);
    if (engine == null) {
      throw StateError(
        'No FeedbackScope found in context. '
        'Wrap the tree with ConsonaProvider (default plugins) or FeedbackScope.',
      );
    }
    return engine;
  }

  /// Ambient [FeedbackEngine], or null when absent (tests / optional feedback).
  static FeedbackEngine? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FeedbackScope>()?.engine;
  }

  @override
  bool updateShouldNotify(FeedbackScope oldWidget) => engine != oldWidget.engine;
}

/// Convenience alias matching Consona naming convention.
typedef ConsonaFeedbackScope = FeedbackScope;
