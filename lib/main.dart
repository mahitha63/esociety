import 'package:flutter/material.dart';
import 'package:esociety/screens/dashboard_screen.dart';
import 'package:esociety/screens/payments_screen.dart';
import 'package:esociety/screens/profile_screen.dart';
import 'package:esociety/models/user_profile.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // to remove the debug banner
      title: 'eSociety',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Centralized state for user profile, managed by the AppShell.
  UserProfile _userProfile = UserProfile(
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1 234 567 890',
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
    ];

    const List<String> titles = <String>['Dashboard', 'Payments', 'Profile'];

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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              onTap: () {
                // Add logout logic here
                Navigator.pop(context);
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
