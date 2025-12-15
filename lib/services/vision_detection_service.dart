import 'dart:convert';
import 'dart:io';

import '../enums/network_errors.dart';
import '../core/result.dart';
import '../domain/models/vision_detection_data.dart';
import 'api_service.dart';

/// Protocol (interface) for vision detection service.
abstract class VisionDetectionService {
  /// Accepts the captured image file and returns vision detection data.
  Future<Result<VisionDetectionData?, NetworkError?>> detectLabels(
    File imageFile,
  );
}

/// Vision detection service that sends image bytes to a Cloud Run endpoint.
class GoogleVisionDetectionService implements VisionDetectionService {
  GoogleVisionDetectionService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;

  static const String _url =
      'https://analyze-image-698327160260.europe-west1.run.app';

  @override
  Future<Result<VisionDetectionData?, NetworkError?>> detectLabels(
    File imageFile,
  ) async {
    // Read the image file and encode it as base64
    final bytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(bytes);

    final uri = Uri.parse(_url);
    final body = <String, dynamic>{'imageBase64': imageBase64};

    final apiResult = await _apiService.post(uri, body: body);

    if (!apiResult.isSuccess || apiResult.data == null) {
      return Result.failure(apiResult.error);
    }

    try {
      final data = apiResult.data!;
      final detectionData = VisionDetectionData.fromJson(data);
      return Result.success(detectionData);
    } catch (e) {
      return Result.failure(NetworkError.badResponse);
    }
  }
}
