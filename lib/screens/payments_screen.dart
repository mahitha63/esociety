import 'package:flutter/material.dart';
import 'monthly_maintenance_screen.dart';

class PaymentsScreen extends StatelessWidget {
  static const String routeName = '/payments';
  
  const PaymentsScreen({super.key});

  // Helper to create styled navigation cards
  Widget _buildPaymentCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String routeName,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.of(context).pushNamed(routeName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildPaymentCard(
              context: context,
              icon: Icons.calendar_month,
              title: 'Monthly Maintenance',
              subtitle: 'View dues, payments, and fines',
              routeName: MonthlyMaintenanceScreen.routeName),
          // Other payment types like 'Gym Fees', 'Event Contributions' can be added here.
        ],
      ),
    );
  }
}
