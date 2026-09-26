class CravingLog {
  final String id;
  final DateTime timestamp;
  final String trigger;
  final int intensity; // 1-10
  final String? microAction;
  final int delayedMinutesCompleted;
  final String outcome; // 'craving_passed', 'delayed_then_smoked', 'smoked', 'still_craving', 'other_strategy'
  final bool? didSmoke;
  final bool isSynced;

  CravingLog({
    required this.id,
    required this.timestamp,
    required this.trigger,
    required this.intensity,
    this.microAction,
    this.delayedMinutesCompleted = 0,
    this.outcome = 'craving_passed',
    this.didSmoke,
    this.isSynced = false,
  });

  bool get wasOvercome => outcome == 'craving_passed' || outcome == 'avoided';
  bool get wasDelayed => delayedMinutesCompleted > 0;

  String get outcomeDisplay {
    switch (outcome) {
      case 'craving_passed':
      case 'avoided':
        return 'Craving passed';
      case 'delayed_then_smoked':
        return 'Delayed then smoked';
      case 'smoked':
        return 'Smoked';
      case 'still_craving':
        return 'Still craving';
      case 'other_strategy':
        return 'Used other strategy';
      default:
        return 'Craving passed';
    }
  }

  CravingLog copyWith({
    String? id,
    DateTime? timestamp,
    String? trigger,
    int? intensity,
    String? microAction,
    int? delayedMinutesCompleted,
    String? outcome,
    bool? didSmoke,
    bool? isSynced,
  }) {
    return CravingLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      trigger: trigger ?? this.trigger,
      intensity: intensity ?? this.intensity,
      microAction: microAction ?? this.microAction,
      delayedMinutesCompleted: delayedMinutesCompleted ?? this.delayedMinutesCompleted,
      outcome: outcome ?? this.outcome,
      didSmoke: didSmoke ?? this.didSmoke,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'trigger': trigger,
    'intensity': intensity,
    'microAction': microAction,
    'delayedMinutesCompleted': delayedMinutesCompleted,
    'outcome': outcome,
    'didSmoke': didSmoke,
    'isSynced': isSynced,
  };

  factory CravingLog.fromJson(Map<String, dynamic> json) => CravingLog(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    trigger: json['trigger'] as String? ?? 'Stress',
    intensity: json['intensity'] as int? ?? 5,
    microAction: json['microAction'] as String?,
    delayedMinutesCompleted: json['delayedMinutesCompleted'] as int? ?? 0,
    outcome: json['outcome'] as String? ?? 'craving_passed',
    didSmoke: json['didSmoke'] as bool?,
    isSynced: json['isSynced'] as bool? ?? false,
  );
}
