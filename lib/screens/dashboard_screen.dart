import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';

class DashboardScreen extends StatelessWidget {
  // Callback to allow this screen to trigger navigation in the parent AppShell
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
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
        Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<MaintenanceProvider>(
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
                                onPressed: () => onNavigate(1), child: const Text('Pay Now')),
                          ),
                        ]
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Section 2: Quick Stats
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Open Complaints', '2', Colors.orange),
            _buildStatCard('Notices', '1', Colors.blue),
            _buildStatCard('Visitors Today', '5', Colors.green),
          ],
        ),
      ],
    );
  }

  // Helper method to build a stat card to avoid code repetition
  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
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
