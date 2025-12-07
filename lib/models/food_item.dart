import 'dart:convert';

class FoodItem {
  final String id;
  final String name;
  final String imagePath;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final DateTime capturedAt;
  final int? fdcId; // USDA FoodData Central ID

  const FoodItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.capturedAt,
    this.fdcId,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? calories,
    double? carbs,
    double? protein,
    double? fat,
    DateTime? capturedAt,
    int? fdcId,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      capturedAt: capturedAt ?? this.capturedAt,
      fdcId: fdcId ?? this.fdcId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'capturedAt': capturedAt.toIso8601String(),
      'fdcId': fdcId,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      calories: (json['calories'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      fdcId: json['fdcId'] as int?,
    );
  }

  static String encodeList(List<FoodItem> items) {
    final list = items.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  static List<FoodItem> decodeList(String source) {
    if (source.isEmpty) return [];
    final List<dynamic> list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}


