import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/foodies_controller.dart';
import '../../models/food_item.dart';
import '../custom_widgets/generic_list.dart';
import '../custom_widgets/generic_list_item.dart';
import 'food_detail_screen.dart';

class FoodiesScreen extends StatelessWidget {
  FoodiesScreen({super.key});

  final _controller = Get.find<FoodiesController>();
  final ImagePicker _picker = ImagePicker();

  Future<void> _captureFood() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    await _controller.captureFood(photo);
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('Foodies'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() {
        if (_controller.error.value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_controller.error.value!),
                backgroundColor: Colors.red,
              ),
            );
            _controller.error.value = null;
          });
        }

        return GenericList<FoodItem>(
          items: _controller.items,
          isLoading: _controller.isLoading.value,
          emptyMessage: 'No food items yet.\nTap + to capture your first meal!',
          emptyIcon: Icons.restaurant_menu,
          itemBuilder: (context, item, index) {
            return GenericListItem(
              title: item.name,
              subtitle: '${item.calories.toStringAsFixed(0)} kcal',
              imagePath: item.imagePath,
              details: [
                DetailItem(
                  label: 'Carbs',
                  value: '${item.carbs.toStringAsFixed(1)}g',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                DetailItem(
                  label: 'Protein',
                  value: '${item.protein.toStringAsFixed(1)}g',
                  color: Colors.green.shade400,
                ),
                DetailItem(
                  label: 'Fat',
                  value: '${item.fat.toStringAsFixed(1)}g',
                  color: Colors.orange.shade400,
                ),
              ],
              onTap: () {
                if (item.fdcId != null) {
                  Get.to(() => FoodDetailScreen(fdcId: item.fdcId!));
                } else {
                  Get.snackbar(
                    'No Details Available',
                    'This food item does not have detailed information.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureFood,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture Food'),
      ),
    );
  }
}
