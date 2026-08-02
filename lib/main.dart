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
import 'package:cloud_firestore/cloud_firestore.dart';

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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snap.hasData) {
          final uid = snap.data!.uid;
          if (uid != _lastUid) {
            _lastUid = uid;
            Future.microtask(() {
              if (mounted) {
                context.read<AppDataStore>().clear();
                context.read<AppDataStore>().initialize();
              }
            });
          }
          // Role-based routing — check Firestore for role
          return const _RoleRouter();
        }

        if (_lastUid != null) {
          _lastUid = null;
          Future.microtask(() {
            if (mounted) context.read<AppDataStore>().clear();
          });
        }

        return LoginScreen();
      },
    );
  }
}

// Separate widget that routes to the correct navbar based on role
class _RoleRouter extends StatelessWidget {
  const _RoleRouter();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return LoginScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final role = (snap.data?.data()
            as Map<String, dynamic>?)?['role'] as String? ?? 'user';

            if (role == 'admin') {
            Future.microtask(() {
              if (context.mounted) {
                context.read<AppDataStore>().initializeAdmin();
              }
            });
            return const AdminBottomNavbar();
          }

        return role == 'admin'
            ? const AdminBottomNavbar()
            : BottomNavbar();
      },
    );
  }
}