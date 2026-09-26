class SmokingLog {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String source; // 'manual', 'quick_log', 'delay_intervention', 'sync'
  final String syncStatus; // 'synced', 'pending', 'failed'
  final DateTime createdAt;
  final String? trigger;
  final String? routine;
  final String? situation;
  final String? mood;
  final String? location;
  final String? note;
  final int? cravingIntensity; // 1 to 10
  final bool delayedFirst;
  final int? delayMinutes;
  final int? delayDuration; // Seconds or minutes delayed
  final bool isSynced;

  SmokingLog({
    required this.id,
    String? userId,
    required this.timestamp,
    String? source,
    String? syncStatus,
    DateTime? createdAt,
    this.trigger,
    this.routine,
    this.situation,
    this.mood,
    this.location,
    this.note,
    this.cravingIntensity,
    this.delayedFirst = false,
    this.delayMinutes,
    this.delayDuration,
    this.isSynced = false,
  })  : userId = userId ?? 'user_local',
        source = source ?? (delayedFirst ? 'delay_intervention' : 'quick_log'),
        syncStatus = syncStatus ?? (isSynced ? 'synced' : 'pending'),
        createdAt = createdAt ?? timestamp;

  SmokingLog copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? source,
    String? syncStatus,
    DateTime? createdAt,
    String? trigger,
    String? routine,
    String? situation,
    String? mood,
    String? location,
    String? note,
    int? cravingIntensity,
    bool? delayedFirst,
    int? delayMinutes,
    int? delayDuration,
    bool? isSynced,
  }) {
    return SmokingLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      trigger: trigger ?? this.trigger,
      routine: routine ?? this.routine,
      situation: situation ?? this.situation,
      mood: mood ?? this.mood,
      location: location ?? this.location,
      note: note ?? this.note,
      cravingIntensity: cravingIntensity ?? this.cravingIntensity,
      delayedFirst: delayedFirst ?? this.delayedFirst,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      delayDuration: delayDuration ?? this.delayDuration,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'syncStatus': syncStatus,
    'createdAt': createdAt.toIso8601String(),
    'trigger': trigger,
    'routine': routine,
    'situation': situation,
    'mood': mood,
    'location': location,
    'note': note,
    'cravingIntensity': cravingIntensity,
    'delayedFirst': delayedFirst,
    'delayMinutes': delayMinutes,
    'delayDuration': delayDuration,
    'isSynced': isSynced,
  };

  factory SmokingLog.fromJson(Map<String, dynamic> json) => SmokingLog(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? 'user_local',
    timestamp: DateTime.parse(json['timestamp'] as String),
    source: json['source'] as String? ?? 'quick_log',
    syncStatus: json['syncStatus'] as String? ?? (json['isSynced'] == true ? 'synced' : 'pending'),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.parse(json['timestamp'] as String)
        : DateTime.parse(json['timestamp'] as String),
    trigger: json['trigger'] as String?,
    routine: json['routine'] as String?,
    situation: json['situation'] as String?,
    mood: json['mood'] as String?,
    location: json['location'] as String?,
    note: json['note'] as String?,
    cravingIntensity: json['cravingIntensity'] as int?,
    delayedFirst: json['delayedFirst'] as bool? ?? false,
    delayMinutes: json['delayMinutes'] as int?,
    delayDuration: json['delayDuration'] as int?,
    isSynced: json['isSynced'] as bool? ?? false,
  );
}
