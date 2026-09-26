enum ReductionStrategy {
  gradual, // 12 -> 11 -> 10 -> 9
  intervalExtension, // Increase time between cigarettes
  triggerTarget, // Target specific trigger cigarettes
  delayProgression, // Delay selected cigarettes
  clusterReduction, // Remove cigarettes from high-frequency periods
}

class ReductionPlan {
  final ReductionStrategy strategy;
  final String title;
  final String description;
  final String rationale;
  final int startingCpd;
  final int currentTargetCpd;
  final int finalTargetCpd;
  final int recommendedDelayMinutes;
  final String? targetTrigger;

  const ReductionPlan({
    required this.strategy,
    required this.title,
    required this.description,
    required this.rationale,
    required this.startingCpd,
    required this.currentTargetCpd,
    required this.finalTargetCpd,
    required this.recommendedDelayMinutes,
    this.targetTrigger,
  });

  Map<String, dynamic> toJson() => {
    'strategy': strategy.name,
    'title': title,
    'description': description,
    'rationale': rationale,
    'startingCpd': startingCpd,
    'currentTargetCpd': currentTargetCpd,
    'finalTargetCpd': finalTargetCpd,
    'recommendedDelayMinutes': recommendedDelayMinutes,
    'targetTrigger': targetTrigger,
  };

  factory ReductionPlan.fromJson(Map<String, dynamic> json) => ReductionPlan(
    strategy: ReductionStrategy.values.firstWhere(
      (e) => e.name == json['strategy'],
      orElse: () => ReductionStrategy.gradual,
    ),
    title: json['title'] as String? ?? 'Gradual Reduction',
    description: json['description'] as String? ?? '',
    rationale: json['rationale'] as String? ?? '',
    startingCpd: json['startingCpd'] as int? ?? 10,
    currentTargetCpd: json['currentTargetCpd'] as int? ?? 8,
    finalTargetCpd: json['finalTargetCpd'] as int? ?? 0,
    recommendedDelayMinutes: json['recommendedDelayMinutes'] as int? ?? 7,
    targetTrigger: json['targetTrigger'] as String?,
  );
}
