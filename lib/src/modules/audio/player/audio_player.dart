/// Consona AudioPlayer — Composite audio player (card surface).
library;

import 'package:flutter/widgets.dart';

import '../engine/audio_engine.dart';
import 'audio_player_card.dart';

export 'audio_player_card.dart';
export 'audio_player_pill.dart';

enum ConsonaAudioPlayerStyle {
  timeline,
  waveform,
}

/// Minimalist composite audio player surface (delegates to [ConsonaAudioPlayerCard]).
class ConsonaAudioPlayer extends StatelessWidget {
  const ConsonaAudioPlayer({
    super.key,
    required this.engine,
    this.style = ConsonaAudioPlayerStyle.waveform,
    this.showPoster = false,
  });

  final AudioEngine engine;
  final ConsonaAudioPlayerStyle style;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    return ConsonaAudioPlayerCard(
      engine: engine,
      showPoster: showPoster,
      timeline: style == ConsonaAudioPlayerStyle.waveform
          ? ConsonaAudioPlayerTimeline.waveform
          : ConsonaAudioPlayerTimeline.slider,
    );
  }
}
