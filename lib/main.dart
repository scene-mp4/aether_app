// navigation
import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/bottom_navbar.dart';
import 'screens/pollutracker_legacy/map_tab.dart';
import 'screens/pollutracker_legacy/trackers_tab.dart';
import 'screens/pollutracker_legacy/settings_tab.dart';

// firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// Main file that only contains the navigation routes for the individual app screens.
// Read the details about each tab / screen file in the screens / tabs file folders.

// TODO: 
// - Set specific colors for the theme instead of using fromSeed


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AETHER App",
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 0, 4, 255))),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/bottom_navbar': (context) => BottomNavbar(),
        '/map': (context) => MapTab(),
        '/trackers': (context) => TrackersTab(),
        '/settings': (context) => SettingsTab(),
      },
    );
  }
}
