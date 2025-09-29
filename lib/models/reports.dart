class MonthlyReportEntry {
  final String month;
  final int year;
  final double amountPaid;
  final double amountPending;

  MonthlyReportEntry({
    required this.month,
    required this.year,
    required this.amountPaid,
    required this.amountPending,
  });
}

class YearlyReportEntry {
  final int year;
  final double totalCollected;
  final double totalExpense;

  YearlyReportEntry({
    required this.year,
    required this.totalCollected,
    required this.totalExpense,
  });
}

class YoYEntry {
  final int year;
  final double amount;
  YoYEntry({required this.year, required this.amount});
}
