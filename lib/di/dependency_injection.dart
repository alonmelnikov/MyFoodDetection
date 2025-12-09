import 'package:get/get.dart';

import '../controllers/food_detail_controller.dart';
import '../controllers/foodies_controller.dart';
import '../services/api_service.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/foodies_storage_service.dart';
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
  static FoodiesStorageService? _storageService;

  /// Initialize all dependencies and register controllers
  static Future<void> initialize() async {
    print('[DI] 🚀 Initializing dependencies...');

    // 1. Load environment variables
    await EnvSecretsService.load();
    print('[DI] ✅ Environment variables loaded');

    // 2. Initialize core services
    final apiService = HttpApiService();
    final secretsService = EnvSecretsService();
    print('[DI] ✅ Core services initialized');

    // 3. Initialize storage services
    final storageService = FileStorageService(directoryName: 'foodies_cache');
    _storageService = FoodiesStorageService(storageService: storageService);

    // Cache cleanup will run in background after UI loads (non-blocking)
    print('[DI] ✅ Storage services initialized');

    // 4. Initialize vision services
    final visionService = GoogleVisionDetectionService(apiService: apiService);
    final foodDetectionService = FoodDetectionService(
      visionService: visionService,
    );
    print('[DI] ✅ Vision services initialized');

    // 5. Initialize food data services
    final foodDataService = UsdaFoodDataService(
      apiService: apiService,
      secretsService: secretsService,
      storageService: _storageService!,
    );
    print('[DI] ✅ Food data services initialized');

    // 6. Initialize use cases
    final loadFoodHistoryUseCase = LoadFoodHistoryUseCaseImpl(
      storageService: _storageService!,
    );
    final captureAndDetectFoodUseCase = CaptureAndDetectFoodUseCaseImpl(
      detectionService: foodDetectionService,
      foodDataService: foodDataService,
      storageService: _storageService!,
    );
    final clearAllUseCase = ClearAllUseCaseImpl(
      storageService: _storageService!,
    );
    final loadFoodDetailUseCase = LoadFoodDetailUseCaseImpl(
      foodDataService: foodDataService,
    );
    print('[DI] ✅ Use cases initialized');

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
    print('[DI] ✅ Controllers registered');

    print('[DI] ✅ All dependencies initialized successfully');
  }

  /// Get the storage service instance (for cache cleanup)
  static FoodiesStorageService? get storageService => _storageService;
}
