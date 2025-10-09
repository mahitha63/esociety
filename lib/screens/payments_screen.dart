import 'package:flutter/material.dart';
import 'monthly_maintenance_screen.dart';
import 'expense_approval_screen.dart';
import 'create_expense_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// This screen acts as a central hub for all payment-related sections.
/// It provides navigation to different types of payments the society manages.
/// As per the work breakdown, this is part of Dev B's responsibility.
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPaymentCategoryCard(
          context: context,
          icon: Icons.house,
          title: 'Monthly Maintenance',
          subtitle: 'View inward payments, dues, and history.',
          onTap: () => Navigator.of(
            context,
          ).pushNamed(MonthlyMaintenanceScreen.routeName),
        ),
        _buildPaymentCategoryCard(
          context: context,
          icon: Icons.receipt_long,
          title: 'Outward Payments (Expenses)',
          subtitle: auth.isAdmin
              ? 'Approve or reject expense requests.'
              : 'Submit a new expense for approval.',
          onTap: () => Navigator.of(context).pushNamed(
            auth.isAdmin
                ? ExpenseApprovalScreen.routeName
                : CreateExpenseScreen.routeName,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
