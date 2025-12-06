class FoodDetectionResult {
  final String? label;
  final double? confidence;
  final Map<String, dynamic> raw;

  const FoodDetectionResult({
    required this.label,
    required this.confidence,
    required this.raw,
  });

  /// Build from a JSON structure similar to Google Vision label response.
  ///
  /// Supports two shapes:
  /// 1) Cloud Run simplified: { "label": "Pizza", "confidence": 0.98, ... }
  /// 2) Raw Vision: { "responses": [ { "labelAnnotations": [ { "description": "...", "score": 0.9 }, ... ] } ] }
  factory FoodDetectionResult.fromJson(Map<String, dynamic> json) {
    // Simplified Cloud Run shape.
    if (json.containsKey('label')) {
      return FoodDetectionResult(
        label: json['label'] as String?,
        confidence: (json['confidence'] is num)
            ? (json['confidence'] as num).toDouble()
            : null,
        raw: json,
      );
    }

    // Fallback: try to interpret as raw Vision JSON.
    final responses = json['responses'] as List<dynamic>? ?? [];
    if (responses.isNotEmpty) {
      final first = responses.first as Map<String, dynamic>;
      final labels = first['labelAnnotations'] as List<dynamic>? ?? [];
      if (labels.isNotEmpty) {
        final top = labels.first as Map<String, dynamic>;
        final description = top['description'] as String?;
        final score = (top['score'] is num)
            ? (top['score'] as num).toDouble()
            : null;

        return FoodDetectionResult(
          label: description,
          confidence: score,
          raw: json,
        );
      }
    }

    return FoodDetectionResult(
      label: null,
      confidence: null,
      raw: json,
    );
  }
}


