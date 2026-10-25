/// Consona Feedback Profiles — Sensory character profiles
library;

enum FeedbackProfile {
  /// Standard balanced tactile feel (light haptics, soft synth micro-clicks).
  tactile,

  /// Crisp, tactilely pronounced feel (medium haptics, sharp click cues).
  mechanical,

  /// Minimalist feel (selection haptic, whisper-quiet micro cues).
  subtle,

  /// Purely visual (zero sound, zero haptics).
  silent,
}
