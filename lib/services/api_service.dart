// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:esociety/widgets/config.dart';
import 'package:esociety/models/reports.dart';
import 'package:esociety/models/maintenance_record.dart';

class ApiService {
  // Mockers
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

  // Real HTTP implementations
  static Future<List<MonthlyReportEntry>> fetchMonthlyReportHttp(
    String token, {
    int year = 2024,
  }) async {
    final url = Uri.parse('${Config.baseUrl}/reports/monthly?year=$year');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map(
            (e) => MonthlyReportEntry(
              month: e['month'],
              year: e['year'],
              amountPaid: (e['amountPaid'] as num).toDouble(),
              amountPending: (e['amountPending'] as num).toDouble(),
            ),
          )
          .toList();
    } else {
      throw Exception('Failed monthly: ${res.body}');
    }
  }

  static Future<List<YearlyReportEntry>> fetchYearlyReportHttp(
    String token,
  ) async {
    final url = Uri.parse('${Config.baseUrl}/reports/yearly');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
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
      throw Exception('Failed yearly: ${res.body}');
    }
  }

  static Future<List<YoYEntry>> fetchYoYComparisonHttp(String token) async {
    final url = Uri.parse('${Config.baseUrl}/reports/yoy');
    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
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
      throw Exception('Failed yoy: ${res.body}');
    }
  }

  // Public methods: UI calls these and passes token (token can be null for mock)
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

  // --- Dev C: Monthly Maintenance Mock ---
  static Future<List<MaintenanceRecord>> fetchMonthlyMaintenanceMock() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Uncomment the line below to test the error handling UI
    // throw Exception('Failed to load maintenance data');

    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month, 10);

    return [
      MaintenanceRecord(
          familyName: 'Sharma Family',
          flatNumber: 'A-101',
          amount: 2500,
          status: PaymentStatus.paid,
          dueDate: dueDate,
          paymentDate: DateTime(now.year, now.month, 5)),
      MaintenanceRecord(
          familyName: 'Patel Family',
          flatNumber: 'B-204',
          amount: 2500,
          status: PaymentStatus.late,
          dueDate: dueDate,
          fine: 100),
      MaintenanceRecord(
          familyName: 'Khan Family',
          flatNumber: 'C-301',
          amount: 3000,
          status: PaymentStatus.due,
          dueDate: dueDate),
      MaintenanceRecord(
          familyName: 'Singh Family',
          flatNumber: 'A-402',
          amount: 2500,
          status: PaymentStatus.paid,
          dueDate: dueDate,
          paymentDate: DateTime(now.year, now.month, 8)),
    ];
  }

  static Future<List<MaintenanceRecord>> fetchMonthlyMaintenance(String? token) {
    if (Config.useMockData) return fetchMonthlyMaintenanceMock();
    // In the future, a real HTTP call would go here.
    // return fetchMonthlyMaintenanceHttp(token ?? '');
    throw UnimplementedError('HTTP implementation for maintenance not available');
  }

  // --- Dev C: Send Reminder Mock ---
  static Future<bool> sendReminderMock(String familyName) async {
    // Simulate a network call that takes 1-2 seconds
    await Future.delayed(Duration(seconds: 1 + DateTime.now().second % 2));
    return true; // Simulate a successful API call
  }
}
