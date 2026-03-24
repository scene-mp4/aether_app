import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class TrackersInfo extends StatefulWidget {
  final VoidCallback onBack;
  final String trackerId;
  final String trackerName;
  final String trackerLocation;

  TrackersInfo({
    required this.onBack,
    required this.trackerId,
    required this.trackerName,
    required this.trackerLocation,
  });

  @override
  _TrackersInfoState createState() => _TrackersInfoState();
}

class _TrackersInfoState extends State<TrackersInfo> {
  final Color primaryGreen = const Color(0xFFD1EBE9);

  // --- FORMULAS & CALCULATION HELPERS ---

  double calculateAbsoluteHumidity(double temp, double hum) {
    return (6.112 * exp((17.67 * temp) / (temp + 243.5)) * hum * 2.1674) /
        (273.15 + temp);
  }

  int calculatePM25AQI(double concentration) {
    if (concentration <= 0) return 0;
    final List<List<double>> bp = [
      [0.0, 12.0, 0, 50],
      [12.1, 35.4, 51, 100],
      [35.5, 55.4, 101, 150],
      [55.5, 150.4, 151, 200],
      [150.5, 250.4, 201, 300],
      [250.5, 350.4, 301, 400],
      [350.5, 500.4, 401, 500],
    ];
    for (var r in bp) {
      if (concentration >= r[0] && concentration <= r[1]) {
        return (((r[3] - r[2]) / (r[1] - r[0])) * (concentration - r[0]) + r[2])
            .round();
      }
    }
    return 500;
  }

  double calculatePPM(double ratio, double a, double b) {
    if (ratio <= 0 || ratio.isNaN) return 0.0;
    return a * pow(ratio, b);
  }

  double getCorrectionFactor(double t, double h) {
    return -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
  }

  int getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo = (co / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

  // --- COLOR & STATUS HELPERS ---

  Color _getColor(num aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade800;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return const Color(0xFF800000);
  }

  String _getStatus(num aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy (Sensitive)";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  Color _getTempColor(double t) {
    if (t >= 18 && t <= 26) return Colors.green;
    if ((t >= 10 && t < 18) || (t > 26 && t <= 30))
      return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getTempStatus(double t) {
    if (t >= 18 && t <= 26) return "Comfort";
    if (t > 26 && t <= 30) return "Warm";
    if (t < 18 && t >= 10) return "Cool";
    return "Extreme";
  }

  Color _getHumidityColor(double h) {
    if (h >= 30 && h <= 50) return Colors.green;
    if (h > 50 && h <= 70) return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getHumidityStatus(double h) {
    if (h >= 30 && h <= 50) return "Ideal";
    if (h > 50 && h <= 70) return "Moderate";
    return "High Risk";
  }

  Color _getLPGColor(double ppm) {
    if (ppm <= 200) return Colors.green;
    if (ppm <= 1000) return Colors.orange;
    return Colors.red;
  }

  String _getLPGStatus(double ppm) {
    if (ppm <= 200) return "Safe";
    if (ppm <= 1000) return "Warning";
    return "Dangerous";
  }

  Color _getCOColor(double ppm) {
    if (ppm <= 9) return Colors.green;
    if (ppm <= 35) return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getCOStatus(double ppm) {
    if (ppm <= 9) return "Normal";
    if (ppm <= 35) return "Harmful";
    return "Alert";
  }

  Color _getCO2Color(double ppm) {
    if (ppm <= 600) return Colors.green;
    if (ppm <= 1000) return Colors.yellow.shade800;
    return Colors.orange;
  }

  String _getCO2Status(double ppm) {
    if (ppm <= 600) return "Excellent";
    if (ppm <= 1000) return "Poor";
    return "High";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack,
        ),
        title: Text(
          widget.trackerName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.trackerId)
            .collection('readings')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final hasReading = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final data = hasReading
              ? snapshot.data!.docs.first.data() as Map<String, dynamic>
              : <String, dynamic>{};

          double t = hasReading ? (data['temperature'] ?? 0.0).toDouble() : 0.0;
          double h = hasReading ? (data['humidity'] ?? 0.0).toDouble() : 0.0;
          double pm25 = hasReading ? (data['pm25'] ?? 0.0).toDouble() : 0.0;
          double v2 = hasReading ? (data['mq2_v'] ?? 0.0).toDouble() : 0.0;
          double v9 = hasReading ? (data['mq9_v'] ?? 0.0).toDouble() : 0.0;
          double v135 = hasReading ? (data['mq135_v'] ?? 0.0).toDouble() : 0.0;

          double r2 = (hasReading && v2 > 0) ? (3.3 - v2) / v2 : 0.0;
          double r9 = (hasReading && v9 > 0) ? (3.3 - v9) / v9 : 0.0;
          double r135 = (hasReading && v135 > 0) ? (3.3 - v135) / v135 : 0.0;

          double lpg = calculatePPM(r2, 574.25, -2.222);
          double co = calculatePPM(r9, 1000.5, -1.969);
          double co2 = calculatePPM(
            r135 / (getCorrectionFactor(t, h).clamp(0.1, 10)),
            110.47,
            -2.862,
          );
          double nh3 = calculatePPM(r135, 102.2, -2.473);

          int pmAqi = calculatePM25AQI(pm25);
          int finalIAQI = getCompositeIAQI(co, co2, nh3, pmAqi);
          double absHum = calculateAbsoluteHumidity(t, h);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            children: [
              _buildAQICard(finalIAQI, "Just now", widget.trackerLocation),
              const SizedBox(height: 30),
              const Text(
                "Air Metrics",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 15),

              _buildPollutantTile(
                "Temperature",
                t.toStringAsFixed(1),
                "°C",
                _getTempStatus(t),
                _getTempColor(t),
              ),
              _buildPollutantTile(
                "Humidity",
                h.toStringAsFixed(0),
                "%",
                _getHumidityStatus(h),
                _getHumidityColor(h),
              ),
              _buildPollutantTile(
                "Absolute Humidity",
                absHum.toStringAsFixed(2),
                "g/m³",
                "Water Vapor",
                Colors.indigo,
              ),

              const Divider(height: 40, thickness: 1),
              const Text(
                "Pollutants",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 15),

              _buildPollutantTile(
                "PM2.5 Dust",
                pm25.toStringAsFixed(1),
                "µg/m³",
                "AQI: $pmAqi",
                _getColor(pmAqi),
              ),
              _buildPollutantTile(
                "LPG / Smoke",
                lpg.toStringAsFixed(1),
                "ppm",
                _getLPGStatus(lpg),
                _getLPGColor(lpg),
              ),
              _buildPollutantTile(
                "CO (Monoxide)",
                co.toStringAsFixed(1),
                "ppm",
                _getCOStatus(co),
                _getCOColor(co),
              ),
              _buildPollutantTile(
                "CO₂ (Est.)",
                co2.toStringAsFixed(0),
                "ppm",
                _getCO2Status(co2),
                _getCO2Color(co2),
              ),

              const SizedBox(height: 30),
              _buildSectionCard(
                title: "History",
                child: SlidingHistoryContent(trackerId: widget.trackerId),
              ),
              const SizedBox(height: 20),

              // Dynamic Advice Section
              _buildSectionCard(
                title: "Advice",
                child: _buildDynamicAdvice(t, h, lpg, co, co2, pmAqi),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildDynamicAdvice(
    double t,
    double h,
    double lpg,
    double co,
    double co2,
    int pmAqi,
  ) {
    if (lpg > 200 || co > 9 || pmAqi > 100) {
      return _buildAdviceBox(
        Colors.red,
        Icons.warning_amber_rounded,
        "Action Required",
        "High pollutants detected. Open windows immediately for ventilation.",
      );
    } else if (co2 > 1000) {
      return _buildAdviceBox(
        Colors.orange,
        Icons.air,
        "Poor Ventilation",
        "CO2 levels are high. Please let in fresh air to avoid drowsiness.",
      );
    } else if (t > 30 || h > 70) {
      return _buildAdviceBox(
        Colors.blue,
        Icons.thermostat,
        "Comfort Alert",
        "Environment is outside the ideal range. Consider adjusting your HVAC.",
      );
    } else {
      return _buildAdviceBox(
        Colors.green,
        Icons.check_circle_outline,
        "Air is Healthy",
        "Everything looks great! No significant pollutants detected.",
      );
    }
  }

  Widget _buildAQICard(int aqi, String time, String loc) {
    Color statusColor = _getColor(aqi);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Air Quality Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$aqi",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("IAQI", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _getStatus(aqi),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontSize: 18,
            ),
          ),
          Text(
            "Last updated: $time",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantTile(
    String label,
    String value,
    String unit,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                "$value $unit",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildAdviceBox(
    Color color,
    IconData icon,
    String title,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SlidingHistoryContent extends StatefulWidget {
  final String trackerId;

  const SlidingHistoryContent({Key? key, required this.trackerId}) : super(key: key);

  @override
  _SlidingHistoryContentState createState() => _SlidingHistoryContentState();
}

class _SlidingHistoryContentState extends State<SlidingHistoryContent> {
  int selectedTabIndex = 0;
  final List<String> tabs = ["Today", "7 Days", "30 Days"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment(-1.0 + (selectedTabIndex * 1.0), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => selectedTabIndex = index),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: selectedTabIndex == index
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _buildChartBox("Graph for ${tabs[selectedTabIndex]}", 180),
      ],
    );
  }

  Widget _buildChartBox(String text, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
