class PatternInsight {
  final String id;
  final String title;
  final String message;
  final String category; // 'rhythm', 'trigger', 'high_risk', 'progress', 'intervention'
  final String? actionableAdvice;
  final String iconName;
  final int dataPointsCount;
  final double confidence; // 0.0 to 1.0

  PatternInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.actionableAdvice,
    required this.iconName,
    this.dataPointsCount = 0,
    this.confidence = 1.0,
  });

  bool get isSupportedByData => dataPointsCount >= 3;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'category': category,
    'actionableAdvice': actionableAdvice,
    'iconName': iconName,
    'dataPointsCount': dataPointsCount,
    'confidence': confidence,
  };

  factory PatternInsight.fromJson(Map<String, dynamic> json) => PatternInsight(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    category: json['category'] as String? ?? 'rhythm',
    actionableAdvice: json['actionableAdvice'] as String?,
    iconName: json['iconName'] as String? ?? 'alarm',
    dataPointsCount: json['dataPointsCount'] as int? ?? 0,
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
  );
}
