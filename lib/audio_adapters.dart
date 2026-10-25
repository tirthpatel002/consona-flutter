/// Native audio backends for consona_flutter (`audioplayers` + `record`).
///
/// Import this barrel only when you need real playback / mic capture.
/// Core engines default to silent mocks without these adapters.
library consona_audio_adapters;

export 'src/modules/audio/adapters/audioplayers_audio_backend.dart';
export 'src/modules/audio/adapters/audioplayers_sound_player.dart';
export 'src/modules/audio/adapters/record_audio_recorder_backend.dart';
export 'src/modules/audio/adapters/recorder_backend_factory.dart';
