import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsNewPage extends StatefulWidget {
  const SettingsNewPage({Key? key}) : super(key: key);

  @override
  State<SettingsNewPage> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsNewPage> {
  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App Settings State
  bool pushNotifications = true;
  bool darkMode = false;

  // User & Loading State (explicit non-null defaults)
  String username = "User";
  String userRole = "User";
  String email = "";
  String phoneNumber = "";
  bool _isSigningOut = false;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetch user profile data safely from Firebase Auth and Firestore
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (mounted) {
          setState(() {
            if (userDoc.exists && userDoc.data() != null) {
              final Map<String, dynamic> data =
                  userDoc.data() as Map<String, dynamic>;
              
              username = (data['username'] ?? user.displayName ?? "User").toString();
              userRole = (data['role'] ?? "Member").toString();
              phoneNumber = (data['phone'] ?? data['phoneNumber'] ?? user.phoneNumber ?? "").toString();
            } else {
              username = (user.displayName ?? "User").toString();
              phoneNumber = (user.phoneNumber ?? "").toString();
            }
            email = (user.email ?? "").toString();
            _isLoadingUser = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            username = (user.displayName ?? user.email ?? "User").toString();
            email = (user.email ?? "").toString();
            phoneNumber = (user.phoneNumber ?? "").toString();
            _isLoadingUser = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  /// Sign Out Logic
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out of AETHER?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Log Out",
              style: TextStyle(color: Color(0xFFEF323B), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Log out failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSigningOut = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const lightBg = Color(0xFFEBF2FF);

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                color: primaryBlue,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your account and preferences',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // --- Profile Info Card ---
                    _buildProfileCard(primaryBlue),

                    const SizedBox(height: 16),

                    // --- App Settings Card ---
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Text(
                              'App Settings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEF2F6)),
                          _buildSwitchRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Push notifications',
                            subtitle: 'Receive air quality alerts',
                            value: pushNotifications,
                            onChanged: (val) => setState(() => pushNotifications = val),
                          ),
                          const Divider(height: 1, indent: 50, color: Color(0xFFEEF2F6)),
                          _buildSwitchRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Dark mode',
                            subtitle: 'Adjust theme appearance',
                            value: darkMode,
                            onChanged: (val) => setState(() => darkMode = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- More Info Card ---
                    _buildCardWrapper(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Text(
                              'More',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEF2F6)),
                          _buildAboutUsDropdown(primaryBlue),
                          const Divider(height: 1, indent: 50, color: Color(0xFFEEF2F6)),
                          _buildPrivacyPolicyDropdown(primaryBlue),
                          const Divider(height: 1, indent: 50, color: Color(0xFFEEF2F6)),
                          _buildTermsDropdown(primaryBlue),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Log Out Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSigningOut ? null : _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF233C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: _isSigningOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          _isSigningOut ? 'Signing out...' : 'Log Out',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Footer Version Info ---
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Text(
                      'Home Medix Physical Therapy, Caregiving & Nursing Services',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile Card Design - Completely Safe Against Null JS Errors
  Widget _buildProfileCard(Color primaryColor) {
    // Safe string parsing for initial avatar
    final String safeUsername = username.isEmpty ? "User" : username;
    final String initial = safeUsername[0].toUpperCase();

    final String displayEmail = email.trim().isEmpty ? "No email provided" : email;
    final String displayPhone = phoneNumber.trim().isEmpty ? "+63 912 345 6789" : phoneNumber;

    return _buildCardWrapper(
      child: InkWell(
        onTap: () {
          // Account Management Tap Action
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingUser ? "Loading..." : safeUsername,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userRole,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Tap to manage account",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email Row
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: Color(0xFF475569)),
                  const SizedBox(width: 10),
                  Text(
                    displayEmail,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Telephone / Phone Row
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF475569)),
                  const SizedBox(width: 10),
                  Text(
                    displayPhone,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper Card Container Wrapper
  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Switch Row Item
  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  /// About Us Dropdown
  Widget _buildAboutUsDropdown(Color primaryColor) {
    return _baseExpansionTile(
      title: 'About us',
      icon: Icons.shield_outlined,
      iconColor: primaryColor,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Empowering Communities Through Real-Time Air Quality Insights"),
          _bodyText("AETHER is an innovative IoT-based air quality tracking system designed to bridge the gap between air pollutant data and senior citizen health."),
        ],
      ),
    );
  }

  /// Privacy Policy Dropdown
  Widget _buildPrivacyPolicyDropdown(Color primaryColor) {
    return _baseExpansionTile(
      title: 'Privacy policy',
      icon: Icons.article_outlined,
      iconColor: primaryColor,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText("Last Updated: March 2026"),
          _sectionTitle("Data We Collect"),
          _bodyText("User Profile Information: Name and email stored via Firebase Authentication."),
        ],
      ),
    );
  }

  /// Terms Dropdown
  Widget _buildTermsDropdown(Color primaryColor) {
    return _baseExpansionTile(
      title: 'Terms and conditions',
      icon: Icons.article_outlined,
      iconColor: primaryColor,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bodyText("Last Updated: March 2026"),
          _sectionTitle("Use of Service"),
          _bodyText("AETHER is provided for educational and informational purposes."),
        ],
      ),
    );
  }

  /// Expansion Tile Base
  Widget _baseExpansionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
      );

  Widget _bodyText(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: Color(0xFF64748B),
        ),
      );
}