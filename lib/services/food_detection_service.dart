import 'dart:convert';
import 'dart:io';

import '../enums/network_errors.dart';
import '../models/food_detection_result.dart';
import '../models/result.dart';
import 'api_service.dart';

/// Protocol (interface) for any food detection service.
abstract class FoodDetectionService {
  /// Accepts the captured image file and returns a detection model + optional error.
  Future<Result<FoodDetectionResult?, NetworkError?>> detectFood(
    File imageFile,
  );
}

/// Food detection service that sends the captured image bytes to a Cloud Run
/// HTTP endpoint that performs the actual analysis (inspired by your example).
class GoogleVisionFoodDetectionService implements FoodDetectionService {
  GoogleVisionFoodDetectionService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  static const String _url =
      'https://analyze-image-698327160260.europe-west1.run.app';

  @override
  Future<Result<FoodDetectionResult?, NetworkError?>> detectFood(
    File imageFile,
  ) async {
    print('[FoodDetection] 🚀 Starting food detection...');
    print('[FoodDetection] 📁 Image file: ${imageFile.path}');

    // Read the image file and encode it as base64, like in your sample.
    final bytes = await imageFile.readAsBytes();
    print('[FoodDetection] 📦 Image size: ${bytes.length} bytes');

    final imageBase64 = base64Encode(bytes);
    print(
      '[FoodDetection] ✅ Base64 encoding complete (${imageBase64.length} chars)',
    );

    final uri = Uri.parse(_url);
    print('[FoodDetection] 🌐 Calling API: $_url');

    final body = <String, dynamic>{'imageBase64': imageBase64};

    final apiResult = await _apiService.post(uri, body: body);

    if (!apiResult.isSuccess || apiResult.data == null) {
      // Propagate network error (or null) as the error side of Result.
      print('[FoodDetection] ❌ API call failed: ${apiResult.error}');
      return Result.failure(apiResult.error);
    }

    print('[FoodDetection] ✅ API call successful');
    print('[FoodDetection] 📥 Response data: ${apiResult.data}');

    try {
      final data = apiResult.data!;
      final detection = FoodDetectionResult.fromJson(data);
      print('[FoodDetection] ✅ Detection parsed successfully');
      print('[FoodDetection] 🍕 Detected label: ${detection.label}');
      print('[FoodDetection] 📊 Confidence: ${detection.confidence}');
      return Result.success(detection);
    } catch (e) {
      print('[FoodDetection] ❌ Failed to parse response: $e');
      return Result.failure(NetworkError.badResponse);
    }
  }
}
