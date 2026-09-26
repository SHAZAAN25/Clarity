class HealthMilestone {
  final String id;
  final String title;
  final String timeframe;
  final String description;
  final String scientificSource;
  final int requiredHours;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0

  HealthMilestone({
    required this.id,
    required this.title,
    required this.timeframe,
    required this.description,
    required this.scientificSource,
    required this.requiredHours,
    required this.isUnlocked,
    required this.progress,
  });

  factory HealthMilestone.fromHoursSinceLastSmoke(
    String id,
    String title,
    String timeframe,
    String description,
    String source,
    int requiredHours,
    double hoursSmokeFree,
  ) {
    final double prog = (hoursSmokeFree / requiredHours).clamp(0.0, 1.0);
    return HealthMilestone(
      id: id,
      title: title,
      timeframe: timeframe,
      description: description,
      scientificSource: source,
      requiredHours: requiredHours,
      isUnlocked: prog >= 1.0,
      progress: prog,
    );
  }

  bool get isCompleted => isUnlocked;
  double get progressFraction => progress;
  String get source => scientificSource;
}
