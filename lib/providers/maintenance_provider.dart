import 'package:flutter/material.dart';
import 'dart:async';
import '../models/maintenance_record.dart';
import '../services/api_service.dart' as api;

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceRecord> _allRecords = [];
  List<MaintenanceRecord> _userRecords = [];
  bool _isLoading = false;
  String? _error;

  List<MaintenanceRecord> get userRecords => _userRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gets the most current record for the user (due, late, or last paid).
  MaintenanceRecord? get currentRecord {
    if (_userRecords.isEmpty) return null;
    return _userRecords.first;
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
      _allRecords = await api.ApiService.fetchMonthlyMaintenance(token);

      // Filter records for the current user.
      // This simulates what a user-specific API endpoint would do.
      _userRecords = _allRecords.where((r) {
        return r.familyName.toLowerCase().startsWith(
              username.toLowerCase(),
            );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load payment data. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }
}