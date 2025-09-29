import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/profile_screen.dart';
import '../models/user_profile.dart';

// --- DEVELOPMENT ---
// Set to `true` to bypass login and go directly to the dashboard.
const bool _devBypassLogin = true;

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
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
          //home: auth.isAuthenticated
          home: _devBypassLogin || auth.isAuthenticated
              ? AppShell(
                  // Pass user data from provider to the AppShell
                  //username: auth.username ?? 'User',
                  //role: auth.role ?? 'user',
                  // When bypassing login, use dummy data.
                  // Change 'role' to 'admin' to test admin UI.
                  username: _devBypassLogin
                      ? 'dev_user'
                      : auth.username ?? 'User',
                  role: _devBypassLogin ? 'user' : auth.role ?? 'user',
                )
              : SplashScreen(),
          routes: {
            LoginScreen.routeName: (_) => LoginScreen(),
            SignupScreen.routeName: (_) => SignupScreen(),
            ReportsScreen.routeName: (_) => ReportsScreen(),
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
  static const int _userHomeIndex = 0; // Dashboard
  static const int _adminHomeIndex = 3; // Reports

  int _selectedIndex = 0;

  // Centralized state for user profile, managed by the AppShell.
  UserProfile _userProfile = UserProfile(
    name: 'User', // Will be updated in initState
    email: 'user@example.com',
    phone: 'N/A',
    societyNumber: 'A-12345',
  );

  // Callback for the ProfileScreen to update the user's data.
  void _updateProfile(UserProfile newProfile) {
    // This will trigger a rebuild of AppShell, updating the drawer header.
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
    // Set the initial screen based on the user's role.
    // Admins land on the Reports screen, others on the Dashboard.
    _selectedIndex = widget.role == 'admin' ? _adminHomeIndex : _userHomeIndex;
    // Initialize the user profile with data passed from the AuthProvider
    _userProfile = UserProfile(
      name: widget.username,
      email: '${widget.username}@example.com', // Placeholder email
      phone: _userProfile.phone,
      societyNumber: _userProfile.societyNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of widgets to call in the body. We pass the navigation function
    // to the DashboardScreen so it can switch tabs.
    final List<Widget> widgetOptions = <Widget>[
      DashboardScreen(onNavigate: _onItemTapped), //Index 0 : Dashboard
      const PaymentsScreen(), //Index 1: Payments
      ProfileScreen(
        userProfile: _userProfile,
        onProfileUpdated: _updateProfile,
      ), //Index 2: Profile
      if (widget.role == 'admin')
        ReportsScreen(), // Index 3: Reports (Admin only)
    ];

    final List<String> titles = <String>[
      'Dashboard',
      'Payments',
      'Profile',
      if (widget.role == 'admin') 'Reports',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
      ),
      drawer: Drawer(
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
                  style: TextStyle(fontSize: 40.0, color: Colors.blue[800]),
                ),
              ),
              decoration: BoxDecoration(color: Colors.blue[800]),
            ),
            _buildDrawerItem(icon: Icons.home, title: 'Dashboard', index: 0),
            _buildDrawerItem(icon: Icons.payment, title: 'Payments', index: 1),
            _buildDrawerItem(icon: Icons.person, title: 'Profile', index: 2),
            // Conditionally show the Reports item in the drawer
            if (widget.role == 'admin')
              _buildDrawerItem(
                icon: Icons.bar_chart,
                title: 'Reports',
                index: 3,
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              onTap: () {
                // Call the logout method from the provider
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
            const Spacer(), // Pushes the version number to the bottom
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
      body: Center(child: widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          if (widget.role == 'admin')
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to build drawer items to reduce code repetition
  // and handle selection state.
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue[800] : null),
        title: Text(
          title,
          style: TextStyle(
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
