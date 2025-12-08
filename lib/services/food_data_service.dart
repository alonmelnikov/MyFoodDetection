import '../enums/network_errors.dart';
import '../models/food_nutrients.dart';
import '../core/result.dart';
import 'api_service.dart';
import 'foodies_storage_service.dart';
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
    required FoodiesStorageService storageService,
  }) : _apiService = apiService,
       _secretsService = secretsService,
       _storageService = storageService;

  final ApiService _apiService;
  final SecretsService _secretsService;
  final FoodiesStorageService _storageService;

  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  /// Get the API key from secrets service
  String? get _apiKey => _secretsService.usdaApiKey;

  @override
  Future<Result<Map<String, dynamic>, NetworkError?>> searchFoods(
    String query,
  ) async {
    print('[FoodDataService] 🔍 Searching for foods: $query');

    // Check cache first
    final cachedData = await _storageService.getFoodSearchResults(query);
    if (cachedData != null) {
      print('[FoodDataService] ✅ Returning cached search results');
      return Result.success(cachedData);
    }

    if (_apiKey == null) {
      print('[FoodDataService] ❌ API key not found');
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

    print('[FoodDataService] 🌐 Calling API: ${uri.toString()}');

    final result = await _apiService.get(uri);

    if (!result.isSuccess) {
      print('[FoodDataService] ❌ Search failed: ${result.error}');
      return Result.failure(result.error);
    }

    print('[FoodDataService] ✅ Search successful');
    print('[FoodDataService] 📄 JSON Response:');
    print('[FoodDataService] ${result.data}');

    // Cache the result
    await _storageService.saveFoodSearchResults(query, result.data!);

    return Result.success(result.data!);
  }

  @override
  Future<Result<Map<String, dynamic>, NetworkError?>> getFoodById(
    int fdcId,
  ) async {
    print('[FoodDataService] 📋 Getting food details for FDC ID: $fdcId');

    // Check cache first
    final cachedData = await _storageService.getFoodDetail(fdcId);
    if (cachedData != null) {
      print('[FoodDataService] ✅ Returning cached food detail');
      return Result.success(cachedData);
    }

    if (_apiKey == null) {
      print('[FoodDataService] ❌ API key not found');
      return Result.failure(NetworkError.unauthorized);
    }

    final uri = Uri.parse(
      '$_baseUrl/food/$fdcId',
    ).replace(queryParameters: {'api_key': _apiKey!});

    print('[FoodDataService] 🌐 Calling API: ${uri.toString()}');

    final result = await _apiService.get(uri);

    if (!result.isSuccess) {
      print('[FoodDataService] ❌ Get food failed: ${result.error}');
      return Result.failure(result.error);
    }

    print('[FoodDataService] ✅ Get food successful');
    print('[FoodDataService] 📄 JSON Response:');
    print('[FoodDataService] ${result.data}');

    // Cache the result
    await _storageService.saveFoodDetail(fdcId, result.data!);

    return Result.success(result.data!);
  }

  @override
  Future<Result<FoodNutrients?, NetworkError?>> getFoodNutrientsByName(
    String foodName,
  ) async {
    print('[FoodDataService] 🍎 Getting nutrients for: $foodName');

    // First, search for the food
    final searchResult = await searchFoods(foodName);

    if (!searchResult.isSuccess || searchResult.data == null) {
      print('[FoodDataService] ❌ Search failed for: $foodName');
      return Result.failure(searchResult.error);
    }

    final searchData = searchResult.data!;
    final foods = searchData['foods'] as List<dynamic>?;

    if (foods == null || foods.isEmpty) {
      print('[FoodDataService] ⚠️ No foods found for: $foodName');
      return Result.success(null);
    }

    // Get the first food item
    final firstFood = foods.first as Map<String, dynamic>;
    final foodNutrients = firstFood['foodNutrients'] as List<dynamic>?;
    final fdcId = firstFood['fdcId'] as int?;

    if (foodNutrients == null || foodNutrients.isEmpty) {
      print('[FoodDataService] ⚠️ No nutrients found for: $foodName');
      return Result.success(null);
    }

    print('[FoodDataService] 📊 Parsing ${foodNutrients.length} nutrients');

    final nutrients = FoodNutrients.fromJson(foodNutrients);

    // Add fdcId to nutrients
    final nutrientsWithId = FoodNutrients(
      calories: nutrients.calories,
      carbs: nutrients.carbs,
      protein: nutrients.protein,
      fat: nutrients.fat,
      fdcId: fdcId,
    );

    print('[FoodDataService] ✅ Nutrients parsed successfully');
    print('[FoodDataService]    - FDC ID: $fdcId');
    print('[FoodDataService]    - Calories: ${nutrientsWithId.calories}');
    print('[FoodDataService]    - Carbs: ${nutrientsWithId.carbs}g');
    print('[FoodDataService]    - Protein: ${nutrientsWithId.protein}g');
    print('[FoodDataService]    - Fat: ${nutrientsWithId.fat}g');

    return Result.success(nutrientsWithId);
  }
}
