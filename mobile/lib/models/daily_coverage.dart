import 'strategy_mode.dart';

class DailyCoverage {
  final String dateString; // YYYY-MM-DD
  final DateTime? dayStartedAt;
  final DateTime? firstTrackedAt;
  final DateTime? lastTrackedAt;
  final DateTime? trackingCompletedAt; // Explicit confirmation timestamp
  final int trackingSessionCount;
  final int eventCount;
  final bool dayClosed;
  final bool confirmedZero; // Explicitly confirmed smoke-free day
  final CoverageStatus coverageStatus;
  final int actualCigarettes;
  final int targetCigarettes;
  final bool isSteady;

  const DailyCoverage({
    required this.dateString,
    this.dayStartedAt,
    this.firstTrackedAt,
    this.lastTrackedAt,
    this.trackingCompletedAt,
    this.trackingSessionCount = 0,
    this.eventCount = 0,
    this.dayClosed = false,
    this.confirmedZero = false,
    this.coverageStatus = CoverageStatus.unknown,
    this.actualCigarettes = 0,
    this.targetCigarettes = 0,
    this.isSteady = false,
  });

  DailyCoverage copyWith({
    String? dateString,
    DateTime? dayStartedAt,
    DateTime? firstTrackedAt,
    DateTime? lastTrackedAt,
    DateTime? trackingCompletedAt,
    int? trackingSessionCount,
    int? eventCount,
    bool? dayClosed,
    bool? confirmedZero,
    CoverageStatus? coverageStatus,
    int? actualCigarettes,
    int? targetCigarettes,
    bool? isSteady,
  }) {
    return DailyCoverage(
      dateString: dateString ?? this.dateString,
      dayStartedAt: dayStartedAt ?? this.dayStartedAt,
      firstTrackedAt: firstTrackedAt ?? this.firstTrackedAt,
      lastTrackedAt: lastTrackedAt ?? this.lastTrackedAt,
      trackingCompletedAt: trackingCompletedAt ?? this.trackingCompletedAt,
      trackingSessionCount: trackingSessionCount ?? this.trackingSessionCount,
      eventCount: eventCount ?? this.eventCount,
      dayClosed: dayClosed ?? this.dayClosed,
      confirmedZero: confirmedZero ?? this.confirmedZero,
      coverageStatus: coverageStatus ?? this.coverageStatus,
      actualCigarettes: actualCigarettes ?? this.actualCigarettes,
      targetCigarettes: targetCigarettes ?? this.targetCigarettes,
      isSteady: isSteady ?? this.isSteady,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateString': dateString,
    'dayStartedAt': dayStartedAt?.toIso8601String(),
    'firstTrackedAt': firstTrackedAt?.toIso8601String(),
    'lastTrackedAt': lastTrackedAt?.toIso8601String(),
    'trackingCompletedAt': trackingCompletedAt?.toIso8601String(),
    'trackingSessionCount': trackingSessionCount,
    'eventCount': eventCount,
    'dayClosed': dayClosed,
    'confirmedZero': confirmedZero,
    'coverageStatus': coverageStatus.code,
    'actualCigarettes': actualCigarettes,
    'targetCigarettes': targetCigarettes,
    'isSteady': isSteady,
  };

  factory DailyCoverage.fromJson(Map<String, dynamic> json) => DailyCoverage(
    dateString: json['dateString'] as String,
    dayStartedAt: json['dayStartedAt'] != null
        ? DateTime.tryParse(json['dayStartedAt'] as String)
        : null,
    firstTrackedAt: json['firstTrackedAt'] != null
        ? DateTime.tryParse(json['firstTrackedAt'] as String)
        : null,
    lastTrackedAt: json['lastTrackedAt'] != null
        ? DateTime.tryParse(json['lastTrackedAt'] as String)
        : null,
    trackingCompletedAt: json['trackingCompletedAt'] != null
        ? DateTime.tryParse(json['trackingCompletedAt'] as String)
        : null,
    trackingSessionCount: json['trackingSessionCount'] as int? ?? 0,
    eventCount: json['eventCount'] as int? ?? 0,
    dayClosed: json['dayClosed'] as bool? ?? false,
    confirmedZero: json['confirmedZero'] as bool? ?? false,
    coverageStatus: CoverageStatusExtension.fromCode(json['coverageStatus'] as String?),
    actualCigarettes: json['actualCigarettes'] as int? ?? 0,
    targetCigarettes: json['targetCigarettes'] as int? ?? 0,
    isSteady: json['isSteady'] as bool? ?? false,
  );
}
