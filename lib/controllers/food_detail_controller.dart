import 'package:get/get.dart';

import '../domain/models/food_detail.dart';
import '../useCases/load_food_detail_use_case.dart';

class FoodDetailsController extends GetxController {
  FoodDetailsController({required this.loadFoodDetailUseCase});

  final LoadFoodDetailUseCase loadFoodDetailUseCase;

  // Reactive variables
  final Rxn<FoodDetail> foodDetail = Rxn<FoodDetail>();
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  Future<void> loadFoodDetails(int fdcId) async {
    isLoading.value = true;
    error.value = null;
    foodDetail.value = null;

    try {
      final detail = await loadFoodDetailUseCase.execute(fdcId);
      foodDetail.value = detail;
    } catch (e) {
      error.value = 'Failed to load food details. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
