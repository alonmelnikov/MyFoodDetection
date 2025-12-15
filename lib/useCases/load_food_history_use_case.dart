import '../domain/models/food_item.dart';
import '../services/food_history_storage_service.dart';

/// Use case for loading food history
abstract class LoadFoodHistoryUseCase {
  Future<List<FoodItem>> execute();
}

class LoadFoodHistoryUseCaseImpl implements LoadFoodHistoryUseCase {
  LoadFoodHistoryUseCaseImpl({
    required FoodHistoryStorageService historyStorageService,
  }) : _historyStorageService = historyStorageService;

  final FoodHistoryStorageService _historyStorageService;

  @override
  Future<List<FoodItem>> execute() async {
    final items = await _historyStorageService.loadFoodItems();
    return items;
  }
}
