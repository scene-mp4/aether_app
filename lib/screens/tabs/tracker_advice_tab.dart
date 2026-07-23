import 'package:flutter/material.dart';

class TrackerAdviceTab extends StatelessWidget {
  const TrackerAdviceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Air Quality Status Banner Card
        _buildStatusBanner(),
        const SizedBox(height: 16),

        // 2. What You Should Do Card
        _buildWhatYouShouldDoCard(),
        const SizedBox(height: 16),

        // 3. All Current Readings Card
        _buildAllCurrentReadingsCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- 1. AIR QUALITY STATUS BANNER ---
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF16A34A),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Air Quality is Good",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14532D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "AQI 42 — No immediate action needed for residents.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF15803D),
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

  // --- 2. WHAT YOU SHOULD DO CARD ---
  Widget _buildWhatYouShouldDoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What You Should Do",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Action 1: Ventilation
          _buildActionItem(
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF2563EB),
            title: "Keep Ventilation Going",
            description:
                "Air quality is currently good. Continue current ventilation practices to maintain safe levels.",
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFDBEAFE),
          ),
          const SizedBox(height: 10),

          // Action 2: Temperature
          _buildActionItem(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFFD97706),
            title: "Monitor Temperature",
            description:
                "Temperature is comfortable at 25.5°C. Monitor and adjust AC if it rises above 26°C.",
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
          ),
          const SizedBox(height: 10),

          // Action 3: Humidity
          _buildActionItem(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF16A34A),
            title: "Humidity is Fine",
            description:
                "Humidity at 55% is within the comfortable range. No action needed.",
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
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
                    fontSize: 14,
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

  // --- 3. ALL CURRENT READINGS CARD ---
  Widget _buildAllCurrentReadingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Current Readings",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          _buildReadingRow("PM1.0", "5.2 µg/m³", "Good", isSuperscript: true),
          _buildReadingRow("PM2.5", "9.0 µg/m³", "Good", isSuperscript: true),
          _buildReadingRow("PM10", "18.5 µg/m³", "Good", isSuperscript: true),
          _buildReadingRow("CO", "1.2 ppm", "Good"),
          _buildReadingRow("CO₂", "420 ppm", "Good", isSubscript: true),
          _buildReadingRow("O₃", "22 ppb", "Good", isSubscript: true),
          _buildReadingRow("Temperature", "25.5°C", "Very Comfortable"),
          _buildReadingRow("Humidity", "55%", "Comfortable", showDivider: false),

          const SizedBox(height: 12),
          const Text(
            "Pollutant classifications: ATMO (2025) · Temperature & humidity: ATMO (2025)",
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingRow(
    String label,
    String value,
    String status, {
    bool isSuperscript = false,
    bool isSubscript = false,
    bool showDivider = true,
  }) {
    final bool isVeryComfortable = status == "Very Comfortable";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Parameter Label
              _buildFormattedLabel(label, isSuperscript: isSuperscript, isSubscript: isSubscript),

              // Value & Status Badge
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isVeryComfortable
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  Widget _buildFormattedLabel(
    String label, {
    bool isSuperscript = false,
    bool isSubscript = false,
  }) {
    if (isSubscript && label.contains("₂")) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          children: const [
            TextSpan(text: "CO"),
            TextSpan(
              text: "2",
              style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    if (isSubscript && label.contains("₃")) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          children: const [
            TextSpan(text: "O"),
            TextSpan(
              text: "3",
              style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF0F172A),
      ),
    );
  }
}