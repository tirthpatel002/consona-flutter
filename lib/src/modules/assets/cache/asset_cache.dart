/// Consona Asset Cache — In-memory byte buffer cache for rendered/fetched assets
library;

import 'dart:typed_data';

class ConsonaAssetCache {
  ConsonaAssetCache({this.maxEntries = 128});

  final int maxEntries;
  final Map<String, Uint8List> _cache = {};

  Uint8List? get(String key) => _cache[key];

  void put(String key, Uint8List bytes) {
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = bytes;
  }

  bool contains(String key) => _cache.containsKey(key);

  void clear() => _cache.clear();
}
