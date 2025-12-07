import 'dart:io';

import '../services/foodies_storage_service.dart';

/// Use case for clearing all food data
abstract class ClearAllUseCase {
  Future<void> execute();
}

class ClearAllUseCaseImpl implements ClearAllUseCase {
  ClearAllUseCaseImpl({required FoodiesStorageService storageService})
      : _storageService = storageService;

  final FoodiesStorageService _storageService;

  @override
  Future<void> execute() async {
    print('[ClearAllUseCase] 🗑️ Clearing all data...');

    // Load items first to get image paths
    final items = await _storageService.loadFoodItems();

    // Delete all image files
    for (final item in items) {
      try {
        final imageFile = File(item.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('[ClearAllUseCase] 🗑️ Deleted image: ${item.imagePath}');
        }
      } catch (e) {
        print(
          '[ClearAllUseCase] ⚠️ Failed to delete image ${item.imagePath}: $e',
        );
      }
    }

    // Clear storage
    await _storageService.clearAll();
    print('[ClearAllUseCase] ✅ All data cleared');
  }
}

