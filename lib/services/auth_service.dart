// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../widgets/config.dart';

class AuthService {
  // Mock login - same method signature as real login
  static Future<Map<String, dynamic>> loginMock(
    String username,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Check for specific admin credentials
    if (username == 'admin' && password == 'Admin@123') {
      return {
        'token': 'mock-admin-token-12345',
        'user': {'id': 99, 'username': 'admin', 'role': 'admin'},
      };
    }

    // Default user response
    return {
      'token': 'mock-token-${username.hashCode}',
      'user': {'id': 1, 'username': username, 'role': 'user'},
    };
  }

  static Future<Map<String, dynamic>> signupMock(
    String username,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'token': 'mock-token-${username.hashCode}',
      'user': {'id': 2, 'username': username, 'role': 'user'},
    };
  }

  // Real HTTP login (ready to use once backend is available)
  static Future<Map<String, dynamic>> loginHttp(
    String username,
    String password,
  ) async {
    final url = Uri.parse('${Config.baseUrl}/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> signupHttp(
    String username,
    String password,
  ) async {
    final url = Uri.parse('${Config.baseUrl}/auth/signup');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Signup failed: ${res.body}');
    }
  }

  // Public methods used by UI - choose mock or http based on config
  static Future<Map<String, dynamic>> login(String username, String password) {
    if (Config.useMockData) {
      return loginMock(username, password);
    } else {
      return loginHttp(username, password);
    }
  }

  static Future<Map<String, dynamic>> signup(String username, String password) {
    if (Config.useMockData) {
      return signupMock(username, password);
    } else {
      return signupHttp(username, password);
    }
  }
}
