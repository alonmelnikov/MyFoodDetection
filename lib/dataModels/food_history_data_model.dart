import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_detection_result.dart';
import '../models/food_item.dart';
import '../models/result.dart';
import '../services/food_detection_service.dart';

/// Interface for the food history view model / data model.
abstract class FoodHistoryDataModelInterface {
  Future<List<FoodItem>> loadHistory();
  Future<FoodItem> captureAndDetectFood(File imageFile);
}

class FoodHistoryDataModelImpl implements FoodHistoryDataModelInterface {
  FoodHistoryDataModelImpl({required FoodDetectionService detectionService})
    : _detectionService = detectionService;

  final FoodDetectionService _detectionService;

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

    final Result<FoodDetectionResult?, NetworkError?> detectionResult =
        await _detectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print('[DataModel] ❌ Detection service returned failure');
      print('[DataModel] ⚠️ Error: ${detectionResult.error}');
      throw Exception('Food detection failed: ${detectionResult.error}');
    }

    print('[DataModel] ✅ Detection service succeeded');
    final detection = detectionResult.data!;
    final label = detection.label ?? 'Food';
    print(
      '[DataModel] 🏷️ Label extracted: $label (fallback applied: ${detection.label == null})',
    );

    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    print('[DataModel] 🔨 Building FoodItem...');
    print('[DataModel]    - ID: $itemId');
    print('[DataModel]    - Name: $label');
    print('[DataModel]    - Path: ${imageFile.path}');
    print('[DataModel]    - Time: $now');

    final item = FoodItem(
      id: itemId,
      name: label,
      imagePath: imageFile.path,
      calories: 0,
      carbs: 0,
      protein: 0,
      fat: 0,
      capturedAt: now,
    );

    print('[DataModel] ✅ FoodItem created successfully');
    return item;
  }
}
