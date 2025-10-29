// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:esociety/widgets/config.dart';
import 'package:esociety/models/reports.dart';
import 'package:esociety/models/maintenance_record.dart';
import 'package:esociety/providers/expense_provider.dart' as expense_model;

class ApiService {
  // -----------------------
  // Mockers (unchanged)
  // -----------------------
  static Future<List<MonthlyReportEntry>> fetchMonthlyReportMock({
    int year = 2024,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.generate(12, (i) {
      final m = i + 1;
      return MonthlyReportEntry(
        month: [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][i],
        year: year,
        amountPaid: (5000 + i * 300).toDouble(),
        amountPending: (i % 4 == 0) ? 1000.0 : 0.0,
      );
    });
  }

  static Future<List<YearlyReportEntry>> fetchYearlyReportMock() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now().year;
    return [
      YearlyReportEntry(
        year: now - 2,
        totalCollected: 120000,
        totalExpense: 90000,
      ),
      YearlyReportEntry(
        year: now - 1,
        totalCollected: 150000,
        totalExpense: 110000,
      ),
      YearlyReportEntry(
        year: now,
        totalCollected: 160000,
        totalExpense: 125000,
      ),
    ];
  }

  static Future<List<YoYEntry>> fetchYoYComparisonMock() async {
    final yr = await fetchYearlyReportMock();
    return yr
        .map((y) => YoYEntry(year: y.year, amount: y.totalCollected.toDouble()))
        .toList();
  }

  // -----------------------
  // Helpers
  // -----------------------
  static String _buildBase(String path) {
    final base = Config.baseUrl.trimRight();
    final cleanedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return '$cleanedBase$cleanedPath';
  }

  static Map<String, String> _authHeaders(String token) {
    // Backend uses SimpleAuthFilter with X-USER & X-ROLES
    final user = token.isEmpty ? 'guest' : token.replaceFirst('session-', '');
    return {
      'Content-Type': 'application/json',
      'X-USER': user,
      'X-ROLES': 'ADMIN', // adjust role header if needed at runtime
    };
  }

  // -----------------------
  // Real HTTP implementations (with /api prefix)
  // -----------------------

  static Future<List<MonthlyReportEntry>> fetchMonthlyReportHttp(
    String token, {
    int year = 2024,
  }) async {
    final url = Uri.parse(_buildBase('/api/reports/yearly'));
    try {
      final res = await http
          .get(url, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final totalForYear = list.cast<Map>().firstWhere(
          (e) => (e['year']?.toString() ?? '') == year.toString(),
          orElse: () => {'totalCollected': 0, 'year': year},
        );
        final totalCollected = (totalForYear['totalCollected'] as num)
            .toDouble();
        final perMonth = totalCollected / 12.0;
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return List.generate(12, (i) {
          return MonthlyReportEntry(
            month: months[i],
            year: year,
            amountPaid: perMonth,
            amountPending: 0.0,
          );
        });
      } else {
        throw Exception(
          'Failed monthly (status ${res.statusCode}): ${res.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out while fetching monthly reports');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<YearlyReportEntry>> fetchYearlyReportHttp(
    String token,
  ) async {
    final url = Uri.parse(_buildBase('/api/reports/yearly'));
    try {
      final res = await http
          .get(url, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map(
              (e) => YearlyReportEntry(
                year: e['year'],
                totalCollected: (e['totalCollected'] as num).toDouble(),
                totalExpense: (e['totalExpense'] as num).toDouble(),
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Failed yearly (status ${res.statusCode}): ${res.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out while fetching yearly reports');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<YoYEntry>> fetchYoYComparisonHttp(String token) async {
    final url = Uri.parse(_buildBase('/api/reports/yoy'));
    try {
      final res = await http
          .get(url, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map(
              (e) => YoYEntry(
                year: e['year'],
                amount: (e['amount'] as num).toDouble(),
              ),
            )
            .toList();
      } else {
        throw Exception('Failed yoy (status ${res.statusCode}): ${res.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out while fetching YoY data');
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<expense_model.Expense>> fetchExpensesHttp(
    String token,
  ) async {
    final url = Uri.parse(_buildBase('/api/reports/expenses'));
    try {
      final res = await http
          .get(url, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
        return list
            .map(
              (e) => expense_model.Expense(
                id: e['id']?.toString() ?? '',
                title: e['title']?.toString() ?? '',
                amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
                submittedBy: e['submittedBy']?.toString() ?? '',
                submissionDate:
                    DateTime.tryParse(e['submissionDate']?.toString() ?? '') ??
                    DateTime.now(),
                invoiceUrl: e['invoiceUrl']?.toString() ?? '',
                status: _mapExpenseStatus(e['status']?.toString()),
                approvedBy: e['approvedBy']?.toString(),
                approvalDate: DateTime.tryParse(
                  e['approvalDate']?.toString() ?? '',
                ),
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Failed expenses (status ${res.statusCode}): ${res.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Request timed out while fetching expenses');
    } catch (e) {
      rethrow;
    }
  }

  static expense_model.ExpenseStatus _mapExpenseStatus(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'approved':
        return expense_model.ExpenseStatus.approved;
      case 'rejected':
        return expense_model.ExpenseStatus.rejected;
      default:
        return expense_model.ExpenseStatus.pending;
    }
  }

  // -----------------------
  // Public methods: UI calls these and passes token (token can be null for mock)
  // -----------------------
  static Future<List<MonthlyReportEntry>> fetchMonthlyReport(
    String? token, {
    int year = 2024,
  }) {
    if (Config.useMockData) return fetchMonthlyReportMock(year: year);
    return fetchMonthlyReportHttp(token ?? '');
  }

  static Future<List<YearlyReportEntry>> fetchYearlyReport(String? token) {
    if (Config.useMockData) return fetchYearlyReportMock();
    return fetchYearlyReportHttp(token ?? '');
  }

  static Future<List<YoYEntry>> fetchYoYComparison(String? token) {
    if (Config.useMockData) return fetchYoYComparisonMock();
    return fetchYoYComparisonHttp(token ?? '');
  }

  // --- Dev C: Monthly Maintenance Mock (unchanged) ---
  static Future<List<MaintenanceRecord>> fetchMonthlyMaintenanceMock() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      MaintenanceRecord(
        familyName: 'Sharma',
        flatNumber: 'A-101',
        amount: 500,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        status: PaymentStatus.due,
      ),
      MaintenanceRecord(
        familyName: 'Sharma',
        flatNumber: 'A-101',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        status: PaymentStatus.paid,
        paymentDate: DateTime.now().subtract(const Duration(days: 28)),
      ),
      MaintenanceRecord(
        familyName: 'Patel',
        flatNumber: 'B-204',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        status: PaymentStatus.late,
        fine: 50,
      ),
      MaintenanceRecord(
        familyName: 'Patel',
        flatNumber: 'B-204',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 35)),
        status: PaymentStatus.paid,
        paymentDate: DateTime.now().subtract(const Duration(days: 32)),
      ),
      MaintenanceRecord(
        familyName: 'Patel',
        flatNumber: 'B-204',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 65)),
        status: PaymentStatus.paid,
        paymentDate: DateTime.now().subtract(const Duration(days: 61)),
      ),
      MaintenanceRecord(
        familyName: 'Khan',
        flatNumber: 'C-301',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 35)),
        status: PaymentStatus.paid,
        paymentDate: DateTime.now().subtract(const Duration(days: 32)),
      ),
    ];
  }

  static Future<List<MaintenanceRecord>> fetchMonthlyMaintenance(
    String? token,
  ) {
    if (Config.useMockData) return fetchMonthlyMaintenanceMock();
    throw UnimplementedError(
      'HTTP implementation for maintenance not available',
    );
  }

  // --- Dev C: Send Reminder Mock ---
  static Future<bool> sendReminderMock(String familyName) async {
    await Future.delayed(Duration(seconds: 1 + DateTime.now().second % 2));
    return true;
  }
}
