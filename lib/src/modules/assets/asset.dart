/// Consona Asset — Sealed hierarchy for bundled, network, and synthesized assets
library;

import 'asset_kind.dart';
import 'synth/sound_recipe.dart';

abstract class ConsonaSynthRecipe {
  const ConsonaSynthRecipe();
}

sealed class ConsonaAsset {
  const ConsonaAsset({required this.kind});

  final ConsonaAssetKind kind;

  const factory ConsonaAsset.bundled(
    String path, {
    String? package,
    ConsonaAssetKind kind,
  }) = BundledAsset;

  const factory ConsonaAsset.network(
    String url, {
    Duration? maxAge,
    ConsonaAssetKind kind,
  }) = NetworkAsset;

  const factory ConsonaAsset.synth(
    SoundRecipe recipe, {
    ConsonaAssetKind kind,
  }) = SynthAsset;
}

class BundledAsset extends ConsonaAsset {
  const BundledAsset(
    this.path, {
    this.package,
    super.kind = ConsonaAssetKind.sound,
  });

  final String path;
  final String? package;
}

class NetworkAsset extends ConsonaAsset {
  const NetworkAsset(
    this.url, {
    this.maxAge,
    super.kind = ConsonaAssetKind.sound,
  });

  final String url;
  final Duration? maxAge;
}

class SynthAsset extends ConsonaAsset {
  const SynthAsset(
    this.recipe, {
    super.kind = ConsonaAssetKind.sound,
  });

  final SoundRecipe recipe;
}
