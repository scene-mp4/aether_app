import 'package:flutter/material.dart';

class TrackerClimateTab extends StatefulWidget {
  const TrackerClimateTab({super.key});

  @override
  State<TrackerClimateTab> createState() => _TrackerClimateTabState();
}

class _TrackerClimateTabState extends State<TrackerClimateTab> {
  // Independent expand/collapse states for Temperature and Humidity cards
  bool _isTempExpanded = false;
  bool _isHumidityExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Temperature Card
        _buildMetricCard(
          icon: Icons.thermostat_outlined,
          iconColor: const Color(0xFFEA580C),
          title: "Temperature",
          value: "25.5°C",
          statusText: "Very Comfortable",
          statusBgColor: const Color(0xFFDCFCE7),
          statusTextColor: const Color(0xFF15803D),
          subText: "Very Comfortable: 20–25.9°C",
          isExpanded: _isTempExpanded,
          onToggleInfo: () {
            setState(() {
              _isTempExpanded = !_isTempExpanded;
            });
          },
          infoContent: _buildTemperatureInfoContent(),
        ),
        const SizedBox(height: 12),

        // 2. Humidity Card
        _buildMetricCard(
          icon: Icons.water_drop_outlined,
          iconColor: const Color(0xFF0284C7),
          title: "Humidity",
          value: "55%",
          statusText: "Comfortable",
          statusBgColor: const Color(0xFFDCFCE7),
          statusTextColor: const Color(0xFF15803D),
          subText: "Very Comfortable: 40–49.9%",
          isExpanded: _isHumidityExpanded,
          onToggleInfo: () {
            setState(() {
              _isHumidityExpanded = !_isHumidityExpanded;
            });
          },
          infoContent: _buildHumidityInfoContent(),
        ),
        const SizedBox(height: 16),

        // 3. Climate History Chart Card
        _buildClimateHistoryCard(),
        const SizedBox(height: 16),

        // 4. Climate Recommendations Card
        _buildRecommendationsCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- REUSABLE METRIC CARD ---
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String subText,
    required bool isExpanded,
    required VoidCallback onToggleInfo,
    required Widget infoContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onToggleInfo,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpanded ? const Color(0xFF2563EB) : const Color(0xFFDBEAFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: isExpanded ? Colors.white : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "More Info",
                        style: TextStyle(
                          fontSize: 11,
                          color: isExpanded ? Colors.white : const Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 14,
                        color: isExpanded ? Colors.white : const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Expanded Info Container
          if (isExpanded) ...[
            const SizedBox(height: 12),
            infoContent,
          ],

          const SizedBox(height: 12),

          // Value Display
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Subtext
          Text(
            subText,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // --- TEMPERATURE INFO CONTENT ---
  Widget _buildTemperatureInfoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "This is the air temperature inside the room. It rises when many people are present, when sunlight enters, or when ventilation is poor.",
            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            "Elderly and ill residents are more sensitive to heat. A too-warm room can cause dehydration, fatigue, and heat-related illness.",
            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            "Very Comfortable: 20–25.9°C · Comfortable: 17–19°C or 26–28.9°C (ATMO, 2025)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- HUMIDITY INFO CONTENT ---
  Widget _buildHumidityInfoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Humidity measures how much moisture is in the air. It rises with many occupants, bathing activities, or rainy weather.",
            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            "Too much humidity promotes mold growth and worsens breathing problems. Too little causes dry skin and irritated airways.",
            style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.4),
          ),
          SizedBox(height: 8),
          Text(
            "Very Comfortable: 40–49.9% · Comfortable: 35–39.9% or 50–64.9% (ATMO, 2025)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Climate History (Today)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _DotLegend(color: Color(0xFFEAB308), label: "Temp (°C)"),
              SizedBox(width: 12),
              _DotLegend(color: Color(0xFF3B82F6), label: "Humidity (%)"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: Size.infinite,
              painter: DualChartPainter(
                yLabels: const ["60", "45", "30", "15", "0"],
                xLabels: const ["12am", "4am", "8am", "12pm", "4pm", "8pm"],
                humidityPoints: const [0.93, 0.96, 0.86, 0.80, 0.83, 0.90],
                tempPoints: const [0.40, 0.38, 0.42, 0.45, 0.43, 0.41],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommendations Based on Climate",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            icon: Icons.thermostat,
            iconColor: const Color(0xFFEA580C),
            title: "Temperature Rises at Midday",
            description:
                "Temperature peaks around 12pm. Adjust the air conditioner in advance to keep residents comfortable (target 20–26°C).",
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFFEDD5),
          ),
          const SizedBox(height: 10),
          _buildRecommendationItem(
            icon: Icons.water_drop,
            iconColor: const Color(0xFF2563EB),
            title: "Humidity Drops During the Afternoon",
            description:
                "Low humidity may cause dry skin or irritated airways. Consider a humidifier during peak dry hours.",
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
          ),
          const SizedBox(height: 10),
          _buildRecommendationItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            title: "Evening Conditions Improve",
            description:
                "Temperature and humidity stabilize by 8pm. No special action needed during evening hours.",
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER CLASSES FOR DUAL CHART & LEGEND ---

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class DualChartPainter extends CustomPainter {
  final List<String> yLabels;
  final List<String> xLabels;
  final List<double> humidityPoints;
  final List<double> tempPoints;

  DualChartPainter({
    required this.yLabels,
    required this.xLabels,
    required this.humidityPoints,
    required this.tempPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 28.0;
    const double bottomPadding = 20.0;
    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw Grid Lines & Y Axis Labels
    final int yCount = yLabels.length;
    for (int i = 0; i < yCount; i++) {
      final double y = chartHeight * (i / (yCount - 1));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 4, y - (textPainter.height / 2)),
      );
    }

    // 2. Draw X Axis Ticks & Labels
    final int xCount = xLabels.length;
    for (int i = 0; i < xCount; i++) {
      final double x = leftPadding + (chartWidth * (i / (xCount - 1)));

      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), chartHeight + 4),
      );
    }

    void drawSeries(List<double> points, Color color) {
      if (points.isEmpty) return;

      final Path path = Path();
      final List<Offset> offsetPoints = [];

      for (int i = 0; i < points.length; i++) {
        final double x = leftPadding + (chartWidth * (i / (points.length - 1)));
        final double y = chartHeight * (1.0 - points[i]);
        offsetPoints.add(Offset(x, y));
      }

      path.moveTo(offsetPoints[0].dx, offsetPoints[0].dy);

      for (int i = 0; i < offsetPoints.length - 1; i++) {
        final Offset p0 = offsetPoints[i];
        final Offset p1 = offsetPoints[i + 1];
        final Offset controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final Offset controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }

      final Paint linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);
    }

    // 3. Draw Lines
    drawSeries(humidityPoints, const Color(0xFF3B82F6));
    drawSeries(tempPoints, const Color(0xFFEAB308));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}