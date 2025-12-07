import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/food_detail_controller.dart';

class FoodDetailScreen extends StatelessWidget {
  const FoodDetailScreen({super.key, required this.fdcId});

  final int fdcId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodDetailController>();
    
    // Load food detail when screen opens
    controller.loadFoodDetail(fdcId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.error.value!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadFoodDetail(fdcId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final foodDetail = controller.foodDetail.value;
        if (foodDetail == null) {
          return const Center(
            child: Text('No data available'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name
              Text(
                foodDetail.description,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Brand owner (if available)
              if (foodDetail.brandOwner != null) ...[
                Text(
                  'Brand: ${foodDetail.brandOwner}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
              ],

              // Serving size
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        'Serving Size: ${foodDetail.servingSize} ${foodDetail.servingSizeUnit ?? "g"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Main nutrients
              Text(
                'Nutrition Facts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              _buildNutrientCard(
                'Calories',
                foodDetail.calories,
                'kcal',
                Icons.local_fire_department,
                Colors.red,
              ),
              _buildNutrientCard(
                'Carbohydrates',
                foodDetail.carbs,
                'g',
                Icons.grain,
                Colors.brown,
              ),
              _buildNutrientCard(
                'Protein',
                foodDetail.protein,
                'g',
                Icons.fitness_center,
                Colors.blue,
              ),
              _buildNutrientCard(
                'Fat',
                foodDetail.fat,
                'g',
                Icons.opacity,
                Colors.orange,
              ),
              const SizedBox(height: 24),

              // All nutrients
              Text(
                'All Nutrients',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: foodDetail.nutrients.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = foodDetail.nutrients.entries.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),

              // Ingredients (if available)
              if (foodDetail.ingredients != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      foodDetail.ingredients!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNutrientCard(
    String name,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name),
        trailing: Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

