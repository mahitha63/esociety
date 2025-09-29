import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:esociety/providers/auth_provider.dart';
import 'package:esociety/services/api_service.dart' as api;
import 'package:esociety/widgets/dashboard_card.dart' as widgets;
import 'package:esociety/models/reports.dart';

class ReportsScreen extends StatefulWidget {
  static const String routeName = '/reports';
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<MonthlyReportEntry>> _monthlyFuture;
  late Future<List<YearlyReportEntry>> _yearlyFuture;
  late Future<List<YoYEntry>> _yoyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  void _fetchAll() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    _monthlyFuture = api.ApiService.fetchMonthlyReport(token);
    _yearlyFuture = api.ApiService.fetchYearlyReport(token);
    _yoyFuture = api.ApiService.fetchYoYComparison(token);
  }

  Widget _summaryRow(List<YearlyReportEntry> years) {
    double collected = years.fold(0.0, (s, y) => s + y.totalCollected);
    double expense = years.fold(0.0, (s, y) => s + y.totalExpense);
    double pending = (collected - expense).abs(); // demo metric

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

  Widget _monthlyTab() {
    return FutureBuilder<List<MonthlyReportEntry>>(
      future: _monthlyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done)
          return Center(child: CircularProgressIndicator());
        if (snap.hasError) return _errorWidget(() => setState(_fetchAll));
        final months = snap.data!;
        // Line chart data
        final spots = months
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.amountPaid))
            .toList();
        return Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= months.length)
                              return const SizedBox.shrink();
                            return Text(
                              months[idx].month.substring(0, 3),
                              style: TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: months
                      .map(
                        (m) => Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.calendar_month),
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

  Widget _yearlyTab() {
    return FutureBuilder<List<YearlyReportEntry>>(
      future: _yearlyFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done)
          return Center(child: CircularProgressIndicator());
        if (snap.hasError) return _errorWidget(() => setState(_fetchAll));
        final years = snap.data!;
        return Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              _summaryRow(years),
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: years
                      .map(
                        (y) => Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.timeline),
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
        if (snap.connectionState != ConnectionState.done)
          return Center(child: CircularProgressIndicator());
        if (snap.hasError) return _errorWidget(() => setState(_fetchAll));
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
          padding: EdgeInsets.all(12),
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
                            if (idx < 0 || idx >= data.length)
                              return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '${data[idx].year}',
                                style: TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: data
                      .map(
                        (d) => Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.bar_chart),
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

  Widget _errorWidget(VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load data', style: TextStyle(color: Colors.red)),
          SizedBox(height: 8),
          ElevatedButton(onPressed: retry, child: Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /*return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // The Consumer in main.dart will handle navigation after logout.
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
            Tab(text: 'YoY'),
          ],

          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              width: 3.0,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_monthlyTab(), _yearlyTab(), _yoyTab()],
      ),*/
    return TabBarView(
      controller: _tabController,
      children: [_monthlyTab(), _yearlyTab(), _yoyTab()],
    );
  }
}
