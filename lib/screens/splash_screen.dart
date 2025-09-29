import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

//import '../services/auth_service.dart';
class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    // A small delay to show the splash screen while the token is loaded.
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return; // Ensure the widget is still in the tree.
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // If not authenticated after the check, navigate to the login screen.
    // If authenticated, the Consumer in main.dart will handle the navigation.
    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
