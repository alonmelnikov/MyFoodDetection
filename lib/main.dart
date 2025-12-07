import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/food_history_controller.dart';
import 'dataModels/food_history_data_model.dart';
import 'services/api_service.dart';
import 'services/food_detection_service.dart';
import 'services/vision_detection_service.dart';
import 'ui/screens/food_history_screen.dart';

void main() {
  // Initialize services
  final apiService = HttpApiService();
  final visionService = GoogleVisionDetectionService(
    apiService: apiService,
  );
  final foodDetectionService = FoodDetectionService(
    visionService: visionService,
  );
  final dataModel = FoodHistoryDataModelImpl(
    detectionService: foodDetectionService,
  );

  // Register controller with GetX (uses FoodHistoryDataModelInterface)
  Get.put(FoodHistoryController(dataModel: dataModel));

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
      home: FoodHistoryScreen(),
    );
  }
}
