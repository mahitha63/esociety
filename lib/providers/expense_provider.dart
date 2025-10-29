import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart' as auth_provider;

enum ExpenseStatus { pending, approved, rejected }

class Expense {
  final String id;
  final String title;
  final double amount;
  final String submittedBy;
  final DateTime submissionDate;
  final String invoiceUrl; // Mock URL to an invoice image/PDF
  ExpenseStatus status;
  String? approvedBy;
  DateTime? approvalDate;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.submittedBy,
    required this.submissionDate,
    this.invoiceUrl =
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    this.status = ExpenseStatus.pending,
    this.approvedBy,
    this.approvalDate,
  });
}

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get allExpenses => _expenses;
  List<Expense> get pendingExpenses =>
      _expenses.where((e) => e.status == ExpenseStatus.pending).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFromBackend(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final auth = auth_provider.AuthProvider();
      // In a real app, you'd get provider from context; using storage-backed instance to reuse token
      await Future.delayed(const Duration(milliseconds: 10));
      final token = auth.token ?? '';
      final list = await ApiService.fetchExpensesHttp(token);
      _expenses
        ..clear()
        ..addAll(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void approveExpense(String id, String adminUsername) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index].status = ExpenseStatus.approved;
      _expenses[index].approvedBy = adminUsername;
      _expenses[index].approvalDate = DateTime.now();
      notifyListeners();
    }
  }

  void rejectExpense(String id) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index].status = ExpenseStatus.rejected;
      // You might want to add a rejection reason field as well
      notifyListeners();
    }
  }

  void addExpense({
    required String title,
    required double amount,
    required String submittedBy,
  }) {
    final newExpense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}', // Simple unique ID
      title: title,
      amount: amount,
      submittedBy: submittedBy,
      submissionDate: DateTime.now(),
    );
    _expenses.insert(0, newExpense); // Add to the top of the list
    notifyListeners();
  }
}
