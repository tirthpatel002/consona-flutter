/// Consona Feedback Config — Global sensory feedback switches and volume
library;

import 'feedback_profile.dart';

class FeedbackConfig {
  const FeedbackConfig({
    this.enabled = true,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.volume = 0.8,
    this.profile = FeedbackProfile.tactile,
  });

  final bool enabled;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final double volume;
  final FeedbackProfile profile;

  FeedbackConfig copyWith({
    bool? enabled,
    bool? hapticsEnabled,
    bool? soundEnabled,
    double? volume,
    FeedbackProfile? profile,
  }) {
    return FeedbackConfig(
      enabled: enabled ?? this.enabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      volume: volume ?? this.volume,
      profile: profile ?? this.profile,
    );
  }
}
