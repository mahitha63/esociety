import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:esociety/models/dashboard_stats.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class DashboardProvider with ChangeNotifier {
  DashboardStats? _dashboardStats;
  bool _isLoading = false;
  String _errorMessage = '';

  DashboardStats? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Private method to get the correct host IP address for local testing
  String _getHost() {
    if (kIsWeb) {
      // For web, use 'localhost'
      return 'localhost';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2
      return '10.0.2.2';
    } else {
      // For other platforms (iOS, desktop), use localhost
      return 'localhost';
    }
  }

  // UPDATED: Now accepts optional filter parameters
  Future<void> fetchDashboardData({String? wardId, String? startDate, String? endDate}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final host = _getHost();
      
      // Construct the URL with optional query parameters
      Uri uri = Uri.http('$host:8080', '/api/dashboard/stats', {
        if (wardId != null && wardId.isNotEmpty) 'wardId': wardId,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _dashboardStats = DashboardStats.fromJson(jsonResponse);
      } else {
        _errorMessage = 'Failed to load dashboard data. Status Code: ${response.statusCode}';
        _dashboardStats = null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _dashboardStats = null;
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}