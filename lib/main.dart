import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/family_provider.dart'; // Import FamilyProvider
import '../providers/maintenance_provider.dart'; // Import MaintenanceProvider
import '../providers/expense_provider.dart'; // Import ExpenseProvider
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/monthly_maintenance_screen.dart';
import '../models/user_profile.dart';
import '../screens/create_expense_screen.dart';
import '../screens/expense_approval_screen.dart';
import '../screens/families_screen.dart';
import 'package:esociety/providers/dashboard_provider.dart'; // <-- New import

// --- DEVELOPMENT ---
// Set to `true` to bypass login and go directly to the dashboard.
const bool _devBypassLogin = false;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ), // <-- This line is added
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, // to remove the debug banner
          title: 'eSociety',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: auth.isInitializing
              ? const SplashScreen()
              : _devBypassLogin || auth.isAuthenticated
              ? AppShell(
                  username: _devBypassLogin
                      ? 'patel' // e.g., 'patel', 'sharma', 'khan'
                      : auth.username ?? 'User',
                  role: _devBypassLogin
                      ? 'user'
                      : auth.role ?? 'user', // 'user' or 'admin'
                )
              : const LoginScreen(),
          routes: {
            LoginScreen.routeName: (_) => const LoginScreen(),
            SignupScreen.routeName: (_) => const SignupScreen(),
            ReportsScreen.routeName: (_) => const ReportsScreen(),
            MonthlyMaintenanceScreen.routeName: (_) =>
                const MonthlyMaintenanceScreen(),
            FamiliesScreen.routeName: (_) =>
                const FamiliesScreen(), // Add FamiliesScreen route
            CreateExpenseScreen.routeName: (_) => const CreateExpenseScreen(),
            ExpenseApprovalScreen.routeName: (_) =>
                const ExpenseApprovalScreen(),
          },
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  final String username;
  final String role;

  const AppShell({super.key, required this.username, required this.role});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  UserProfile _userProfile = UserProfile(
    name: 'User', // Will be updated in initState
    email: 'user@example.com',
    phone: 'N/A',
    societyNumber: 'A-12345',
  );

  void _updateProfile(UserProfile newProfile) {
    setState(() {
      _userProfile = newProfile;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _userProfile = UserProfile(
      name: widget.username,
      email: '${widget.username}@example.com', // Placeholder email
      phone: _userProfile.phone,
      societyNumber: _userProfile.societyNumber,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MaintenanceProvider>(
        context,
        listen: false,
      ).fetchMaintenanceRecords(
        Provider.of<AuthProvider>(context, listen: false).token,
        widget.username,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      const DashboardScreen(),
      const PaymentsScreen(),
      const FamiliesScreen(),
      if (widget.role == 'admin') const ReportsScreen(),
      ProfileScreen(
        userProfile: _userProfile,
        onProfileUpdated: _updateProfile,
      ),
    ];

    final List<String> titles = <String>[
      'Dashboard',
      'Payments',
      'Families',
      if (widget.role == 'admin') 'Reports',
      'Profile',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      _userProfile.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(_userProfile.email),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        _userProfile.name.isNotEmpty
                            ? _userProfile.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 40.0,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(color: Colors.blue[800]),
                  ),
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment,
                    title: 'Payments',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.group,
                    title: 'Families',
                    index: 2,
                  ),
                  if (widget.role == 'admin')
                    _buildDrawerItem(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      index: 3,
                    ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    index: widget.role == 'admin' ? 4 : 3,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () {
                      Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).logout();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Version 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(child: widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Families',
          ),
          if (widget.role == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex > titles.length - 1 ? 0 : _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue[800] : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue[900] : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          _onItemTapped(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
