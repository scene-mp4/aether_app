import 'package:flutter/material.dart';
import '../main.dart';
import 'tabs/map_tab.dart';
import 'tabs/trackers_tab.dart';
import 'tabs/settings_tab.dart';

// Contains the bottom navigation bar. All other tabs will be in separate files, and when a tab is pressed on the bottom navigation bar, the current screen should change.
// TODO: 

class BottomNavbar extends StatefulWidget{
  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
int _currentIndex = 1;

final List<Widget> tabs = [
  MapTab(),
  TrackersTab(),
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
            icon: Icon(Icons.radio_button_checked),
            label: "Trackers",
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