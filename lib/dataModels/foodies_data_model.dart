import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_item.dart';
import '../models/result.dart';
import '../models/vision_label.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';

/// Interface for the foodies view model / data model.
abstract class FoodiesDataModelInterface {
  Future<List<FoodItem>> loadHistory();
  Future<FoodItem> captureAndDetectFood(File imageFile);
}

class FoodiesDataModelImpl implements FoodiesDataModelInterface {
  FoodiesDataModelImpl({
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
    print('[FoodiesDataModel] 🎯 captureAndDetectFood called');
    print('[FoodiesDataModel] 📂 Validating image file: ${imageFile.path}');

    if (!await imageFile.exists()) {
      print('[FoodiesDataModel] ❌ Image file does not exist!');
      throw Exception('Captured image file does not exist.');
    }

    print('[FoodiesDataModel] ✅ Image file validated, calling detection service...');

    final Result<List<VisionLabel>, NetworkError?> detectionResult =
        await _foodDetectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print('[FoodiesDataModel] ❌ Detection service returned failure');
      print('[FoodiesDataModel] ⚠️ Error: ${detectionResult.error}');
      throw Exception('Food detection failed: ${detectionResult.error}');
    }

    final labels = detectionResult.data!;

    if (labels.isEmpty) {
      print('[FoodiesDataModel] ❌ No labels detected');
      throw Exception('No food labels detected in image');
    }

    print('[FoodiesDataModel] ✅ Detection service returned ${labels.length} labels');

    // Reverse labels to get highest scores first and limit to 5
    final labelsToTry = labels.reversed.take(5).toList();
    print(
      '[FoodiesDataModel] 🔄 Will try ${labelsToTry.length} labels (highest scores first, max 5)',
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
        '[FoodiesDataModel] 🔄 Trying label ${i + 1}/${labelsToTry.length}: ${label.description}',
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

        print('[FoodiesDataModel] ✅ Successfully got nutrients for: $selectedLabel');
        break;
      } else {
        print(
          '[FoodiesDataModel] ⚠️ Failed to get nutrients for: ${label.description}',
        );
      }
    }

    // If all labels failed, throw error
    if (selectedLabel == null) {
      print(
        '[FoodiesDataModel] ❌ Failed to get nutrients for all ${labelsToTry.length} labels tried',
      );
      throw Exception('Could not find nutrition data for detected food items');
    }

    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    print('[FoodiesDataModel] 🔨 Building FoodItem...');
    print('[FoodiesDataModel]    - ID: $itemId');
    print('[FoodiesDataModel]    - Name: $selectedLabel');
    print('[FoodiesDataModel]    - Path: ${imageFile.path}');
    print('[FoodiesDataModel]    - Calories: $calories');
    print('[FoodiesDataModel]    - Carbs: ${carbs}g');
    print('[FoodiesDataModel]    - Protein: ${protein}g');
    print('[FoodiesDataModel]    - Fat: ${fat}g');
    print('[FoodiesDataModel]    - Time: $now');

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

    print('[FoodiesDataModel] ✅ FoodItem created successfully');
    return item;
  }
}

