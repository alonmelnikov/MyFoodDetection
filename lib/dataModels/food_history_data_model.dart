import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_detection_result.dart';
import '../models/food_item.dart';
import '../models/result.dart';
import '../services/food_detection_service.dart';

/// Interface for the food history view model / data model.
abstract class FoodHistoryDataModelInterface {
  Future<List<FoodItem>> loadHistory();
  Future<FoodItem> captureAndDetectFood(File imageFile);
}

class FoodHistoryDataModelImpl implements FoodHistoryDataModelInterface {
  FoodHistoryDataModelImpl({required FoodDetectionService detectionService})
    : _detectionService = detectionService;

  final FoodDetectionService _detectionService;

  @override
  Future<List<FoodItem>> loadHistory() async {
    return <FoodItem>[];
  }

  /// Process detection results and return top 3 labels based on combined score.
  ///
  /// Combined score = topicality * 0.7 + score * 0.3
  List<Map<String, dynamic>> getTop3Results(Map<String, dynamic> rawJson) {
    print('[DataModel] 📊 Processing results to get top 3...');

    // Extract items from the raw JSON
    List<dynamic> items = [];

    // Try different possible JSON structures
    if (rawJson.containsKey('results')) {
      items = rawJson['results'] as List<dynamic>? ?? [];
    } else if (rawJson.containsKey('labels')) {
      items = rawJson['labels'] as List<dynamic>? ?? [];
    } else if (rawJson.containsKey('responses')) {
      final responses = rawJson['responses'] as List<dynamic>? ?? [];
      if (responses.isNotEmpty) {
        final first = responses.first as Map<String, dynamic>;
        items = first['labelAnnotations'] as List<dynamic>? ?? [];
      }
    }

    if (items.isEmpty) {
      print('[DataModel] ⚠️ No items found in raw JSON');
      return [];
    }

    // Calculate combined score for each item
    final scoredItems = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final topicality = (item['topicality'] as num?)?.toDouble() ?? 0.0;
      final score = (item['score'] as num?)?.toDouble() ?? 0.0;
      final combined = topicality * 0.7 + score * 0.3;

      scoredItems.add({
        ...item,
        'combinedScore': combined,
      });

      print(
        '[DataModel]   - ${item['description'] ?? item['label'] ?? 'Unknown'}: '
        'topicality=$topicality, score=$score, combined=$combined',
      );
    }

    // Sort by combined score (descending)
    scoredItems.sort((a, b) {
      final scoreA = a['combinedScore'] as double;
      final scoreB = b['combinedScore'] as double;
      return scoreB.compareTo(scoreA);
    });

    // Return top 3
    final top3 = scoredItems.take(3).toList();
    print('[DataModel] ✅ Top 3 results selected');

    return top3;
  }

  @override
  Future<FoodItem> captureAndDetectFood(File imageFile) async {
    print('[DataModel] 🎯 captureAndDetectFood called');
    print('[DataModel] 📂 Validating image file: ${imageFile.path}');

    if (!await imageFile.exists()) {
      print('[DataModel] ❌ Image file does not exist!');
      throw Exception('Captured image file does not exist.');
    }

    print('[DataModel] ✅ Image file validated, calling detection service...');

    final Result<FoodDetectionResult?, NetworkError?> detectionResult =
        await _detectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print('[DataModel] ❌ Detection service returned failure');
      print('[DataModel] ⚠️ Error: ${detectionResult.error}');
      throw Exception('Food detection failed: ${detectionResult.error}');
    }

    print('[DataModel] ✅ Detection service succeeded');
    final detection = detectionResult.data!;

    // Get top 3 results based on combined score
    final top3 = getTop3Results(detection.raw);

    // Use the best result (first in top 3) as the label
    String label = 'Food';
    if (top3.isNotEmpty) {
      label = top3.first['description'] as String? ??
          top3.first['label'] as String? ??
          detection.label ??
          'Food';
    } else {
      label = detection.label ?? 'Food';
    }

    print(
      '[DataModel] 🏷️ Label extracted: $label (from top result)',
    );

    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    print('[DataModel] 🔨 Building FoodItem...');
    print('[DataModel]    - ID: $itemId');
    print('[DataModel]    - Name: $label');
    print('[DataModel]    - Path: ${imageFile.path}');
    print('[DataModel]    - Time: $now');

    final item = FoodItem(
      id: itemId,
      name: label,
      imagePath: imageFile.path,
      calories: 0,
      carbs: 0,
      protein: 0,
      fat: 0,
      capturedAt: now,
    );

    print('[DataModel] ✅ FoodItem created successfully');
    return item;
  }
}
