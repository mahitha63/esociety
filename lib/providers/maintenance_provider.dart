import 'package:flutter/material.dart';
import 'dart:async';
import '../models/maintenance_record.dart';
import '../services/api_service.dart' as api;

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // This now returns all records, filtering will be done in the UI.
  List<MaintenanceRecord> get userRecords => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets the most current record for the user (due, late, or last paid).
  MaintenanceRecord? get currentRecord {
    // This logic might need to be adapted if it's used by multiple users at once.
    // For a single user app state, this is okay.
    if (_records.isEmpty) return null;
    return _records.first;
  }

  /// Calculates the total upcoming due amount for the dashboard.
  double get upcomingDueAmount {
    if (currentRecord == null) return 0.0;

    switch (currentRecord!.status) {
      case PaymentStatus.due:
        return currentRecord!.amount;
      case PaymentStatus.late:
        return currentRecord!.amount + (currentRecord!.fine ?? 0);
      default:
        return 0.0;
    }
  }

  Future<void> fetchMaintenanceRecords(String? token, String? username) async {
    if (username == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await api.ApiService.fetchMonthlyMaintenance(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load payment data. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulates making a payment for a specific family's most recent due/late record.
  Future<void> makePayment(String familyName) async {
    // Find the first record for the user that is not paid.
    final index = _records.indexWhere((r) =>
        r.familyName.toLowerCase() == familyName.toLowerCase() &&
        r.status != PaymentStatus.paid);

    if (index != -1) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      final oldRecord = _records[index];
      // Create a new record with the updated status and payment date
      _records[index] = oldRecord.copyWith(
          status: PaymentStatus.paid,
          paymentDate: DateTime.now(),
          fine: 0); // Clear fine on payment
      notifyListeners();
    }
  }
}