import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/dashboard_card.dart' as widgets;
import '../services/api_service.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../models/reports.dart';
import '../providers/maintenance_provider.dart';
import '../providers/expense_provider.dart';

class ReportsScreen extends StatefulWidget {
  static const String routeName = '/reports';

  const ReportsScreen({super.key});
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<YearlyReportEntry> _dummyYearlyData = [
    YearlyReportEntry(
      year: DateTime.now().year,
      totalCollected: 25000, // Dummy yearly total
      totalExpense: 18000,
    ),
    YearlyReportEntry(
      year: DateTime.now().year - 1,
      totalCollected: 22000,
      totalExpense: 17500,
    ),
  ];

  final List<YoYEntry> _dummyYoYData = [
    YoYEntry(year: DateTime.now().year - 2, amount: 20000),
    YoYEntry(year: DateTime.now().year - 1, amount: 22000),
    YoYEntry(year: DateTime.now().year, amount: 25000),
  ];

  // Futures that resolve immediately with our dummy data.
  late Future<List<YearlyReportEntry>> _yearlyFuture;
  late Future<List<YoYEntry>> _yoyFuture;
  late Future<List<MonthlyReportEntry>> _monthlyFuture;

  @override
  void initState() {
    super.initState();
    // The number of tabs is now 3 (Yearly, YoY, Expenses)
    _tabController = TabController(length: 4, vsync: this);
    _yearlyFuture = ApiService.fetchYearlyReport(Provider.of<auth_provider.AuthProvider>(context, listen: false).token);
    _yoyFuture = ApiService.fetchYoYComparison(Provider.of<auth_provider.AuthProvider>(context, listen: false).token);
    _monthlyFuture = ApiService.fetchMonthlyReport(
      Provider.of<auth_provider.AuthProvider>(context, listen: false).token,
      year: DateTime.now().year,
    );
    // Load expenses list from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      expenseProvider.loadFromBackend(context);
    });
  }

  Widget _monthlyTab() {
    return FutureBuilder<List<MonthlyReportEntry>>(
      future: _monthlyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _errorWidget(() {});
        }
        final data = snap.data!;
        final maxY = data
            .map((d) => d.amountPaid)
            .fold<double>(0.0, (prev, v) => v > prev ? v : prev);
        final spots = data.asMap().entries.map((e) {
          final idx = e.key;
          return FlSpot(idx.toDouble(), e.value.amountPaid);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (data.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY * 1.2,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                data[idx].month,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blue,
                        dotData: const FlDotData(show: false),
                        spots: spots,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: data
                      .map(
                        (m) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: Text('${m.month} ${m.year}'),
                            subtitle: Text(
                              'Paid: ₹${m.amountPaid.toStringAsFixed(0)} • Pending: ₹${m.amountPending.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(BuildContext context, List<YearlyReportEntry> years) {
    double collected = years.fold(0.0, (s, y) => s + y.totalCollected);
    double expense = years.fold(0.0, (s, y) => s + y.totalExpense);

    // Dynamically calculate pending amount from the MaintenanceProvider
    final maintenance = Provider.of<MaintenanceProvider>(
      context,
      listen: false,
    );
    final pending = maintenance.userRecords
        .where((r) => r.status == 'late' || r.status == 'due')
        .fold(0.0, (sum, r) => sum + r.amount + (r.fine ?? 0));

    return Row(
      children: [
        Expanded(
          child: widgets.DashboardCard(
            title: 'Collected',
            value: '₹${collected.toStringAsFixed(0)}',
            icon: Icons.account_balance,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: widgets.DashboardCard(
            title: 'Expenses',
            value: '₹${expense.toStringAsFixed(0)}',
            icon: Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: widgets.DashboardCard(
            title: 'Pending',
            value: '₹${pending.toStringAsFixed(0)}',
            icon: Icons.pending_actions,
          ),
        ),
      ],
    );
  }

  Widget _yearlyTab() {
    return FutureBuilder<List<YearlyReportEntry>>(
      future: _yearlyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _errorWidget(() {});
        }
        final years = snap.data!;
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _summaryRow(context, years),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: years
                      .map(
                        (y) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.timeline),
                            title: Text('${y.year}'),
                            subtitle: Text(
                              'Collected: ₹${y.totalCollected.toStringAsFixed(0)} • Expense: ₹${y.totalExpense.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _yoyTab() {
    return FutureBuilder<List<YoYEntry>>(
      future: _yoyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _errorWidget(() {});
        }
        final data = snap.data!;
        final maxAmount = data
            .map((d) => d.amount)
            .reduce((a, b) => a > b ? a : b);
        final groups = data.asMap().entries.map((e) {
          final idx = e.key;
          return BarChartGroupData(
            x: idx,
            barRods: [BarChartRodData(toY: e.value.amount, width: 18)],
            showingTooltipIndicators: [0],
          );
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxAmount * 1.2,
                    barGroups: groups,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '${data[idx].year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: data
                      .map(
                        (d) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.bar_chart),
                            title: Text('${d.year}'),
                            subtitle: Text(
                              'Amount: ₹${d.amount.toStringAsFixed(0)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _expensesTab() {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final allExpenses = expenseProvider.allExpenses;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (expenseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (expenseProvider.error != null) {
      return _errorWidget(() {
        expenseProvider.loadFromBackend(context);
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: allExpenses.length,
      itemBuilder: (context, index) {
        final expense = allExpenses[index];
        IconData icon;
        Color color;
        switch (expense.status) {
          case ExpenseStatus.approved:
            icon = Icons.check_circle;
            color = Colors.green;
            break;
          case ExpenseStatus.rejected:
            icon = Icons.cancel;
            color = Colors.red;
            break;
          case ExpenseStatus.pending:
          default:
            icon = Icons.hourglass_top;
            color = Colors.orange;
            break;
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(expense.title),
            subtitle: Text(
              'Submitted by ${expense.submittedBy} on ${DateFormat.yMMMd().format(expense.submissionDate)}',
            ),
            trailing: Text(currencyFormat.format(expense.amount)),
          ),
        );
      },
    );
  }

  Widget _errorWidget(VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to load data',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This AppBar is nested within the main AppShell's AppBar.
      // It only contains the TabBar for this specific screen.
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back button
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly Inward'),
            Tab(text: 'YoY'),
            Tab(text: 'Expenses'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_monthlyTab(), _yearlyTab(), _yoyTab(), _expensesTab()],
      ),
    );
  }
}
