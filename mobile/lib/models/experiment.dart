class BehavioralExperiment {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final DateTime startDate;
  final bool isCompleted;
  final bool? wasSuccessful; // user feedback: did this work for you?
  final String? reflectionNote;

  const BehavioralExperiment({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.startDate,
    this.isCompleted = false,
    this.wasSuccessful,
    this.reflectionNote,
  });

  bool get isActive =>
      !isCompleted &&
      DateTime.now().difference(startDate).inDays < durationDays;

  int get currentDay {
    final diff = DateTime.now().difference(startDate).inDays + 1;
    return diff.clamp(1, durationDays);
  }

  BehavioralExperiment copyWith({
    bool? isCompleted,
    bool? wasSuccessful,
    String? reflectionNote,
  }) {
    return BehavioralExperiment(
      id: id,
      title: title,
      description: description,
      durationDays: durationDays,
      startDate: startDate,
      isCompleted: isCompleted ?? this.isCompleted,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      reflectionNote: reflectionNote ?? this.reflectionNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'durationDays': durationDays,
    'startDate': startDate.toIso8601String(),
    'isCompleted': isCompleted,
    'wasSuccessful': wasSuccessful,
    'reflectionNote': reflectionNote,
  };

  factory BehavioralExperiment.fromJson(Map<String, dynamic> json) =>
      BehavioralExperiment(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        durationDays: json['durationDays'] as int? ?? 3,
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        isCompleted: json['isCompleted'] as bool? ?? false,
        wasSuccessful: json['wasSuccessful'] as bool?,
        reflectionNote: json['reflectionNote'] as String?,
      );
}
