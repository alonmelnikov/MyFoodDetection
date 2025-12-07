/// Model representing food nutrients data from USDA API
class FoodNutrients {
  final double calories;
  final double carbs;
  final double protein;
  final double fat;

  FoodNutrients({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Parse nutrients from USDA API food nutrients array
  factory FoodNutrients.fromJson(List<dynamic> foodNutrients) {
    double calories = 0;
    double carbs = 0;
    double protein = 0;
    double fat = 0;

    for (final nutrient in foodNutrients) {
      if (nutrient is! Map<String, dynamic>) continue;

      final nutrientName = nutrient['nutrientName'] as String?;
      final value = (nutrient['value'] as num?)?.toDouble() ?? 0.0;

      // Match nutrient names (USDA uses specific names)
      if (nutrientName != null) {
        if (nutrientName.toLowerCase().contains('energy') ||
            nutrientName.toLowerCase() == 'calories') {
          calories = value;
        } else if (nutrientName.toLowerCase().contains('carbohydrate')) {
          carbs = value;
        } else if (nutrientName.toLowerCase().contains('protein')) {
          protein = value;
        } else if (nutrientName.toLowerCase().contains('total lipid') ||
            nutrientName.toLowerCase().contains('fat')) {
          fat = value;
        }
      }
    }

    return FoodNutrients(
      calories: calories,
      carbs: carbs,
      protein: protein,
      fat: fat,
    );
  }
}

