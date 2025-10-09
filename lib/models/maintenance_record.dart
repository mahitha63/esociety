enum PaymentStatus { paid, due, late }

class MaintenanceRecord {
  String familyName;
  String flatNumber;
  double amount;
  PaymentStatus status;
  DateTime dueDate;
  DateTime? paymentDate;
  double? fine;

  MaintenanceRecord({
    required this.familyName,
    required this.flatNumber,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paymentDate,
    this.fine,
  });

  /// Creates a copy of this MaintenanceRecord but with the given fields replaced with the new values.
  MaintenanceRecord copyWith({
    String? familyName,
    String? flatNumber,
    double? amount,
    PaymentStatus? status,
    DateTime? dueDate,
    DateTime? paymentDate,
    double? fine,
  }) {
    return MaintenanceRecord(
      familyName: familyName ?? this.familyName,
      flatNumber: flatNumber ?? this.flatNumber,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      fine: fine ?? this.fine,
    );
  }
}