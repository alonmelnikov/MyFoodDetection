import '../enums/network_errors.dart';
import '../models/food_detail.dart';
import '../models/result.dart';
import '../services/food_data_service.dart';

/// Interface for the food detail data model.
abstract class FoodDetailDataModelInterface {
  Future<FoodDetail> loadFoodDetail(int fdcId);
}

class FoodDetailDataModelImpl implements FoodDetailDataModelInterface {
  FoodDetailDataModelImpl({required FoodDataService foodDataService})
      : _foodDataService = foodDataService;

  final FoodDataService _foodDataService;

  @override
  Future<FoodDetail> loadFoodDetail(int fdcId) async {
    print('[FoodDetailDataModel] 🎯 loadFoodDetail called for FDC ID: $fdcId');

    final Result<Map<String, dynamic>, NetworkError?> result =
        await _foodDataService.getFoodById(fdcId);

    if (!result.isSuccess || result.data == null) {
      print('[FoodDetailDataModel] ❌ Failed to load food detail');
      print('[FoodDetailDataModel] ⚠️ Error: ${result.error}');
      throw Exception('Failed to load food details: ${result.error}');
    }

    print('[FoodDetailDataModel] ✅ Food detail loaded successfully');
    
    final foodDetail = FoodDetail.fromJson(result.data!);
    
    print('[FoodDetailDataModel] 📊 Food: ${foodDetail.description}');
    print('[FoodDetailDataModel] 📊 Nutrients count: ${foodDetail.nutrients.length}');

    return foodDetail;
  }
}

