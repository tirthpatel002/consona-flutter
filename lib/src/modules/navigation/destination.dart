/// Consona Destination — one navigable page of a [ConsonaNav] / [ConsonaShell]
library;

import 'package:flutter/widgets.dart';

/// A single destination: how it is shown in the nav and the page it owns.
class ConsonaDestination {
  const ConsonaDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.selectedIcon,
    this.badge,
  });

  /// Stable identity; used for selection and for keeping the page alive.
  final String id;

  /// Visible label and accessibility label.
  final String label;

  final IconData icon;

  /// Icon shown while selected (falls back to [icon]).
  final IconData? selectedIcon;

  /// Optional badge (e.g. a `ConsonaBadge`) shown on the item.
  final Widget? badge;

  /// Builds the page. Called lazily on first visit; the page is then kept alive.
  final WidgetBuilder builder;
}
