/// Consona Sound Library — Bridge between feedback cue keys and ConsonaAssetLibrary
library;

import 'dart:typed_data';
import '../../assets/asset.dart';
import '../../assets/asset_library.dart';
import '../models/feedback_profile.dart';
import 'default_cues.dart';

class SoundLibrary {
  SoundLibrary(this._assets) {
    // Populate default synth cues (and per-profile variants) into the asset
    // library as fallbacks so apps can override any key with BundledAsset or
    // NetworkAsset while retaining synth fallback if loading fails.
    for (final entry in DefaultSoundCues.allWithVariants.entries) {
      _assets.registerFallback(entry.key, ConsonaAsset.synth(entry.value));
    }
  }

  final ConsonaAssetLibrary _assets;

  Future<Uint8List?> loadCueBytes(String cueName) => _assets.loadBytes(cueName);

  bool hasCue(String cueName) => _assets.has(cueName);

  /// Resolves the key to play for [cueName] under [profile], falling back to
  /// the base cue when the app registered no profile-specific variant.
  String resolveKey(String cueName, FeedbackProfile profile) {
    final variant = DefaultSoundCues.variantKey(cueName, profile);
    return _assets.has(variant) ? variant : cueName;
  }
}
