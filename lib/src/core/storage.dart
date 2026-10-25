/// Consona Storage Adapter — Abstract and implementations
library;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConsonaStorageAdapter {
  FutureOr<String?> getString(String key);
  FutureOr<void> setString(String key, String value);
  FutureOr<void> remove(String key);
  FutureOr<void> clear();

  FutureOr<String?> read(String key) => getString(key);
  FutureOr<void> write(String key, String value) => setString(key, value);

  static ConsonaStorageAdapter memory() => MemoryStorageAdapter();
  static ConsonaStorageAdapter sharedPrefs() => SharedPrefsStorageAdapter();
}

/// In-memory storage adapter for tests and ephemeral sessions.
class MemoryStorageAdapter extends ConsonaStorageAdapter {
  final Map<String, String> _store = {};

  @override
  String? getString(String key) => _store[key];

  @override
  void setString(String key, String value) {
    _store[key] = value;
  }

  @override
  void remove(String key) {
    _store.remove(key);
  }

  @override
  void clear() {
    _store.clear();
  }
}

/// SharedPreferences storage adapter for cross-session mobile persistence.
class SharedPrefsStorageAdapter extends ConsonaStorageAdapter {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}
