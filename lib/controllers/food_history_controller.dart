import 'dart:io';

import 'package:get/get.dart';

import '../dataModels/food_history_data_model.dart';
import '../enums/network_errors.dart';
import '../models/food_detection_result.dart';
import '../models/food_item.dart';
import '../models/result.dart';
import '../services/food_detection_service.dart';

class FoodHistoryController extends GetxController
    implements FoodHistoryDataModel {
  FoodHistoryController({required FoodDetectionService detectionService})
      : _detectionService = detectionService;

  final FoodDetectionService _detectionService;

  // Reactive variables for UI state
  final RxList<FoodItem> items = <FoodItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString(); // Reactive nullable String

  @override
  void onInit() {
    super.onInit();
    _loadHistoryWithState();
  }

  /// Internal method that loads history and updates UI state
  Future<void> _loadHistoryWithState() async {
    isLoading.value = true;
    error.value = null;

    try {
      final historyItems = await loadHistory();
      items.value = historyItems;
    } catch (e) {
      error.value = 'Failed to load history';
    } finally {
      isLoading.value = false;
    }
  }

  /// Interface method: Load history (dummy implementation)
  @override
  Future<List<FoodItem>> loadHistory() async {
    // Dummy implementation: no persistence, start with an empty list.
    return <FoodItem>[];
  }

  /// Interface method: Capture and detect food from image file
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

  /// UI method: Capture food and update reactive state
  Future<void> captureFood(File imageFile) async {
    print('[CaptureFood] 🎬 Starting captureFood flow...');
    print('[CaptureFood] 📸 Image file: ${imageFile.path}');
    print('[CaptureFood] 📂 File exists: ${await imageFile.exists()}');

    isLoading.value = true;
    error.value = null;
    print('[CaptureFood] ⏳ State set to loading, calling detection...');

    try {
      final item = await captureAndDetectFood(imageFile);
      print('[CaptureFood] ✅ Detection successful!');
      print('[CaptureFood] 🍕 Food name: ${item.name}');
      print('[CaptureFood] 🆔 Item ID: ${item.id}');
      print('[CaptureFood] 📁 Saved at: ${item.imagePath}');
      print('[CaptureFood] 🕐 Captured at: ${item.capturedAt}');
      print('[CaptureFood] 📊 Current items count: ${items.length}');

      items.insert(0, item); // Add to beginning of list

      print('[CaptureFood] ✅ State updated, new items count: ${items.length}');
    } catch (e, stackTrace) {
      print('[CaptureFood] ❌ Error occurred: $e');
      print('[CaptureFood] 📚 Stack trace: $stackTrace');

      error.value = 'Failed to analyze food. Please try again.';

      print('[CaptureFood] ⚠️ Error state set');
    } finally {
      isLoading.value = false;
    }
  }
}
