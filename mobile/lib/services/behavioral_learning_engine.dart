import 'dart:math' as math;
import '../models/craving_log.dart';
import '../models/smoking_log.dart';
import '../models/pattern_insight.dart';

class StrategySuccessRate {
  final String strategyName;
  final int totalAttempts;
  final int successfulDelays;
  final double successRate;

  const StrategySuccessRate({
    required this.strategyName,
    required this.totalAttempts,
    required this.successfulDelays,
    required this.successRate,
  });
}

class BehavioralLearningEngine {
  static const int minLogsForBasicPatterns = 4;
  static const int minLogsForDeepInsights = 7;

  /// Detects real patterns strictly from logged data (Section 18 & 20).
  /// If data is insufficient, returns an empty list or "still learning" status.
  static List<PatternInsight> analyzePatterns({
    required List<SmokingLog> smokingLogs,
    required List<CravingLog> cravingLogs,
  }) {
    final insights = <PatternInsight>[];
    final totalEvents = smokingLogs.length + cravingLogs.length;

    if (totalEvents < minLogsForBasicPatterns) {
      return insights; // Insufficient data: UI shows "We're still learning your pattern."
    }

    // 1. Time-of-day clustering (High-Risk Hours)
    final hourlyCounts = List<int>.filled(24, 0);
    for (final s in smokingLogs) {
      hourlyCounts[s.timestamp.hour]++;
    }
    for (final c in cravingLogs) {
      hourlyCounts[c.timestamp.hour]++;
    }

    int peakHour = -1;
    int maxHourCount = 0;
    for (int h = 0; h < 24; h++) {
      if (hourlyCounts[h] > maxHourCount) {
        maxHourCount = hourlyCounts[h];
        peakHour = h;
      }
    }

    if (maxHourCount >= 3 && peakHour >= 0) {
      final periodStart = '${peakHour % 12 == 0 ? 12 : peakHour % 12}:00 ${peakHour >= 12 ? 'PM' : 'AM'}';
      final endHour = (peakHour + 2) % 24;
      final periodEnd = '${endHour % 12 == 0 ? 12 : endHour % 12}:00 ${endHour >= 12 ? 'PM' : 'AM'}';
      final pct = ((maxHourCount / totalEvents) * 100).round();

      insights.add(
        PatternInsight(
          id: 'pattern_peak_hour',
          title: 'High-Risk Time Window',
          message: '$pct% of your smoking and craving urges cluster between $periodStart and $periodEnd.',
          category: 'high_risk',
          actionableAdvice: 'Setting a gentle delay intention 15 minutes before this window breaks the automatic loop.',
          iconName: 'alarm',
          dataPointsCount: maxHourCount,
          confidence: math.min(1.0, maxHourCount / 6.0),
        ),
      );
    }

    // 2. Trigger analysis
    final triggerCounts = <String, int>{};
    for (final s in smokingLogs) {
      if (s.trigger != null && s.trigger!.isNotEmpty) {
        triggerCounts[s.trigger!] = (triggerCounts[s.trigger!] ?? 0) + 1;
      }
    }
    for (final c in cravingLogs) {
      if (c.trigger.isNotEmpty) {
        triggerCounts[c.trigger] = (triggerCounts[c.trigger] ?? 0) + 1;
      }
    }

    if (triggerCounts.isNotEmpty) {
      String topTrigger = '';
      int maxTriggerCount = 0;
      triggerCounts.forEach((k, v) {
        if (v > maxTriggerCount) {
          maxTriggerCount = v;
          topTrigger = k;
        }
      });

      if (maxTriggerCount >= 3) {
        final pct = ((maxTriggerCount / totalEvents) * 100).round();
        insights.add(
          PatternInsight(
            id: 'pattern_top_trigger',
            title: 'Dominant Habit Trigger',
            message: '"$topTrigger" is present in $pct% of your logged urges.',
            category: 'trigger',
            actionableAdvice: 'Notice the physical cue when "$topTrigger" arises. Pausing to take 5 slow breaths decouples the automatic action.',
            iconName: 'psychology',
            dataPointsCount: maxTriggerCount,
            confidence: math.min(1.0, maxTriggerCount / 6.0),
          ),
        );
      }
    }

    // 3. Delay & Intervention Success (Section 23: "What worked for you?")
    final completedCravings = cravingLogs.where((c) => c.delayedMinutesCompleted > 0 || c.wasOvercome).toList();
    if (completedCravings.length >= 3) {
      final successful = completedCravings.where((c) => c.wasOvercome).length;
      final rate = ((successful / completedCravings.length) * 100).round();

      insights.add(
        PatternInsight(
          id: 'pattern_delay_success',
          title: 'Craving Resilience',
          message: 'You have successfully overcome or delayed $rate% of cravings you consciously intervened on.',
          category: 'progress',
          actionableAdvice: 'Every conscious delay retrains dopamine pathways away from automatic lighting.',
          iconName: 'timer',
          dataPointsCount: completedCravings.length,
          confidence: math.min(1.0, completedCravings.length / 5.0),
        ),
      );
    }

    return insights;
  }

  /// Calculates "What Worked For You" strategy rankings (Section 23)
  static List<StrategySuccessRate> getStrategySuccessRankings(List<CravingLog> cravingLogs) {
    final strategyMap = <String, List<bool>>{};

    for (final c in cravingLogs) {
      final action = c.microAction ?? 'Conscious Delay';
      strategyMap.putIfAbsent(action, () => []).add(c.wasOvercome);
    }

    final rankings = <StrategySuccessRate>[];
    strategyMap.forEach((name, outcomes) {
      if (outcomes.isNotEmpty) {
        final successes = outcomes.where((s) => s).length;
        final rate = successes / outcomes.length;
        rankings.add(
          StrategySuccessRate(
            strategyName: name,
            totalAttempts: outcomes.length,
            successfulDelays: successes,
            successRate: rate,
          ),
        );
      }
    });

    rankings.sort((a, b) => b.successRate.compareTo(a.successRate));
    return rankings;
  }
}
