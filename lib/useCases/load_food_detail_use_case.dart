import '../core/result.dart';
import '../enums/network_errors.dart';
import '../models/food_detail.dart';
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
    print('[LoadFoodDetailUseCase] 🎯 execute called for FDC ID: $fdcId');

    final Result<Map<String, dynamic>, NetworkError?> result =
        await _foodDataService.getFoodById(fdcId);

    if (!result.isSuccess || result.data == null) {
      print('[LoadFoodDetailUseCase] ❌ Failed to load food detail');
      print('[LoadFoodDetailUseCase] ⚠️ Error: ${result.error}');
      throw Exception('Failed to load food details: ${result.error}');
    }

    print('[LoadFoodDetailUseCase] ✅ Food detail loaded successfully');

    final foodDetail = FoodDetail.fromJson(result.data!);

    print('[LoadFoodDetailUseCase] 📊 Food: ${foodDetail.description}');
    print(
      '[LoadFoodDetailUseCase] 📊 Nutrients count: ${foodDetail.nutrients.length}',
    );

    return foodDetail;
  }
}

