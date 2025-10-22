// lib/services/storage_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureKeyPrefix = 'secure_';
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> writeSecure(String key, String value) async {
    await _secure.write(key: '$_secureKeyPrefix$key', value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secure.read(key: '$_secureKeyPrefix$key');
  }

  Future<void> deleteSecure(String key) async {
    await _secure.delete(key: '$_secureKeyPrefix$key');
  }

  Future<void> deleteAllSecure() async {
    await _secure.deleteAll();
  }

  Future<void> migrateFromPrefsIfNeeded(List<String> keysToMigrate) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keysToMigrate) {
      final current = prefs.getString(key);
      final secureVal = await readSecure(key);
      if (current != null && (secureVal == null || secureVal.isEmpty)) {
        try {
          await writeSecure(key, current);
          await prefs.remove(key);
          if (kDebugMode) debugPrint('[StorageService] Migrated $key -> secure storage');
        } catch (e) {
          if (kDebugMode) debugPrint('[StorageService] Migrate error for $key: $e');
        }
      }
    }
  }

  Future<String?> readSecureOrPrefs(String key) async {
    final s = await readSecure(key);
    if (s != null) return s;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
