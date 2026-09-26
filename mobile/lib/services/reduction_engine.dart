import 'dart:math' as math;
import '../models/reduction_plan.dart';
import '../models/smoking_log.dart';
import '../models/craving_log.dart';
import '../models/user_profile.dart';

class ReductionEngine {
  /// Generates an adaptive, personalized reduction recommendation based on actual performance.
  static ReductionPlan generatePlan({
    required UserProfile profile,
    required List<SmokingLog> smokingLogs,
    required List<CravingLog> cravingLogs,
  }) {
    final baseline = profile.baselineCpd > 0 ? profile.baselineCpd : 10;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentLogs = smokingLogs.where((l) => l.timestamp.isAfter(sevenDaysAgo)).toList();

    double recentAvg = baseline.toDouble();
    if (recentLogs.isNotEmpty) {
      recentAvg = recentLogs.length / 7.0;
    }

    final targetCpd = profile.targetCpd > 0 ? profile.targetCpd : math.max(1, (baseline * 0.8).round());

    // 1. If user has strong trigger clusters (e.g. coffee or stress)
    final triggerCounts = <String, int>{};
    for (final log in recentLogs) {
      if (log.trigger != null && log.trigger!.isNotEmpty) {
        triggerCounts[log.trigger!] = (triggerCounts[log.trigger!] ?? 0) + 1;
      }
    }

    String? dominantTrigger;
    int dominantTriggerCount = 0;
    triggerCounts.forEach((k, v) {
      if (v > dominantTriggerCount) {
        dominantTriggerCount = v;
        dominantTrigger = k;
      }
    });

    if (dominantTrigger != null && dominantTriggerCount >= 4 && (dominantTriggerCount / recentLogs.length) > 0.35) {
      return ReductionPlan(
        strategy: ReductionStrategy.triggerTarget,
        title: 'Target "$dominantTrigger" Smoking',
        description: 'Focus solely on interrupting the automatic urge associated with $dominantTrigger.',
        rationale: 'Over 35% of your recent cigarettes occur after "$dominantTrigger". By replacing just this one recurring trigger with a 7-minute pause or water break, your daily count drops naturally without overall willpower fatigue.',
        startingCpd: baseline,
        currentTargetCpd: math.max(1, targetCpd),
        finalTargetCpd: 0,
        recommendedDelayMinutes: 7,
        targetTrigger: dominantTrigger,
      );
    }

    // 2. If user already has high delay success, use Delay Progression
    final completedDelays = cravingLogs.where((c) => c.delayedMinutesCompleted > 0).length;
    if (completedDelays >= 5) {
      return ReductionPlan(
        strategy: ReductionStrategy.delayProgression,
        title: 'Progressive Delay Strategy',
        description: 'Extend your conscious delay window from 7 to 12 minutes.',
        rationale: 'You have shown strong resilience in delaying cravings ($completedDelays successful delays). Increasing delay intervals retrains prefrontal impulse control and increases total smoke-free gaps across your day.',
        startingCpd: baseline,
        currentTargetCpd: math.max(1, targetCpd),
        finalTargetCpd: 0,
        recommendedDelayMinutes: 12,
      );
    }

    // 3. Default: Gentle Gradual Reduction with clear steps
    final nextTarget = math.max(1, (recentAvg - 1).round());
    return ReductionPlan(
      strategy: ReductionStrategy.gradual,
      title: 'Gradual Pace Reduction',
      description: 'Gently reduce daily consumption by 1 cigarette every 3 to 5 days.',
      rationale: 'A gradual step-down gives your nicotine receptors time to down-regulate smoothly, preventing the intense withdrawal spikes caused by abrupt cutoffs.',
      startingCpd: baseline,
      currentTargetCpd: nextTarget,
      finalTargetCpd: 0,
      recommendedDelayMinutes: 7,
    );
  }
}
