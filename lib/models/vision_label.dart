class VisionLabel {
  final String description;
  final double score;
  final double topicality;

  VisionLabel({
    required this.description,
    required this.score,
    required this.topicality,
  });

  factory VisionLabel.fromJson(Map<String, dynamic> json) {
    return VisionLabel(
      description: json['description'] as String,
      score: (json['score'] as num).toDouble(),
      topicality: (json['topicality'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Calculate combined score: topicality * 0.7 + score * 0.3
  double get combinedScore => topicality * 0.7 + score * 0.3;
}

