// lib/config.dart
class Config {
  // Toggle demo/mock mode. For now keep true for demo.
  static const bool useMockData = true;

  // When connecting to a real backend:
  // - for Android emulator use 10.0.2.2
  // - for device use the PC LAN IP (e.g., 192.168.1.100)
  static const String host = '10.0.2.2';
  static const int port = 8080;

  static String get baseUrl => 'http://$host:$port/api';
}
