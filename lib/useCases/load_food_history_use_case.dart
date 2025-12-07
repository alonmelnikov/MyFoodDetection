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
    return await _storageService.loadFoodItems();
  }
}
