/// Protocol (interface) for food data caching
abstract class FoodDataCacheService {
  Map<String, dynamic>? getSearchResults(String query);
  void setSearchResults(String query, Map<String, dynamic> data);

  Map<String, dynamic>? getFoodDetail(int fdcId);
  void setFoodDetail(int fdcId, Map<String, dynamic> data);

  void clear();
}

/// In-memory cache for USDA FoodData Central responses.
///
/// This cache is intentionally **memory-only** (cleared on app restart).
/// It supports:
/// - Search results cache by query
/// - Food detail cache by FDC ID
/// - Max-items eviction (oldest-first by insertion time)
class FoodDataMemoryCacheService implements FoodDataCacheService {
  FoodDataMemoryCacheService({int maxItems = 30, Duration? ttl})
    : _maxItems = maxItems,
      _ttl = ttl;

  final int _maxItems;
  final Duration? _ttl;

  final Map<String, _CacheEntry<Map<String, dynamic>>> _searchCache = {};
  final Map<int, _CacheEntry<Map<String, dynamic>>> _detailCache = {};

  @override
  Map<String, dynamic>? getSearchResults(String query) {
    final key = query.toLowerCase();
    final entry = _searchCache[key];
    if (entry == null) return null;
    if (_isExpired(entry)) {
      _searchCache.remove(key);
      return null;
    }
    return entry.data;
  }

  @override
  void setSearchResults(String query, Map<String, dynamic> data) {
    _searchCache[query.toLowerCase()] = _CacheEntry(data);
    _evictIfNeeded();
  }

  @override
  Map<String, dynamic>? getFoodDetail(int fdcId) {
    final entry = _detailCache[fdcId];
    if (entry == null) return null;
    if (_isExpired(entry)) {
      _detailCache.remove(fdcId);
      return null;
    }
    return entry.data;
  }

  @override
  void setFoodDetail(int fdcId, Map<String, dynamic> data) {
    _detailCache[fdcId] = _CacheEntry(data);
    _evictIfNeeded();
  }

  @override
  void clear() {
    _searchCache.clear();
    _detailCache.clear();
  }

  bool _isExpired(_CacheEntry entry) {
    final ttl = _ttl;
    if (ttl == null) return false;
    final age = DateTime.now().difference(entry.createdAt);
    return age > ttl;
  }

  void _evictIfNeeded() {
    if (_maxItems <= 0) return;
    final total = _searchCache.length + _detailCache.length;
    if (total <= _maxItems) return;

    final all = <_EvictionCandidate>[];
    _searchCache.forEach((key, entry) {
      all.add(_EvictionCandidate.search(key: key, createdAt: entry.createdAt));
    });
    _detailCache.forEach((fdcId, entry) {
      all.add(
        _EvictionCandidate.detail(fdcId: fdcId, createdAt: entry.createdAt),
      );
    });

    all.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first
    final toRemove = total - _maxItems;
    for (var i = 0; i < toRemove && i < all.length; i++) {
      final candidate = all[i];
      if (candidate.searchKey != null) {
        _searchCache.remove(candidate.searchKey);
      } else if (candidate.fdcId != null) {
        _detailCache.remove(candidate.fdcId);
      }
    }
  }
}

class _CacheEntry<T> {
  _CacheEntry(this.data) : createdAt = DateTime.now();
  final T data;
  final DateTime createdAt;
}

class _EvictionCandidate {
  _EvictionCandidate.search({required String key, required this.createdAt})
    : searchKey = key,
      fdcId = null;

  _EvictionCandidate.detail({required this.fdcId, required this.createdAt})
    : searchKey = null;

  final String? searchKey;
  final int? fdcId;
  final DateTime createdAt;
}
