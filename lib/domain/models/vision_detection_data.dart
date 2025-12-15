import 'vision_label.dart';

class VisionDetectionData {
  final List<VisionLabel> labels;

  VisionDetectionData({required this.labels});

  factory VisionDetectionData.fromJson(Map<String, dynamic> json) {
    // Handle Google Vision API response structure: responses[0].labelAnnotations
    List<dynamic> labelsJson = [];

    if (json.containsKey('responses')) {
      final responses = json['responses'] as List<dynamic>?;
      if (responses != null && responses.isNotEmpty) {
        final firstResponse = responses.first as Map<String, dynamic>;
        labelsJson = firstResponse['labelAnnotations'] as List<dynamic>? ?? [];
      }
    } else if (json.containsKey('labels')) {
      // Fallback for simplified structure
      labelsJson = json['labels'] as List<dynamic>? ?? [];
    }

    final labels = labelsJson
        .map((item) => VisionLabel.fromJson(item as Map<String, dynamic>))
        .toList();

    return VisionDetectionData(labels: labels);
  }

  /// Get labels sorted by combined score (topicality * 0.7 + score * 0.3)
  /// from low to high
  List<VisionLabel> getSortedLabels() {
    final sorted = List<VisionLabel>.from(labels);
    sorted.sort((a, b) => a.combinedScore.compareTo(b.combinedScore));
    return sorted;
  }
}
