import '../enums/network_errors.dart';
import '../domain/models/food_nutrients.dart';
import '../core/result.dart';
import 'api_service.dart';
import 'food_data_memory_cache_service.dart';
import 'secrets_service.dart';

/// Protocol (interface) for food data service.
abstract class FoodDataService {
  /// Search for foods by query string
  Future<Result<Map<String, dynamic>, NetworkError?>> searchFoods(String query);

  /// Get food details by FDC ID
  Future<Result<Map<String, dynamic>, NetworkError?>> getFoodById(int fdcId);

  /// Get food nutrients by food name
  Future<Result<FoodNutrients?, NetworkError?>> getFoodNutrientsByName(
    String foodName,
  );
}

/// Food data service that uses USDA FoodData Central API with caching
class UsdaFoodDataService implements FoodDataService {
  UsdaFoodDataService({
    required ApiService apiService,
    required SecretsService secretsService,
    required FoodDataCacheService cacheService,
  }) : _apiService = apiService,
       _secretsService = secretsService,
       _cacheService = cacheService;

  final ApiService _apiService;
  final SecretsService _secretsService;
  final FoodDataCacheService _cacheService;

  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Get the API key from secrets service
  String? get _apiKey => _secretsService.usdaApiKey;

  @override
  Future<Result<Map<String, dynamic>, NetworkError?>> searchFoods(
    String query,
  ) async {
    // Check cache first
    final cachedData = _cacheService.getSearchResults(query);
    if (cachedData != null) {
      return Result.success(cachedData);
    }

    if (_apiKey == null) {
      return Result.failure(NetworkError.unauthorized);
    }

    final uri = Uri.parse('$_baseUrl/foods/search').replace(
      queryParameters: {
        'api_key': _apiKey!,
        'query': query,
        'pageSize': '10',
        'dataType': 'Foundation,Survey (FNDDS)',
      },
    );

    final result = await _apiService.get(uri);

    if (!result.isSuccess) {
      return Result.failure(result.error);
    }

    // Cache the result
    _cacheService.setSearchResults(query, result.data!);

    return Result.success(result.data!);
  }

  @override
  Future<Result<Map<String, dynamic>, NetworkError?>> getFoodById(
    int fdcId,
  ) async {
    // Check cache first
    final cachedData = _cacheService.getFoodDetail(fdcId);
    if (cachedData != null) {
      return Result.success(cachedData);
    }

    if (_apiKey == null) {
      return Result.failure(NetworkError.unauthorized);
    }

    final uri = Uri.parse(
      '$_baseUrl/food/$fdcId',
    ).replace(queryParameters: {'api_key': _apiKey!});

    final result = await _apiService.get(uri);

    if (!result.isSuccess) {
      return Result.failure(result.error);
    }

    // Cache the result
    _cacheService.setFoodDetail(fdcId, result.data!);

    return Result.success(result.data!);
  }

  @override
  Future<Result<FoodNutrients?, NetworkError?>> getFoodNutrientsByName(
    String foodName,
  ) async {
    // First, search for the food
    final searchResult = await searchFoods(foodName);

    if (!searchResult.isSuccess || searchResult.data == null) {
      return Result.failure(searchResult.error);
    }

    final searchData = searchResult.data!;
    final foods = searchData['foods'] as List<dynamic>?;

    if (foods == null || foods.isEmpty) {
      return Result.success(null);
    }

    // Get the first food item
    final firstFood = foods.first as Map<String, dynamic>;
    final foodNutrients = firstFood['foodNutrients'] as List<dynamic>?;
    final fdcId = firstFood['fdcId'] as int?;

    if (foodNutrients == null || foodNutrients.isEmpty) {
      return Result.success(null);
    }

    final nutrients = FoodNutrients.fromJson(foodNutrients);

    // Add fdcId to nutrients
    final nutrientsWithId = FoodNutrients(
      calories: nutrients.calories,
      carbs: nutrients.carbs,
      protein: nutrients.protein,
      fat: nutrients.fat,
      fdcId: fdcId,
    );

    return Result.success(nutrientsWithId);
  }
}
