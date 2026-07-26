import 'package:flutter/material.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Banner
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat Cards Grid
                  _buildStatCardsGrid(),
                  const SizedBox(height: 16),

                  // Air Quality Index (24h) Chart Card
                  _buildAirQualityChartCard(),
                  const SizedBox(height: 16),

                  // Pollutant Distribution Pie Chart Card
                  _buildPollutantDistributionCard(),
                  const SizedBox(height: 16),

                  // Facility Status List Card
                  _buildFacilityStatusCard(),
                  const SizedBox(height: 16),

                  // Recent Alerts List Card
                  _buildRecentAlertsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Widget
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3), // Blue background
      padding: EdgeInsets.only(
        top: topPadding + 16,
        bottom: 20,
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
// Clickable Notification Bell Icon
              GestureDetector(
                onTap: () => _showNotificationsBottomSheet(context),
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Dashboard',
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

  // Method to show the notifications bottom sheet
  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
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
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              // List Items
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
        );
      },
    );
  }
  // 2x2 Top Summary Cards Grid
  Widget _buildStatCardsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: const [
        _StatCard(
          icon: Icons.monitor_heart,
          iconBgColor: Color(0xFF3B82F6),
          title: 'Total Trackers',
          value: '0',
          subtitle: '+0 this month',
        ),
        _StatCard(
          icon: Icons.people,
          iconBgColor: Color(0xFF22C55E),
          title: 'Active Users',
          value: '0',
          subtitle: '+0 this week',
        ),
        _StatCard(
          icon: Icons.warning_rounded,
          iconBgColor: Color(0xFFF97316),
          title: 'Critical Alerts',
          value: '0',
          subtitle: '0 resolved today',
        ),
        _StatCard(
          icon: Icons.air,
          iconBgColor: Color(0xFFEAB308),
          title: 'Average AQI',
          value: '0',
          subtitle: 'AQI Level',
        ),
      ],
    );
  }

  // Air Quality Index Line Chart Widget
  Widget _buildAirQualityChartCard() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Air Quality Index (24h)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _AqiChartPainter(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _ChartLegendItem(color: Color(0xFFEAB308), label: 'PM2.5'),
                    _ChartLegendItem(color: Color(0xFF3B82F6), label: 'CO2'),
                    _ChartLegendItem(color: Color(0xFFEF4444), label: 'CO'),
                    _ChartLegendItem(color: Color(0xFFA855F7), label: 'O3'),
                  ],
                ),
              ],
            ),
          );
        }

  // Pollutant Distribution Pie Chart Widget
  Widget _buildPollutantDistributionCard() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pollutant Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                painter: _PieChartPainter(),
              ),
            ),
          ],
        ),
      );
    }

  // Facility Status Section
  Widget _buildFacilityStatusCard() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Facility Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            _FacilityStatusItem(
              title: 'Tracker 1 Location',
              aqi: 0,
              status: 'Good',
              statusColor: Color(0xFFDCFCE7),
              textColor: Color(0xFF15803D),
            ),
            _FacilityStatusItem(
              title: 'Tracker 2 Location',
              aqi: 0,
              status: 'Unhealthy',
              statusColor: Color(0xFFFFEDD5),
              textColor: Color(0xFFC2410C),
            ),
          ],
        ),
      );
    }

  // Recent Alerts Section
  Widget _buildRecentAlertsCard() {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 12),
            _AlertItem(
              location: 'Tracker 1 Location',
              detail: 'PM2.5: 125',
              time: '10 min ago',
              status: 'Unhealthy',
              statusBgColor: Color(0xFFFEF3C7),
              statusTextColor: Color(0xFFB45309),
            ),
            SizedBox(height: 10),
            _AlertItem(
              location: 'Tracker 2 Location',
              detail: 'CO2: 850 ppm',
              time: '10 min ago',
              status: 'Unhealthy',
              statusBgColor: Color(0xFFFEF3C7),
              statusTextColor: Color(0xFFB45309),
            ),
          ],
        ),
      );
    }
  }


// Single Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12), // Small tight gap directly between icon and text
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Single Notification Tile Widget
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

// Chart Legend Item
class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Facility Status Row Item
class _FacilityStatusItem extends StatelessWidget {
  final String title;
  final int aqi;
  final String status;
  final Color statusColor;
  final Color textColor;

  const _FacilityStatusItem({
    required this.title,
    required this.aqi,
    required this.status,
    required this.statusColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                'AQI: $aqi',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alert Box Row Item
class _AlertItem extends StatelessWidget {
  final String location;
  final String detail;
  final String time;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;

  const _AlertItem({
    required this.location,
    required this.detail,
    required this.time,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Light yellow tint background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
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
            detail,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for 24h Line Chart
class _AqiChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 32.0;
    final double paddingBottom = 24.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y Axis Values & Dotted Grid
final List<int> yValues = [0, 150, 300, 450, 600];
    for (int val in yValues) {
      double y = chartHeight - (val / 600) * chartHeight;
      canvas.drawLine(
          Offset(paddingLeft, y), Offset(size.width, y), gridPaint);

      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - 6));
    }

    // X Axis Labels
    final List<String> xLabels = ['00:00', '04:00', '08:00', '12:00', '20:00'];
    for (int i = 0; i < xLabels.length; i++) {
      double x = paddingLeft + (i / (xLabels.length - 1)) * chartWidth;
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - (textPainter.width / 2), size.height - 16));
    }

    // Purple Trend Line
    final List<Offset> points = [
      Offset(paddingLeft, chartHeight - (50 / 600) * chartHeight),
      Offset(paddingLeft + 0.25 * chartWidth, chartHeight - (40 / 600) * chartHeight),
      Offset(paddingLeft + 0.50 * chartWidth, chartHeight - (60 / 600) * chartHeight),
      Offset(paddingLeft + 0.75 * chartWidth, chartHeight - (80 / 600) * chartHeight),
      Offset(paddingLeft + chartWidth, chartHeight - (65 / 600) * chartHeight),
    ];

    final Paint linePaint = Paint()
      ..color = const Color(0xFFA855F7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Path path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Points / Dots
    final Paint dotPaint = Paint()..color = const Color(0xFFA855F7);
    for (var pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Pie Chart
class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.height / 2.5;

    final List<double> values = [0.35, 0.28, 0.20, 0.10, 0.07];
    final List<Color> colors = [
      const Color(0xFFEAB308), // PM2.5 35%
      const Color(0xFF22C55E), // PM10 28%
      const Color(0xFF3B82F6), // CO2 20%
      const Color(0xFFEF4444), // CO 10%
      const Color(0xFFA855F7), // O3 7%
    ];

    double startAngle = -1.57; // Start top

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = values[i] * 2 * 3.141592653589793;
      final Paint slicePaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        slicePaint,
      );
      startAngle += sweepAngle;
    }

    // Pie Chart Overlay Labels
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, Color color, Offset pos) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos);
    }

    drawLabel('PM2.5 35%', const Color(0xFFEAB308), Offset(center.dx + 25, center.dy - radius - 20));
    drawLabel('PM10 28%', const Color(0xFF22C55E), Offset(center.dx - radius - 70, center.dy - 30));
    drawLabel('CO2 20%', const Color(0xFF3B82F6), Offset(center.dx - 40, center.dy + radius + 10));
    drawLabel('CO 10%', const Color(0xFFEF4444), Offset(center.dx + radius - 5, center.dy + 35));
    drawLabel('O3 7%', const Color(0xFFA855F7), Offset(center.dx + radius + 5, center.dy - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}