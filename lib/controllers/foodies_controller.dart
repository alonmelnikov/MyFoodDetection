import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/base_interface_controller.dart';
import '../core/food_detection_exception.dart';
import '../domain/models/food_item.dart';
import '../useCases/capture_and_detect_food_use_case.dart';
import '../useCases/clear_all_use_case.dart';
import '../useCases/load_food_history_use_case.dart';
import 'foodies_controller_interface.dart';

class FoodiesController extends BaseController
    implements FoodiesControllerInterface {
  FoodiesController({
    required this.loadFoodHistoryUseCase,
    required this.captureAndDetectFoodUseCase,
    required this.clearAllUseCase,
  });

  final LoadFoodHistoryUseCase loadFoodHistoryUseCase;
  final CaptureAndDetectFoodUseCase captureAndDetectFoodUseCase;
  final ClearAllUseCase clearAllUseCase;

  // Reactive variables
  @override
  final RxList<FoodItem> items = <FoodItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void mainActionRequested() {
    isLoading.value = true;
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    error.value = null;

    try {
      final historyItems = await loadFoodHistoryUseCase.execute();
      items.value = historyItems;
    } catch (e) {
      error.value = 'Failed to load history';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> captureFood(XFile? photo) async {
    if (photo == null) {
      return;
    }

    // Set loading state immediately when returning from camera
    isLoading.value = true;
    error.value = null;

    await _processAndDetectFood(photo);
  }

  Future<void> _processAndDetectFood(XFile photo) async {
    try {
      final item = await captureAndDetectFoodUseCase.execute(photo);
      items.insert(0, item); // Add to beginning of list
    } on FoodDetectionException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> clearAll() async {
    isLoading.value = true;
    error.value = null;

    try {
      await clearAllUseCase.execute();
      items.clear();
    } catch (e) {
      error.value = 'Failed to clear data. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
