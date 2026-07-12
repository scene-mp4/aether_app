import 'package:flutter/material.dart';
import 'package:pollutracker_app/screens/tabs/analytics_new.dart';
import 'package:pollutracker_app/screens/tabs/settings_new.dart';
import 'package:pollutracker_app/screens/tabs/summary_new.dart';
import 'package:pollutracker_app/screens/tabs/trackers_new.dart';
import '../main.dart';

// Contains the bottom navigation bar. All other tabs will be in separate files, and when a tab is pressed on the bottom navigation bar, the current screen should change.
// TODO: 

class BottomNavbar extends StatefulWidget{
  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
int _currentIndex = 1;

final List<Widget> tabs = [
  TrackersNewPage(),
  SummaryNewPage(),
  AnalyticsNewPage(),
  SettingsNewPage()
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
            icon: Icon(Icons.track_changes),
            label: "Trackers",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "Summary",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart_rounded),
            label: "Analytics",
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