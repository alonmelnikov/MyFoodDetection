/// Model representing detailed food information from USDA API
class FoodDetail {
  final int fdcId;
  final String description;
  final String? brandOwner;
  final String? ingredients;
  final double servingSize;
  final String? servingSizeUnit;
  final Map<String, double> nutrients;

  FoodDetail({
    required this.fdcId,
    required this.description,
    this.brandOwner,
    this.ingredients,
    required this.servingSize,
    this.servingSizeUnit,
    required this.nutrients,
  });

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    final nutrients = <String, double>{};

    // Parse food nutrients
    final foodNutrients = json['foodNutrients'] as List<dynamic>? ?? [];
    for (final nutrient in foodNutrients) {
      if (nutrient is! Map<String, dynamic>) continue;

      // Handle nested structure: nutrient.nutrient.name and nutrient.amount
      final nutrientData = nutrient['nutrient'] as Map<String, dynamic>?;
      final nutrientName = nutrientData?['name'] as String?;
      final value = (nutrient['amount'] as num?)?.toDouble();

      if (nutrientName != null && value != null) {
        nutrients[nutrientName] = value;
      }
    }

    return FoodDetail(
      fdcId: json['fdcId'] as int,
      description: json['description'] as String? ?? 'Unknown',
      brandOwner: json['brandOwner'] as String?,
      ingredients: json['ingredients'] as String?,
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 100.0,
      servingSizeUnit: json['servingSizeUnit'] as String?,
      nutrients: nutrients,
    );
  }

  /// Get specific nutrient value by name
  double? getNutrient(String nutrientName) {
    return nutrients[nutrientName];
  }

  /// Get calories (Energy)
  double get calories {
    return nutrients.entries
        .firstWhere(
          (e) => e.key.toLowerCase().contains('energy'),
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }

  /// Get carbs
  double get carbs {
    return nutrients.entries
        .firstWhere(
          (e) => e.key.toLowerCase().contains('carbohydrate'),
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }

  /// Get protein
  double get protein {
    return nutrients.entries
        .firstWhere(
          (e) => e.key.toLowerCase().contains('protein'),
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }

  /// Get fat
  double get fat {
    return nutrients.entries
        .firstWhere(
          (e) =>
              e.key.toLowerCase().contains('total lipid') ||
              e.key.toLowerCase().contains('fat'),
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }
}
