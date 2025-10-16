import 'package:flutter_test/flutter_test.dart';
import 'package:esociety/providers/expense_provider.dart';

void main() {
  group('ExpenseProvider Unit Tests', () {
    late ExpenseProvider expenseProvider;

    // Create a fresh instance of the provider before each test
    setUp(() {
      expenseProvider = ExpenseProvider();
    });

    test('Initial state is correct', () {
      expect(
        expenseProvider.allExpenses.length,
        3,
        reason: "Should start with 3 total expenses",
      );
      expect(
        expenseProvider.pendingExpenses.length,
        1,
        reason: "Should start with 1 pending expense",
      );
    });

    test('addExpense should add a new pending expense', () {
      final initialCount = expenseProvider.allExpenses.length;

      expenseProvider.addExpense(
        title: 'New Cleaning Supplies',
        amount: 750.0,
        submittedBy: 'test_user',
      );

      expect(expenseProvider.allExpenses.length, initialCount + 1);
      // The new expense should be at the top of the list
      final newExpense = expenseProvider.allExpenses.first;
      expect(newExpense.title, 'New Cleaning Supplies');
      expect(newExpense.status, ExpenseStatus.pending);
    });

    test('approveExpense should change status to approved', () {
      const expenseId = 'exp_001'; // This is a pending expense in dummy data
      const admin = 'admin_user';

      expenseProvider.approveExpense(expenseId, admin);

      final approvedExpense = expenseProvider.allExpenses.firstWhere(
        (e) => e.id == expenseId,
      );

      expect(approvedExpense.status, ExpenseStatus.approved);
      expect(approvedExpense.approvedBy, admin);
      expect(approvedExpense.approvalDate, isA<DateTime>());
      expect(
        expenseProvider.pendingExpenses.length,
        0,
        reason: "Pending list should now be empty",
      );
    });

    test('rejectExpense should change status to rejected', () {
      const expenseId = 'exp_001'; // This is a pending expense in dummy data

      expenseProvider.rejectExpense(expenseId);

      final rejectedExpense = expenseProvider.allExpenses.firstWhere(
        (e) => e.id == expenseId,
      );

      expect(rejectedExpense.status, ExpenseStatus.rejected);
    });
  });
}
