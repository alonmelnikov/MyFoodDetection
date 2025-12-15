import 'dart:io';

import '../enums/network_errors.dart';
import '../core/result.dart';
import '../domain/models/vision_label.dart';
import 'vision_detection_service.dart';

/// Food detection service that uses VisionDetectionService to fetch labels
/// and sorts them by combined score (topicality * 0.7 + score * 0.3).
class FoodDetectionService {
  FoodDetectionService({required VisionDetectionService visionService})
    : _visionService = visionService;

  final VisionDetectionService _visionService;

  /// Detects food from image and returns all VisionLabels sorted by score.
  Future<Result<List<VisionLabel>, NetworkError?>> detectFood(
    File imageFile,
  ) async {
    // Call vision detection service
    final visionResult = await _visionService.detectLabels(imageFile);

    if (!visionResult.isSuccess || visionResult.data == null) {
      return Result.failure(visionResult.error);
    }

    final detectionData = visionResult.data!;

    // Sort labels by combined score (low to high)
    final sortedLabels = detectionData.getSortedLabels();

    return Result.success(sortedLabels);
  }
}
