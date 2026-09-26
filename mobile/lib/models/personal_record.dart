class PersonalRecords {
  final double longestSmokeFreeHours;
  final int mostCigarettesAvoidedDay;
  final int mostSuccessfulDelaysDay;
  final int mostCravingsOvercomeDay;
  final int longestStreakDays;
  final DateTime? longestGapAchievedAt;

  const PersonalRecords({
    this.longestSmokeFreeHours = 0.0,
    this.mostCigarettesAvoidedDay = 0,
    this.mostSuccessfulDelaysDay = 0,
    this.mostCravingsOvercomeDay = 0,
    this.longestStreakDays = 0,
    this.longestGapAchievedAt,
  });

  PersonalRecords copyWith({
    double? longestSmokeFreeHours,
    int? mostCigarettesAvoidedDay,
    int? mostSuccessfulDelaysDay,
    int? mostCravingsOvercomeDay,
    int? longestStreakDays,
    DateTime? longestGapAchievedAt,
  }) {
    return PersonalRecords(
      longestSmokeFreeHours:
          longestSmokeFreeHours ?? this.longestSmokeFreeHours,
      mostCigarettesAvoidedDay:
          mostCigarettesAvoidedDay ?? this.mostCigarettesAvoidedDay,
      mostSuccessfulDelaysDay:
          mostSuccessfulDelaysDay ?? this.mostSuccessfulDelaysDay,
      mostCravingsOvercomeDay:
          mostCravingsOvercomeDay ?? this.mostCravingsOvercomeDay,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      longestGapAchievedAt: longestGapAchievedAt ?? this.longestGapAchievedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'longestSmokeFreeHours': longestSmokeFreeHours,
    'mostCigarettesAvoidedDay': mostCigarettesAvoidedDay,
    'mostSuccessfulDelaysDay': mostSuccessfulDelaysDay,
    'mostCravingsOvercomeDay': mostCravingsOvercomeDay,
    'longestStreakDays': longestStreakDays,
    'longestGapAchievedAt': longestGapAchievedAt?.toIso8601String(),
  };

  factory PersonalRecords.fromJson(Map<String, dynamic> json) =>
      PersonalRecords(
        longestSmokeFreeHours:
            (json['longestSmokeFreeHours'] as num?)?.toDouble() ?? 0.0,
        mostCigarettesAvoidedDay:
            json['mostCigarettesAvoidedDay'] as int? ?? 0,
        mostSuccessfulDelaysDay:
            json['mostSuccessfulDelaysDay'] as int? ?? 0,
        mostCravingsOvercomeDay:
            json['mostCravingsOvercomeDay'] as int? ?? 0,
        longestStreakDays: json['longestStreakDays'] as int? ?? 0,
        longestGapAchievedAt: json['longestGapAchievedAt'] != null
            ? DateTime.tryParse(json['longestGapAchievedAt'] as String)
            : null,
      );
}
