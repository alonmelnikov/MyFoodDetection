import '../domain/models/food_item.dart';
import 'storage_service.dart';

/// Disk-backed persistence for the user's FoodItem history.
///
/// This service is intentionally **only** responsible for saving/loading
/// FoodItem history (not caching API responses).
class FoodHistoryStorageService {
  FoodHistoryStorageService({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  static const String _foodItemsKey = 'food_items';

  Future<void> saveFoodItems(List<FoodItem> items) async {
    final jsonString = FoodItem.encodeList(items);
    await _storageService.save(_foodItemsKey, jsonString);
  }

  Future<List<FoodItem>> loadFoodItems() async {
    final jsonString = await _storageService.read(_foodItemsKey);
    if (jsonString == null) return [];
    return FoodItem.decodeList(jsonString);
  }

  Future<void> clearFoodItems() async {
    await _storageService.delete(_foodItemsKey);
  }

  /// Removes legacy disk cache files from the older architecture:
  /// - food_search_*
  /// - food_detail_*
  Future<void> cleanupLegacyApiCacheFiles() async {
    try {
      final keys = await _storageService.listKeys();
      for (final key in keys) {
        if (key.startsWith('food_search_') || key.startsWith('food_detail_')) {
          await _storageService.delete(key);
        }
      }
    } catch (e) {
      // Silently ignore cleanup issues.
    }
  }
}


