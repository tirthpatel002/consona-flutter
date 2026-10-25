/// Consona Border — Semantic border resolution by role and interaction state
library;

import 'package:flutter/widgets.dart';
import '../core/types.dart';
import 'colors.dart';
import 'stroke.dart';

class ConsonaBorderSpec {
  const ConsonaBorderSpec({
    required this.colorRole,
    this.widthScale = 1.0,
    this.style = ConsonaBorderStyle.solid,
    this.sides = const {
      ConsonaBorderEdge.top,
      ConsonaBorderEdge.bottom,
      ConsonaBorderEdge.start,
      ConsonaBorderEdge.end,
    },
    this.states = const {},
  });

  final String colorRole;
  final double widthScale;
  final ConsonaBorderStyle style;
  final Set<ConsonaBorderEdge> sides;
  final Map<ConsonaInteractionState, ConsonaBorderSpec> states;

  ConsonaBorderSpec forState(ConsonaInteractionState state) {
    if (states.containsKey(state)) {
      return states[state]!;
    }
    return this;
  }
}

class ConsonaBorder {
  const ConsonaBorder({
    required this.stroke,
    required this.colors,
    this.strategy = ConsonaBorderStrategy.border,
    this.darkStrategy,
    this.roles = ConsonaBorder.defaultRoles,
  });

  final ConsonaStroke stroke;
  final ConsonaColors colors;
  final ConsonaBorderStrategy strategy;
  final ConsonaBorderStrategy? darkStrategy;
  final Map<ConsonaBorderRole, ConsonaBorderSpec> roles;

  static const Map<ConsonaBorderRole, ConsonaBorderSpec> defaultRoles = {
    ConsonaBorderRole.subtle: ConsonaBorderSpec(
      colorRole: 'borderLight',
      widthScale: 1.0,
    ),
    ConsonaBorderRole.defaultBorder: ConsonaBorderSpec(
      colorRole: 'border',
      widthScale: 1.0,
      states: {
        ConsonaInteractionState.hovered: ConsonaBorderSpec(
          colorRole: 'borderStrong',
          widthScale: 1.0,
        ),
        ConsonaInteractionState.pressed: ConsonaBorderSpec(
          colorRole: 'borderStrong',
          widthScale: 1.0,
        ),
      },
    ),
    ConsonaBorderRole.strong: ConsonaBorderSpec(
      colorRole: 'borderStrong',
      widthScale: 2.0,
    ),
    ConsonaBorderRole.focus: ConsonaBorderSpec(
      colorRole: 'focusRing',
      widthScale: 1.5,
    ),
    ConsonaBorderRole.error: ConsonaBorderSpec(
      colorRole: 'danger',
      widthScale: 1.5,
    ),
    ConsonaBorderRole.disabled: ConsonaBorderSpec(
      colorRole: 'muted',
      widthScale: 1.0,
    ),
    ConsonaBorderRole.divider: ConsonaBorderSpec(
      colorRole: 'borderLight',
      widthScale: 1.0,
      sides: {ConsonaBorderEdge.bottom},
    ),
    ConsonaBorderRole.inputOutline: ConsonaBorderSpec(
      colorRole: 'border',
      widthScale: 1.0,
      states: {
        ConsonaInteractionState.hovered: ConsonaBorderSpec(
          colorRole: 'borderStrong',
          widthScale: 1.0,
        ),
        ConsonaInteractionState.focused: ConsonaBorderSpec(
          colorRole: 'focusRing',
          widthScale: 1.5,
        ),
        ConsonaInteractionState.error: ConsonaBorderSpec(
          colorRole: 'danger',
          widthScale: 1.5,
        ),
      },
    ),
    ConsonaBorderRole.surfaceEdge: ConsonaBorderSpec(
      colorRole: 'borderLight',
      widthScale: 1.0,
    ),
  };

  ConsonaBorderStrategy get activeStrategy =>
      (colors.isDark && darkStrategy != null) ? darkStrategy! : strategy;

  bool _isFunctional(ConsonaBorderRole role) => switch (role) {
        ConsonaBorderRole.focus ||
        ConsonaBorderRole.error ||
        ConsonaBorderRole.disabled ||
        ConsonaBorderRole.divider ||
        ConsonaBorderRole.inputOutline =>
          true,
        _ => false,
      };

  bool _drawsBorder(ConsonaBorderRole role) {
    if (_isFunctional(role)) return true;
    return activeStrategy == ConsonaBorderStrategy.border ||
        activeStrategy == ConsonaBorderStrategy.both;
  }

  Color _resolveColor(String role) {
    return switch (role) {
      'border' => colors.border,
      'borderLight' => colors.borderLight,
      'borderStrong' => colors.borderStrong,
      'primary' => colors.primary,
      'focusRing' => colors.focusRing,
      'danger' => colors.danger,
      'muted' => colors.muted,
      _ => colors.border,
    };
  }

  /// Resolves a full [BoxBorder] for a given role and interaction state.
  BoxBorder resolve(
    ConsonaBorderRole role, {
    ConsonaInteractionState state = ConsonaInteractionState.idle,
    BuildContext? context,
  }) {
    final spec = (roles[role] ?? defaultRoles[role]!).forState(state);
    final width = stroke.resolveWidth(context) * spec.widthScale;

    if (width <= 0 || spec.style == ConsonaBorderStyle.none || !_drawsBorder(role)) {
      return const Border();
    }

    final side = BorderSide(
      width: width,
      color: _resolveColor(spec.colorRole),
    );

    return BorderDirectional(
      top: spec.sides.contains(ConsonaBorderEdge.top) ? side : BorderSide.none,
      bottom: spec.sides.contains(ConsonaBorderEdge.bottom) ? side : BorderSide.none,
      start: spec.sides.contains(ConsonaBorderEdge.start) ? side : BorderSide.none,
      end: spec.sides.contains(ConsonaBorderEdge.end) ? side : BorderSide.none,
    );
  }

  /// Resolves a single [BorderSide] for a given role.
  BorderSide resolveSide(
    ConsonaBorderRole role, {
    ConsonaInteractionState state = ConsonaInteractionState.idle,
    BuildContext? context,
  }) {
    final spec = (roles[role] ?? defaultRoles[role]!).forState(state);
    final width = stroke.resolveWidth(context) * spec.widthScale;

    if (width <= 0 || spec.style == ConsonaBorderStyle.none || !_drawsBorder(role)) {
      return BorderSide.none;
    }

    return BorderSide(
      width: width,
      color: _resolveColor(spec.colorRole),
    );
  }

  /// Linearly interpolates between two [ConsonaBorder] instances.
  static ConsonaBorder lerp(ConsonaBorder a, ConsonaBorder b, double t) {
    return ConsonaBorder(
      stroke: ConsonaStroke.lerp(a.stroke, b.stroke, t),
      colors: ConsonaColors.lerp(a.colors, b.colors, t),
      strategy: t < 0.5 ? a.strategy : b.strategy,
      darkStrategy: t < 0.5 ? a.darkStrategy : b.darkStrategy,
      roles: t < 0.5 ? a.roles : b.roles,
    );
  }
}
