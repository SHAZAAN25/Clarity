class MoneyStats {
  final double packPriceInr;
  final int packSize;
  final int cigarettesSmokedToday;
  final int cigarettesAvoidedToday;
  final int cigarettesSmokedThisWeek;
  final int baselineCpd;
  final String currencySymbol;

  const MoneyStats({
    required this.packPriceInr,
    this.packSize = 20,
    required this.cigarettesSmokedToday,
    required this.cigarettesAvoidedToday,
    required this.cigarettesSmokedThisWeek,
    required this.baselineCpd,
    this.currencySymbol = '₹',
  });

  double get costPerCigarette =>
      packSize > 0 ? packPriceInr / packSize : 15.0;

  double get spentToday => cigarettesSmokedToday * costPerCigarette;

  double get retainedToday => cigarettesAvoidedToday * costPerCigarette;

  double get spentThisWeek => cigarettesSmokedThisWeek * costPerCigarette;

  double get baselineMonthlyExpense =>
      baselineCpd * 30.0 * costPerCigarette;

  double get baselineYearlyExpense =>
      baselineCpd * 365.0 * costPerCigarette;

  double get potentialMonthlySavings =>
      retainedToday * 30.0;

  String formatInr(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(0)}';
  }
}
