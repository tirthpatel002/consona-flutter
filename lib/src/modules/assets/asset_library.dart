/// Consona Asset Library — Multi-source asset resolution with fallback chain
library;

import 'package:flutter/services.dart';
import 'asset.dart';
import 'cache/asset_cache.dart';

class ConsonaAssetLibrary {
  ConsonaAssetLibrary({
    Map<String, ConsonaAsset>? initialManifest,
    ConsonaAssetCache? cache,
    this.networkFetcher,
  })  : _manifest = Map.of(initialManifest ?? {}),
        _cache = cache ?? ConsonaAssetCache();

  final Map<String, ConsonaAsset> _manifest;
  final Map<String, ConsonaAsset> _fallbacks = {};
  final ConsonaAssetCache _cache;

  /// Optional HTTP/custom fetcher for [NetworkAsset] entries.
  final Future<Uint8List?> Function(String url)? networkFetcher;

  /// Registers or overrides an asset entry in the library manifest.
  /// If a [SynthAsset] was previously registered for [key], it is preserved
  /// as a fallback in case a bundled or network override fails to load.
  void register(String key, ConsonaAsset asset) {
    final previous = _manifest[key];
    if (previous is SynthAsset && asset is! SynthAsset) {
      _fallbacks[key] = previous;
    }
    _manifest[key] = asset;
  }

  /// Registers a fallback asset (such as a default [SynthAsset]) used when
  /// the primary asset in the manifest fails to load.
  void registerFallback(String key, ConsonaAsset fallback) {
    _fallbacks[key] = fallback;
    _manifest.putIfAbsent(key, () => fallback);
  }

  /// Bulk contributes asset entries.
  void contribute(Map<String, ConsonaAsset> entries) {
    for (final entry in entries.entries) {
      register(entry.key, entry.value);
    }
  }

  Future<Uint8List?> _resolveAsset(ConsonaAsset asset) async {
    switch (asset) {
      case SynthAsset(:final recipe):
        return recipe.toWav();
      case BundledAsset(:final path, :final package):
        try {
          final assetKey = package != null ? 'packages/$package/$path' : path;
          final byteData = await rootBundle.load(assetKey);
          return byteData.buffer.asUint8List();
        } catch (_) {
          return null;
        }
      case NetworkAsset(:final url):
        if (networkFetcher != null) {
          try {
            return await networkFetcher!(url);
          } catch (_) {
            return null;
          }
        }
        return null;
    }
  }

  /// Resolves an asset's raw bytes following the fallback chain:
  /// `cache -> network / bundled -> synth fallback -> null (silent)`
  Future<Uint8List?> loadBytes(String key) async {
    if (_cache.contains(key)) {
      return _cache.get(key);
    }

    final asset = _manifest[key];
    if (asset == null) return null;

    Uint8List? bytes = await _resolveAsset(asset);
    if (bytes == null) {
      final fallback = _fallbacks[key];
      if (fallback != null && !identical(fallback, asset)) {
        bytes = await _resolveAsset(fallback);
      }
    }

    if (bytes != null) {
      _cache.put(key, bytes);
    }

    return bytes;
  }

  bool has(String key) => _manifest.containsKey(key);

  void clearCache() => _cache.clear();
}
