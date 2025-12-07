import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_detection_result.dart';
import '../models/result.dart';
import 'vision_detection_service.dart';

/// Food detection service that uses VisionDetectionService to fetch labels
/// and sorts them by combined score (topicality * 0.7 + score * 0.3).
class FoodDetectionService {
  FoodDetectionService({required VisionDetectionService visionService})
      : _visionService = visionService;

  final VisionDetectionService _visionService;

  /// Detects food from image and returns sorted results.
  Future<Result<FoodDetectionResult?, NetworkError?>> detectFood(
    File imageFile,
  ) async {
    print('[FoodDetection] 🚀 Starting food detection...');

    // Call vision detection service
    final visionResult = await _visionService.detectLabels(imageFile);

    if (!visionResult.isSuccess || visionResult.data == null) {
      print('[FoodDetection] ❌ Vision detection failed: ${visionResult.error}');
      return Result.failure(visionResult.error);
    }

    final detectionData = visionResult.data!;
    print('[FoodDetection] 📊 Received ${detectionData.labels.length} labels');

    // Sort labels by combined score (low to high)
    final sortedLabels = detectionData.getSortedLabels();
    print('[FoodDetection] 🔄 Sorted labels by combined score (low to high)');

    // Log sorted results
    for (var i = 0; i < sortedLabels.length; i++) {
      final label = sortedLabels[i];
      print(
        '[FoodDetection]   ${i + 1}. ${label.description}: '
        'combined=${label.combinedScore.toStringAsFixed(3)} '
        '(topicality=${label.topicality.toStringAsFixed(3)}, '
        'score=${label.score.toStringAsFixed(3)})',
      );
    }

    // Use the best label (highest combined score = last in sorted list)
    final bestLabel = sortedLabels.isNotEmpty ? sortedLabels.last : null;

    if (bestLabel == null) {
      print('[FoodDetection] ⚠️ No labels found');
      return Result.success(
        FoodDetectionResult(
          label: 'Food',
          confidence: 0.0,
          raw: {},
        ),
      );
    }

    print('[FoodDetection] ✅ Best label: ${bestLabel.description}');
    print('[FoodDetection] 📊 Combined score: ${bestLabel.combinedScore}');

    // Create FoodDetectionResult with the best label
    final result = FoodDetectionResult(
      label: bestLabel.description,
      confidence: bestLabel.combinedScore,
      raw: {
        'labels': sortedLabels
            .map((l) => {
                  'description': l.description,
                  'score': l.score,
                  'topicality': l.topicality,
                  'combinedScore': l.combinedScore,
                })
            .toList(),
      },
    );

    return Result.success(result);
  }
}
