import 'dart:math' as math;
import '../models/user_profile.dart';
import '../models/target_history_entry.dart';
import '../models/target_cycle.dart';
import '../models/strategy_mode.dart';

class TargetEngineResult {
  final int newTarget;
  final StrategyMode strategyMode;
  final TargetHistoryEntry? historyEntry;
  final TargetCycle updatedCycle;
  final bool didChange;
  final String explanation;

  const TargetEngineResult({
    required this.newTarget,
    required this.strategyMode,
    this.historyEntry,
    required this.updatedCycle,
    required this.didChange,
    required this.explanation,
  });
}

class TargetEngine {
  /// Section 17: Initial Reduction Target
  /// initialTarget = ceil(effectiveBaseline * 0.90)
  /// Constraints: 1 <= initialTarget <= effectiveBaseline
  static int calculateInitialReductionTarget(int baseline) {
    if (baseline <= 0) return 1;
    final target = (baseline * 0.90).ceil();
    return target.clamp(1, baseline);
  }

  /// Section 19: Quit-by-Date deterministic schedule
  /// Calculates linear decreasing daily ceiling from starting target down to 0 on targetQuitDate.
  static int calculateQuitByDateTarget({
    required int startingTarget,
    required DateTime targetQuitDate,
    required DateTime currentDate,
    required DateTime scheduleStartDate,
  }) {
    final start = DateTime(scheduleStartDate.year, scheduleStartDate.month, scheduleStartDate.day);
    final targetDate = DateTime(targetQuitDate.year, targetQuitDate.month, targetQuitDate.day);
    final current = DateTime(currentDate.year, currentDate.month, currentDate.day);

    if (current.isAfter(targetDate) || current.isAtSameMomentAs(targetDate)) {
      return 0;
    }

    final totalDays = targetDate.difference(start).inDays;
    if (totalDays <= 0) return 0;

    final daysRemaining = targetDate.difference(current).inDays;
    if (daysRemaining <= 0) return 0;

    // Linear decrease ceiling: starts at startingTarget on day 0, reaches 0 on quit date
    final fraction = daysRemaining / totalDays;
    final scheduled = (startingTarget * fraction).ceil();
    return scheduled.clamp(0, startingTarget);
  }

  /// Section 25 & 26 & 27 & 28: Weekly Target Evaluation
  /// 7-day cycle evaluation:
  /// - Requires at least 5 valid days. If < 5: HOLD TARGET.
  /// - If weeklyAverage <= currentTarget and validDayCount >= 5:
  ///     nextTarget = max(1, floor(currentTarget * 0.90))
  /// - If weeklyAverage > currentTarget:
  ///     target remains unchanged.
  /// - If 2 consecutive cycles fail: transition to STABILIZE mode.
  /// - After a successful cycle in STABILIZE: resume REDUCE mode.
  /// - Target floor for reduction is 1 (never drops to 0 automatically).
  static TargetEngineResult evaluateCycle({
    required UserProfile profile,
    required TargetCycle activeCycle,
    required int currentTarget,
    required double weeklyAverage,
    required int validDayCount,
    required DateTime evaluationDate,
  }) {
    // 1. Explicit Quit Modes outrank reduction cycles
    if (profile.strategyMode == StrategyMode.quitNow) {
      final cycle = activeCycle.copyWith(
        validDayCount: validDayCount,
        weeklyAverage: weeklyAverage,
        status: 'active',
      );
      return TargetEngineResult(
        newTarget: 0,
        strategyMode: StrategyMode.quitNow,
        updatedCycle: cycle,
        didChange: false,
        explanation: 'Active strategy is Smoke-Free (Quit Now). Target remains 0.',
      );
    }

    if (profile.strategyMode == StrategyMode.quitByDate && profile.targetQuitDate != null) {
      final scheduledTarget = calculateQuitByDateTarget(
        startingTarget: profile.targetCigarettesPerDay > 0
            ? profile.targetCigarettesPerDay
            : profile.cigarettesPerDay,
        targetQuitDate: profile.targetQuitDate!,
        currentDate: evaluationDate,
        scheduleStartDate: activeCycle.startDate,
      );
      final cycle = activeCycle.copyWith(
        validDayCount: validDayCount,
        weeklyAverage: weeklyAverage,
        status: 'completed_scheduled',
      );
      return TargetEngineResult(
        newTarget: scheduledTarget,
        strategyMode: StrategyMode.quitByDate,
        updatedCycle: cycle,
        didChange: scheduledTarget != currentTarget,
        explanation: 'Scheduled reduction toward quit date: target is $scheduledTarget.',
      );
    }

    // 2. Section 25: Insufficient valid days (< 5 days) -> HOLD TARGET
    if (validDayCount < 5) {
      final cycle = activeCycle.copyWith(
        validDayCount: validDayCount,
        weeklyAverage: weeklyAverage,
        status: 'held_incomplete',
      );
      return TargetEngineResult(
        newTarget: currentTarget,
        strategyMode: profile.strategyMode,
        updatedCycle: cycle,
        didChange: false,
        explanation:
            'Hold target: cycle had $validDayCount valid tracking days (5 required to evaluate changes).',
      );
    }

    // 3. Section 26: Successful cycle (weeklyAverage <= currentTarget and validDayCount >= 5)
    final isSuccessful = weeklyAverage <= currentTarget;

    if (isSuccessful) {
      // Floor at 1 for gradual reduction (Section 29)
      final calculatedNext = (currentTarget * 0.90).floor();
      final nextTarget = math.max(1, calculatedNext);
      final didChange = nextTarget != currentTarget;

      final updatedCycle = activeCycle.copyWith(
        validDayCount: validDayCount,
        weeklyAverage: weeklyAverage,
        status: 'completed_successful',
        consecutiveFailures: 0,
      );

      TargetHistoryEntry? entry;
      if (didChange) {
        entry = TargetHistoryEntry(
          id: 'th_${DateTime.now().millisecondsSinceEpoch}',
          userId: profile.id,
          previousTarget: currentTarget,
          newTarget: nextTarget,
          effectiveDate: evaluationDate,
          reason: 'Cycle completed successfully (avg ${weeklyAverage.toStringAsFixed(1)} <= $currentTarget)',
          source: 'cycle_reduction',
          strategyState: StrategyMode.reduce.code,
          cycleId: activeCycle.cycleId,
          createdAt: DateTime.now(),
        );
      }

      return TargetEngineResult(
        newTarget: nextTarget,
        strategyMode: StrategyMode.reduce, // Resumes normal reduction even if previously in STABILIZE
        historyEntry: entry,
        updatedCycle: updatedCycle,
        didChange: didChange,
        explanation: didChange
            ? 'Cycle achieved! Target reduced by 10% from $currentTarget to $nextTarget.'
            : 'Target reached the reduction floor of 1 cigarette/day.',
      );
    }

    // 4. Section 27 & 28: Unsuccessful cycle (weeklyAverage > currentTarget)
    final failures = activeCycle.consecutiveFailures + 1;
    final entersStabilize = failures >= 2;
    final newMode = entersStabilize ? StrategyMode.stabilize : profile.strategyMode;

    final updatedCycle = activeCycle.copyWith(
      validDayCount: validDayCount,
      weeklyAverage: weeklyAverage,
      status: 'completed_unsuccessful',
      consecutiveFailures: failures,
    );

    TargetHistoryEntry? entry;
    if (entersStabilize && profile.strategyMode != StrategyMode.stabilize) {
      entry = TargetHistoryEntry(
        id: 'th_${DateTime.now().millisecondsSinceEpoch}',
        userId: profile.id,
        previousTarget: currentTarget,
        newTarget: currentTarget,
        effectiveDate: evaluationDate,
        reason: 'Two consecutive unsuccessful cycles. Entering stabilization mode to build consistency.',
        source: 'stabilize',
        strategyState: StrategyMode.stabilize.code,
        cycleId: activeCycle.cycleId,
        createdAt: DateTime.now(),
      );
    }

    final reason = entersStabilize
        ? 'Target held at $currentTarget. Transitioning to Stabilization mode to regain consistency without pressure.'
        : 'Target remains unchanged at $currentTarget (avg ${weeklyAverage.toStringAsFixed(1)}). Keep tracking steadily.';

    return TargetEngineResult(
      newTarget: currentTarget,
      strategyMode: newMode,
      historyEntry: entry,
      updatedCycle: updatedCycle,
      didChange: entersStabilize && profile.strategyMode != StrategyMode.stabilize,
      explanation: reason,
    );
  }

  /// Section 30: Manual Target Changes
  /// Records immutable target history entry with source 'manual'
  static TargetHistoryEntry recordManualTargetChange({
    required String userId,
    required int previousTarget,
    required int newTarget,
    required String reason,
    required String strategyState,
  }) {
    return TargetHistoryEntry(
      id: 'th_man_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      previousTarget: previousTarget,
      newTarget: newTarget,
      effectiveDate: DateTime.now(),
      reason: reason.isNotEmpty ? reason : 'Manual adjustment by user',
      source: 'manual',
      strategyState: strategyState,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a new 7-day target cycle starting on local calendar boundary
  static TargetCycle createNewCycle({
    required String userId,
    required int cycleNumber,
    required int target,
    required DateTime startDate,
    int consecutiveFailures = 0,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(const Duration(days: 7));
    return TargetCycle(
      cycleId: 'cycle_${userId}_$cycleNumber',
      userId: userId,
      startDate: start,
      endDate: end,
      target: target,
      validDayCount: 0,
      weeklyAverage: null,
      status: 'active',
      consecutiveFailures: consecutiveFailures,
    );
  }
}
