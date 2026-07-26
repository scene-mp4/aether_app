import 'package:flutter/material.dart';

class AdminTrackersTab extends StatelessWidget {
  const AdminTrackersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Grey background to match the card edges
      backgroundColor: const Color(0xFFF8FAFC),
      // Right-side sliding notification drawer
      endDrawer: const _NotificationsEndDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Blue Header Banner
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Prominent Add New Button
                  _buildAddNewButton(),
                  const SizedBox(height: 20),

                  // List of Trackers
                  _buildTrackerCard(
                    title: 'Tracker 1',
                    status: 'Active',
                    location: 'Location',
                    lastUpdate: '2 min ago',
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerCard(
                    title: 'Tracker 2',
                    status: 'Active',
                    location: 'Location',
                    lastUpdate: '5 min ago',
                  ),
                  const SizedBox(height: 40), // Extra space at bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AETHER Branded Header
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3), // Blue background
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
              // Clickable Notification Bell Icon (Opens End Drawer from Right)
              Builder(
                builder: (innerContext) {
                  return GestureDetector(
                    onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications, color: Colors.white, size: 26),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF2B52F3), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Text(
            'Trackers',
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

  // Floating Action Button Style Add Tracker
  Widget _buildAddNewButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Brighter blue
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1D4ED8), // Dark blue shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Add New Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic Tracker Details Card
  Widget _buildTrackerCard({
    required String title,
    required String status,
    required String location,
    required String lastUpdate,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            // Top Row: Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Light green background
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle Row: Location and Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Last Update\n$lastUpdate',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bottom Buttons
            Row(
              children: [
                Expanded(child: _buildCardActionButton(icon: Icons.edit_note, label: 'Edit')),
                const SizedBox(width: 12),
                Expanded(child: _buildCardActionButton(icon: Icons.delete_outline, label: 'Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Generic Grey Edit/Delete Button inside cards
  Widget _buildCardActionButton({required IconData icon, required String label}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light grey
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Right-Side Notifications Drawer
class _NotificationsEndDrawer extends StatelessWidget {
  const _NotificationsEndDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Text(
                          '3',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                    IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    tooltip: 'Close',
                    onPressed: () {
                      Navigator.of(context).pop(); // Closes the end drawer
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // Notification Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: const [
                  _NotificationTile(
                    icon: Icons.warning_amber_rounded,
                    iconBgColor: Color(0xFFFEF3C7),
                    iconColor: Color(0xFFD97706),
                    title: 'High PM2.5 Level Alert',
                    subtitle: 'Common Area AQI reached 125 (Unhealthy).',
                    time: '10 min ago',
                    isUnread: true,
                  ),
                  _NotificationTile(
                    icon: Icons.air,
                    iconBgColor: Color(0xFFFEE2E2),
                    iconColor: Color(0xFFDC2626),
                    title: 'Critical CO2 Elevation',
                    subtitle: 'Senior Care Unit B CO2 level exceeded 850 ppm.',
                    time: '25 min ago',
                    isUnread: true,
                  ),
                  _NotificationTile(
                    icon: Icons.check_circle_outline,
                    iconBgColor: Color(0xFFDCFCE7),
                    iconColor: Color(0xFF16A34A),
                    title: 'Alert Resolved',
                    subtitle: 'Therapy Wing O3 levels returned to normal limits.',
                    time: '1 hour ago',
                    isUnread: true,
                  ),
                  _NotificationTile(
                    icon: Icons.person_add_alt_1,
                    iconBgColor: Color(0xFFDBEAFE),
                    iconColor: Color(0xFF2563EB),
                    title: 'New Tracker Assigned',
                    subtitle: 'Device #AETH-07 registered to Nursing Station.',
                    time: '3 hours ago',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Single Notification List Item Tile
class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const _NotificationTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isUnread ? const Color(0xFFF8FAFC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}