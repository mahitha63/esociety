import 'package:flutter/material.dart';

// Import the screens for each tab.
import 'dashboard_screen.dart'; // Dev B's work
import 'monthly_maintenance_screen.dart'; // Dev C's work (used for Payments tab)
import 'families_screen.dart'; // Dev D's work
import 'reports_screen.dart'; // Dev A's work
import 'profile_screen.dart'; // Placeholder for Dev D/A
import '../models/user_profile.dart'; // Model for ProfileScreen

/// A stateful widget that manages the main navigation shell of the app.
class MainScreen extends StatefulWidget {
  static const String routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  // Dummy data for the profile screen. In a real app, this would come from a provider.
  UserProfile _userProfile = UserProfile(
    name: 'R. Sharma',
    email: 'sharma.r@example.com',
    phone: '+91 98765 43210',
    societyNumber: 'A-101',
  );

  @override
  void initState() {
    super.initState();

    // The list of screens is now initialized here to allow passing instance methods
    // like _onItemTapped and state variables like _userProfile.
    _widgetOptions = <Widget>[
      // Index 0: Dashboard
      DashboardScreen(onNavigate: _onItemTapped),
      // Index 1: Payments (Using MonthlyMaintenanceScreen as the main payments view)
      const MonthlyMaintenanceScreen(),
      // Index 2: Families
      const FamiliesScreen(),
      // Index 3: Reports
      const ReportsScreen(),
      // Index 4: Profile
      ProfileScreen(
        userProfile: _userProfile,
        onProfileUpdated: (updatedProfile) {
          setState(() => _userProfile = updatedProfile);
          // Here you would also call an API to save the changes to the backend.
        },
      ),
    ];
  }

  // Handles tap events on the navigation bar items.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body displays the widget from _widgetOptions at the current index.
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // The items are ordered as per your request.
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Families',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}