/// Consona Mobile Core Types & Enums
library;

/// Semantic color intent roles for components.
enum ConsonaIntent {
  // Core 5
  primary,
  subtle,
  outline,
  plain,
  danger,
  // Optional semantic extras
  secondary,
  success,
  warning,
  ghost;

  bool get isCore =>
      this == primary ||
      this == subtle ||
      this == outline ||
      this == plain ||
      this == danger;
}

/// Optical sizing roles scaling geometry, font, and padding.
enum ConsonaOpticalSize {
  xs,
  sm,
  md,
  lg,
  sqXs,
  sqSm,
  sqMd,
  sqLg;

  bool get isSquare =>
      this == sqXs || this == sqSm || this == sqMd || this == sqLg;

  ConsonaOpticalSize get standardEquivalent => switch (this) {
        sqXs => xs,
        sqSm => sm,
        sqMd => md,
        sqLg => lg,
        _ => this,
      };
}

/// Shape and corner geometry variants.
enum ConsonaShapeVariant {
  base,
  pill,
  squircle,
  inset,
}

/// Optical roles for curvature/radius scaling.
enum ConsonaRadiusRole {
  /// Stadium / capsule corners (always fully rounded).
  full,
  macro,
  base,
  micro,
  atom,
}

/// Whole-theme or per-component radius preset options.
enum ConsonaRadiusPreset {
  none,
  sm,
  md,
  lg,
  xl,
  full,
  squircle,
}

/// Elevation and depth levels for ambient tinted shadows.
enum ConsonaShadowLevel {
  none,
  subtle,
  soft,
  strong,
}

/// Stroke / border width presets.
enum ConsonaStrokePreset {
  flat,
  standard,
  bold,
}

/// Density scale presets.
enum ConsonaDensityPreset {
  compact,
  normal,
  spacious;

  double get factor => switch (this) {
        compact => 0.85,
        normal => 1.0,
        spacious => 1.15,
      };
}

/// Interactive button lifecycle states.
enum ButtonState {
  idle,
  loading,
  success,
  error;

  ConsonaInteractionState get interactionState => switch (this) {
        ButtonState.loading => ConsonaInteractionState.idle,
        ButtonState.error => ConsonaInteractionState.error,
        ButtonState.success => ConsonaInteractionState.selected,
        ButtonState.idle => ConsonaInteractionState.idle,
      };
}

/// General component interaction states for token resolution.
enum ConsonaInteractionState {
  idle,
  hovered,
  pressed,
  focused,
  selected,
  error,
  disabled,
}

/// Optical typography role hierarchy.
enum ConsonaTextRole {
  hero,
  titleLarge,
  titleMedium,
  body,
  caption,
  label,
}

/// Border roles for semantic borders.
enum ConsonaBorderRole {
  subtle,
  defaultBorder,
  strong,
  focus,
  error,
  disabled,
  divider,
  inputOutline,
  surfaceEdge,
}

/// Border vs shadow rendering strategy.
enum ConsonaBorderStrategy {
  border,
  shadow,
  both,
  none,
}

/// Border styling modes.
enum ConsonaBorderStyle {
  solid,
  dashed,
  none,
  inset,
}

/// Border directional edges.
enum ConsonaBorderEdge {
  top,
  bottom,
  start,
  end,
}

/// Motion roles for animation duration and curve resolution.
enum ConsonaMotionRole {
  press,
  toggle,
  reveal,
  focus,
  page,
  shimmer,
  pulse,
}

/// Theme mode selection.
enum ConsonaThemeMode {
  system,
  light,
  dark,
}
