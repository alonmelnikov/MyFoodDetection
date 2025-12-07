import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/food_detection_exception.dart';
import '../dataModels/foodies_data_model.dart';
import '../models/food_item.dart';

class FoodiesController extends GetxController {
  FoodiesController({required this.dataModel});

  final FoodiesDataModelInterface dataModel;

  // Reactive variables
  final RxList<FoodItem> items = <FoodItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

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

  Future<void> captureFood(XFile? photo) async {
    if (photo == null) {
      print('[FoodiesController] 📷 User cancelled camera');
      return;
    }

    print('[FoodiesController] 📸 Photo captured: ${photo.path}');

    final File imageFile = File(photo.path);
    await _processAndDetectFood(imageFile);
  }

  Future<void> _processAndDetectFood(File imageFile) async {
    print('[ProcessFood] 🎬 Starting food processing...');
    print('[ProcessFood] 📸 Image file: ${imageFile.path}');
    print('[ProcessFood] 📂 File exists: ${await imageFile.exists()}');

    isLoading.value = true;
    error.value = null;
    print('[ProcessFood] ⏳ State set to loading, calling data model...');

    try {
      final item = await dataModel.captureAndDetectFood(imageFile);
      print('[ProcessFood] ✅ Detection successful!');
      print('[ProcessFood] 🍕 Food name: ${item.name}');
      print('[ProcessFood] 🆔 Item ID: ${item.id}');
      print('[ProcessFood] 📁 Saved at: ${item.imagePath}');
      print('[ProcessFood] 🕐 Captured at: ${item.capturedAt}');
      print('[ProcessFood] 📊 Current items count: ${items.length}');

      items.insert(0, item); // Add to beginning of list

      print('[ProcessFood] ✅ State updated, new items count: ${items.length}');
    } on FoodDetectionException catch (e) {
      print('[ProcessFood] ❌ FoodDetectionException: ${e.type} - ${e.message}');
      error.value = e.message;
    } catch (e, stackTrace) {
      print('[ProcessFood] ❌ Unexpected error occurred: $e');
      print('[ProcessFood] 📚 Stack trace: $stackTrace');

      error.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAll() async {
    isLoading.value = true;
    error.value = null;

    try {
      await dataModel.clearAll();
      items.clear();
      print('[FoodiesController] ✅ All data cleared');
    } catch (e) {
      print('[FoodiesController] ❌ Failed to clear data: $e');
      error.value = 'Failed to clear data. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
