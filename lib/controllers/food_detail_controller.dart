import 'package:get/get.dart';

import '../dataModels/food_detail_data_model.dart';
import '../models/food_detail.dart';

class FoodDetailsController extends GetxController {
  FoodDetailsController({required this.dataModel});

  final FoodDetailDataModelInterface dataModel;

  // Reactive variables
  final Rxn<FoodDetail> foodDetail = Rxn<FoodDetail>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  Future<void> loadFoodDetails(int fdcId) async {
    print('[FoodDetailController] 🎬 Loading food detail for FDC ID: $fdcId');

    isLoading.value = true;
    error.value = null;
    foodDetail.value = null;

    try {
      final detail = await dataModel.loadFoodDetail(fdcId);
      foodDetail.value = detail;
      print('[FoodDetailController] ✅ Food detail loaded');
    } catch (e, stackTrace) {
      print('[FoodDetailController] ❌ Error: $e');
      print('[FoodDetailController] 📚 Stack trace: $stackTrace');
      error.value = 'Failed to load food details. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
