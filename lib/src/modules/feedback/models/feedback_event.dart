/// Consona Feedback Events & Haptic Intensity
library;

enum HapticIntensity {
  none,
  selection,
  light,
  medium,
  heavy,
}

enum FeedbackEvent {
  tap,
  toggleOn,
  toggleOff,
  tick,
  pop,
  selection,
  success,
  error,

  /// Soothing page / tab swipe settle.
  swipe,

  /// Deprecated no-op — scroll sound removed; kept for API stability.
  scroll,
}
