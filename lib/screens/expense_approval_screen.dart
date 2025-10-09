import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import 'create_expense_screen.dart';

/// "Checker" Screen: Allows admins to view and approve/reject outward payments.
class ExpenseApprovalScreen extends StatelessWidget {
  static const String routeName = '/expense-approval';
  const ExpenseApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.pendingExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Approvals'),
        backgroundColor: Colors.blue[800],
      ),
      body: expenses.isEmpty
          ? const Center(child: Text('No pending expense approvals.'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                return _buildExpenseCard(
                  context,
                  expenses[index],
                  expenseProvider,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(CreateExpenseScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    Expense expense,
    ExpenseProvider provider,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(expense.amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Divider(height: 20),
            Text(
              'Submitted by: ${expense.submittedBy} on ${DateFormat.yMMMd().format(expense.submissionDate)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {}, // Mock invoice view
                  child: const Text('View Invoice'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    provider.rejectExpense(expense.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense Rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final adminUsername = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).username!;
                    provider.approveExpense(expense.id, adminUsername);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense Approved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
