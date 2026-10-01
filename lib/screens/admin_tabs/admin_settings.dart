import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pollutracker_app/stores/app_data_store.dart';
import 'package:pollutracker_app/screens/tabs/notifications_screen.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  // ✅ Explicitly type the GlobalKey with 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // General Settings Controllers
  final TextEditingController _systemNameController =
      TextEditingController(text: 'AETHER Admin Portal');
  final TextEditingController _orgController = TextEditingController(
      text: 'Home Medix Physical Therapy, Caregiving');
  String _selectedTimezone = 'Asia/Manila (GMT+8)';

  // Notification Toggles
  bool _emailAlerts = true;
  bool _pushNotifications = true;
  bool _criticalAlerts = true;

  // Alert Threshold Controllers
  final TextEditingController _pm25Controller =
      TextEditingController(text: '35');
  final TextEditingController _pm10Controller =
      TextEditingController(text: '50');
  final TextEditingController _co2Controller =
      TextEditingController(text: '800');
  final TextEditingController _coController = TextEditingController(text: '9');
  final TextEditingController _o3Controller = TextEditingController(text: '70');
  final TextEditingController _tempController =
      TextEditingController(text: '32');
  final TextEditingController _humidityController =
      TextEditingController(text: '70');

  final List<String> _timezones = const [
    'Asia/Manila (GMT+8)',
    'UTC (GMT+0)',
    'America/New_York (GMT-5)',
    'Europe/London (GMT+0)',
  ];

  Future<void> _handleLogout() async {
    // FIX 1: await clear() so all Firestore streams are fully cancelled
    // before signOut() fires. clear() is now async — not awaiting it causes
    // old stream callbacks to fire during the next login and corrupt state.
    await context.read<AppDataStore>().clear();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Continue even if sign-out throws.
    }

    // FIX 2: No Navigator call — AuthGate listens to authStateChanges and
    // routes to LoginScreen automatically when signOut() completes.
    // Pushing '/login' manually bypasses AuthGate, breaking _RoleRouter's
    // ValueKey rebuild on the next login.
  }

  @override
  void dispose() {
    _systemNameController.dispose();
    _orgController.dispose();
    _pm25Controller.dispose();
    _pm10Controller.dispose();
    _co2Controller.dispose();
    _coController.dispose();
    _o3Controller.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // 2. Assign Scaffold Key
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const NotificationsScreen(), // 3. Use real-time NotificationsScreen drawer
      body: Column(
        children: [
          _buildHeader(context),

          // Scrollable Settings Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. General Settings Card
                  _buildSectionCard(
                    icon: Icons.language,
                    title: 'General Settings',
                    subtitle: 'Configure system preferences',
                    children: [
                      _buildLabel('System Name'),
                      _buildTextField(_systemNameController),
                      const SizedBox(height: 16),
                      _buildLabel('Organization'),
                      _buildTextField(_orgController),
                      const SizedBox(height: 16),
                      _buildLabel('Timezone'),
                      _buildDropdownField(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Notification Settings Card
                  _buildSectionCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification Settings',
                    subtitle: 'Manage alert thresholds and notifications',
                    children: [
                      _buildSwitchTile(
                        title: 'Email Alerts',
                        subtitle: 'Send email when AQI reaches unhealthy levels',
                        value: _emailAlerts,
                        onChanged: (val) => setState(() => _emailAlerts = val),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Real-time alerts to user mobile apps',
                        value: _pushNotifications,
                        onChanged: (val) => setState(() => _pushNotifications = val),
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      _buildSwitchTile(
                        title: 'Critical Alerts',
                        subtitle: 'Immediate notifications for hazardous conditions',
                        value: _criticalAlerts,
                        onChanged: (val) => setState(() => _criticalAlerts = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Alert Thresholds Card
                  _buildSectionCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Alert Thresholds',
                    subtitle: 'Configure when to trigger notifications',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'PM2.5 Threshold (µg/m³)',
                              controller: _pm25Controller,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'PM10 Threshold (µg/m³)',
                              controller: _pm10Controller,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'CO2 Threshold (ppm)',
                              controller: _co2Controller,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'CO Threshold (ppm)',
                              controller: _coController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'O3 Threshold (ppb)',
                              controller: _o3Controller,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'Temperature (°C)',
                              controller: _tempController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThresholdInput(
                              label: 'Humidity (%)',
                              controller: _humidityController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()), // Spacer for balance
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B52F3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reset to Defaults',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _handleLogout();
                      },
                      icon: const Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Exact header structure from AdminUsersTab
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3),
      padding: EdgeInsets.only(
        top: topPadding + 16,
        bottom: 15,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/Aether_logo_v1.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AETHER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: const Icon(Icons.notifications, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimezone,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          items: _timezones.map((tz) {
            return DropdownMenuItem(value: tz, child: Text(tz));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTimezone = val);
          },
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF2563EB),
          activeTrackColor: const Color(0xFFEFF6FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThresholdInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}

