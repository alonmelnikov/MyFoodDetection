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

  /// Cache expiration time (1 week)
  static const Duration _cacheExpiration = Duration(days: 7);

  /// Maximum number of cache items (memory limit)
  static const int _maxCacheItems = 30;

  /// Save food search results
  Future<void> saveFoodSearchResults(
    String query,
    Map<String, dynamic> data,
  ) async {
    print('[FoodiesStorage] 💾 Saving search results for: $query');
    final key = _foodSearchPrefix + query.toLowerCase();
    await _saveCacheData(key, data);
    print('[FoodiesStorage] ✅ Search results saved');
  }

  /// Get cached food search results
  Future<Map<String, dynamic>?> getFoodSearchResults(String query) async {
    print('[FoodiesStorage] 🔍 Looking for cached search results: $query');
    final key = _foodSearchPrefix + query.toLowerCase();
    return await _readAndValidateCache(key);
  }

  /// Save food detail by FDC ID
  Future<void> saveFoodDetail(int fdcId, Map<String, dynamic> data) async {
    print('[FoodiesStorage] 💾 Saving food detail for FDC ID: $fdcId');
    final key = _foodDetailPrefix + fdcId.toString();
    await _saveCacheData(key, data);
    print('[FoodiesStorage] ✅ Food detail saved');
  }

  /// Get cached food detail by FDC ID
  Future<Map<String, dynamic>?> getFoodDetail(int fdcId) async {
    print('[FoodiesStorage] 🔍 Looking for cached food detail: $fdcId');
    final key = _foodDetailPrefix + fdcId.toString();
    return await _readAndValidateCache(key);
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
      final cacheKeys = await _getCacheKeys();
      int deletedCount = 0;
      int checkedCount = 0;

      for (final key in cacheKeys) {
        checkedCount++;
        final result = await _validateCacheEntry(key);

        if (result == null) continue;

        if (result.isExpired || result.isCorrupted) {
          await _storageService.delete(key);
          deletedCount++;
          print(
            '[FoodiesStorage] 🗑️ Deleted ${result.isExpired ? "expired" : "corrupted"} cache: $key',
          );
        }
      }

      print(
        '[FoodiesStorage] ✅ Cleanup complete: checked $checkedCount, deleted $deletedCount',
      );
    } catch (e) {
      print('[FoodiesStorage] ❌ Cleanup failed: $e');
    }
  }

  /// Evict oldest cache entries if we've reached the limit
  Future<void> _evictIfNeeded() async {
    try {
      final cacheKeys = await _getCacheKeys();
      final currentCount = cacheKeys.length;

      if (currentCount < _maxCacheItems) {
        print(
          '[FoodiesStorage] 📊 Cache count: $currentCount/$_maxCacheItems (no eviction needed)',
        );
        return;
      }

      print(
        '[FoodiesStorage] ⚠️ Cache limit reached: $currentCount/$_maxCacheItems, evicting oldest...',
      );

      final cacheEntries = await _loadCacheEntries(cacheKeys);
      final sortedEntries = _sortByTimestamp(cacheEntries);
      final itemsToDelete = currentCount - _maxCacheItems + 1;

      await _deleteOldestEntries(sortedEntries, itemsToDelete);

      print(
        '[FoodiesStorage] ✅ Eviction complete: deleted $itemsToDelete items',
      );
    } catch (e) {
      print('[FoodiesStorage] ❌ Eviction failed: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheKeys = await _getCacheKeys();

      return {
        'status': 'active',
        'expiration_days': _cacheExpiration.inDays,
        'max_items': _maxCacheItems,
        'current_items': cacheKeys.length,
        'removal_policy': 'lazy_deletion + oldest_first_eviction',
        'note':
            'Expired items deleted on access. Oldest items evicted when limit reached.',
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  // ==================== Private Helper Methods ====================

  /// Get all cache keys that match our prefixes
  Future<List<String>> _getCacheKeys() async {
    final allKeys = await _storageService.listKeys();
    return allKeys
        .where(
          (key) =>
              key.startsWith(_foodSearchPrefix) ||
              key.startsWith(_foodDetailPrefix),
        )
        .toList();
  }

  /// Build cache data structure with timestamp
  Map<String, dynamic> _buildCacheData(Map<String, dynamic> data) {
    return {'data': data, 'timestamp': DateTime.now().millisecondsSinceEpoch};
  }

  /// Save cache data with eviction check
  Future<void> _saveCacheData(String key, Map<String, dynamic> data) async {
    await _evictIfNeeded();
    final cacheData = _buildCacheData(data);
    await _storageService.save(key, jsonEncode(cacheData));
  }

  /// Read and validate cache entry
  Future<Map<String, dynamic>?> _readAndValidateCache(String key) async {
    final cachedString = await _storageService.read(key);

    if (cachedString == null) {
      print('[FoodiesStorage] ⚠️ No cached data found');
      return null;
    }

    final result = await _validateCacheEntry(key, cachedString);

    if (result == null) {
      return null;
    }

    if (result.isExpired) {
      print('[FoodiesStorage] ⏰ Cache expired, deleting...');
      await _storageService.delete(key);
      return null;
    }

    if (result.isCorrupted) {
      print('[FoodiesStorage] ❌ Failed to parse cached data');
      await _storageService.delete(key);
      return null;
    }

    print('[FoodiesStorage] ✅ Returning cached data');
    return result.data;
  }

  /// Validate a cache entry
  Future<_CacheValidationResult?> _validateCacheEntry(
    String key, [
    String? cachedString,
  ]) async {
    final data = cachedString ?? await _storageService.read(key);
    if (data == null) return null;

    try {
      final cacheData = jsonDecode(data) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final cacheContent = cacheData['data'] as Map<String, dynamic>?;

      if (cacheContent == null) {
        return _CacheValidationResult(
          isCorrupted: true,
          isExpired: false,
          data: null,
        );
      }

      final isExpired = _isExpired(cachedTime);

      return _CacheValidationResult(
        isCorrupted: false,
        isExpired: isExpired,
        data: cacheContent,
      );
    } catch (e) {
      return _CacheValidationResult(
        isCorrupted: true,
        isExpired: false,
        data: null,
      );
    }
  }

  /// Check if cache entry is expired
  bool _isExpired(DateTime cachedTime) {
    return DateTime.now().difference(cachedTime) > _cacheExpiration;
  }

  /// Load cache entries with timestamps
  Future<List<_CacheEntry>> _loadCacheEntries(List<String> keys) async {
    final cacheEntries = <_CacheEntry>[];

    for (final key in keys) {
      final cachedString = await _storageService.read(key);
      if (cachedString == null) continue;

      try {
        final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
        final timestamp = cacheData['timestamp'] as int;
        cacheEntries.add(_CacheEntry(key: key, timestamp: timestamp));
      } catch (e) {
        // Corrupted cache, delete it
        await _storageService.delete(key);
      }
    }

    return cacheEntries;
  }

  /// Sort cache entries by timestamp (oldest first)
  List<_CacheEntry> _sortByTimestamp(List<_CacheEntry> entries) {
    final sorted = List<_CacheEntry>.from(entries);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  /// Delete oldest cache entries
  Future<void> _deleteOldestEntries(
    List<_CacheEntry> sortedEntries,
    int count,
  ) async {
    for (var i = 0; i < count && i < sortedEntries.length; i++) {
      await _storageService.delete(sortedEntries[i].key);
      print(
        '[FoodiesStorage] 🗑️ Evicted oldest cache: ${sortedEntries[i].key}',
      );
    }
  }
}

/// Internal class to track cache entries for eviction
class _CacheEntry {
  final String key;
  final int timestamp;

  _CacheEntry({required this.key, required this.timestamp});
}

/// Result of cache validation
class _CacheValidationResult {
  final bool isCorrupted;
  final bool isExpired;
  final Map<String, dynamic>? data;

  _CacheValidationResult({
    required this.isCorrupted,
    required this.isExpired,
    required this.data,
  });
}
