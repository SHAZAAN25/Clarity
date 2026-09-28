import 'strategy_mode.dart';
import 'baseline_history.dart';

class UserProfile {
  final String id;
  final String email;
  final String name; // Authoritative name field
  final int questionnaireBaseline; // Reported during onboarding (never overwritten)
  final int? observedBaseline; // Median of 7 valid completed days
  final int cigarettesPerDay; // Effective baseline CPD
  final int targetCigarettesPerDay; // Authoritative active target CPD
  final int smokingDuration; // Years smoked
  final int ageStarted;
  final int firstCigaretteTime; // Minutes after waking
  final int averageInterval; // Typical minutes between cigarettes
  final double packPrice; // INR
  final int cigarettesPerPack; // Pack size
  final String currency; // Always '₹'
  final List<String> routines; // Daily smoking routines
  final List<String> triggers; // Smoking triggers
  final List<String> goals; // Primary cessation / reduction goals
  final String motivation; // Personal motivation
  final int currentDelayMinutes; // Adaptive delay capacity
  final bool onboardingCompleted; // Authoritative onboarding status
  final bool isAuthenticated;
  final StrategyMode strategyMode; // REDUCE, QUIT_BY_DATE, QUIT_NOW, STABILIZE
  final DateTime? targetQuitDate; // For QUIT_BY_DATE
  final int steadyStreak; // Authoritative streak of completed steady days
  final bool notificationsEnabled;
  final bool highRiskAlertsEnabled;
  final String baselineSource; // 'questionnaire', 'observed_average'
  final List<BaselineHistoryEntry> baselineHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.email = '',
    this.name = '',
    int? questionnaireBaseline,
    this.observedBaseline,
    int cigarettesPerDay = 0,
    this.targetCigarettesPerDay = 0,
    this.smokingDuration = 0,
    this.ageStarted = 18,
    this.firstCigaretteTime = 30,
    this.averageInterval = 60,
    this.packPrice = 200.0, // Default realistic INR pack price
    this.cigarettesPerPack = 20,
    this.currency = '₹', // Strictly INR
    this.routines = const [],
    this.triggers = const [],
    this.goals = const [],
    this.motivation = '',
    this.currentDelayMinutes = 7,
    this.onboardingCompleted = false,
    this.isAuthenticated = false,
    this.strategyMode = StrategyMode.reduce,
    this.targetQuitDate,
    this.steadyStreak = 0,
    this.notificationsEnabled = true,
    this.highRiskAlertsEnabled = true,
    this.baselineSource = 'questionnaire',
    this.baselineHistory = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : questionnaireBaseline = questionnaireBaseline ?? (cigarettesPerDay > 0 ? cigarettesPerDay : 0),
        cigarettesPerDay = observedBaseline ?? (cigarettesPerDay > 0 ? cigarettesPerDay : (questionnaireBaseline ?? 0)),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Backward-compatible accessors for legacy code
  String get displayName => name;
  int get baselineCpd => cigarettesPerDay;
  int get targetCpd => targetCigarettesPerDay;
  int get effectiveBaseline => observedBaseline ?? questionnaireBaseline;
  int get yearsSmoked => smokingDuration;
  int get firstCigaretteAfterWakingMinutes => firstCigaretteTime;
  int get typicalIntervalMinutes => averageInterval;
  int get packSize => cigarettesPerPack;
  List<String> get smokingRoutines => routines;
  bool get isOnboarded => onboardingCompleted;
  int get streakDays => steadyStreak;

  double get costPerCigarette =>
      packPrice / (cigarettesPerPack > 0 ? cigarettesPerPack : 20);

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? questionnaireBaseline,
    int? observedBaseline,
    int? cigarettesPerDay,
    int? targetCigarettesPerDay,
    int? smokingDuration,
    int? ageStarted,
    int? firstCigaretteTime,
    int? averageInterval,
    double? packPrice,
    int? cigarettesPerPack,
    String? currency,
    List<String>? routines,
    List<String>? triggers,
    List<String>? goals,
    String? motivation,
    int? currentDelayMinutes,
    bool? onboardingCompleted,
    bool? isAuthenticated,
    StrategyMode? strategyMode,
    DateTime? targetQuitDate,
    int? steadyStreak,
    bool? notificationsEnabled,
    bool? highRiskAlertsEnabled,
    String? baselineSource,
    List<BaselineHistoryEntry>? baselineHistory,
    DateTime? updatedAt,
    // Support legacy names in copyWith
    String? displayName,
    int? baselineCpd,
    int? targetCpd,
    int? yearsSmoked,
    int? firstCigaretteAfterWakingMinutes,
    int? typicalIntervalMinutes,
    int? packSize,
    List<String>? smokingRoutines,
    bool? isOnboarded,
    int? streakDays,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? displayName ?? this.name,
      questionnaireBaseline: questionnaireBaseline ?? this.questionnaireBaseline,
      observedBaseline: observedBaseline ?? this.observedBaseline,
      cigarettesPerDay: cigarettesPerDay ?? baselineCpd ?? this.cigarettesPerDay,
      targetCigarettesPerDay: targetCigarettesPerDay ?? targetCpd ?? this.targetCigarettesPerDay,
      smokingDuration: smokingDuration ?? yearsSmoked ?? this.smokingDuration,
      ageStarted: ageStarted ?? this.ageStarted,
      firstCigaretteTime: firstCigaretteTime ?? firstCigaretteAfterWakingMinutes ?? this.firstCigaretteTime,
      averageInterval: averageInterval ?? typicalIntervalMinutes ?? this.averageInterval,
      packPrice: packPrice ?? this.packPrice,
      cigarettesPerPack: cigarettesPerPack ?? packSize ?? this.cigarettesPerPack,
      currency: '₹', // Strictly INR
      routines: routines ?? smokingRoutines ?? this.routines,
      triggers: triggers ?? this.triggers,
      goals: goals ?? this.goals,
      motivation: motivation ?? this.motivation,
      currentDelayMinutes: currentDelayMinutes ?? this.currentDelayMinutes,
      onboardingCompleted: onboardingCompleted ?? isOnboarded ?? this.onboardingCompleted,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      strategyMode: strategyMode ?? this.strategyMode,
      targetQuitDate: targetQuitDate ?? this.targetQuitDate,
      steadyStreak: steadyStreak ?? streakDays ?? this.steadyStreak,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      highRiskAlertsEnabled: highRiskAlertsEnabled ?? this.highRiskAlertsEnabled,
      baselineSource: baselineSource ?? this.baselineSource,
      baselineHistory: baselineHistory ?? this.baselineHistory,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'displayName': name,
    'questionnaireBaseline': questionnaireBaseline,
    'observedBaseline': observedBaseline,
    'cigarettesPerDay': cigarettesPerDay,
    'baselineCpd': cigarettesPerDay,
    'targetCigarettesPerDay': targetCigarettesPerDay,
    'targetCpd': targetCigarettesPerDay,
    'smokingDuration': smokingDuration,
    'yearsSmoked': smokingDuration,
    'ageStarted': ageStarted,
    'firstCigaretteTime': firstCigaretteTime,
    'firstCigaretteAfterWakingMinutes': firstCigaretteTime,
    'averageInterval': averageInterval,
    'typicalIntervalMinutes': averageInterval,
    'packPrice': packPrice,
    'cigarettesPerPack': cigarettesPerPack,
    'packSize': cigarettesPerPack,
    'currency': '₹',
    'routines': routines,
    'smokingRoutines': routines,
    'triggers': triggers,
    'goals': goals,
    'motivation': motivation,
    'currentDelayMinutes': currentDelayMinutes,
    'onboardingCompleted': onboardingCompleted,
    'isOnboarded': onboardingCompleted,
    'isAuthenticated': isAuthenticated,
    'strategyMode': strategyMode.code,
    'targetQuitDate': targetQuitDate?.toIso8601String(),
    'steadyStreak': steadyStreak,
    'streakDays': steadyStreak,
    'notificationsEnabled': notificationsEnabled,
    'highRiskAlertsEnabled': highRiskAlertsEnabled,
    'baselineSource': baselineSource,
    'baselineHistory': baselineHistory.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final cpd = (json['cigarettesPerDay'] ?? json['baselineCpd']) as int? ?? 0;
    final qBaseline = json['questionnaireBaseline'] as int? ?? cpd;
    final oBaseline = json['observedBaseline'] as int?;
    final target = (json['targetCigarettesPerDay'] ?? json['targetCpd']) as int? ?? 0;
    final duration = (json['smokingDuration'] ?? json['yearsSmoked']) as int? ?? 0;
    final firstTime = (json['firstCigaretteTime'] ?? json['firstCigaretteAfterWakingMinutes']) as int? ?? 30;
    final interval = (json['averageInterval'] ?? json['typicalIntervalMinutes']) as int? ?? 60;
    final pSize = (json['cigarettesPerPack'] ?? json['packSize']) as int? ?? 20;
    final rawRoutines = (json['routines'] ?? json['smokingRoutines']) as List<dynamic>?;
    final routinesList = rawRoutines?.map((e) => e.toString()).toList() ?? const <String>[];
    final isOnboard = (json['onboardingCompleted'] ?? json['isOnboarded']) as bool? ?? false;
    final streak = (json['steadyStreak'] ?? json['streakDays']) as int? ?? 0;
    final rawName = (json['name'] ?? json['displayName']) as String? ?? '';

    List<BaselineHistoryEntry> bHistory = [];
    if (json['baselineHistory'] is List) {
      bHistory = (json['baselineHistory'] as List)
          .map((e) => BaselineHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return UserProfile(
      id: json['id'] as String? ?? 'usr_local',
      email: json['email'] as String? ?? '',
      name: rawName,
      questionnaireBaseline: qBaseline,
      observedBaseline: oBaseline,
      cigarettesPerDay: cpd,
      targetCigarettesPerDay: target,
      smokingDuration: duration,
      ageStarted: json['ageStarted'] as int? ?? 18,
      firstCigaretteTime: firstTime,
      averageInterval: interval,
      packPrice: (json['packPrice'] as num?)?.toDouble() ?? 200.0,
      cigarettesPerPack: pSize > 0 ? pSize : 20,
      currency: '₹', // Strictly INR
      routines: routinesList,
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      motivation: json['motivation'] as String? ?? '',
      currentDelayMinutes: json['currentDelayMinutes'] as int? ?? 7,
      onboardingCompleted: isOnboard,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      strategyMode: StrategyModeExtension.fromCode(json['strategyMode'] as String?),
      targetQuitDate: json['targetQuitDate'] != null
          ? DateTime.tryParse(json['targetQuitDate'] as String)
          : null,
      steadyStreak: streak,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      highRiskAlertsEnabled: json['highRiskAlertsEnabled'] as bool? ?? true,
      baselineSource: json['baselineSource'] as String? ?? 'questionnaire',
      baselineHistory: bHistory,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
