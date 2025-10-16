import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_stats.dart';
import '../models/ward_stats.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Add a variable to hold the selected ward
  String? _selectedWard;

  // List of wards for the dropdown
  final List<String> _wards = ['All Wards', 'A', 'B'];

  @override
  void initState() {
    super.initState();
    // Initially select 'All Wards'
    _selectedWard = _wards[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger the data fetch without a filter on initialization
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Account Summary',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Add a dropdown for the ward filter here
        if (auth.isAdmin) ...[
          _buildFilterWidget(context), // Calling the new, styled widget
          const SizedBox(height: 16),
        ],
        auth.isAdmin ? _buildAdminSummary(context) : _buildUserSummary(context),
        const SizedBox(height: 24),
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (auth.isAdmin) _buildAdminQuickStats(context),
        if (!auth.isAdmin) _buildUserQuickStats(context),
      ],
    );
  }

  // --- REPLACED/UPDATED FILTER WIDGET ---
  Widget _buildFilterWidget(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.filter_alt, color: Colors.blueGrey, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Filter by Ward:',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedWard,
              icon: const Icon(Icons.arrow_drop_down),
              elevation: 8,
              style: const TextStyle(color: Colors.blue, fontSize: 16),
              underline: Container(
                height: 2,
                color: Colors.transparent, // Hides the default underline
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedWard = newValue;
                  });
                  Provider.of<DashboardProvider>(
                    context,
                    listen: false,
                  ).fetchDashboardData(
                    wardId: newValue == 'All Wards' ? null : newValue,
                  );
                }
              },
              items: _wards.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(value),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
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
                  dueAmount > 0
                      ? currencyFormat.format(dueAmount)
                      : 'All Clear!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: dueAmount > 0 ? Colors.redAccent : Colors.green,
                  ),
                ),
                if (dueAmount > 0) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/monthly-maintenance');
                      },
                      child: const Text('View Payments'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the summary cards for an admin using the new DashboardProvider.
  Widget _buildAdminSummary(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dashboardProvider.errorMessage.isNotEmpty) {
          return Center(child: Text(dashboardProvider.errorMessage));
        }

        final DashboardStats? stats = dashboardProvider.dashboardStats;
        if (stats == null) {
          return const Center(child: Text("No dashboard data available."));
        }

        // Correctly calculate filtered totals from the wardStatistics list
        double totalFilteredCollected =
            stats.wardStatistics?.fold<double>(
              0.0,
              (previousValue, element) =>
                  previousValue + (element.collectedAmount ?? 0),
            ) ??
            0.0;

        double totalFilteredPending =
            stats.wardStatistics?.fold<double>(
              0.0,
              (previousValue, element) =>
                  previousValue + (element.pendingAmount ?? 0),
            ) ??
            0.0;

        int totalFilteredDefaulters =
            stats.wardStatistics?.fold<int>(
              0,
              (previousValue, element) =>
                  previousValue + (element.defaulterCount ?? 0),
            ) ??
            0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The filter widget is now called higher up in the build method
            // and handled by the separate _buildFilterWidget method.
            Row(
              children: [
                _buildStatCard(
                  'Total Defaulters',
                  totalFilteredDefaulters.toString(),
                  totalFilteredDefaulters > 0 ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  'Total Collected',
                  '₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(totalFilteredCollected)}',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatCard(
                  'Total Pending',
                  '₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(totalFilteredPending)}',
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildStatCard('Pending Expenses', '0', Colors.purple),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Quick stats for the admin view using the new DashboardProvider (Per-Ward Stats).
  Widget _buildAdminQuickStats(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final DashboardStats? stats = dashboardProvider.dashboardStats;

        if (dashboardProvider.isLoading && stats == null) {
          return Container();
        }

        if (stats == null ||
            stats.wardStatistics == null ||
            stats.wardStatistics!.isEmpty) {
          return const Center(child: Text("No ward-specific stats available."));
        }

        List<Widget> rows = [];
        for (var i = 0; i < stats.wardStatistics!.length; i += 2) {
          List<Widget> rowChildren = [];

          final WardStats wardStat1 = stats.wardStatistics![i];
          rowChildren.add(
            _buildStatCard(
              'Ward ${wardStat1.wardId ?? 'N/A'}',
              'Defaulters: ${wardStat1.defaulterCount ?? 0}',
              Colors.blue,
              valueFontSize: 18,
            ),
          );

          if (i + 1 < stats.wardStatistics!.length) {
            rowChildren.add(const SizedBox(width: 8));
            final WardStats wardStat2 = stats.wardStatistics![i + 1];
            rowChildren.add(
              _buildStatCard(
                'Ward ${wardStat2.wardId ?? 'N/A'}',
                'Defaulters: ${wardStat2.defaulterCount ?? 0}',
                Colors.blue,
                valueFontSize: 18,
              ),
            );
          }

          rows.add(Row(children: rowChildren));
          rows.add(const SizedBox(height: 8));
        }

        return Column(children: rows);
      },
    );
  }

  /// Quick stats for the user view.
  Widget _buildUserQuickStats(BuildContext context) {
    return Row(
      children: [
        _buildStatCard('Notices', '1', Colors.blue),
        const SizedBox(width: 8),
        _buildStatCard('Visitors Today', '5', Colors.green),
      ],
    );
  }

  /// Helper method to build a stat card to avoid code repetition.
  Widget _buildStatCard(
    String title,
    String value,
    Color color, {
    double valueFontSize = 24,
  }) {
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
