// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:esociety/providers/auth_provider.dart';
import 'package:esociety/main.dart';

void main() {
  testWidgets(
    'App smoke test: Navigates to LoginScreen for unauthenticated user',
    (WidgetTester tester) async {
      // Build our app with the necessary provider.
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const MainApp(),
        ),
      );

      // Initially, the SplashScreen should be visible.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the splash screen timer and navigation to complete.
      await tester.pumpAndSettle();

      // After the splash screen, the LoginScreen should be visible.
      // We can verify this by finding a unique widget on the login screen.
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    },
  );
}
