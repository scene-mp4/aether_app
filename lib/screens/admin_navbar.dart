import 'package:flutter/material.dart';
import 'package:pollutracker_app/screens/admin_tabs/admin_advice.dart';
import 'package:pollutracker_app/screens/admin_tabs/admin_dashboard.dart';
import 'package:pollutracker_app/screens/admin_tabs/admin_settings.dart';
import 'package:pollutracker_app/screens/admin_tabs/admin_trackers.dart';
import 'package:pollutracker_app/screens/admin_tabs/admin_users.dart';
// Contains the bottom navigation bar for the admin side. All other tabs will be in separate files, and when a tab is pressed on the bottom navigation bar, the current screen should change.
// TODO: 

class AdminBottomNavbar extends StatefulWidget {
  const AdminBottomNavbar({super.key});

  @override
  State<AdminBottomNavbar> createState() => AdminBottomNavbarState();
}

class AdminBottomNavbarState extends State<AdminBottomNavbar> {
  int _currentIndex = 1;

  final List<Widget> tabs = [
  AdminDashboardTab(),
  AdminTrackersTab(),
  AdminUsersTab(),
  AdminAdviceTab(),
  AdminSettingsTab(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Dashboard",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: "Trackers",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: "Users",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: "Advice",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            ),
        ]
        ),
    );
  }
}