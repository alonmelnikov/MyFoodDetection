/// Custom exception for food detection errors
class FoodDetectionException implements Exception {
  final FoodDetectionErrorType type;
  final String message;

  FoodDetectionException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

enum FoodDetectionErrorType {
  timeout,
  foodNotRecognized,
  noInternet,
  general,
}
