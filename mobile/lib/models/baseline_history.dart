class BaselineHistoryEntry {
  final String source; // 'questionnaire', 'observed_average', 'manual'
  final int value;
  final DateTime effectiveDate;
  final DateTime createdAt;

  const BaselineHistoryEntry({
    required this.source,
    required this.value,
    required this.effectiveDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'source': source,
    'value': value,
    'effectiveDate': effectiveDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory BaselineHistoryEntry.fromJson(Map<String, dynamic> json) => BaselineHistoryEntry(
    source: json['source'] as String? ?? 'questionnaire',
    value: json['value'] as int? ?? 10,
    effectiveDate: json['effectiveDate'] != null
        ? DateTime.tryParse(json['effectiveDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
