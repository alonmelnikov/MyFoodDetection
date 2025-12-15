import 'package:get/get.dart';

import '../controllers/food_detail_controller.dart';
import '../controllers/foodies_controller.dart';
import '../services/api_service.dart';
import '../services/food_data_memory_cache_service.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/food_history_storage_service.dart';
import '../services/secrets_service.dart';
import '../services/storage_service.dart';
import '../services/vision_detection_service.dart';
import '../useCases/capture_and_detect_food_use_case.dart';
import '../useCases/clear_all_use_case.dart';
import '../useCases/load_food_detail_use_case.dart';
import '../useCases/load_food_history_use_case.dart';

/// Dependency Injection container
/// Responsible for initializing and wiring all dependencies
class DependencyInjection {
  static FoodHistoryStorageService? _historyStorageService;

  /// Initialize all dependencies and register controllers
  static Future<void> initialize() async {
    // 1. Load environment variables
    await EnvSecretsService.load();

    // 2. Initialize core services
    final apiService = HttpApiService();
    final secretsService = EnvSecretsService();

    // 3. Initialize storage services
    final storageService = FileStorageService(directoryName: 'foodies_cache');
    _historyStorageService = FoodHistoryStorageService(
      storageService: storageService,
    );

    // Memory-only cache for USDA responses
    final FoodDataCacheService foodDataCacheService =
        FoodDataMemoryCacheService(maxItems: 30);

    // 4. Initialize vision services
    final visionService = GoogleVisionDetectionService(apiService: apiService);
    final foodDetectionService = FoodDetectionService(
      visionService: visionService,
    );

    // 5. Initialize food data services
    final foodDataService = UsdaFoodDataService(
      apiService: apiService,
      secretsService: secretsService,
      cacheService: foodDataCacheService,
    );

    // 6. Initialize use cases
    final loadFoodHistoryUseCase = LoadFoodHistoryUseCaseImpl(
      historyStorageService: _historyStorageService!,
    );
    final captureAndDetectFoodUseCase = CaptureAndDetectFoodUseCaseImpl(
      detectionService: foodDetectionService,
      foodDataService: foodDataService,
      historyStorageService: _historyStorageService!,
    );
    final clearAllUseCase = ClearAllUseCaseImpl(
      historyStorageService: _historyStorageService!,
    );
    final loadFoodDetailUseCase = LoadFoodDetailUseCaseImpl(
      foodDataService: foodDataService,
    );

    // 8. Register controllers with GetX
    Get.put(
      FoodiesController(
        loadFoodHistoryUseCase: loadFoodHistoryUseCase,
        captureAndDetectFoodUseCase: captureAndDetectFoodUseCase,
        clearAllUseCase: clearAllUseCase,
      ),
    );
    Get.put(
      FoodDetailsController(loadFoodDetailUseCase: loadFoodDetailUseCase),
    );
  }

  /// Get the history storage service instance (for background cleanup)
  static FoodHistoryStorageService? get historyStorageService =>
      _historyStorageService;
}
