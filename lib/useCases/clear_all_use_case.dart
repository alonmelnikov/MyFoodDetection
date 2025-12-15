import 'dart:io';

import '../services/food_history_storage_service.dart';

/// Use case for clearing all food data
abstract class ClearAllUseCase {
  Future<void> execute();
}

class ClearAllUseCaseImpl implements ClearAllUseCase {
  ClearAllUseCaseImpl({required FoodHistoryStorageService historyStorageService})
      : _historyStorageService = historyStorageService;

  final FoodHistoryStorageService _historyStorageService;

  @override
  Future<void> execute() async {
    // Load items first to get image paths
    final items = await _historyStorageService.loadFoodItems();

    // Delete all image files
    for (final item in items) {
      try {
        final imageFile = File(item.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        // Silently handle delete errors
      }
    }

    // Clear storage
    await _historyStorageService.clearFoodItems();
  }
}

