class TargetCycle {
  final String cycleId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int target;
  final int validDayCount;
  final double? weeklyAverage;
  final String status; // 'active', 'completed_successful', 'completed_unsuccessful', 'held_incomplete'
  final int consecutiveFailures;

  const TargetCycle({
    required this.cycleId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.target,
    this.validDayCount = 0,
    this.weeklyAverage,
    this.status = 'active',
    this.consecutiveFailures = 0,
  });

  bool get isSuccessful =>
      validDayCount >= 5 &&
      weeklyAverage != null &&
      weeklyAverage! <= target;

  bool get canEvaluate => validDayCount >= 5;

  TargetCycle copyWith({
    String? cycleId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? target,
    int? validDayCount,
    double? weeklyAverage,
    String? status,
    int? consecutiveFailures,
  }) {
    return TargetCycle(
      cycleId: cycleId ?? this.cycleId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      target: target ?? this.target,
      validDayCount: validDayCount ?? this.validDayCount,
      weeklyAverage: weeklyAverage ?? this.weeklyAverage,
      status: status ?? this.status,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }

  Map<String, dynamic> toJson() => {
    'cycleId': cycleId,
    'userId': userId,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'target': target,
    'validDayCount': validDayCount,
    'weeklyAverage': weeklyAverage,
    'status': status,
    'consecutiveFailures': consecutiveFailures,
  };

  factory TargetCycle.fromJson(Map<String, dynamic> json) => TargetCycle(
    cycleId: json['cycleId'] as String? ?? 'cycle_1',
    userId: json['userId'] as String? ?? 'user_local',
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    endDate: json['endDate'] != null
        ? DateTime.tryParse(json['endDate'] as String) ?? DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(const Duration(days: 7)),
    target: json['target'] as int? ?? 10,
    validDayCount: json['validDayCount'] as int? ?? 0,
    weeklyAverage: (json['weeklyAverage'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'active',
    consecutiveFailures: json['consecutiveFailures'] as int? ?? 0,
  );
}
