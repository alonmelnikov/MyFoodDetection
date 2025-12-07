import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/food_detail_controller.dart';
import 'controllers/foodies_controller.dart';
import 'dataModels/food_detail_data_model.dart';
import 'dataModels/foodies_data_model.dart';
import 'services/api_service.dart';
import 'services/food_data_service.dart';
import 'services/food_detection_service.dart';
import 'services/secrets_service.dart';
import 'services/vision_detection_service.dart';
import 'ui/screens/foodies_screen.dart';

void main() async {
  // Load environment variables from .env file
  await EnvSecretsService.load();

  // Initialize services
  final apiService = HttpApiService();
  final secretsService = EnvSecretsService();
  final visionService = GoogleVisionDetectionService(apiService: apiService);
  final foodDetectionService = FoodDetectionService(
    visionService: visionService,
  );
  final foodDataService = UsdaFoodDataService(
    apiService: apiService,
    secretsService: secretsService,
  );
  final foodiesDataModel = FoodiesDataModelImpl(
    detectionService: foodDetectionService,
    foodDataService: foodDataService,
  );
  final detailDataModel = FoodDetailDataModelImpl(
    foodDataService: foodDataService,
  );

  // Register controllers with GetX
  Get.put(FoodiesController(dataModel: foodiesDataModel));
  Get.put(FoodDetailController(dataModel: detailDataModel));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Food Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: FoodiesScreen(),
    );
  }
}
