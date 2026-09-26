import '../models/smoking_log.dart';
import '../models/craving_log.dart';
import '../models/daily_coverage.dart';
import '../models/strategy_mode.dart';

class TrackingCoverageService {
  /// Evaluates coverage for a single calendar day (YYYY-MM-DD)
  /// Rules:
  /// - If the day is completely in the future: UNKNOWN
  /// - If day has 0 logs and 0 tracking sessions: UNKNOWN
  /// - If user started tracking late in the day (e.g., first tracked after 18:00 on first day) without day closure: PARTIAL
  /// - If user has events or sessions spanning at least 6 hours, or logged >= 3 events, or explicitly marked day closed: VALID
  static DailyCoverage evaluateDay({
    required DateTime date,
    required List<SmokingLog> daySmokingLogs,
    required List<CravingLog> dayCravingLogs,
    required int targetCpd,
    required StrategyMode strategyMode,
    bool dayExplicitlyClosed = false,
    DateTime? trackingCompletedAt,
    bool confirmedZero = false,
    DateTime? firstSessionAt,
    DateTime? lastSessionAt,
    int sessionCount = 0,
    bool isFirstDayOfAccount = false,
  }) {
    final dateString =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final totalEvents = daySmokingLogs.length + dayCravingLogs.length;

    // Collect all timestamps for this day
    final allTimestamps = <DateTime>[];
    for (final s in daySmokingLogs) {
      allTimestamps.add(s.timestamp);
    }
    for (final c in dayCravingLogs) {
      allTimestamps.add(c.timestamp);
    }
    if (firstSessionAt != null) allTimestamps.add(firstSessionAt);
    if (lastSessionAt != null) allTimestamps.add(lastSessionAt);

    allTimestamps.sort();

    DateTime? firstTracked = allTimestamps.isNotEmpty ? allTimestamps.first : null;
    DateTime? lastTracked = allTimestamps.isNotEmpty ? allTimestamps.last : null;

    final actualCigarettes = daySmokingLogs.length;

    CoverageStatus status;

    if (confirmedZero) {
      // Section 29: Explicitly confirmed zero-cigarette day
      status = CoverageStatus.valid;
    } else if (allTimestamps.isEmpty && sessionCount == 0 && !dayExplicitlyClosed) {
      // Untracked day
      status = CoverageStatus.unknown;
    } else if (dayExplicitlyClosed) {
      // User explicitly closed/completed day
      status = CoverageStatus.valid;
    } else if (isFirstDayOfAccount && firstTracked != null && firstTracked.hour >= 18) {
      // Section 22: New user starts at 8 PM -> PARTIAL day
      status = CoverageStatus.partial;
    } else if (allTimestamps.isNotEmpty) {
      final spanHours = lastTracked!.difference(firstTracked!).inMinutes / 60.0;
      // Day is valid if tracked across >= 6 hours, or user has logged >= 3 events, or multiple sessions
      if (spanHours >= 6.0 || totalEvents >= 3 || sessionCount >= 3) {
        status = CoverageStatus.valid;
      } else {
        status = CoverageStatus.partial;
      }
    } else {
      status = CoverageStatus.partial;
    }

    // Steady evaluation only for valid or completed days
    bool isSteady = false;
    if (status == CoverageStatus.valid) {
      if (strategyMode == StrategyMode.quitNow) {
        isSteady = actualCigarettes == 0;
      } else {
        isSteady = actualCigarettes <= targetCpd;
      }
    }

    return DailyCoverage(
      dateString: dateString,
      dayStartedAt: firstSessionAt,
      firstTrackedAt: firstTracked,
      lastTrackedAt: lastTracked,
      trackingCompletedAt: trackingCompletedAt,
      trackingSessionCount: sessionCount > 0 ? sessionCount : (totalEvents > 0 ? 1 : 0),
      eventCount: totalEvents,
      dayClosed: dayExplicitlyClosed,
      confirmedZero: confirmedZero,
      coverageStatus: status,
      actualCigarettes: actualCigarettes,
      targetCigarettes: targetCpd,
      isSteady: isSteady,
    );
  }

  /// Calculates consecutive Steady streak across completed past valid days.
  /// Section 33:
  /// - Only completed VALID days count.
  /// - If a completed valid day exceeds active target: streak resets.
  /// - Untracked/Unknown days do NOT increment streak and do not falsely count as 0.
  static int calculateSteadyStreak({
    required List<DailyCoverage> pastDaysAscending,
    required StrategyMode strategyMode,
  }) {
    if (pastDaysAscending.isEmpty) return 0;

    int streak = 0;
    // Iterate from newest completed day backwards
    for (int i = pastDaysAscending.length - 1; i >= 0; i--) {
      final day = pastDaysAscending[i];

      if (day.coverageStatus != CoverageStatus.valid) {
        // Untracked or partial day: stops the active streak
        break;
      }

      final metCriterion = (strategyMode == StrategyMode.quitNow)
          ? day.actualCigarettes == 0
          : day.actualCigarettes <= day.targetCigarettes;

      if (metCriterion) {
        streak++;
      } else {
        // Exceeded target: streak broken
        break;
      }
    }
    return streak;
  }
}
