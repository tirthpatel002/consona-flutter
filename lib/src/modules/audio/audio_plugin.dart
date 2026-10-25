/// Consona AudioPlugin — Optional plugin hook for audio module presence.
library;

import '../../core/plugin.dart';
import '../../core/registry.dart';

/// Marks the audio module as available.
///
/// Does not register a shared [AudioEngine]. Create one engine (and one
/// backend) per player surface — a registry singleton would couple every UI
/// to a single transport runtime.
class ConsonaAudioPlugin implements ConsonaPlugin {
  const ConsonaAudioPlugin();

  @override
  final String id = 'consona.audio';

  @override
  final Set<String> dependsOn = const {};

  @override
  void onAttach(ConsonaRegistry registry) {
    // Intentionally no registerEngine — shared engines sync UIs.
  }

  @override
  void onDetach() {}
}
