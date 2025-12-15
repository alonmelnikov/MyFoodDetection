import '../core/result.dart';
import '../enums/network_errors.dart';
import '../domain/models/food_detail.dart';
import '../services/food_data_service.dart';

/// Use case for loading food detail by FDC ID
abstract class LoadFoodDetailUseCase {
  Future<FoodDetail> execute(int fdcId);
}

class LoadFoodDetailUseCaseImpl implements LoadFoodDetailUseCase {
  LoadFoodDetailUseCaseImpl({
    required FoodDataService foodDataService,
  }) : _foodDataService = foodDataService;

  final FoodDataService _foodDataService;

  @override
  Future<FoodDetail> execute(int fdcId) async {
    final Result<Map<String, dynamic>, NetworkError?> result =
        await _foodDataService.getFoodById(fdcId);

    if (!result.isSuccess || result.data == null) {
      throw Exception('Failed to load food details: ${result.error}');
    }

    final foodDetail = FoodDetail.fromJson(result.data!);

    return foodDetail;
  }
}

