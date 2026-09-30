import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Strings ──

  Future<bool> saveString(String key, String value) {
    return _instance.setString(key, value);
  }

  String? getString(String key) {
    return _instance.getString(key);
  }

  // ── Ints ──

  Future<bool> saveInt(String key, int value) {
    return _instance.setInt(key, value);
  }

  int? getInt(String key) {
    return _instance.getInt(key);
  }

  // ── Bools ──

  Future<bool> saveBool(String key, bool value) {
    return _instance.setBool(key, value);
  }

  bool? getBool(String key) {
    return _instance.getBool(key);
  }

  // ── Doubles ──

  Future<bool> saveDouble(String key, double value) {
    return _instance.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _instance.getDouble(key);
  }

  // ── JSON Objects ──

  Future<bool> saveJson(String key, Map<String, dynamic> value) {
    return _instance.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = _instance.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveJsonList(String key, List<dynamic> value) {
    return _instance.setString(key, jsonEncode(value));
  }

  List<dynamic>? getJsonList(String key) {
    final raw = _instance.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Cache with expiry ──

  Future<void> saveWithExpiry(
    String key,
    String value,
    Duration expiry,
  ) async {
    final cacheData = {
      'value': value,
      'expiresAt': DateTime.now().add(expiry).toIso8601String(),
    };
    await _instance.setString(key, jsonEncode(cacheData));
  }

  String? getWithExpiry(String key) {
    final raw = _instance.getString(key);
    if (raw == null) return null;

    try {
      final cacheData = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        _instance.remove(key);
        return null;
      }

      return cacheData['value'] as String;
    } catch (_) {
      _instance.remove(key);
      return null;
    }
  }

  Future<void> saveJsonWithExpiry(
    String key,
    Map<String, dynamic> value,
    Duration expiry,
  ) async {
    final cacheData = {
      'value': value,
      'expiresAt': DateTime.now().add(expiry).toIso8601String(),
    };
    await _instance.setString(key, jsonEncode(cacheData));
  }

  Map<String, dynamic>? getJsonWithExpiry(String key) {
    final raw = _instance.getString(key);
    if (raw == null) return null;

    try {
      final cacheData = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cacheData['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        _instance.remove(key);
        return null;
      }

      return cacheData['value'] as Map<String, dynamic>;
    } catch (_) {
      _instance.remove(key);
      return null;
    }
  }

  bool hasCache(String key) {
    return _instance.containsKey(key);
  }

  Future<void> remove(String key) async {
    await _instance.remove(key);
  }

  Future<void> clearAll() async {
    await _instance.clear();
  }

  Future<void> clearCache() async {
    final keys = _instance.getKeys();
    for (final key in keys) {
      final raw = _instance.getString(key);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          if (data.containsKey('expiresAt')) {
            await _instance.remove(key);
          }
        } catch (_) {}
      }
    }
  }

  bool has(String key) {
    return _instance.containsKey(key);
  }

  List<String> getKeys() {
    return _instance.getKeys().toList();
  }
}
