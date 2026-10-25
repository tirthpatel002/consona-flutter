/// Consona Sound Player — Low-latency audio player abstraction
library;

import 'package:flutter/services.dart';

abstract class SoundPlayer {
  Future<void> playBytes(Uint8List bytes, {double volume = 1.0});
  void stop() {}
  void dispose() {}
}

/// Fallback no-op player that operates silently without errors or latency.
class NoopSoundPlayer implements SoundPlayer {
  const NoopSoundPlayer();

  @override
  Future<void> playBytes(Uint8List bytes, {double volume = 1.0}) async {}

  @override
  void stop() {}

  @override
  void dispose() {}
}

/// Fallback system click player using platform standard [SystemSound].
class SystemSoundPlayer implements SoundPlayer {
  const SystemSoundPlayer();

  @override
  Future<void> playBytes(Uint8List bytes, {double volume = 1.0}) async {
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  void stop() {}

  @override
  void dispose() {}
}
