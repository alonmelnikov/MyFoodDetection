import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/food_history_controller.dart';
import 'dataModels/food_history_data_model.dart';
import 'services/api_service.dart';
import 'services/food_detection_service.dart';
import 'ui/screens/food_history_screen.dart';

void main() {
  // Initialize services
  final apiService = HttpApiService();
  final detectionService = GoogleVisionFoodDetectionService(
    apiService: apiService,
  );
  final dataModel = FoodHistoryDataModelImpl(
    detectionService: detectionService,
  );

  // Register controller with GetX
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
      home: const FoodHistoryScreen(),
    );
  }
}
