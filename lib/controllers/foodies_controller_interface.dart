import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/base_interface_controller.dart';
import '../domain/models/food_item.dart';

/// Interface for FoodiesController - defines the contract for the screen
abstract class FoodiesControllerInterface extends BaseInterfaceController {
  /// Reactive list of food items
  RxList<FoodItem> get items;

  /// Capture food from photo
  Future<void> captureFood(XFile? photo);

  /// Clear all food items and cache
  Future<void> clearAll();

  void mainActionRequested();
}
