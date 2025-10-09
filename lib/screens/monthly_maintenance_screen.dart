import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import 'package:provider/provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/notification.dart' as model;
import '../services/api_service.dart' as api;
import 'package:intl/intl.dart';

class MonthlyMaintenanceScreen extends StatefulWidget {
  static const String routeName = '/monthly-maintenance';

  const MonthlyMaintenanceScreen({super.key});

  @override
  State<MonthlyMaintenanceScreen> createState() =>
      _MonthlyMaintenanceScreenState();
}

class _MonthlyMaintenanceScreenState extends State<MonthlyMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  PaymentStatus? _filterStatus;
  List<model.AppNotification> _notifications = [];
  final Set<String> _sendingReminders = {};
  bool _isPaying = false; // State to track payment processing

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: Colors.blue[800],
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text(_notifications.length.toString()),
                child: const Icon(Icons.notifications),
              ),
              onPressed: () => _showNotificationsDialog(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Provider.of<MaintenanceProvider>(
          context,
          listen: false,
        ).fetchMaintenanceRecords(auth.token, auth.username),
        child: Consumer<MaintenanceProvider>(
          builder: (context, maintenance, child) {
            if (maintenance.isLoading && maintenance.userRecords.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (maintenance.error != null) {
              return _buildErrorWidget();
            }

            final records = maintenance.userRecords;
            if (records.isEmpty) {
              // If the API returns nothing, show the empty state.
              return _buildEmptyState(message: 'No maintenance records found.');
            }

            // Admin sees all records, user sees only their own.
            return auth.isAdmin
                ? _buildAdminView(records) // Admin sees all dummy records
                : _buildUserView(records, auth.username);
          },
        ),
      ),
    );
  }

  void _generateNotifications(List<MaintenanceRecord> records) {
    final now = DateTime.now();
    final newNotifications = <model.AppNotification>[];

    for (var record in records) {
      final daysUntilDue = record.dueDate.difference(now).inDays;

      if (record.status == PaymentStatus.late) {
        newNotifications.add(
          model.AppNotification(
            title: 'Overdue Payment',
            body: '${record.familyName}\'s payment is overdue.',
            date: now,
            type: model.NotificationType.late,
            icon: Icons.error,
            color: Colors.red,
          ),
        );
      } else if (record.status == PaymentStatus.due &&
          daysUntilDue <= 7 &&
          daysUntilDue >= 0) {
        newNotifications.add(
          model.AppNotification(
            title: 'Upcoming Due Date',
            body:
                '${record.familyName}\'s payment is due in $daysUntilDue days.',
            date: now,
            type: model.NotificationType.upcoming,
            icon: Icons.hourglass_top,
            color: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _notifications = newNotifications;
    });
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminders & Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notif = _notifications[index];
              return ListTile(
                leading: Icon(notif.icon, color: notif.color),
                title: Text(notif.title),
                subtitle: Text(notif.body),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          const Text(
            'Failed to load data.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 8),
          const Text('Please check your connection and try again.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                Provider.of<MaintenanceProvider>(
                  context,
                  listen: false,
                ).fetchMaintenanceRecords(
                  Provider.of<AuthProvider>(context, listen: false).token,
                  Provider.of<AuthProvider>(context, listen: false).username,
                ),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminView(List<MaintenanceRecord> records) {
    // Filter records based on the selected chip.
    final List<MaintenanceRecord> filteredRecords = records.where((r) {
      if (_filterStatus == null) return true;
      return r.status == _filterStatus;
    }).toList();
    // Identify defaulters for the summary card.
    final defaulters = records
        .where((r) => r.status == PaymentStatus.late)
        .toList();

    return Column(
      children: [
        _buildSummaryCard(defaulters),
        _buildFilterChips(),
        if (filteredRecords.isEmpty)
          Expanded(
            child: _buildEmptyState(message: 'No records match your filter.'),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                // Add animation to each card
                return _buildAnimatedListItem(
                  index: index,
                  child: _buildRecordCard(filteredRecords[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUserView(
    List<MaintenanceRecord> allRecords,
    String? currentUsername,
  ) {
    // Find records for the current user.
    final userSpecificRecords = allRecords
        .where(
          (r) => r.familyName.toLowerCase() == currentUsername?.toLowerCase(),
        )
        .toList();

    // Sort records by due date, newest first, to ensure the most recent one is the 'current' record.
    userSpecificRecords.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    if (userSpecificRecords.isEmpty) {
      return _buildEmptyState(message: "You have no maintenance records yet.");
    }

    // The first record is the most current one for the user.
    final currentRecord = userSpecificRecords.first;
    // All other real records are considered part of the payment history.
    final historyRecords = userSpecificRecords.length > 1
        ? userSpecificRecords.skip(1).toList()
        : <MaintenanceRecord>[];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildUserSummaryCard(currentRecord),
        // Only show the "Payment History" section if there are past records.
        if (historyRecords.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          // Create a list of history tiles from the past records.
          ...historyRecords
              .map((record) => _buildUserHistoryTile(record))
              .toList(),
        ],
      ],
    );
  }

  Widget _buildUserSummaryCard(MaintenanceRecord record) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    IconData icon;
    Color color;
    String title;
    String subtitle;
    Widget amountWidget;

    switch (record.status) {
      case PaymentStatus.paid:
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'All Paid Up!';
        subtitle = 'Thank you for your timely payment.';
        amountWidget = Text(
          currencyFormat.format(record.amount),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
        break;
      case PaymentStatus.due:
        icon = Icons.hourglass_top;
        color = Colors.orange;
        title = 'Payment Due';
        subtitle =
            'Your maintenance is due by ${DateFormat.yMMMd().format(record.dueDate)}.';
        amountWidget = Text(
          currencyFormat.format(record.amount),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
        break;
      case PaymentStatus.late:
        icon = Icons.warning;
        color = Colors.red;
        title = 'Payment Overdue';
        final total = record.amount + (record.fine ?? 0);
        subtitle =
            'A fine of ${currencyFormat.format(record.fine)} has been applied.';
        amountWidget = Text(
          currencyFormat.format(total),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
        break;
    }

    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            amountWidget,
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (record.status != PaymentStatus.paid) ...[
              const SizedBox(height: 16),
              _isPaying
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() => _isPaying = true);
                        await Provider.of<MaintenanceProvider>(
                          context,
                          listen: false,
                        ).makePayment(record.familyName);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment Successful!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() => _isPaying = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Pay Now'),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterStatus == null,
            onSelected: (selected) => setState(() => _filterStatus = null),
          ),
          FilterChip(
            label: const Text('Due'),
            selected: _filterStatus == PaymentStatus.due,
            onSelected: (selected) =>
                setState(() => _filterStatus = PaymentStatus.due),
            selectedColor: Colors.orange[100],
          ),
          FilterChip(
            label: const Text('Late'),
            selected: _filterStatus == PaymentStatus.late,
            onSelected: (selected) =>
                setState(() => _filterStatus = PaymentStatus.late),
            selectedColor: Colors.red[100],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<MaintenanceRecord> defaulters) {
    if (defaulters.isEmpty) {
      // "All Caught Up!" message
      return Card(
        color: Colors.green[50],
        margin: const EdgeInsets.all(12),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green, size: 36),
          title: Text(
            'All Caught Up!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Everyone has paid their maintenance fees.'),
        ),
      );
    }

    // "Action Required" summary card
    final totalDue = defaulters.fold<double>(
      0,
      (sum, item) => sum + item.amount + (item.fine ?? 0),
    );
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = PaymentStatus.late;
        });
      },
      child: Card(
        color: Colors.red[50],
        margin: const EdgeInsets.all(12),
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.red, size: 36),
          title: Text(
            'Action Required: ${defaulters.length} Defaulters',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Total amount overdue: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalDue)}',
          ),
          trailing: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list),
              Text('Tap to see', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MaintenanceRecord record) {
    switch (record.status) {
      case PaymentStatus.paid:
        return _buildPaidCard(record);
      case PaymentStatus.due:
        return _buildDueCard(record);
      case PaymentStatus.late:
        return _buildLateCard(record);
    }
  }

  Widget _buildPaidCard(MaintenanceRecord record) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.green.shade50,
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          '${record.familyName} (${record.flatNumber})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Paid on ${DateFormat.yMMMd().format(record.paymentDate!)}',
        ),
        trailing: Text(
          currencyFormat.format(record.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDueCard(MaintenanceRecord record) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.orange.shade50,
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.hourglass_top, color: Colors.orange),
        title: Text(
          '${record.familyName} (${record.flatNumber})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Due by ${DateFormat.yMMMd().format(record.dueDate)}'),
        trailing: Text(
          currencyFormat.format(record.amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLateCard(MaintenanceRecord record) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final total = record.amount + (record.fine ?? 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.red.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(
                '${record.familyName} (${record.flatNumber})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Overdue since ${DateFormat.yMMMd().format(record.dueDate)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  if (record.fine != null && record.fine! > 0)
                    Text(
                      '+ ${currencyFormat.format(record.fine)} fine',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
                child: _buildSendReminderButton(record),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendReminderButton(MaintenanceRecord record) {
    if (_sendingReminders.contains(record.familyName)) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton.icon(
      onPressed: () async {
        setState(() {
          _sendingReminders.add(record.familyName);
        });
        final success = await api.ApiService.sendReminderMock(
          record.familyName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Reminder sent to ${record.familyName}'
                    : 'Failed to send reminder.',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          setState(() => _sendingReminders.remove(record.familyName));
        }
      },
      icon: const Icon(Icons.send, size: 16),
      label: const Text('Send Reminder'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildAnimatedListItem({required int index, required Widget child}) {
    // Simple fade-in and slide-up animation for list items
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, builderChild) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: builderChild),
        );
      },
      child: child,
    );
  }

  Widget _buildUserHistoryTile(MaintenanceRecord record) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    Icon icon;
    Color color;

    switch (record.status) {
      case PaymentStatus.paid:
        icon = const Icon(Icons.check, color: Colors.green);
        color = Colors.green;
        break;
      case PaymentStatus.due:
        icon = const Icon(Icons.hourglass_empty, color: Colors.orange);
        color = Colors.orange;
        break;
      case PaymentStatus.late:
        icon = const Icon(Icons.error_outline, color: Colors.red);
        color = Colors.red;
        break;
    }

    return ListTile(
      leading: icon,
      title: Text(
        'Maintenance for ${DateFormat('MMMM yyyy').format(record.dueDate)}' +
            (record.status == PaymentStatus.paid
                ? ' (Paid)'
                : ''), // Explicitly mark paid transactions
      ),
      trailing: Text(
        currencyFormat.format(record.amount),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
