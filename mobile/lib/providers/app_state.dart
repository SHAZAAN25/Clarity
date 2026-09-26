import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/smoking_log.dart';
import '../models/craving_log.dart';
import '../models/reduction_plan.dart';
import '../models/personal_record.dart';
import '../models/experiment.dart';
import '../models/pattern_insight.dart';
import '../models/money_stats.dart';
import '../models/health_milestone.dart';
import '../models/strategy_mode.dart';
import '../models/target_history_entry.dart';
import '../models/target_cycle.dart';
import '../models/daily_coverage.dart';
import '../services/storage_service.dart';
import '../services/target_engine.dart';
import '../services/tracking_coverage_service.dart';
import '../services/notification_service.dart';
import '../services/smart_delay_engine.dart';
import '../services/behavioral_learning_engine.dart';
import '../services/reduction_engine.dart';
import '../services/sync_service.dart';

class AppState extends ChangeNotifier {
  UserProfile _profile = UserProfile(
    id: 'user_local',
    email: '',
    name: '',
    cigarettesPerDay: 0,
    targetCigarettesPerDay: 0,
    packPrice: 200.0,
    cigarettesPerPack: 20,
    currency: '₹',
    currentDelayMinutes: 7,
    onboardingCompleted: false,
    isAuthenticated: false,
    steadyStreak: 0,
    strategyMode: StrategyMode.reduce,
  );

  List<SmokingLog> _smokingLogs = [];
  List<CravingLog> _cravingLogs = [];
  List<BehavioralExperiment> _experiments = [];
  PersonalRecords _personalRecords = const PersonalRecords();
  List<TargetHistoryEntry> _targetHistory = [];
  List<TargetCycle> _targetCycles = [];
  List<DailyCoverage> _dailyCoverage = [];
  String _authToken = '';
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.dark;

  // Authoritative getters
  UserProfile get profile => _profile;
  List<SmokingLog> get smokingLogs => List.unmodifiable(_smokingLogs);
  List<CravingLog> get cravingLogs => List.unmodifiable(_cravingLogs);
  List<BehavioralExperiment> get experiments => List.unmodifiable(_experiments);
  PersonalRecords get personalRecords => _personalRecords;
  List<TargetHistoryEntry> get targetHistory => List.unmodifiable(_targetHistory);
  List<TargetCycle> get targetCycles => List.unmodifiable(_targetCycles);
  List<DailyCoverage> get dailyCoverage => List.unmodifiable(_dailyCoverage);
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  bool get isOnboarded => _profile.onboardingCompleted;
  String get authToken => _authToken;

  TargetCycle? get activeCycle {
    if (_targetCycles.isEmpty) return null;
    return _targetCycles.firstWhere(
      (c) => c.status == 'active',
      orElse: () => _targetCycles.last,
    );
  }

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await NotificationService.initialize();

    final data = await StorageService.loadData();
    if (data.containsKey('profile') && data['profile'] is Map) {
      _profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);

      if (data['smokingLogs'] is List) {
        _smokingLogs = (data['smokingLogs'] as List)
            .map((e) => SmokingLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['cravingLogs'] is List) {
        _cravingLogs = (data['cravingLogs'] as List)
            .map((e) => CravingLog.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['experiments'] is List) {
        _experiments = (data['experiments'] as List)
            .map((e) => BehavioralExperiment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['records'] is Map) {
        _personalRecords =
            PersonalRecords.fromJson(data['records'] as Map<String, dynamic>);
      }
      if (data['targetHistory'] is List) {
        _targetHistory = (data['targetHistory'] as List)
            .map((e) => TargetHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['targetCycles'] is List) {
        _targetCycles = (data['targetCycles'] as List)
            .map((e) => TargetCycle.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['dailyCoverage'] is List) {
        _dailyCoverage = (data['dailyCoverage'] as List)
            .map((e) => DailyCoverage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['themeMode'] == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
      _authToken = data['authToken'] as String? ?? '';
    } else {
      // Clean, un-onboarded initial state. No fake data! (Section 3 & 34)
      _smokingLogs = [];
      _cravingLogs = [];
      _targetHistory = [];
      _targetCycles = [];
      _dailyCoverage = [];
      _experiments = [];
      _personalRecords = const PersonalRecords();
    }

    // Refresh streak and coverage for today
    _recalculateSteadyStreak();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.saveData(
      profile: _profile,
      smokingLogs: _smokingLogs,
      cravingLogs: _cravingLogs,
      experiments: _experiments,
      records: _personalRecords,
      targetHistory: _targetHistory,
      targetCycles: _targetCycles,
      dailyCoverage: _dailyCoverage,
      themeMode: _themeMode == ThemeMode.light ? 'light' : 'dark',
      authToken: _authToken,
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      _persist();
    }
  }

  // --- Daily Metrics ---
  List<SmokingLog> get todaySmokingLogs {
    final now = DateTime.now();
    return _smokingLogs.where((log) {
      return log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day;
    }).toList();
  }

  int get todaySmokedCount => todaySmokingLogs.length;

  int get todayTargetCount {
    if (_profile.strategyMode == StrategyMode.quitNow) return 0;
    if (_profile.targetCigarettesPerDay > 0) return _profile.targetCigarettesPerDay;
    if (_profile.cigarettesPerDay > 0) {
      return TargetEngine.calculateInitialReductionTarget(_profile.cigarettesPerDay);
    }
    return 0;
  }

  int get todayRemainingCount => math.max(0, todayTargetCount - todaySmokedCount);

  // Section 34: Return 0 or honest avoided count
  int get cigarettesAvoidedToday {
    if (_profile.cigarettesPerDay <= 0) return 0;
    return math.max(0, _profile.cigarettesPerDay - todaySmokedCount);
  }

  DailyTargetStatus get todayStatus {
    if (_profile.strategyMode == StrategyMode.quitNow) {
      return todaySmokedCount == 0
          ? DailyTargetStatus.smokeFree
          : DailyTargetStatus.smoked;
    }
    return todaySmokedCount <= todayTargetCount
        ? DailyTargetStatus.withinTarget
        : DailyTargetStatus.aboveTarget;
  }

  int get steadyStreak => _profile.steadyStreak;

  int get successfulDelaysToday {
    final now = DateTime.now();
    final cravingDelays = _cravingLogs.where((c) {
      return c.timestamp.year == now.year &&
          c.timestamp.month == now.month &&
          c.timestamp.day == now.day &&
          (c.delayedMinutesCompleted > 0 || c.wasOvercome);
    }).length;
    final smokeDelays = todaySmokingLogs.where((s) => s.delayedFirst).length;
    return math.max(cravingDelays, smokeDelays);
  }

  double get hoursSinceLastSmoke {
    if (_smokingLogs.isEmpty) return 0.0;
    final sorted = List<SmokingLog>.from(_smokingLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final diff = DateTime.now().difference(sorted.first.timestamp);
    return math.max(0.05, diff.inMinutes / 60.0);
  }

  String get currentSmokingInterval {
    if (_smokingLogs.isEmpty) return 'No logs yet';
    final hours = hoursSinceLastSmoke;
    if (hours < 1.0) {
      final mins = (hours * 60).round();
      return '$mins min';
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  String get longestSmokeFreeGapToday {
    final todayLogs = List<SmokingLog>.from(todaySmokingLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (todayLogs.isEmpty) {
      final hours = hoursSinceLastSmoke;
      if (hours <= 0.0) return '0m';
      return '${hours.floor()}h ${((hours - hours.floor()) * 60).round()}m';
    }

    Duration maxGap = Duration.zero;
    final startOfDay = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day, 6, 0);

    if (todayLogs.first.timestamp.isAfter(startOfDay)) {
      maxGap = todayLogs.first.timestamp.difference(startOfDay);
    }

    for (int i = 0; i < todayLogs.length - 1; i++) {
      final gap = todayLogs[i + 1].timestamp.difference(todayLogs[i].timestamp);
      if (gap > maxGap) {
        maxGap = gap;
      }
    }

    final lastGap = DateTime.now().difference(todayLogs.last.timestamp);
    if (lastGap > maxGap) {
      maxGap = lastGap;
    }

    final h = maxGap.inHours;
    final m = maxGap.inMinutes % 60;
    return '${h}h ${m}m';
  }

  // --- Money Stats (Section 35: Strictly INR) ---
  MoneyStats get moneyStats {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weekLogsCount =
        _smokingLogs.where((l) => l.timestamp.isAfter(sevenDaysAgo)).length;

    return MoneyStats(
      packPriceInr: _profile.packPrice,
      packSize: _profile.cigarettesPerPack,
      cigarettesSmokedToday: todaySmokedCount,
      cigarettesAvoidedToday: cigarettesAvoidedToday,
      cigarettesSmokedThisWeek: weekLogsCount,
      baselineCpd: _profile.cigarettesPerDay > 0 ? _profile.cigarettesPerDay : 10,
      currencySymbol: '₹',
    );
  }

  double get totalMoneySaved => moneyStats.retainedToday;

  // --- Smart Adaptive Delay ---
  int get adaptiveDelayMinutes {
    return SmartDelayEngine.calculateOptimalDelay(
      cravingHistory: _cravingLogs,
      smokingHistory: _smokingLogs,
      cravingIntensity: 6,
      trigger: 'General',
      baselineIntervalMinutes: _profile.averageInterval,
    );
  }

  // --- Reduction Plan ---
  ReductionPlan get reductionPlan {
    return ReductionEngine.generatePlan(
      profile: _profile,
      smokingLogs: _smokingLogs,
      cravingLogs: _cravingLogs,
    );
  }

  // --- Behavioral Patterns (Real Data Only) ---
  List<PatternInsight> get patternInsights {
    return BehavioralLearningEngine.analyzePatterns(
      smokingLogs: _smokingLogs,
      cravingLogs: _cravingLogs,
    );
  }

  List<StrategySuccessRate> get strategyRankings {
    return BehavioralLearningEngine.getStrategySuccessRankings(_cravingLogs);
  }

  // --- Hourly Rhythm Breakdown (24h) ---
  Map<int, int> get hourlyRhythm {
    final map = <int, int>{};
    for (int h = 0; h < 24; h += 2) {
      map[h] = 0;
    }
    for (final log in todaySmokingLogs) {
      final hour = log.timestamp.hour;
      final bucket = (hour ~/ 2) * 2;
      map[bucket] = (map[bucket] ?? 0) + 1;
    }
    return map;
  }

  // --- Trigger Breakdown ---
  Map<String, int> get triggerBreakdown {
    final map = <String, int>{};
    for (final log in _smokingLogs) {
      if (log.trigger != null && log.trigger!.isNotEmpty) {
        map[log.trigger!] = (map[log.trigger!] ?? 0) + 1;
      }
    }
    for (final craving in _cravingLogs) {
      if (craving.trigger.isNotEmpty) {
        map[craving.trigger] = (map[craving.trigger] ?? 0) + 1;
      }
    }
    return map;
  }

  String get mostCommonTrigger {
    final breakdown = triggerBreakdown;
    if (breakdown.isEmpty) return 'No data yet';
    String topKey = 'None';
    int maxVal = -1;
    breakdown.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        topKey = key;
      }
    });
    return topKey;
  }

  // Section 21 & 53: Weekly average across valid tracked days
  double? get weeklyAverageCpd {
    final validDays = _dailyCoverage
        .where((d) => d.coverageStatus == CoverageStatus.valid)
        .toList();
    if (validDays.isEmpty) {
      return null;
    }
    final total = validDays.fold<int>(0, (sum, d) => sum + d.actualCigarettes);
    return total / validDays.length;
  }

  // --- Health Milestones ---
  List<HealthMilestone> get healthMilestones {
    final hours = hoursSinceLastSmoke;
    return [
      HealthMilestone.fromHoursSinceLastSmoke(
        'm1',
        'Pulse & Blood Pressure',
        '20 Minutes',
        'Heart rate and arterial pressure settle toward baseline resting values.',
        'World Health Organization (WHO)',
        1,
        hours,
      ),
      HealthMilestone.fromHoursSinceLastSmoke(
        'm2',
        'Blood Oxygen Normalization',
        '8 Hours',
        'Carbon monoxide drops by half; arterial oxygen saturation recovers.',
        'American Heart Association (AHA)',
        8,
        hours,
      ),
      HealthMilestone.fromHoursSinceLastSmoke(
        'm3',
        'Carbon Monoxide Clearance',
        '24 Hours',
        'Carbon monoxide is cleared from circulation; lungs begin clearing cellular debris.',
        'Centers for Disease Control (CDC)',
        24,
        hours,
      ),
      HealthMilestone.fromHoursSinceLastSmoke(
        'm4',
        'Sensory Nerve Regeneration',
        '48 Hours',
        'Olfactory and taste receptor endings begin structural regeneration.',
        'National Health Service (NHS)',
        48,
        hours,
      ),
      HealthMilestone.fromHoursSinceLastSmoke(
        'm5',
        'Bronchial Relaxation',
        '72 Hours',
        'Bronchial smooth muscle relaxes; breathing capacity and energy noticeably increase.',
        'CDC / Mayo Clinic',
        72,
        hours,
      ),
      HealthMilestone.fromHoursSinceLastSmoke(
        'm6',
        'Cardiovascular Circulation',
        '2 Weeks',
        'Peripheral blood circulation improves; physical exertion feels significantly lighter.',
        'Cochrane Tobacco Addiction Group',
        336,
        hours,
      ),
    ];
  }

  // --- Actions ---

  /// Section 13: Log cigarette event with full event model & offline resilience
  Future<void> logCigarette({
    String? trigger,
    String? routine,
    String? situation,
    String? mood,
    String? location,
    String? note,
    int? cravingIntensity,
    bool delayedFirst = false,
    int? delayMinutes,
    int? delayDuration,
  }) async {
    final now = DateTime.now();
    final log = SmokingLog(
      id: 'smoke_${now.millisecondsSinceEpoch}',
      userId: _profile.id,
      timestamp: now,
      source: delayedFirst ? 'delay_intervention' : 'quick_log',
      syncStatus: 'pending',
      createdAt: now,
      trigger: trigger,
      routine: routine,
      situation: situation,
      mood: mood,
      location: location,
      note: note,
      cravingIntensity: cravingIntensity,
      delayedFirst: delayedFirst,
      delayMinutes: delayMinutes,
      delayDuration: delayDuration,
      isSynced: false,
    );

    _smokingLogs.insert(0, log);

    _updateTodayCoverage();
    _recalculateSteadyStreak();
    _checkAndUpdateRecords();

    notifyListeners();
    await _persist();

    // Async sync with backend
    SyncService.pushSmokingEvent(log: log, authToken: _authToken).then((success) {
      if (success) {
        final idx = _smokingLogs.indexWhere((l) => l.id == log.id);
        if (idx >= 0) {
          _smokingLogs[idx] = _smokingLogs[idx].copyWith(syncStatus: 'synced', isSynced: true);
          _persist();
        }
      }
    });
  }

  Future<void> logCraving({
    required String trigger,
    required int intensity,
    String? microAction,
    int delayedMinutes = 0,
    int? delayedMinutesCompleted,
    String outcome = 'craving_passed',
    bool? didSmoke,
  }) async {
    final now = DateTime.now();
    final effectiveDelay = delayedMinutesCompleted ?? delayedMinutes;

    final craving = CravingLog(
      id: 'crav_${now.millisecondsSinceEpoch}',
      timestamp: now,
      trigger: trigger,
      intensity: intensity,
      microAction: microAction,
      delayedMinutesCompleted: effectiveDelay,
      outcome: outcome,
      didSmoke: didSmoke,
      isSynced: false,
    );

    _cravingLogs.insert(0, craving);

    _updateTodayCoverage();
    _checkAndUpdateRecords();

    notifyListeners();
    await _persist();

    SyncService.pushCravingEvent(log: craving, authToken: _authToken).then((success) {
      if (success) {
        final idx = _cravingLogs.indexWhere((c) => c.id == craving.id);
        if (idx >= 0) {
          _cravingLogs[idx] = _cravingLogs[idx].copyWith(isSynced: true);
          _persist();
        }
      }
    });
  }

  /// Updates or registers today's coverage state
  void _updateTodayCoverage() {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final coverage = TrackingCoverageService.evaluateDay(
      date: now,
      daySmokingLogs: todaySmokingLogs,
      dayCravingLogs: _cravingLogs.where((c) {
        return c.timestamp.year == now.year &&
            c.timestamp.month == now.month &&
            c.timestamp.day == now.day;
      }).toList(),
      targetCpd: todayTargetCount,
      strategyMode: _profile.strategyMode,
      dayExplicitlyClosed: false,
    );

    final idx = _dailyCoverage.indexWhere((d) => d.dateString == dateStr);
    if (idx >= 0) {
      _dailyCoverage[idx] = coverage;
    } else {
      _dailyCoverage.add(coverage);
    }
  }

  /// Recalculates consecutive steady days across completed valid past days (Section 33)
  void _recalculateSteadyStreak() {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Past completed days only
    final pastDays = _dailyCoverage
        .where((d) => d.dateString.compareTo(todayStr) < 0)
        .toList()
      ..sort((a, b) => a.dateString.compareTo(b.dateString));

    final streak = TrackingCoverageService.calculateSteadyStreak(
      pastDaysAscending: pastDays,
      strategyMode: _profile.strategyMode,
    );

    _profile = _profile.copyWith(steadyStreak: streak);
  }

  void _checkAndUpdateRecords() {
    final hours = hoursSinceLastSmoke;
    final avoided = cigarettesAvoidedToday;
    final delays = successfulDelaysToday;
    final cravingsOvercome = _cravingLogs.where((c) {
      final now = DateTime.now();
      return c.timestamp.year == now.year &&
          c.timestamp.month == now.month &&
          c.timestamp.day == now.day &&
          c.wasOvercome;
    }).length;

    _personalRecords = _personalRecords.copyWith(
      longestSmokeFreeHours:
          math.max(_personalRecords.longestSmokeFreeHours, hours),
      mostCigarettesAvoidedDay:
          math.max(_personalRecords.mostCigarettesAvoidedDay, avoided),
      mostSuccessfulDelaysDay:
          math.max(_personalRecords.mostSuccessfulDelaysDay, delays),
      mostCravingsOvercomeDay:
          math.max(_personalRecords.mostCravingsOvercomeDay, cravingsOvercome),
    );
  }

  /// Section 5 & 16 & 17: Complete mandatory onboarding with deterministic initial reduction target
  Future<void> completeOnboarding({
    String? name,
    required int baselineCpd,
    required int yearsSmoked,
    required int ageStarted,
    required int firstCigAfterWakingMins,
    required int typicalIntervalMins,
    required int packSize,
    required double packPriceInr,
    required List<String> routines,
    required List<String> triggers,
    required List<String> goals,
    required String motivation,
    StrategyMode strategyMode = StrategyMode.reduce,
    DateTime? targetQuitDate,
  }) async {
    // Section 17: initialTarget = ceil(effectiveBaseline * 0.90)
    final initialTarget = strategyMode == StrategyMode.quitNow
        ? 0
        : TargetEngine.calculateInitialReductionTarget(baselineCpd);

    final now = DateTime.now();
    final firstCycle = TargetEngine.createNewCycle(
      userId: _profile.id,
      cycleNumber: 1,
      target: initialTarget,
      startDate: now,
    );

    final initialHistory = TargetHistoryEntry(
      id: 'th_init_${now.millisecondsSinceEpoch}',
      userId: _profile.id,
      previousTarget: baselineCpd,
      newTarget: initialTarget,
      effectiveDate: now,
      reason: 'Initial questionnaire baseline reduction setup',
      source: 'initial',
      strategyState: strategyMode.code,
      cycleId: firstCycle.cycleId,
      createdAt: now,
    );

    _profile = _profile.copyWith(
      name: name?.trim() ?? '',
      cigarettesPerDay: baselineCpd,
      targetCigarettesPerDay: initialTarget,
      smokingDuration: yearsSmoked,
      ageStarted: ageStarted,
      firstCigaretteTime: firstCigAfterWakingMins,
      averageInterval: typicalIntervalMins,
      cigarettesPerPack: packSize,
      packPrice: packPriceInr,
      currency: '₹', // Strictly INR
      routines: routines,
      triggers: triggers,
      goals: goals,
      motivation: motivation,
      currentDelayMinutes: 7,
      onboardingCompleted: true,
      isAuthenticated: true,
      strategyMode: strategyMode,
      targetQuitDate: targetQuitDate,
      steadyStreak: 0, // Starts at 0 until real valid days completed (Section 34)
    );

    _targetCycles = [firstCycle];
    _targetHistory = [initialHistory];
    _updateTodayCoverage();

    notifyListeners();
    await _persist();
  }

  /// Section 30: Manual Target Changes
  /// Records immutable target history entry
  Future<void> updateGoal({
    required int targetCpd,
    int? delayMinutes,
    String reason = 'Manual target adjustment',
  }) async {
    final prev = _profile.targetCigarettesPerDay;
    final entry = TargetEngine.recordManualTargetChange(
      userId: _profile.id,
      previousTarget: prev,
      newTarget: targetCpd,
      reason: reason,
      strategyState: _profile.strategyMode.code,
    );

    _targetHistory.insert(0, entry);
    _profile = _profile.copyWith(
      targetCigarettesPerDay: targetCpd,
      currentDelayMinutes: delayMinutes ?? _profile.currentDelayMinutes,
    );

    notifyListeners();
    await _persist();
  }

  /// Updates strategy mode (REDUCE, QUIT_BY_DATE, QUIT_NOW, STABILIZE)
  Future<void> setStrategyMode(StrategyMode mode, {DateTime? quitDate}) async {
    int target = _profile.targetCigarettesPerDay;
    if (mode == StrategyMode.quitNow) {
      target = 0;
    } else if (mode == StrategyMode.quitByDate && quitDate != null) {
      target = TargetEngine.calculateQuitByDateTarget(
        startingTarget: _profile.cigarettesPerDay,
        targetQuitDate: quitDate,
        currentDate: DateTime.now(),
        scheduleStartDate: DateTime.now(),
      );
    }

    final entry = TargetHistoryEntry(
      id: 'th_mode_${DateTime.now().millisecondsSinceEpoch}',
      userId: _profile.id,
      previousTarget: _profile.targetCigarettesPerDay,
      newTarget: target,
      effectiveDate: DateTime.now(),
      reason: 'Strategy mode shifted to ${mode.label}',
      source: 'strategy_shift',
      strategyState: mode.code,
      createdAt: DateTime.now(),
    );

    _targetHistory.insert(0, entry);
    _profile = _profile.copyWith(
      strategyMode: mode,
      targetQuitDate: quitDate,
      targetCigarettesPerDay: target,
    );

    notifyListeners();
    await _persist();
  }

  /// Section 25, 26, 27, 28: Evaluates 7-day target cycle deterministically
  Future<TargetEngineResult> evaluateCycle() async {
    final currentCycle = activeCycle ??
        TargetEngine.createNewCycle(
          userId: _profile.id,
          cycleNumber: _targetCycles.length + 1,
          target: _profile.targetCigarettesPerDay,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
        );

    final validDays = _dailyCoverage
        .where((d) => d.coverageStatus == CoverageStatus.valid)
        .toList();
    final validCount = validDays.length;
    final avg = weeklyAverageCpd ?? _profile.targetCigarettesPerDay.toDouble();

    final result = TargetEngine.evaluateCycle(
      profile: _profile,
      activeCycle: currentCycle,
      currentTarget: _profile.targetCigarettesPerDay,
      weeklyAverage: avg,
      validDayCount: validCount,
      evaluationDate: DateTime.now(),
    );

    if (result.historyEntry != null) {
      _targetHistory.insert(0, result.historyEntry!);
    }

    // Update active cycle
    final cIdx = _targetCycles.indexWhere((c) => c.cycleId == currentCycle.cycleId);
    if (cIdx >= 0) {
      _targetCycles[cIdx] = result.updatedCycle;
    } else {
      _targetCycles.add(result.updatedCycle);
    }

    // Create next active cycle if previous completed
    if (result.updatedCycle.status.startsWith('completed')) {
      final nextCycle = TargetEngine.createNewCycle(
        userId: _profile.id,
        cycleNumber: _targetCycles.length + 1,
        target: result.newTarget,
        startDate: DateTime.now(),
        consecutiveFailures: result.updatedCycle.consecutiveFailures,
      );
      _targetCycles.add(nextCycle);
    }

    _profile = _profile.copyWith(
      targetCigarettesPerDay: result.newTarget,
      strategyMode: result.strategyMode,
    );

    notifyListeners();
    await _persist();

    return result;
  }

  /// Updates profile details (smoking identity)
  Future<void> updateProfile({
    String? name,
    int? cigarettesPerDay,
    int? smokingDuration,
    int? firstCigaretteTime,
    int? averageInterval,
    double? packPrice,
    int? cigarettesPerPack,
    List<String>? routines,
    List<String>? triggers,
    List<String>? goals,
    String? motivation,
    int? targetCpd,
    DateTime? targetQuitDate,
    StrategyMode? strategyMode,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      cigarettesPerDay: cigarettesPerDay,
      smokingDuration: smokingDuration,
      firstCigaretteTime: firstCigaretteTime,
      averageInterval: averageInterval,
      packPrice: packPrice,
      cigarettesPerPack: cigarettesPerPack,
      routines: routines,
      triggers: triggers,
      goals: goals,
      motivation: motivation,
      targetCigarettesPerDay: targetCpd,
      targetQuitDate: targetQuitDate,
      strategyMode: strategyMode,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateBaseline({
    required int baselineCpd,
    required int yearsSmoked,
    required double packPrice,
    required int packSize,
  }) async {
    _profile = _profile.copyWith(
      cigarettesPerDay: baselineCpd,
      smokingDuration: yearsSmoked,
      packPrice: packPrice,
      cigarettesPerPack: packSize,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _profile = _profile.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleHighRiskAlerts(bool enabled) async {
    _profile = _profile.copyWith(highRiskAlertsEnabled: enabled);
    notifyListeners();
    await _persist();
  }

  Future<void> completeExperiment(
      String experimentId, bool wasHelpful, String note) async {
    final index = _experiments.indexWhere((e) => e.id == experimentId);
    if (index >= 0) {
      _experiments[index] = _experiments[index].copyWith(
        isCompleted: true,
        wasSuccessful: wasHelpful,
        reflectionNote: note,
      );
      notifyListeners();
      await _persist();
    }
  }

  /// Syncs all unsynchronized logs with server idempotently
  Future<SyncResult> syncWithServer() async {
    final res = await SyncService.syncPendingQueue(
      allSmokingLogs: _smokingLogs,
      allCravingLogs: _cravingLogs,
      authToken: _authToken,
    );
    notifyListeners();
    await _persist();
    return res;
  }

  /// Explicitly marks today's tracking as completed/closed (Section 21 & 23)
  Future<void> closeDay() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final coverage = TrackingCoverageService.evaluateDay(
      date: now,
      daySmokingLogs: todaySmokingLogs,
      dayCravingLogs: _cravingLogs.where((c) {
        return c.timestamp.year == now.year &&
            c.timestamp.month == now.month &&
            c.timestamp.day == now.day;
      }).toList(),
      targetCpd: todayTargetCount,
      strategyMode: _profile.strategyMode,
      dayExplicitlyClosed: true,
    );

    final idx = _dailyCoverage.indexWhere((d) => d.dateString == dateStr);
    if (idx >= 0) {
      _dailyCoverage[idx] = coverage;
    } else {
      _dailyCoverage.add(coverage);
    }

    _recalculateSteadyStreak();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteAccount() async {
    await StorageService.clearAll();
    _smokingLogs.clear();
    _cravingLogs.clear();
    _experiments.clear();
    _targetHistory.clear();
    _targetCycles.clear();
    _dailyCoverage.clear();
    _personalRecords = const PersonalRecords();
    _profile = UserProfile(
      id: 'user_local',
      email: '',
      name: '',
      cigarettesPerDay: 0,
      targetCigarettesPerDay: 0,
      packPrice: 200.0,
      cigarettesPerPack: 20,
      currency: '₹',
      currentDelayMinutes: 7,
      onboardingCompleted: false,
      isAuthenticated: false,
      steadyStreak: 0,
      strategyMode: StrategyMode.reduce,
    );
    notifyListeners();
  }
}
