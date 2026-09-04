// TO RUN THE PROGRAM USE RUN.BAT SCRIPT TO GET AI ASSISTANT TO WORK PROPERLY

// navigation
import 'package:flutter/material.dart';
import 'package:pollutracker_app/screens/admin_navbar.dart';
import 'package:pollutracker_app/services/notification_service.dart';
import 'screens/login.dart';
import 'screens/bottom_navbar.dart';

// firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stores/app_data_store.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppDataStore(),
      child: const MyApp(),
    ),
  );
}

const Color kPrimaryColor = Color(0xFF0052FF);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AETHER App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary:   kPrimaryColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/login':         (context) => LoginScreen(),
        '/bottom_navbar': (context) => BottomNavbar(),
        '/admin_navbar':  (context) => const AdminBottomNavbar(),
      },
    );
  }
}

// ── AuthGate ──────────────────────────────────────────────────────────────────
//
// Watches Firebase auth state.  When the UID changes (login / account switch):
//   → shows a loading spinner
//   → _RoleRouter (keyed by UID) is rebuilt from scratch
//   → _RoleRouter awaits clear(), fetches role, awaits initialize()
//   → then shows the correct navbar
//
// When the user logs out:
//   → awaits clear() then shows LoginScreen
//
// KEY DESIGN DECISIONS
// 1. AuthGate is a StatefulWidget so _lastUid survives StreamBuilder rebuilds.
// 2. _RoleRouter is keyed with ValueKey(uid) so Flutter throws away the old
//    State and creates a new one on every account switch — guaranteeing a
//    fresh role fetch and fresh initialize() with no leftover state.
// 3. clear() is awaited inside _RoleRouter BEFORE initialize() so no old
//    stream callbacks can fire during the new session.
// ─────────────────────────────────────────────────────────────────────────────

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

        // Firebase hasn't reported yet
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        // ── Logged in ─────────────────────────────────────────────────────
        if (snap.hasData) {
          final uid = snap.data!.uid;

          // Track the current UID so we can detect a real account switch
          if (uid != _lastUid) {
            _lastUid = uid;
          }

          // _RoleRouter is keyed by uid so it's rebuilt fresh on every
          // account switch, guaranteeing a new clear() + initialize() cycle.
          return _RoleRouter(key: ValueKey(uid), uid: uid);
        }

        // ── Logged out ────────────────────────────────────────────────────
        if (_lastUid != null) {
          _lastUid = null;
          // Clear synchronously after the frame — store handles the async
          // cancel internally via its own _clearing guard.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<AppDataStore>().clear();
          });
        }

        FlutterNativeSplash.remove();

        return LoginScreen();
      },
    );
  }
}

// ── _RoleRouter ───────────────────────────────────────────────────────────────
//
// StatefulWidget keyed by uid — a new instance is created for every
// account switch, so initState() always runs fresh.
//
// Sequence:
//   1. await store.clear()          — cancels ALL old Firestore streams
//   2. fetch role from Firestore    — determines which navbar to show
//   3. await store.initialize()     — opens per-user tracker streams
//   4. if admin: await store.initializeAdmin()  — opens all-devices stream
//   5. setState → show correct navbar
//
// clear() is awaited in step 1, so by the time initialize() runs in step 3
// there are zero lingering stream callbacks that could corrupt new state.
// ─────────────────────────────────────────────────────────────────────────────

class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({required super.key, required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  String? _role;      // null = still resolving
  bool    _done = false;

  @override
  void initState() {
    super.initState();
    _resolveAndInit();
  }

  Future<void> _resolveAndInit() async {
    final store = context.read<AppDataStore>();

    // Step 1 — await full stream cancellation before doing anything else.
    // This is the critical fix: clear() is now async and awaits every
    // StreamSubscription.cancel() future, so no old callbacks can fire
    // after this line returns.
    await store.clear();

    if (!mounted) return;

    // Step 2 — fetch user role from Firestore
    String role = 'user';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      role = (doc.data()?['role'] as String?) ?? 'user';
    } catch (e) {
      // Firestore lookup failed — default to regular user
      if (mounted) {
        debugPrint('[_RoleRouter] role fetch failed: $e — defaulting to user');
      }
    }

    if (!mounted) return;

    // Step 3 — initialize the store for this user.
    // Because clear() completed above, initialize() starts with a fully
    // clean slate — no old streams, no stale data.
    await store.initialize();

    if (!mounted) return;

    // Step 4 — if admin, also open the all-devices stream
    if (role == 'admin') {
      await store.initializeAdmin();
    }

    if (!mounted) return;

    FlutterNativeSplash.remove();
    
    setState(() {
      _role = role;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) return const _LoadingScaffold();

    return _role == 'admin'
        ? const AdminBottomNavbar()
        : BottomNavbar();
  }
}

// ── Shared loading widget ─────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}