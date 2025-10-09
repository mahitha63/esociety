import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/models/maintenance_record.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/providers/expense_provider.dart';
import '../lib/providers/family_provider.dart';
import '../lib/providers/maintenance_provider.dart';
import '../lib/screens/dashboard_screen.dart';

/// A helper function to create a testable widget with all necessary providers.
Widget createTestableDashboard({required AuthProvider authProvider}) {
  return MultiProvider(
    providers: [
      // We provide a specific instance of AuthProvider for the test
      ChangeNotifierProvider.value(value: authProvider),
      // For other providers, we can create fresh instances
      ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ChangeNotifierProvider(create: (_) => ExpenseProvider()),
    ],
    child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
  );
}

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders admin view correctly', (WidgetTester tester) async {
      // 1. Setup: Create an AuthProvider for an admin user.
      final authProvider = AuthProvider();
      // Simulate a logged-in admin by calling the actual login method.
      await authProvider.login('admin', 'Admin@123');

      // 2. Act: Build the DashboardScreen with the admin provider.
      await tester.pumpWidget(
        createTestableDashboard(authProvider: authProvider),
      );

      // 3. Assert: Verify that admin-specific widgets are visible.
      expect(find.text('Defaulters'), findsOneWidget);
      expect(find.text('Expense Approvals'), findsOneWidget);
      expect(find.text('Family Approvals'), findsOneWidget);
      expect(find.text('Total Families'), findsOneWidget);

      // And verify user-specific widgets are NOT visible.
      expect(find.text('Upcoming Dues'), findsNothing);
      expect(find.text('All Clear!'), findsNothing);
    });

    testWidgets('Renders user view correctly with no dues', (
      WidgetTester tester,
    ) async {
      // 1. Setup: AuthProvider for a regular user.
      final authProvider = AuthProvider();
      await authProvider.login('testuser', 'User@123');

      // 2. Act: Build the dashboard.
      await tester.pumpWidget(
        createTestableDashboard(authProvider: authProvider),
      );

      // The MaintenanceProvider starts with no records, so it should be "All Clear!"
      // We need to pumpAndSettle to allow the Consumer to build.
      await tester.pumpAndSettle();

      // 3. Assert: Verify user-specific widgets are visible.
      expect(find.text('All Clear!'), findsOneWidget);
      expect(find.text('Notices'), findsOneWidget);

      // And verify admin-specific widgets are NOT visible.
      expect(find.text('Defaulters'), findsNothing);
      expect(find.text('Total Families'), findsNothing);
    });

    testWidgets('Renders user view correctly with upcoming dues', (
      WidgetTester tester,
    ) async {
      // 1. Setup
      final authProvider = AuthProvider();
      await authProvider.login('testuser', 'User@123');

      final maintenanceProvider = MaintenanceProvider();

      // 2. Act: Build the dashboard with a custom MaintenanceProvider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: maintenanceProvider),
            ChangeNotifierProvider(create: (_) => FamilyProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
        ),
      );

      // Manually update the maintenance provider to have a due amount
      maintenanceProvider.setRecordsForTest([
        MaintenanceRecord(
          familyName: 'testuser',
          flatNumber: 'C-101',
          amount: 1500,
          status: PaymentStatus.due,
          dueDate: DateTime.now(),
        ),
      ]);

      await tester.pump(); // Rebuild with the new maintenance data

      // 3. Assert
      expect(find.text('Upcoming Dues'), findsOneWidget);
      expect(find.textContaining('₹1,500.00'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'View Payments'),
        findsOneWidget,
      );
    });
  });
}
