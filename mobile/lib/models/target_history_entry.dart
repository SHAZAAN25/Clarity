class TargetHistoryEntry {
  final String id;
  final String userId;
  final int previousTarget;
  final int newTarget;
  final DateTime effectiveDate;
  final String reason;
  final String source; // 'initial', 'cycle_reduction', 'cycle_hold', 'stabilize', 'manual', 'quit_by_date', 'quit_now'
  final String strategyState; // 'REDUCE', 'QUIT_BY_DATE', 'QUIT_NOW', 'STABILIZE'
  final String? cycleId;
  final DateTime createdAt;

  const TargetHistoryEntry({
    required this.id,
    required this.userId,
    required this.previousTarget,
    required this.newTarget,
    required this.effectiveDate,
    required this.reason,
    required this.source,
    required this.strategyState,
    this.cycleId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'previousTarget': previousTarget,
    'newTarget': newTarget,
    'effectiveDate': effectiveDate.toIso8601String(),
    'reason': reason,
    'source': source,
    'strategyState': strategyState,
    'cycleId': cycleId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TargetHistoryEntry.fromJson(Map<String, dynamic> json) => TargetHistoryEntry(
    id: json['id'] as String? ?? 'th_${DateTime.now().millisecondsSinceEpoch}',
    userId: json['userId'] as String? ?? 'user_local',
    previousTarget: json['previousTarget'] as int? ?? 0,
    newTarget: json['newTarget'] as int? ?? 0,
    effectiveDate: json['effectiveDate'] != null
        ? DateTime.tryParse(json['effectiveDate'] as String) ?? DateTime.now()
        : DateTime.now(),
    reason: json['reason'] as String? ?? '',
    source: json['source'] as String? ?? 'system',
    strategyState: json['strategyState'] as String? ?? 'REDUCE',
    cycleId: json['cycleId'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
