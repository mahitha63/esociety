// lib/config.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static const bool useMockData = false;
  // If testing on Chrome / desktop
  static const String webHost = 'localhost';
  // Emulator: 10.0.2.2, Device: your PC LAN IP e.g. '192.168.1.100'
  static const String emulatorHost = '10.0.2.2';
  static const int port = 8088; // <- IMPORTANT: your backend runs on 8088

  static String get host {
    if (kIsWeb) return webHost;
    // change to emulatorHost if running on an emulator
    return emulatorHost;
  }

  static String get baseUrl => 'http://${host}:${port}';
}
