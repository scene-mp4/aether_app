import 'package:flutter/material.dart';

class AdminAdviceTab extends StatefulWidget {
  const AdminAdviceTab({super.key});

  @override
  State<AdminAdviceTab> createState() => _AdminAdviceTabState();
}

class _AdminAdviceTabState extends State<AdminAdviceTab> {
  // All dropdown options for Trigger condition
  final List<String> _triggerOptions = const [
    'Good - AQI',
    'Moderate - AQI',
    'Unhealthy for Sensitive Groups - AQI',
    'Unhealthy - AQI',
    'Very Unhealthy - AQI',
    'Hazardous - AQI',
    'Good - PM1.0',
    'Moderate - PM1.0',
    'Polluted - PM1.0',
    'Very Polluted - PM1.0',
    'Severely Polluted - PM1.0',
    'Good - PM2.5',
    'Moderate - PM2.5',
    'Polluted - PM2.5',
    'Very Polluted - PM2.5',
    'Severely Polluted - PM2.5',
    'Good - PM10',
    'Moderate - PM10',
    'Polluted - PM10',
    'Very Polluted - PM10',
    'Severely Polluted - PM10',
    'Good - CO',
    'Moderate - CO',
    'Polluted - CO',
    'Very Polluted - CO',
    'Severely Polluted - CO',
    'Good - CO2',
    'Moderate - CO2',
    'Polluted - CO2',
    'Very Polluted - CO2',
    'Severely Polluted - CO2',
    'Good - O3',
    'Moderate - O3',
    'Polluted - O3',
    'Very Polluted - O3',
    'Severely Polluted - O3',
    'Very Uncomfortable - Temperature',
    'Uncomfortable - Temperature',
    'Slightly Uncomfortable - Temperature',
    'Comfortable - Temperature',
    'Very Comfortable - Temperature',
    'Very Uncomfortable - Humidity',
    'Uncomfortable - Humidity',
    'Slightly Uncomfortable - Humidity',
    'Comfortable - Humidity',
    'Very Comfortable - Humidity',
  ];

  // Modal for Add / Edit Advice
  void _showAdviceModal({
    String? title,
    String? trigger,
    String? message,
    String? recommendation,
  }) {
    final bool isEditing = title != null;
    final titleController = TextEditingController(text: title ?? '');
    final messageController = TextEditingController(text: message ?? '');
    final recommendationController =
        TextEditingController(text: recommendation ?? '');

    String? selectedTrigger = (trigger != null && _triggerOptions.contains(trigger))
        ? trigger
        : _triggerOptions.first;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Advice' : 'Add New Advice',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Advice Title Field
                      _buildModalInputField(
                        'Title',
                        titleController,
                        'e.g., Moderate Air Quality',
                      ),
                      const SizedBox(height: 16),

                      // Trigger Dropdown Field
                      _buildTriggerDropdown(
                        selectedTrigger,
                        (newValue) {
                          setModalState(() {
                            selectedTrigger = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Message Field
                      _buildModalInputField(
                        'Message',
                        messageController,
                        'Enter advice message...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Recommendation Field
                      _buildModalInputField(
                        'Recommendation',
                        recommendationController,
                        'Enter health recommendations...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Modal Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B62F6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isEditing ? 'Edit Advice' : 'Add Advice',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTriggerDropdown(
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trigger Condition',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B62F6)),
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
          ),
          items: _triggerOptions.map((String trigger) {
            return DropdownMenuItem<String>(
              value: trigger,
              child: Text(
                trigger,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildModalInputField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B62F6)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const _NotificationsEndDrawer(),
      body: Column(
        children: [
          // Fixed Header pinned at the top
          _buildHeader(context),

          // Scrollable body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildAddNewButton(),
                  const SizedBox(height: 20),

                  // Advice Card 1 - Moderate
                  _buildAdviceCard(
                    title: 'Moderate Air Quality',
                    trigger: 'Moderate - AQI',
                    cardBgColor: const Color(0xFFFEFCE8),
                    borderColor: const Color(0xFFFEF08A),
                    iconData: Icons.info_outline,
                    iconColor: const Color(0xFFD97706),
                    message:
                        'Air quality is acceptable. However, unusually sensitive individuals may experience minor respiratory symptoms.',
                    recommendation:
                        'Consider reducing prolonged or heavy outdoor activities for sensitive groups.',
                  ),
                  const SizedBox(height: 16),

                  // Advice Card 2 - Unhealthy for Sensitive Groups
                  _buildAdviceCard(
                    title: 'Unhealthy for Sensitive Groups',
                    trigger: 'Unhealthy for Sensitive Groups - AQI',
                    cardBgColor: const Color(0xFFFFF7ED),
                    borderColor: const Color(0xFFFFEDD5),
                    iconData: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFC2410C),
                    message:
                        'Members of sensitive groups may experience health effects. The general public is less likely to be affected.',
                    recommendation:
                        'Active seniors and those with respiratory disease should limit prolonged outdoor exertion.',
                  ),
                  const SizedBox(height: 16),

                  // Advice Card 3 - Unhealthy Air Quality
                  _buildAdviceCard(
                    title: 'Unhealthy Air Quality',
                    trigger: 'Unhealthy - AQI',
                    cardBgColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    iconData: Icons.warning_rounded,
                    iconColor: const Color(0xFFDC2626),
                    message:
                        'Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects.',
                    recommendation:
                        'Everyone should avoid prolonged or heavy exertion outdoors. Keep windows closed.',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            'Advice',
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

  Widget _buildAddNewButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1D4ED8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAdviceModal(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Add New Advice',
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

  Widget _buildAdviceCard({
    required String title,
    required String trigger,
    required Color cardBgColor,
    required Color borderColor,
    required IconData iconData,
    required Color iconColor,
    required String message,
    required String recommendation,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF713F12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trigger: $trigger',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF854D0E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Message section
          const Text(
            'Message',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF713F12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Recommendation section
          const Text(
            'Recommendation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF713F12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // Edit & Delete Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildCardActionButton(
                  icon: Icons.edit_note,
                  label: 'Edit',
                  onTap: () => _showAdviceModal(
                    title: title,
                    trigger: trigger,
                    message: message,
                    recommendation: recommendation,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
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