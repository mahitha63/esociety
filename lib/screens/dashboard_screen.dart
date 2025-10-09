import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';

import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/expense_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // We use a ListView to ensure the content is scrollable if it
    // overflows on smaller screens.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Section 1: Summary Cards
        const Text(
          'Account Summary',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // The dashboard view is now dependent on the user's role.
        auth.isAdmin ? _buildAdminSummary(context) : _buildUserSummary(context),
        const SizedBox(height: 24),

        // Section 2: Quick Stats
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Admin sees society-wide stats, user sees personal stats.
        auth.isAdmin ? _buildAdminQuickStats(context) : _buildUserQuickStats(context),
      ],
    );
  }

  /// Builds the summary card for a regular user.
  Widget _buildUserSummary(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<MaintenanceProvider>(
          builder: (context, maintenance, child) {
            if (maintenance.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final dueAmount = maintenance.upcomingDueAmount;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dueAmount > 0 ? 'Upcoming Dues' : 'Account Status',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  dueAmount > 0 ? currencyFormat.format(dueAmount) : 'All Clear!',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: dueAmount > 0 ? Colors.redAccent : Colors.green),
                ),
                if (dueAmount > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/monthly-maintenance');
                        },
                        child: const Text('View Payments')),
                  ),
                ]
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the summary cards for an admin.
  Widget _buildAdminSummary(BuildContext context) {
    final maintenance = Provider.of<MaintenanceProvider>(context);
    final family = Provider.of<FamilyProvider>(context);
    final expense = Provider.of<ExpenseProvider>(context);

    // Calculate total defaulters from the maintenance provider's dummy data.
    final defaulterCount = maintenance.userRecords
        .where((r) => r.status == 'late')
        .length;

    // Get pending family approvals from the family provider.
    final pendingApprovals = family.pendingApproval
        .where((p) => p['status'] == 'pending')
        .length;

    // Get pending expense approvals.
    final pendingExpenses = expense.pendingExpenses.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Defaulters',
                defaulterCount.toString(),
                defaulterCount > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Expense Approvals',
                pendingExpenses.toString(),
                pendingExpenses > 0
                    ? Colors.purple
                    : Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatCard(
            'Expense Approvals',
            '${family.pendingApproval.where((p) => p['status'] == 'pending').length} Pending Families',
            pendingApprovals > 0
                ? Colors.orange
                : Colors.blue,
            valueFontSize: 18),
      ],
    );
  }

  /// Quick stats for the admin view.
  Widget _buildAdminQuickStats(BuildContext context) {
    final family = Provider.of<FamilyProvider>(context);
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Families', family.families.length.toString(), Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Open Complaints', '2', Colors.orange)),
      ],
    );
  }

  /// Quick stats for the user view.
  Widget _buildUserQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Notices', '1', Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('Visitors Today', '5', Colors.green)),
      ],
    );
  }

  // Helper method to build a stat card to avoid code repetition
  Widget _buildStatCard(String title, String value, Color color,
      {double valueFontSize = 24}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
