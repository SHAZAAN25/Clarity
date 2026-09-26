import 'dart:math' as math;
import '../models/craving_log.dart';
import '../models/smoking_log.dart';

/// Smart Adaptive Delay Engine (Section 16)
/// Adapts delay suggestions progressively:
/// - Uses previous delay success rate
/// - Adapts to craving intensity (1-10)
/// - Evaluates trigger difficulty
/// - Considers time since last cigarette
/// - Goal is progressive control, not punishment
class SmartDelayEngine {
  static const int minDelayMinutes = 5;
  static const int maxDelayMinutes = 25;
  static const int defaultStartingDelay = 7;

  /// Calculates the optimal personalized delay duration in minutes.
  static int calculateOptimalDelay({
    required List<CravingLog> cravingHistory,
    required List<SmokingLog> smokingHistory,
    required int cravingIntensity,
    required String trigger,
    required int baselineIntervalMinutes,
  }) {
    if (cravingHistory.isEmpty) {
      // Starting recommendation: gentle 7 minutes or based on intensity
      if (cravingIntensity >= 8) return 5;
      if (cravingIntensity >= 5) return defaultStartingDelay;
      return 10;
    }

    // 1. Analyze historical delay completion rate
    final completedDelays = cravingHistory.where((c) => c.delayedMinutesCompleted > 0).toList();
    final successfulOvercomes = cravingHistory.where((c) => c.wasOvercome).toList();

    int baseDelay = defaultStartingDelay;

    if (completedDelays.length >= 10 && successfulOvercomes.length / cravingHistory.length > 0.7) {
      baseDelay = 15;
    } else if (completedDelays.length >= 5 && successfulOvercomes.length / cravingHistory.length > 0.5) {
      baseDelay = 12;
    } else if (completedDelays.length >= 3) {
      baseDelay = 10;
    } else {
      baseDelay = defaultStartingDelay;
    }

    // 2. Adjust for current craving intensity
    // Very high intensity (9-10) needs an accessible, achievable target, not a daunting one
    if (cravingIntensity >= 8) {
      baseDelay = math.max(minDelayMinutes, baseDelay - 3);
    } else if (cravingIntensity <= 3) {
      baseDelay = math.min(maxDelayMinutes, baseDelay + 3);
    }

    // 3. Trigger specific adjustment
    final triggerCravings = cravingHistory.where((c) => c.trigger.toLowerCase() == trigger.toLowerCase()).toList();
    if (triggerCravings.length >= 3) {
      final triggerSuccessRate = triggerCravings.where((c) => c.wasOvercome).length / triggerCravings.length;
      if (triggerSuccessRate < 0.4) {
        // Challenging trigger: make delay more achievable
        baseDelay = math.max(minDelayMinutes, baseDelay - 2);
      } else if (triggerSuccessRate > 0.75) {
        baseDelay = math.min(maxDelayMinutes, baseDelay + 2);
      }
    }

    return baseDelay.clamp(minDelayMinutes, maxDelayMinutes);
  }

  /// Generates the empathetic rational message accompanying the delay recommendation.
  static String getDelayRationale({
    required int minutes,
    required int cravingIntensity,
    required String trigger,
  }) {
    if (cravingIntensity >= 8) {
      return "This is a strong urge. We'll start with just $minutes minutes—cravings peak at 3-5 minutes, then steadily drop.";
    }
    return "Try waiting $minutes minutes. Delaying retrains dopamine anticipation and puts you back in conscious control.";
  }
}
