/// Consona Feedback Plugin — First-party plugin registering FeedbackEngine
library;

import 'dart:async';
import '../../core/plugin.dart';
import '../../core/registry.dart';
import '../assets/asset_library.dart';
import 'engine/feedback_engine.dart';
import 'engine/haptic_engine.dart';
import 'engine/sound_engine.dart';
import 'models/feedback_config.dart';
import 'player/sound_player.dart';
import 'sound_library/sound_library.dart';

class ConsonaFeedbackPlugin extends ConsonaPlugin {
  ConsonaFeedbackPlugin({
    this.config = const FeedbackConfig(),
    this.player,
  });

  final FeedbackConfig config;
  final SoundPlayer? player;
  SoundEngine? _soundEngine;

  @override
  String get id => 'consona.feedback';

  @override
  Set<String> get dependsOn => const {'consona.assets'};

  @override
  void onAttach(ConsonaRegistry registry) {
    final assets = registry.requireEngine<ConsonaAssetLibrary>();
    final soundLibrary = SoundLibrary(assets);
    final effectivePlayer = player ?? const SystemSoundPlayer();

    final soundEngine = SoundEngine(
      library: soundLibrary,
      player: effectivePlayer,
      enabled: config.soundEnabled,
      volume: config.volume,
    );
    _soundEngine = soundEngine;

    final feedbackEngine = FeedbackEngine(
      config: config,
      hapticEngine: HapticEngine(enabled: config.hapticsEnabled),
      soundEngine: soundEngine,
    );

    registry.registerEngine<FeedbackEngine>(feedbackEngine, replace: true);

    // Prewarm default synth cues in memory asynchronously
    unawaited(soundEngine.prewarm());
  }

  @override
  void onDetach() {
    _soundEngine?.dispose();
    _soundEngine = null;
  }
}
