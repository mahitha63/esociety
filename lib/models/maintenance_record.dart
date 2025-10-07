enum PaymentStatus { paid, due, late }

class MaintenanceRecord {
  final String familyName;
  final String flatNumber;
  final double amount;
  final PaymentStatus status;
  final DateTime dueDate;
  final DateTime? paymentDate;
  final double? fine;

  MaintenanceRecord({
    required this.familyName,
    required this.flatNumber,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paymentDate,
    this.fine,
  });
}