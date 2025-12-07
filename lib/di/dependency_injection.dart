import 'package:get/get.dart';

import '../controllers/food_detail_controller.dart';
import '../controllers/foodies_controller.dart';
import '../dataModels/food_detail_data_model.dart';
import '../dataModels/foodies_data_model.dart';
import '../services/api_service.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/foodies_storage_service.dart';
import '../services/secrets_service.dart';
import '../services/storage_service.dart';
import '../services/vision_detection_service.dart';

/// Dependency Injection container
/// Responsible for initializing and wiring all dependencies
class DependencyInjection {
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
    final foodiesStorageService = FoodiesStorageService(
      storageService: storageService,
    );

    // Clean up expired cache on app startup
    await foodiesStorageService.cleanupExpiredCache();
    print('[DI] ✅ Storage services initialized and cache cleaned');

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
      storageService: foodiesStorageService,
    );
    print('[DI] ✅ Food data services initialized');

    // 6. Initialize data models
    final foodiesDataModel = FoodiesDataModelImpl(
      detectionService: foodDetectionService,
      foodDataService: foodDataService,
      storageService: foodiesStorageService,
    );
    final detailDataModel = FoodDetailDataModelImpl(
      foodDataService: foodDataService,
    );
    print('[DI] ✅ Data models initialized');

    // 7. Register controllers with GetX
    Get.put(FoodiesController(dataModel: foodiesDataModel));
    Get.put(FoodDetailsController(dataModel: detailDataModel));
    print('[DI] ✅ Controllers registered');

    print('[DI] ✅ All dependencies initialized successfully');
  }
}
