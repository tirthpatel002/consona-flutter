/// Consona OverlayPlugin — registers [OverlayEngine] for app-level queues.
library;

import '../../core/plugin.dart';
import '../../core/registry.dart';
import 'engine/overlay_engine.dart';

class ConsonaOverlayPlugin extends ConsonaPlugin {
  ConsonaOverlayPlugin({OverlayEngine? engine}) : _engine = engine;

  final OverlayEngine? _engine;
  OverlayEngine? _owned;

  @override
  String get id => 'consona.overlay';

  @override
  Set<String> get dependsOn => const {};

  @override
  void onAttach(ConsonaRegistry registry) {
    final engine = _engine ?? (_owned = OverlayEngine());
    registry.registerEngine<OverlayEngine>(engine);
  }

  @override
  void onDetach() {
    _owned?.dispose();
    _owned = null;
  }
}
