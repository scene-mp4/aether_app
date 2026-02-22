import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/bottom_navbar.dart';
import 'screens/tabs/map_tab.dart';
import 'screens/tabs/profile_tab.dart';
import 'screens/tabs/settings_tab.dart';

void main() {
  runApp(MyApp());
}

// Main file that only contains the navigation routes for the individual app screens.
// Read the details about each tab / screen file in the screens / tabs file folders.

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pollutracker",
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 0, 255, 106))),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/bottom_navbar': (context) => BottomNavbar(),
        '/map': (context) => MapTab(),
        '/profile': (context) => ProfileTab(),
        '/settings': (context) => SettingsTab(),
      },
    );
  }
}
