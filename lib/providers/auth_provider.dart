// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

const _secureStorage = FlutterSecureStorage();

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _role;
  bool _isLoading = false;

  String? get token => _token;
  String? get username => _username;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _role == 'admin';

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _secureStorage.read(key: 'auth_token');
    if (_token != null && _token!.isNotEmpty) {
      // If a token exists, we might also want to load user info
      _username = await _secureStorage.read(key: 'auth_username');
      _role = await _secureStorage.read(key: 'auth_role');
    }
    notifyListeners();
  }

  // Sets all user data atomically and notifies listeners.
  Future<void> _setAuthenticated(
    String token,
    Map<String, dynamic> user,
  ) async {
    _token = token;
    _username = user['username'] as String?;
    _role = user['role'] as String?;

    await _secureStorage.write(key: 'auth_token', value: _token);
    await _secureStorage.write(key: 'auth_username', value: _username);
    await _secureStorage.write(key: 'auth_role', value: _role);
  }

  String _extractToken(dynamic response) {
    if (response == null) return '';
    if (response is String) return response;
    if (response is Map<String, dynamic>) {
      // common key names: 'token' or 'accessToken'
      if (response.containsKey('token')) return response['token'].toString();
      if (response.containsKey('accessToken'))
        return response['accessToken'].toString();
      // fallback: if the map itself is the token string (rare)
      return response.toString();
    }
    return response.toString();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // AuthService.login returns either Map<String,dynamic> or a String (depending on impl)
      final res = await AuthService.login(username, password);
      final extracted = _extractToken(res);
      if (extracted.isEmpty) throw Exception('No token returned from login');
      await _setAuthenticated(extracted, res['user'] as Map<String, dynamic>);
    } catch (e) {
      rethrow; // let UI show the error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await AuthService.signup(username, password);
      final extracted = _extractToken(res);
      if (extracted.isEmpty) throw Exception('No token returned from signup');
      await _setAuthenticated(extracted, res['user'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'auth_username');
    await _secureStorage.delete(key: 'auth_role');
    _token = null;
    _username = null;
    _role = null;
    notifyListeners();
  }
}
