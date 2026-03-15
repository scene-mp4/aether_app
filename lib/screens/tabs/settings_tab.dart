import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_account_page.dart';

class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool pushNotifications = true;
  bool darkMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color customBgColor = const Color(0xFFF8FAF5);

  // --- LOGOUT FUNCTION ---
  Future<void> _signOut() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to log out of PolluTracker?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Sign Out", style: TextStyle(color: Color.fromARGB(255, 82, 163, 255)))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _auth.signOut();
      // After signing out, Firebase usually handles the state change 
      // if you have an Auth Gate at the top level of your app.
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: customBgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _buildProfileHeader(user),
            const Divider(height: 1, thickness: 0.5, color: Colors.black12),
            
            _buildSectionHeader('App Settings'),
            _buildActionTile('Tracking settings', Icons.chevron_right),
            _buildActionTile('Add new saved locations', Icons.add),
            
            _buildSwitchTile(
              'Push notifications',
              pushNotifications,
              (val) => setState(() => pushNotifications = val),
            ),
            _buildSwitchTile(
              'Dark mode',
              darkMode,
              (val) => setState(() => darkMode = val),
            ),

            const Divider(height: 32, thickness: 0.5, color: Colors.black12),
            
            _buildSectionHeader('More'),
            _buildAboutUsDropdown(),
            _buildPrivacyPolicyDropdown(),
            _buildTermsDropdown(),

            const SizedBox(height: 30),

            // --- THE SIGN OUT BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: const Text("Sign Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 82, 163, 255),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.pets, size: 45, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? "User Name",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF545E56)),
                ),
                Text(
                  '@${user?.email?.split('@')[0] ?? "username"}',
                  style: const TextStyle(fontSize: 16, color: Colors.black45),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageAccountPage()),
                    ).then((_) => setState(() {}));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Text('Manage account', style: TextStyle(color: Colors.black45, decoration: TextDecoration.underline)),
                      Icon(Icons.chevron_right, color: Colors.black45, size: 18),
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

  // --- INFO DROPDOWNS ---
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
      content: _bodyText("Last Updated: March 2026\n\nPolluTracker uses GPS to provide real-time location-specific air quality data. We do not sell your personal information."),
    );
  }

  Widget _buildTermsDropdown() {
    return _baseExpansionTile(
      title: 'Terms and conditions',
      content: _bodyText("1. Use of Service: Educational purposes only.\n2. Limitations: Supports PM2.5, CO₂, CO only.\n3. Scope: Android devices only."),
    );
  }

  // --- REUSABLE BUILDERS ---
  Widget _baseExpansionTile({required String title, required Widget content}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        children: [Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: content)],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF545E56))),
  );

  Widget _bodyText(String text) => Text(text, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF64748B)));

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))));
  }

  Widget _buildActionTile(String title, IconData trailingIcon) {
    return ListTile(title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)), trailing: Icon(trailingIcon, color: Colors.black26));
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: const Color(0xFF5C6BC0)),
    );
  }
}