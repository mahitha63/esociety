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

  // -------------------------
  // Helpers for parsing API
  // -------------------------
  static String _extractTokenFromApi(
    Map<String, dynamic> api,
    String username,
  ) {
    // Look in multiple common places for a token
    final tokenCandidates = [
      if (api.containsKey('data') && api['data'] is Map)
        (api['data'] as Map)['token'],
      api['token'],
      api['accessToken'],
      api['data'] is Map && (api['data'] as Map).containsKey('accessToken')
          ? (api['data'] as Map)['accessToken']
          : null,
    ];

    for (final t in tokenCandidates) {
      if (t != null && t is String && t.isNotEmpty) return t;
    }

    // Fallback: synthesize a session token (legacy behaviour)
    return 'session-$username';
  }

  static Map<String, dynamic> _extractUserFromApi(
    Map<String, dynamic> api,
    String username,
  ) {
    // Backend might return user inside data.user or data or top-level user fields.
    Map<String, dynamic>? user;
    if (api['data'] is Map) {
      final data = (api['data'] as Map).cast<String, dynamic>();
      if (data.containsKey('user') && data['user'] is Map) {
        user = (data['user'] as Map).cast<String, dynamic>();
      } else if (data.containsKey('username') || data.containsKey('id')) {
        user = data;
      }
    }

    if (user == null) {
      if (api['user'] is Map)
        user = (api['user'] as Map).cast<String, dynamic>();
    }

    // Provide a normalized user object
    final id = user != null && (user['id'] != null)
        ? user['id'].toString()
        : username;
    final uname = user != null && (user['username'] != null)
        ? user['username'].toString()
        : username;
    final role = user != null && (user['role'] != null)
        ? user['role'].toString()
        : (username.toLowerCase() == 'admin' ? 'admin' : 'user');

    return {'id': id, 'username': uname, 'role': role};
  }

  // -------------------------
  // Real HTTP login (ready to use once backend is available)
  // -------------------------
  static Future<Map<String, dynamic>> loginHttp(
    String username,
    String password,
  ) async {
    final url = Uri.parse('${Config.baseUrl}/api/auth/login');
    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      // Debugging
      // ignore: avoid_print
      print('[AuthService] POST ${url.toString()} -> ${res.statusCode}');
      // ignore: avoid_print
      print('[AuthService] Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> api =
            jsonDecode(res.body) as Map<String, dynamic>;
        final token = _extractTokenFromApi(api, username);
        final user = _extractUserFromApi(api, username);
        return {'token': token, 'user': user};
      } else {
        throw Exception('Login failed (${res.statusCode}): ${res.body}');
      }
    } on TimeoutException {
      throw Exception('Login request timed out. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  // -------------------------
  // Real HTTP signup
  // -------------------------
  static Future<Map<String, dynamic>> signupHttp(
    String username,
    String password,
  ) async {
    final url = Uri.parse('${Config.baseUrl}/api/auth/signup');
    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'confirmPassword': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      // Debugging
      // ignore: avoid_print
      print('[AuthService] POST ${url.toString()} -> ${res.statusCode}');
      // ignore: avoid_print
      print('[AuthService] Response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> api =
            jsonDecode(res.body) as Map<String, dynamic>;
        final token = _extractTokenFromApi(api, username);
        final user = _extractUserFromApi(api, username);
        return {'token': token, 'user': user};
      } else {
        throw Exception('Signup failed (${res.statusCode}): ${res.body}');
      }
    } on TimeoutException {
      throw Exception('Signup request timed out. Please try again.');
    } catch (e) {
      rethrow;
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
