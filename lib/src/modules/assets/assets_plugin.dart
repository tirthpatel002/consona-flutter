/// Consona Assets Plugin — First-party plugin registering ConsonaAssetLibrary
library;

import '../../core/plugin.dart';
import '../../core/registry.dart';
import 'asset.dart';
import 'asset_library.dart';

class ConsonaAssetsPlugin extends ConsonaPlugin {
  ConsonaAssetsPlugin({this.initialAssets = const {}});

  final Map<String, ConsonaAsset> initialAssets;

  @override
  String get id => 'consona.assets';

  @override
  Set<String> get dependsOn => const {};

  @override
  void onAttach(ConsonaRegistry registry) {
    final library = ConsonaAssetLibrary(initialManifest: initialAssets);
    registry.registerEngine<ConsonaAssetLibrary>(library, replace: true);
  }

  @override
  void onDetach() {}
}
