import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_account_page.dart';
import '../../main.dart';

class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool pushNotifications = true;
  bool darkMode = false;
  bool _isSigningOut = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color customBgColor = const Color(0xFFF8FAF5);

  String username = "User";
  String email = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        setState(() {
          username = userDoc.exists
              ? (userDoc['username'] ?? user.email ?? "User")
              : (user.email ?? "User");

          email = user.email ?? "";
        });
      } catch (e) {
        setState(() {
          username = user.email ?? "User";
          email = user.email ?? "";
        });
      }
    }
  }

Future<void> _signOut() async {
  bool confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Sign Out"),
      content: const Text("Are you sure you want to log out of PolluTracker?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Sign Out",
            style: TextStyle(color: Color.fromARGB(255, 82, 163, 255)),
          ),
        ),
      ],
    ),
  ) ?? false;

  if (confirm) {
    setState(() => _isSigningOut = true);
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildProfileHeader(user),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12),

            // _buildSectionHeader('App Settings'),
 //           _buildActionTile('Tracking settings', Icons.chevron_right),
 //           _buildActionTile('Add new saved locations', Icons.add),

            // _buildSwitchTile(
            //   'Push notifications',
            //   pushNotifications,
            //   (val) => setState(() => pushNotifications = val),
            // ),
            // _buildSwitchTile(
            //   'Dark mode',
            //   themeNotifier.value == ThemeMode.dark,
            //   (val) {
            //     themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
            //     setState(() {});
            //   },
            // ),

            // const Divider(height: 32, thickness: 0.5, color: Colors.black12),

            _buildSectionHeader('More'),
            _buildAboutUsDropdown(),
            _buildPrivacyPolicyDropdown(),
            _buildTermsDropdown(),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _isSigningOut ? null : _signOut,
                icon: _isSigningOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.logout, color: Colors.white, size: 20),
                label: _isSigningOut ? const Text("Signing out...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : const Text("Sign Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 82, 163, 255),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFF90CAF9),
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? const Icon(Icons.pets, size: 45, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF545E56)),
                ),
                Text(
                  email,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black45),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ManageAccountPage()),
                    ).then((_) => setState(() {}));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Manage account',
                          style: TextStyle(
                              color: Colors.black45,
                              decoration: TextDecoration.underline)),
                      Icon(Icons.chevron_right,
                          color: Colors.black45, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutUsDropdown() {
    return _baseExpansionTile(
      title: 'About us',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Empowering Communities Through Real-Time Air Quality Insights"),
          _bodyText("PolluTracker is an innovative IoT-based air quality tracking system designed to bridge the gap between environmental data and public health."),
          _sectionTitle("Our Technology"),
          _bodyText("Using Arduino microcontrollers and sensors (MQ9, MQ135, and MQ2) to monitor PM2.5, CO₂, and CO."),
          _sectionTitle("The Developers"),
          _bodyText("The application is developed by 3rd year IT students: Gaspar, Edward, Dela Cruz, Alvin Ken, Gatapia, Clarence Joaquin, Gelaga, Kerby, and Gonzales, Stephen Andrei"),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyDropdown() {
    return _baseExpansionTile(
      title: 'Privacy policy',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText("Last Updated: March 2026"),
          _sectionTitle("Data We Collect"),
          _bodyText("Location Data: Because PolluTracker is location-specific, we use GPS technology to provide air quality measurements relative to your position. This data is used to visualize pollution hotspots."),
          _bodyText("User Profile Information: We store the name and email provided through Firebase Authentication to personalize your experience."),
          _bodyText("Sensor Data: Pollutant concentrations (CO₂, CO, PM2.5) collected by our IoT devices are stored to generate forecasts and historical trends."),
          _sectionTitle("How We Use Data"),
          _bodyText("To provide real-time air quality alerts and health advice."),
          _bodyText("To assist Local Government Units (LGUs) and researchers in identifying environmental patterns."),
          _bodyText("To improve the application’s accessibility and performance on Android devices."),
          _sectionTitle("Data Sharing"),
          _bodyText("We do not sell your personal information. Aggregated, non-identifiable environmental data may be shared with environmental advocacy groups or researchers to support public health initiatives."),
        ]
      ),
    );
  }

  Widget _buildTermsDropdown() {
    return _baseExpansionTile(
      title: 'Terms and conditions',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText("Last Updated: March 2026"),
          _sectionTitle("Use of Service"),
          _bodyText("PolluTracker is provided for educational and informational purposes. While we strive for high precision using our MQ-series sensors, the data provided should not replace professional medical advice or official government emergency broadcasts."),
          _sectionTitle("Device Limitations"),
          _bodyText("The PolluTracker system is a portable IoT solution. Accuracy can be affected by environmental factors, sensor calibration, and Wi-Fi connectivity. The application currently supports the detection of specific particles (PM2.5, CO₂, CO) only."),
          _sectionTitle("User Responsibilities"),
          _bodyText("Users are encouraged to use the Health Precautionaries and alerts provided by the app to make informed decisions. Users must not attempt to reverse-engineer the IoT device or the Flutter application."),
          _sectionTitle("Scope of Support"),
          _bodyText("The application is currently delimited to Android devices. We reserve the right to update the application and sensor firmware to improve accuracy and user experience."),
          _sectionTitle("Disclaimer"),
          _bodyText("PolluTracker shall not be held liable for any health issues arising from environmental exposure. Our goal is to provide a reference tool to help users minimize risk through awareness."),
        ]
      ),
    );
  }

  Widget _baseExpansionTile({required String title, required Widget content}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: content,
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF545E56))),
      );

  Widget _bodyText(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, height: 1.4, color: Color(0xFF64748B)));

  Widget _buildSectionHeader(String title) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280))));
  }

  Widget _buildActionTile(String title, IconData trailingIcon) {
    return ListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 16, color: Colors.black87)),
        trailing: Icon(trailingIcon, color: Colors.black26));
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF5C6BC0)),
    );
  }
}