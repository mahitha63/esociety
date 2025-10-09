import 'package:flutter/material.dart';

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
    this.invoiceUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    this.status = ExpenseStatus.pending,
    this.approvedBy,
    this.approvalDate,
  });
}

class ExpenseProvider with ChangeNotifier {
  // --- Dummy Data for Demonstration ---
  final List<Expense> _expenses = [
    Expense(
      id: 'exp_001',
      title: 'Security Services - May',
      amount: 15000,
      submittedBy: 'sharma',
      submissionDate: DateTime.now().subtract(const Duration(days: 2)),
      status: ExpenseStatus.pending,
    ),
    Expense(
      id: 'exp_002',
      title: 'Plumbing Repairs - Block B',
      amount: 2500,
      submittedBy: 'admin',
      submissionDate: DateTime.now().subtract(const Duration(days: 10)),
      status: ExpenseStatus.approved,
      approvedBy: 'admin',
      approvalDate: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Expense(
      id: 'exp_003',
      title: 'Gardening Supplies',
      amount: 1200,
      submittedBy: 'patel',
      submissionDate: DateTime.now().subtract(const Duration(days: 5)),
      status: ExpenseStatus.rejected,
    ),
  ];

  List<Expense> get allExpenses => _expenses;
  List<Expense> get pendingExpenses => _expenses.where((e) => e.status == ExpenseStatus.pending).toList();

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