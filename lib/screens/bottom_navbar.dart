import 'package:flutter/material.dart';
import '../main.dart';
import 'tabs/map_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/settings_tab.dart';

// Contains the bottom navigation bar. All other tabs will be in separate files, and when a tab is pressed on the bottom navigation bar, the current screen should change.
// TODO: 

class BottomNavbar extends StatefulWidget{
  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
int _currentIndex = 0;

final List<Widget> tabs = [
  MapTab(),
  ProfileTab(),
  SettingsTab()
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_currentIndex],
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
            icon: Icon(Icons.map),
            label: "Map",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
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