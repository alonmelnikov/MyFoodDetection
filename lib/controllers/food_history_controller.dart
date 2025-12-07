import 'dart:io';

import 'package:get/get.dart';

import '../dataModels/food_history_data_model.dart';
import '../models/food_item.dart';

class FoodHistoryController extends GetxController {
  FoodHistoryController({required this.dataModel});

  final FoodHistoryDataModel dataModel;

  // Reactive variables
  final RxList<FoodItem> items = <FoodItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString(); // Reactive nullable String

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    error.value = null;

    try {
      final historyItems = await dataModel.loadHistory();
      items.value = historyItems;
    } catch (e) {
      error.value = 'Failed to load history';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> captureFood(File imageFile) async {
    print('[CaptureFood] 🎬 Starting captureFood flow...');
    print('[CaptureFood] 📸 Image file: ${imageFile.path}');
    print('[CaptureFood] 📂 File exists: ${await imageFile.exists()}');

    isLoading.value = true;
    error.value = null;
    print('[CaptureFood] ⏳ State set to loading, calling data model...');

    try {
      final item = await dataModel.captureAndDetectFood(imageFile);
      print('[CaptureFood] ✅ Detection successful!');
      print('[CaptureFood] 🍕 Food name: ${item.name}');
      print('[CaptureFood] 🆔 Item ID: ${item.id}');
      print('[CaptureFood] 📁 Saved at: ${item.imagePath}');
      print('[CaptureFood] 🕐 Captured at: ${item.capturedAt}');
      print('[CaptureFood] 📊 Current items count: ${items.length}');

      items.insert(0, item); // Add to beginning of list

      print(
        '[CaptureFood] ✅ State updated, new items count: ${items.length}',
      );
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

