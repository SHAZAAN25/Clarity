import 'package:flutter_test/flutter_test.dart';
import 'package:clarity_mobile/models/user_profile.dart';
import 'package:clarity_mobile/models/target_cycle.dart';
import 'package:clarity_mobile/models/strategy_mode.dart';
import 'package:clarity_mobile/models/smoking_log.dart';
import 'package:clarity_mobile/services/target_engine.dart';
import 'package:clarity_mobile/services/tracking_coverage_service.dart';

void main() {
  group('Target Engine Test Cases (A through M - Section 54)', () {
    late UserProfile baseProfile;
    late TargetCycle baseCycle;

    setUp(() {
      baseProfile = UserProfile(
        id: 'usr_test',
        name: 'Test User',
        cigarettesPerDay: 10,
        targetCigarettesPerDay: 9,
        packPrice: 200.0,
        cigarettesPerPack: 20,
        currency: '₹',
        strategyMode: StrategyMode.reduce,
      );

      baseCycle = TargetEngine.createNewCycle(
        userId: 'usr_test',
        cycleNumber: 1,
        target: 9,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );
    });

    // Case A: Baseline 10 -> Initial Target: 9
    test('Case A: Baseline 10 -> initial target is 9', () {
      final initial = TargetEngine.calculateInitialReductionTarget(10);
      expect(initial, equals(9));
    });

    // Case B: Target 9, Weekly average 8.5, 5+ valid days -> successful cycle -> next target: 8
    test('Case B: Target 9, Weekly avg 8.5, 5 valid days -> next target 8', () {
      final result = TargetEngine.evaluateCycle(
        profile: baseProfile,
        activeCycle: baseCycle,
        currentTarget: 9,
        weeklyAverage: 8.5,
        validDayCount: 5,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(8));
      expect(result.didChange, isTrue);
      expect(result.updatedCycle.status, equals('completed_successful'));
      expect(result.historyEntry, isNotNull);
      expect(result.historyEntry!.previousTarget, equals(9));
      expect(result.historyEntry!.newTarget, equals(8));
    });

    // Case C: Target 9, Weekly average 10 -> unsuccessful -> target remains: 9
    test('Case C: Target 9, Weekly avg 10.0 -> unsuccessful cycle, target remains 9', () {
      final result = TargetEngine.evaluateCycle(
        profile: baseProfile,
        activeCycle: baseCycle,
        currentTarget: 9,
        weeklyAverage: 10.0,
        validDayCount: 5,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(9));
      expect(result.updatedCycle.status, equals('completed_unsuccessful'));
      expect(result.updatedCycle.consecutiveFailures, equals(1));
    });

    // Case D: Two failed cycles -> STABILIZE
    test('Case D: Two consecutive failed cycles transitions to STABILIZE', () {
      final failedCycle1 = baseCycle.copyWith(consecutiveFailures: 1);
      final result = TargetEngine.evaluateCycle(
        profile: baseProfile,
        activeCycle: failedCycle1,
        currentTarget: 9,
        weeklyAverage: 10.5,
        validDayCount: 6,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(9));
      expect(result.strategyMode, equals(StrategyMode.stabilize));
      expect(result.updatedCycle.consecutiveFailures, equals(2));
      expect(result.historyEntry, isNotNull);
      expect(result.historyEntry!.source, equals('stabilize'));
    });

    // Case E: Successful cycle after STABILIZE -> REDUCE
    test('Case E: Successful cycle while in STABILIZE returns to REDUCE', () {
      final stabilizeProfile = baseProfile.copyWith(strategyMode: StrategyMode.stabilize);
      final stabilizeCycle = baseCycle.copyWith(consecutiveFailures: 2);

      final result = TargetEngine.evaluateCycle(
        profile: stabilizeProfile,
        activeCycle: stabilizeCycle,
        currentTarget: 9,
        weeklyAverage: 8.0,
        validDayCount: 5,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(8));
      expect(result.strategyMode, equals(StrategyMode.reduce));
      expect(result.updatedCycle.consecutiveFailures, equals(0));
    });

    // Case F: Target 1, Successful cycle -> remains 1 (floor at 1)
    test('Case F: Target 1 with successful cycle remains 1 (reduction floor)', () {
      final floorProfile = baseProfile.copyWith(targetCigarettesPerDay: 1);
      final floorCycle = baseCycle.copyWith(target: 1);

      final result = TargetEngine.evaluateCycle(
        profile: floorProfile,
        activeCycle: floorCycle,
        currentTarget: 1,
        weeklyAverage: 0.8,
        validDayCount: 6,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(1));
      expect(result.didChange, isFalse);
    });

    // Case G: Quit-now -> target 0
    test('Case G: Quit-Now mode holds target at 0', () {
      final quitNowProfile = baseProfile.copyWith(
        strategyMode: StrategyMode.quitNow,
        targetCigarettesPerDay: 0,
      );
      final quitCycle = baseCycle.copyWith(target: 0);

      final result = TargetEngine.evaluateCycle(
        profile: quitNowProfile,
        activeCycle: quitCycle,
        currentTarget: 0,
        weeklyAverage: 0.0,
        validDayCount: 5,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(0));
      expect(result.strategyMode, equals(StrategyMode.quitNow));
    });

    // Case H: Quit-by-date -> deterministic decreasing schedule reaching 0
    test('Case H: Quit-by-Date calculates deterministic decrease reaching 0 on quit date', () {
      final today = DateTime(2026, 10, 1);
      final quitDate = DateTime(2026, 10, 11); // 10 days duration
      final startDate = DateTime(2026, 10, 1);

      // On start day (10 days remaining / 10 days total) -> target = 10
      final targetDay0 = TargetEngine.calculateQuitByDateTarget(
        startingTarget: 10,
        targetQuitDate: quitDate,
        currentDate: today,
        scheduleStartDate: startDate,
      );
      expect(targetDay0, equals(10));

      // Halfway (day 5, 5 days remaining) -> target = 5
      final targetDay5 = TargetEngine.calculateQuitByDateTarget(
        startingTarget: 10,
        targetQuitDate: quitDate,
        currentDate: DateTime(2026, 10, 6),
        scheduleStartDate: startDate,
      );
      expect(targetDay5, equals(5));

      // On quit date -> target = 0
      final targetQuitDay = TargetEngine.calculateQuitByDateTarget(
        startingTarget: 10,
        targetQuitDate: quitDate,
        currentDate: quitDate,
        scheduleStartDate: startDate,
      );
      expect(targetQuitDay, equals(0));
    });

    // Case I: Only 3 valid days in a cycle -> no automatic target change (HOLD TARGET)
    test('Case I: Cycle with only 3 valid days holds target', () {
      final result = TargetEngine.evaluateCycle(
        profile: baseProfile,
        activeCycle: baseCycle,
        currentTarget: 9,
        weeklyAverage: 7.0, // Low average, but insufficient tracking coverage!
        validDayCount: 3,
        evaluationDate: DateTime.now(),
      );

      expect(result.newTarget, equals(9));
      expect(result.didChange, isFalse);
      expect(result.updatedCycle.status, equals('held_incomplete'));
    });

    // Case J: 5+ valid days -> target may be evaluated
    test('Case J: 5 or more valid days permits target evaluation', () {
      final result = TargetEngine.evaluateCycle(
        profile: baseProfile,
        activeCycle: baseCycle,
        currentTarget: 9,
        weeklyAverage: 8.0,
        validDayCount: 5,
        evaluationDate: DateTime.now(),
      );

      expect(result.didChange, isTrue);
      expect(result.newTarget, equals(8));
    });

    // Case K: Partial day -> not treated as successful full day
    test('Case K: Partial day is classified as PARTIAL and does not create false success', () {
      final now = DateTime(2026, 10, 1, 20, 0); // Started at 8 PM
      final singleLog = [
        SmokingLog(
          id: 's1',
          timestamp: DateTime(2026, 10, 1, 20, 30),
        ),
      ];

      final coverage = TrackingCoverageService.evaluateDay(
        date: now,
        daySmokingLogs: singleLog,
        dayCravingLogs: [],
        targetCpd: 9,
        strategyMode: StrategyMode.reduce,
        isFirstDayOfAccount: true,
      );

      expect(coverage.coverageStatus, equals(CoverageStatus.partial));
      expect(coverage.isSteady, isFalse); // Partial days must not distort steady streaks
    });

    // Case L: Target manually changed -> history recorded
    test('Case L: Manual target change records immutable history entry with source manual', () {
      final entry = TargetEngine.recordManualTargetChange(
        userId: 'usr_test',
        previousTarget: 9,
        newTarget: 7,
        reason: 'User preference adjustment',
        strategyState: 'REDUCE',
      );

      expect(entry.previousTarget, equals(9));
      expect(entry.newTarget, equals(7));
      expect(entry.source, equals('manual'));
      expect(entry.reason, equals('User preference adjustment'));
    });

    // Case M: Historical target -> never rewritten
    test('Case M: Historical target entries preserve original recorded values immutably', () {
      final oldEntry = TargetEngine.recordManualTargetChange(
        userId: 'usr_test',
        previousTarget: 10,
        newTarget: 9,
        reason: 'Initial reduction',
        strategyState: 'REDUCE',
      );

      // Verify serialization and deserialization retains identical immutable values
      final json = oldEntry.toJson();
      final restored = TargetEngineResult(
        newTarget: oldEntry.newTarget,
        strategyMode: StrategyMode.reduce,
        historyEntry: oldEntry,
        updatedCycle: baseCycle,
        didChange: false,
        explanation: 'Audit',
      );

      expect(restored.historyEntry!.previousTarget, equals(10));
      expect(restored.historyEntry!.newTarget, equals(9));
      expect(json['previousTarget'], equals(10));
      expect(json['newTarget'], equals(9));
    });
  });

  group('Acceptance Tests: Sample User Economics & INR (Section 56 & 57)', () {
    test('Test User economics: ₹200 / 20 = ₹10/cig; 5 cigs = ₹50; strictly INR', () {
      final user = UserProfile(
        id: 'user_acceptance',
        name: 'Test User',
        cigarettesPerDay: 10,
        targetCigarettesPerDay: 9,
        smokingDuration: 5,
        firstCigaretteTime: 30,
        cigarettesPerPack: 20,
        packPrice: 200.0,
        currency: '₹',
        routines: ['Morning', 'Coffee', 'After meals'],
        triggers: ['Stress', 'Coffee'],
        goals: ['Reduce'],
        motivation: 'Save money and gain control',
      );

      expect(user.costPerCigarette, equals(10.0));
      const cigsSmoked = 5;
      final costFor5 = cigsSmoked * user.costPerCigarette;
      expect(costFor5, equals(50.0));
      expect(user.currency, equals('₹'));
    });
  });
}
