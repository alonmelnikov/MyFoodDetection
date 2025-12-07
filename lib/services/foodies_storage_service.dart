import 'dart:convert';

import 'storage_service.dart';

/// Service for caching food-related data
class FoodiesStorageService {
  FoodiesStorageService({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  /// Cache key prefixes
  static const String _foodSearchPrefix = 'food_search_';
  static const String _foodDetailPrefix = 'food_detail_';

  /// Cache expiration time (1 week )
  static const Duration _cacheExpiration = Duration(days: 7);

  /// Save food search results
  Future<void> saveFoodSearchResults(
    String query,
    Map<String, dynamic> data,
  ) async {
    print('[FoodiesStorage] 💾 Saving search results for: $query');

    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final key = _foodSearchPrefix + query.toLowerCase();
    await _storageService.save(key, jsonEncode(cacheData));

    print('[FoodiesStorage] ✅ Search results saved');
  }

  /// Get cached food search results
  Future<Map<String, dynamic>?> getFoodSearchResults(String query) async {
    print('[FoodiesStorage] 🔍 Looking for cached search results: $query');

    final key = _foodSearchPrefix + query.toLowerCase();
    final cachedString = await _storageService.read(key);

    if (cachedString == null) {
      print('[FoodiesStorage] ⚠️ No cached results found');
      return null;
    }

    try {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Check if cache is expired
      if (DateTime.now().difference(cachedTime) > _cacheExpiration) {
        print('[FoodiesStorage] ⏰ Cache expired, deleting...');
        await _storageService.delete(key);
        return null;
      }

      print('[FoodiesStorage] ✅ Returning cached results');
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      print('[FoodiesStorage] ❌ Failed to parse cached data: $e');
      await _storageService.delete(key);
      return null;
    }
  }

  /// Save food detail by FDC ID
  Future<void> saveFoodDetail(int fdcId, Map<String, dynamic> data) async {
    print('[FoodiesStorage] 💾 Saving food detail for FDC ID: $fdcId');

    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final key = _foodDetailPrefix + fdcId.toString();
    await _storageService.save(key, jsonEncode(cacheData));

    print('[FoodiesStorage] ✅ Food detail saved');
  }

  /// Get cached food detail by FDC ID
  Future<Map<String, dynamic>?> getFoodDetail(int fdcId) async {
    print('[FoodiesStorage] 🔍 Looking for cached food detail: $fdcId');

    final key = _foodDetailPrefix + fdcId.toString();
    final cachedString = await _storageService.read(key);

    if (cachedString == null) {
      print('[FoodiesStorage] ⚠️ No cached detail found');
      return null;
    }

    try {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Check if cache is expired
      if (DateTime.now().difference(cachedTime) > _cacheExpiration) {
        print('[FoodiesStorage] ⏰ Cache expired, deleting...');
        await _storageService.delete(key);
        return null;
      }

      print('[FoodiesStorage] ✅ Returning cached detail');
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      print('[FoodiesStorage] ❌ Failed to parse cached data: $e');
      await _storageService.delete(key);
      return null;
    }
  }

  /// Clear all cached food data
  Future<void> clearCache() async {
    print('[FoodiesStorage] 🗑️ Clearing all cache...');
    await _storageService.clear();
    print('[FoodiesStorage] ✅ Cache cleared');
  }

  /// Clean up expired cache entries
  /// Scans all cache files and removes expired ones
  Future<void> cleanupExpiredCache() async {
    print('[FoodiesStorage] 🧹 Starting cache cleanup...');

    try {
      final allKeys = await _storageService.listKeys();
      int deletedCount = 0;
      int checkedCount = 0;

      for (final key in allKeys) {
        // Only check keys that match our prefixes
        if (!key.startsWith(_foodSearchPrefix) &&
            !key.startsWith(_foodDetailPrefix)) {
          continue;
        }

        checkedCount++;
        final cachedString = await _storageService.read(key);

        if (cachedString == null) continue;

        try {
          final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
          final timestamp = cacheData['timestamp'] as int;
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

          // Check if cache is expired
          if (DateTime.now().difference(cachedTime) > _cacheExpiration) {
            await _storageService.delete(key);
            deletedCount++;
            print('[FoodiesStorage] 🗑️ Deleted expired cache: $key');
          }
        } catch (e) {
          // If parsing fails, delete corrupted cache
          await _storageService.delete(key);
          deletedCount++;
          print('[FoodiesStorage] 🗑️ Deleted corrupted cache: $key');
        }
      }

      print(
        '[FoodiesStorage] ✅ Cleanup complete: checked $checkedCount, deleted $deletedCount',
      );
    } catch (e) {
      print('[FoodiesStorage] ❌ Cleanup failed: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'status': 'active',
      'expiration_days': _cacheExpiration.inDays,
      'removal_policy': 'lazy_deletion',
      'note': 'Expired items are deleted when accessed. No automatic full scan.',
    };
  }
}
