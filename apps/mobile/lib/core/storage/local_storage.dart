import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider for local storage service
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Service for storing non-sensitive data locally using Hive
class LocalStorageService {
  // Box names
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';
  static const String _tournamentsBox = 'tournaments';
  static const String _playersBox = 'players';

  /// Initialize Hive boxes
  Future<void> init() async {
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_tournamentsBox);
    await Hive.openBox(_playersBox);
  }

  /// Get the settings box
  Box get settingsBox => Hive.box(_settingsBox);

  /// Get the cache box
  Box get cacheBox => Hive.box(_cacheBox);

  /// Get the tournaments box
  Box get tournamentsBox => Hive.box(_tournamentsBox);

  /// Get the players box
  Box get playersBox => Hive.box(_playersBox);

  // Settings operations

  /// Get a setting value
  T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Set a setting value
  Future<void> setSetting<T>(String key, T value) async {
    await settingsBox.put(key, value);
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }

  // Cache operations with expiration

  /// Get cached data if not expired
  T? getCached<T>(String key, {Duration? maxAge}) {
    final data = cacheBox.get(key);
    if (data == null) return null;

    if (data is Map && data.containsKey('timestamp') && maxAge != null) {
      final timestamp = DateTime.parse(data['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > maxAge) {
        // Cache expired
        cacheBox.delete(key);
        return null;
      }
      return data['value'] as T?;
    }

    return data as T?;
  }

  /// Set cached data with timestamp
  Future<void> setCached<T>(String key, T value) async {
    await cacheBox.put(key, {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Delete cached data
  Future<void> deleteCached(String key) async {
    await cacheBox.delete(key);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await cacheBox.clear();
  }

  // Generic box operations

  /// Get data from a specific box
  T? get<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key) as T?;
  }

  /// Put data into a specific box
  Future<void> put<T>(String boxName, String key, T value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  /// Delete data from a specific box
  Future<void> delete(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  /// Clear a specific box
  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  /// Clear all data
  Future<void> clearAll() async {
    await settingsBox.clear();
    await cacheBox.clear();
    await tournamentsBox.clear();
    await playersBox.clear();
  }
}
