import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_item.dart';
import '../models/result.dart';
import '../models/vision_label.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';

/// Interface for the food history view model / data model.
abstract class FoodHistoryDataModelInterface {
  Future<List<FoodItem>> loadHistory();
  Future<FoodItem> captureAndDetectFood(File imageFile);
}

class FoodHistoryDataModelImpl implements FoodHistoryDataModelInterface {
  FoodHistoryDataModelImpl({
    required FoodDetectionService detectionService,
    required FoodDataService foodDataService,
  }) : _foodDetectionService = detectionService,
       _foodDataService = foodDataService;

  final FoodDetectionService _foodDetectionService;
  final FoodDataService _foodDataService;

  @override
  Future<List<FoodItem>> loadHistory() async {
    return <FoodItem>[];
  }

  @override
  Future<FoodItem> captureAndDetectFood(File imageFile) async {
    print('[DataModel] 🎯 captureAndDetectFood called');
    print('[DataModel] 📂 Validating image file: ${imageFile.path}');

    if (!await imageFile.exists()) {
      print('[DataModel] ❌ Image file does not exist!');
      throw Exception('Captured image file does not exist.');
    }

    print('[DataModel] ✅ Image file validated, calling detection service...');

    final Result<List<VisionLabel>, NetworkError?> detectionResult =
        await _foodDetectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print('[DataModel] ❌ Detection service returned failure');
      print('[DataModel] ⚠️ Error: ${detectionResult.error}');
      throw Exception('Food detection failed: ${detectionResult.error}');
    }

    final labels = detectionResult.data!;

    if (labels.isEmpty) {
      print('[DataModel] ❌ No labels detected');
      throw Exception('No food labels detected in image');
    }

    print('[DataModel] ✅ Detection service returned ${labels.length} labels');

    // Reverse labels to get highest scores first and limit to 5
    final labelsToTry = labels.reversed.take(5).toList();
    print(
      '[DataModel] 🔄 Will try ${labelsToTry.length} labels (highest scores first, max 5)',
    );

    // Try each label until we get nutrition data
    String? selectedLabel;
    double calories = 0;
    double carbs = 0;
    double protein = 0;
    double fat = 0;
    int? fdcId;

    for (var i = 0; i < labelsToTry.length; i++) {
      final label = labelsToTry[i];
      print(
        '[DataModel] 🔄 Trying label ${i + 1}/${labelsToTry.length}: ${label.description}',
      );

      final nutrientsResult = await _foodDataService.getFoodNutrientsByName(
        label.description,
      );

      if (nutrientsResult.isSuccess && nutrientsResult.data != null) {
        final nutrients = nutrientsResult.data!;
        selectedLabel = label.description;
        calories = nutrients.calories;
        carbs = nutrients.carbs;
        protein = nutrients.protein;
        fat = nutrients.fat;
        fdcId = nutrients.fdcId;

        print('[DataModel] ✅ Successfully got nutrients for: $selectedLabel');
        break;
      } else {
        print(
          '[DataModel] ⚠️ Failed to get nutrients for: ${label.description}',
        );
      }
    }

    // If all labels failed, throw error
    if (selectedLabel == null) {
      print(
        '[DataModel] ❌ Failed to get nutrients for all ${labelsToTry.length} labels tried',
      );
      throw Exception('Could not find nutrition data for detected food items');
    }

    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    print('[DataModel] 🔨 Building FoodItem...');
    print('[DataModel]    - ID: $itemId');
    print('[DataModel]    - Name: $selectedLabel');
    print('[DataModel]    - Path: ${imageFile.path}');
    print('[DataModel]    - Calories: $calories');
    print('[DataModel]    - Carbs: ${carbs}g');
    print('[DataModel]    - Protein: ${protein}g');
    print('[DataModel]    - Fat: ${fat}g');
    print('[DataModel]    - Time: $now');

    final item = FoodItem(
      id: itemId,
      name: selectedLabel,
      imagePath: imageFile.path,
      calories: calories,
      carbs: carbs,
      protein: protein,
      fat: fat,
      capturedAt: now,
      fdcId: fdcId,
    );

    print('[DataModel] ✅ FoodItem created successfully');
    return item;
  }
}
