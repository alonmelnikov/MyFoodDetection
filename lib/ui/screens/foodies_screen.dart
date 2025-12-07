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
        actions: [
          if (_controller.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear All',
              onPressed: () => _showClearConfirmation(context),
            ),
        ],
      ),
      body: Obx(() {
        if (_controller.error.value != null) {
          final errorMessage = _controller.error.value!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      _getErrorIcon(errorMessage),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: _getErrorColor(errorMessage),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _controller.error.value = null;
          });
        }

        return Column(
          children: [
            if (_controller.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showClearConfirmation(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: GenericList<FoodItem>(
                items: _controller.items,
                isLoading: _controller.isLoading.value,
                emptyMessage: 'No food items yet.',
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
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureFood,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture Food'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  IconData _getErrorIcon(String errorMessage) {
    if (errorMessage.contains('timeout') ||
        errorMessage.contains('timed out')) {
      return Icons.timer_off;
    } else if (errorMessage.contains('recognize') ||
        errorMessage.contains('Could not find nutrition')) {
      return Icons.restaurant_menu_outlined;
    } else if (errorMessage.contains('internet') ||
        errorMessage.contains('connection')) {
      return Icons.wifi_off;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor(String errorMessage) {
    if (errorMessage.contains('timeout') ||
        errorMessage.contains('timed out')) {
      return Colors.orange;
    } else if (errorMessage.contains('recognize') ||
        errorMessage.contains('Could not find nutrition')) {
      return Colors.amber.shade700;
    } else if (errorMessage.contains('internet') ||
        errorMessage.contains('connection')) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to clear all food items and cache? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _controller.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
