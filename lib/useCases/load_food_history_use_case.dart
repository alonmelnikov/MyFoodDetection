import 'dart:io';

import '../models/food_item.dart';
import '../services/foodies_storage_service.dart';

/// Use case for loading food history
abstract class LoadFoodHistoryUseCase {
  Future<List<FoodItem>> execute();
}

class LoadFoodHistoryUseCaseImpl implements LoadFoodHistoryUseCase {
  LoadFoodHistoryUseCaseImpl({required FoodiesStorageService storageService})
    : _storageService = storageService;

  final FoodiesStorageService _storageService;

  @override
  Future<List<FoodItem>> execute() async {
    final items = await _storageService.loadFoodItems();

    // Verify image files exist and log paths
    for (final item in items) {
      final imageFile = File(item.imagePath);
      final exists = await imageFile.exists();
      print('[LoadFoodHistoryUseCase] 📸 Item: ${item.name}');
      print('[LoadFoodHistoryUseCase]    Path: ${item.imagePath}');
      print('[LoadFoodHistoryUseCase]    Exists: $exists');
      if (exists) {
        final size = await imageFile.length();
        print('[LoadFoodHistoryUseCase]    Size: $size bytes');
      }
    }

    return items;
  }
}
