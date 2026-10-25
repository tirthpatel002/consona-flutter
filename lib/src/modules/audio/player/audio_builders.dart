/// Shared builder typedefs for audio player / recorder surfaces.
library;

import 'package:flutter/widgets.dart';

import '../engine/audio_engine.dart';

typedef ConsonaAudioArtworkBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  ImageProvider? artwork,
);

typedef ConsonaAudioTitleBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  String title,
  String? artist,
);

typedef ConsonaAudioControlsBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  VoidCallback onPlayPause,
);

typedef ConsonaAudioTimelineBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
);

typedef ConsonaAudioErrorBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  String message,
);

typedef ConsonaAudioPillArtworkBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  ImageProvider? artwork,
);

typedef ConsonaAudioPillTitleBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  String title,
);

typedef ConsonaAudioPillControlsBuilder = Widget Function(
  BuildContext context,
  AudioPlaybackState state,
  VoidCallback onPlayPause,
);
