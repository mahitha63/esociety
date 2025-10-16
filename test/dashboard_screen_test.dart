import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:esociety/models/dashboard_stats.dart';
import 'package:esociety/models/maintenance_record.dart';
import 'package:esociety/models/ward_stats.dart';
import 'package:esociety/providers/auth_provider.dart';
import 'package:esociety/providers/dashboard_provider.dart';
import 'package:esociety/providers/expense_provider.dart';
import 'package:esociety/providers/family_provider.dart';
import 'package:esociety/providers/maintenance_provider.dart';
import 'package:esociety/screens/dashboard_screen.dart';

/// A helper function to create a testable widget with all necessary providers.
Widget createTestableDashboard({
  required AuthProvider authProvider,
  MaintenanceProvider? maintenanceProvider,
  DashboardProvider? dashboardProvider,
}) {
  return MultiProvider(
    providers: [
      // We provide a specific instance of AuthProvider for the test
      ChangeNotifierProvider.value(value: authProvider),
      // Use provided instances for other providers, or create new ones if not provided.
      ChangeNotifierProvider(
        create: (_) => dashboardProvider ?? DashboardProvider(),
      ),
      ChangeNotifierProvider(
        create: (_) => maintenanceProvider ?? MaintenanceProvider(),
      ),
      // These are not directly tested on this screen but might be dependencies.
      ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ChangeNotifierProvider(create: (_) => ExpenseProvider()),
    ],
    child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
  );
}

void main() {
  group('DashboardScreen Widget Tests', () {
    // This setup function will run before each test, ensuring a clean AuthProvider.
    late AuthProvider authProvider;
    setUp(() {
      authProvider = AuthProvider();
    });

    testWidgets('Renders admin view correctly', (WidgetTester tester) async {
      // 1. Setup: Create an AuthProvider for an admin user.
      await authProvider.login('admin', 'Admin@123');

      // Create a mock DashboardProvider with some data.
      final dashboardProvider = DashboardProvider();

      // 2. Act: Build the DashboardScreen with the admin and mocked dashboard providers.
      await tester.pumpWidget(
        createTestableDashboard(
          authProvider: authProvider,
          dashboardProvider: dashboardProvider,
        ),
      );

      // The screen will initially show a loading indicator from DashboardProvider.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the fetchDashboardData to complete (which is mocked and fast).
      // pumpAndSettle will wait for all animations and frame requests to finish.
      await tester.pumpAndSettle();

      // 3. Assert: Verify that admin-specific widgets are visible.
      // Check for the filter dropdown.
      expect(find.text('Filter by Ward:'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Check for the main summary cards.
      // Note: The actual data is now in the DashboardProvider, so we find the titles.
      expect(find.text('Total Defaulters'), findsOneWidget);
      expect(find.text('Total Collected'), findsOneWidget);
      expect(find.text('Total Pending'), findsOneWidget);
      expect(find.text('Pending Expenses'), findsOneWidget);

      // Check for quick stats section title.
      expect(find.text('Quick Stats'), findsOneWidget);

      // And verify user-specific widgets are NOT visible.
      expect(find.text('Account Summary'), findsOneWidget); // This is common
      expect(find.text('Upcoming Dues'), findsNothing);
      expect(find.text('All Clear!'), findsNothing);
    });

    testWidgets('Renders user view correctly with no dues', (
      WidgetTester tester,
    ) async {
      // 1. Setup: AuthProvider for a regular user and an empty MaintenanceProvider.
      await authProvider.login('testuser', 'User@123');
      final maintenanceProvider = MaintenanceProvider();

      // 2. Act: Build the dashboard.
      await tester.pumpWidget(
        createTestableDashboard(
          authProvider: authProvider,
          maintenanceProvider: maintenanceProvider,
        ),
      );

      // The MaintenanceProvider starts with no records, so it should be "All Clear!"
      // We need to pumpAndSettle to allow the Consumer to build.
      await tester.pumpAndSettle();

      // 3. Assert: Verify user-specific widgets are visible.
      expect(find.text('All Clear!'), findsOneWidget);
      expect(find.text('Notices'), findsOneWidget);

      // And verify admin-specific widgets are NOT visible.
      expect(find.text('Filter by Ward:'), findsNothing);
      expect(find.text('Total Defaulters'), findsNothing);
    });

    testWidgets('Renders user view correctly with upcoming dues', (
      WidgetTester tester,
    ) async {
      // 1. Setup
      await authProvider.login('testuser', 'User@123');
      final maintenanceProvider = MaintenanceProvider();

      // 2. Act: Build the dashboard with a custom MaintenanceProvider
      await tester.pumpWidget(
        createTestableDashboard(
          authProvider: authProvider,
          maintenanceProvider: maintenanceProvider,
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
