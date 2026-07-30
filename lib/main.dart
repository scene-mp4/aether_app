// navigation
import 'package:flutter/material.dart';
import 'package:pollutracker_app/screens/admin_navbar.dart';
import 'screens/login.dart';
import 'screens/bottom_navbar.dart';

// firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'stores/app_data_store.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    // FIX: ChangeNotifierProvider now wraps the entire app so every screen
    // and route can access AppDataStore via context.read / Consumer.
    ChangeNotifierProvider(
      create: (_) => AppDataStore(),
      child: MyApp(),
    ),
  );
}

const Color kPrimaryColor = Color(0xFF0052FF);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AETHER App",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      // FIX: Use AuthGate as the home so the store is initialised on login
      // and cleaned up on logout. The named routes below are still available
      // for any Navigator.pushNamed calls elsewhere in the app.
      home: const AuthGate(),
      routes: {
        '/login':        (context) => LoginScreen(),
        '/bottom_navbar': (context) => BottomNavbar(),
        '/admin_navbar':  (context) => AdminBottomNavbar(),
      },
    );
  }
}

// ── Auth gate ─────────────────────────────────────────────────────────────────
// Listens to Firebase Auth state. When a user logs in, initialises the
// AppDataStore (opens Firestore streams). When they log out, clears the store.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {

        // Still waiting for Firebase to report auth state
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (snap.hasData) {
          // Initialise the store after the current frame finishes building.
          // This is safe to call multiple times — the store guards against
          // double-initialisation internally.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppDataStore>().initialize();
          });

          // Navigate to the appropriate navbar based on user role.
          // Replace BottomNavbar() with AdminBottomNavbar() here if you
          // need role-based routing after the store is ready.
          return BottomNavbar();
        }

        // No user — show login screen and clear any stale store data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppDataStore>().clear();
        });

        return LoginScreen();
      },
    );
  }
}