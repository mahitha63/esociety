import 'package:flutter/material.dart';

//import '../services/auth_service.dart';
class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // The AuthProvider's Consumer in main.dart now handles all navigation.
    // This splash screen is just for presentation while the initial
    // token check happens in the background. We can add a small delay
    // to ensure it's visible.
    Future.delayed(const Duration(seconds: 2), () {
      // The navigation is handled by the auth state change.
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment, size: 72, color: Colors.blue),
            SizedBox(height: 12),
            Text(
              'eSociety',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
