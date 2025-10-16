import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:esociety/providers/auth_provider.dart';
import 'package:esociety/screens/login_screen.dart';
import 'package:esociety/screens/signup_screen.dart';

/// A helper function to create a testable widget with necessary providers.
/// This avoids boilerplate code in each test.
Widget createTestableWidget({required Widget child}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
    child: MaterialApp(
      // Define routes used for navigation during tests
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
      },
      home: child,
    ),
  );
}

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Renders correctly and finds all input fields and buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(child: const LoginScreen()));

      // Verify that the main widgets are present
      expect(find.text('eSociety'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('No account? Create one'), findsOneWidget);
    });

    testWidgets('Shows validation error for empty username and password', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(child: const LoginScreen()));

      // Tap the login button without entering any text
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump(); // Rebuild the widget to show validation messages

      // Check for validation error messages
      expect(find.text('Enter username'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('Shows validation error for a common password', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(child: const LoginScreen()));

      // Find the password field and enter a disallowed password
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'password');

      // Tap the login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Check for the specific error message
      expect(find.text('This password is too common'), findsOneWidget);
    });

    testWidgets('Shows validation error for a password that is too short', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(child: const LoginScreen()));

      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'Short1!');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // The error message for password complexity is long, so we find a part of it.
      expect(find.textContaining('Min 8 chars'), findsOneWidget);
    });
  });

  group('SignupScreen Widget Tests', () {
    testWidgets('Renders correctly and finds all input fields and buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const SignupScreen()),
      );

      expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('Shows validation error for mismatched passwords', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const SignupScreen()),
      );

      // Find password and confirm password fields
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      final confirmPasswordField = find.widgetWithText(
        TextFormField,
        'Confirm Password',
      );

      // Enter different passwords
      await tester.enterText(passwordField, 'ValidPass@123');
      await tester.enterText(confirmPasswordField, 'DifferentPass@123');

      // Tap the sign-up button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      // Check for the mismatch error
      expect(find.text('Passwords do not match!'), findsOneWidget);
    });

    testWidgets('Shows validation error for password without a number', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const SignupScreen()),
      );

      final passwordField = find.widgetWithText(TextFormField, 'Password');

      // Enter a password missing a number
      await tester.enterText(passwordField, 'NoNumberHere!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      // Check for the specific validation rule message
      expect(find.text('• Must contain at least one number.'), findsOneWidget);
    });
  });
}
