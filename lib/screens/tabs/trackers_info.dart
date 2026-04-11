import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    if (ratio.isNaN || ratio <= 0) return 0.0;
    // Protect against extreme or invalid ratio values that cause pow() to explode.
    const double minRatio = 0.01;
    const double maxRatio = 100.0;
    double safeRatio = (ratio).clamp(minRatio, maxRatio).toDouble();
    double val = (a * pow(safeRatio, b)).toDouble();
    if (val.isNaN || val.isInfinite) return 0.0;
    // Cap PPM to a high but reasonable ceiling to avoid misleading huge values.
    return (val.clamp(0.0, 10000.0) as double);
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

  // Estimate gas concentrations (lpg, co, co2, nh3) from a raw reading map.
  Map<String, double> _estimateGasesFromMap(Map<String, dynamic> m) {
    double mq2_v = _toDouble(m['mq2_v']);
    double mq9_v = _toDouble(m['mq9_v']);
    double mq135_v = _toDouble(m['mq135_v']);
    double temp = _toDouble(m['temperature']);
    double hum = _toDouble(m['humidity']);

    if (mq2_v > 20) mq2_v = mq2_v * (5.0 / 1023.0);
    if (mq9_v > 20) mq9_v = mq9_v * (5.0 / 1023.0);
    if (mq135_v > 20) mq135_v = mq135_v * (5.0 / 1023.0);

    const double fallbackRatio = 100.0;
    double r2 = (mq2_v > 0) ? ((5.0 - mq2_v) / mq2_v) : fallbackRatio;
    double r9 = (mq9_v > 0) ? ((5.0 - mq9_v) / mq9_v) : fallbackRatio;
    double r135 = (mq135_v > 0) ? ((5.0 - mq135_v) / mq135_v) : fallbackRatio;

    double lpg = calculatePPM(r2, 574.25, -2.222);
    double coEst = calculatePPM(r9, 1000.5, -1.969);
    double correctionFactor = getCorrectionFactor(temp, hum).clamp(0.1, 10.0).toDouble();
    double co2Est = calculatePPM(r135 / correctionFactor, 110.47, -2.862);
    double nh3 = calculatePPM(r135, 102.2, -2.473);

    double co = _toDouble(m['co'] ?? 0);
    double co2 = _toDouble(m['co2'] ?? m['co2_est']);
    if (co == 0) co = coEst;
    if (co2 == 0) co2 = co2Est;

    return {'lpg': lpg, 'co': co, 'co2': co2, 'nh3': nh3};
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.trackerId)
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(1)
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
          double pm25 = 0.0;
          if (hasReading) {
            final rawPm = data['pm25'];
            if (rawPm is num) {
              pm25 = rawPm.toDouble();
            } else if (rawPm is String) {
              pm25 = double.tryParse(rawPm) ?? 0.0;
            } else {
              pm25 = 0.0;
            }
          }

          double v2 = hasReading ? (data['mq2_v'] ?? 0.0).toDouble() : 0.0;
          double v9 = hasReading ? (data['mq9_v'] ?? 0.0).toDouble() : 0.0;
          double v135 = hasReading ? (data['mq135_v'] ?? 0.0).toDouble() : 0.0;

          // initial resistance estimates will be computed after voltage normalization
          // Heuristic: some devices store raw ADC counts (0-1023). If values look
          // like raw ADC (>20), convert to voltage using 5.0V reference.
          if (v2 > 20) v2 = v2 * (5.0 / 1023.0);
          if (v9 > 20) v9 = v9 * (5.0 / 1023.0);
          if (v135 > 20) v135 = v135 * (5.0 / 1023.0);

          // Compute sensor resistance ratios; if sensor voltage is zero or
          // invalid, fall back to a safe maximum ratio that calculatePPM will clamp.
          const double fallbackRatio = 100.0;
          double r2 = (v2 > 0) ? ((5.0 - v2) / v2) : fallbackRatio;
          double r9 = (v9 > 0) ? ((5.0 - v9) / v9) : fallbackRatio;
          double r135 = (v135 > 0) ? ((5.0 - v135) / v135) : fallbackRatio;

          final gases = _estimateGasesFromMap(data);
          double lpg = gases['lpg']!;
          double co = gases['co']!;
          double co2 = gases['co2']!;
          double nh3 = gases['nh3']!;

          int pmAqi = calculatePM25AQI(pm25);
          int finalIAQI = getCompositeIAQI(co, co2, nh3, pmAqi);
          double absHum = calculateAbsoluteHumidity(t, h);

          // Debug: print intermediate values to help trace IAQI computation
          if (kDebugMode) {
            print('--- Tracker Debug (${widget.trackerName}) ---');
            print('v2: $v2, v9: $v9, v135: $v135');
            print('r2: $r2, r9: $r9, r135: $r135');
            print('lpg: $lpg, co: $co, co2: $co2, nh3: $nh3');
            print('pm25: $pm25 -> pmAqi: $pmAqi');
            print('finalIAQI: $finalIAQI');
          }

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

  void _showEditDialog() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nameController = TextEditingController(text: widget.trackerName);
    final allowed = ['comfort room', 'living room', 'dining area', 'kitchen', 'bedroom'];
    String selectedLocation = allowed.contains(widget.trackerLocation.toLowerCase())
      ? widget.trackerLocation.toLowerCase()
      : 'comfort room';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Tracker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tracker name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                items: const [
                  DropdownMenuItem(value: 'comfort room', child: Text('Comfort Room')),
                  DropdownMenuItem(value: 'living room', child: Text('Living Room')),
                  DropdownMenuItem(value: 'dining area', child: Text('Dining Area')),
                  DropdownMenuItem(value: 'kitchen', child: Text('Kitchen')),
                  DropdownMenuItem(value: 'bedroom', child: Text('Bedroom')),
                ],
                onChanged: (v) {
                  if (v != null) selectedLocation = v;
                },
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('devices').doc(widget.trackerId).update({
                    'device_name': newName,
                    'location': selectedLocation,
                  });

                  if (uid != null) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'trackers.${widget.trackerId}.device_name': newName,
                      'trackers.${widget.trackerId}.location': selectedLocation,
                    }).catchError((_) async {
                      // If trackers map doesn't exist yet, use set with merge
                      await FirebaseFirestore.instance.collection('users').doc(uid).set({
                        'trackers': {
                          widget.trackerId: {'device_name': newName, 'location': selectedLocation}
                        }
                      }, SetOptions(merge: true));
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracker updated')));
                  setState(() {});
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
  Map<int, Future<Map<String, dynamic>>> _historyCache = {};

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
        _buildChartBox("Graph for ${tabs[selectedTabIndex]}", 180.0),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.redAccent, 'PM2.5'),
          const SizedBox(width: 16),
          _legendItem(Colors.teal, 'CO\u2082'),
          const SizedBox(width: 16),
          _legendItem(Colors.green.shade400, 'CO'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

 Widget _buildLineChart(List<dynamic> points, DateTime start) {
  try {
    final spotsPm = <FlSpot>[];
    final spotsCo2 = <FlSpot>[];
    final spotsCo = <FlSpot>[];

    for (var p in points) {
      final dt = p['t'] as DateTime;
      final x = dt.difference(start).inMinutes / 60.0;
      final pmVal = (p['pm25'] as double);
      final co2Val = (p['co2'] as double);
      final coVal = (p['co'] as double);
      if (pmVal.isFinite) spotsPm.add(FlSpot(x, pmVal));
      if (co2Val.isFinite) spotsCo2.add(FlSpot(x, co2Val));
      if (coVal.isFinite) spotsCo.add(FlSpot(x, coVal));
    }

    if (spotsPm.isEmpty) spotsPm.add(FlSpot(0, 0));
    if (spotsCo2.isEmpty) spotsCo2.add(FlSpot(0, 0));
    if (spotsCo.isEmpty) spotsCo.add(FlSpot(0, 0));

    final maxX = spotsPm.isNotEmpty ? spotsPm.last.x : 24.0;
    final interval = ((maxX / 5).clamp(1, maxX)).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final minutes = (v * 60).round();
                final label = start.add(Duration(minutes: minutes));
                final fmt = selectedTabIndex == 0
                    ? "${label.hour.toString().padLeft(2, '0')}:00"
                    : "${label.month}/${label.day}";
                return Text(fmt,
                    style: const TextStyle(fontSize: 10, color: Colors.black45));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minX: 0,
        maxX: maxX,
        lineBarsData: [
          LineChartBarData(
            spots: spotsCo2,
            color: Colors.teal,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: Colors.teal,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            barWidth: 2,
          ),
          LineChartBarData(
            spots: spotsCo,
            color: Colors.green.shade400,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: Colors.green.shade400,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            barWidth: 2,
          ),
          LineChartBarData(
            spots: spotsPm,
            color: Colors.redAccent,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: Colors.redAccent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            barWidth: 2,
          ),
        ],
      ),
    );
  } catch (e, st) {
    if (kDebugMode) {
      print('Error building line chart: $e');
      print(st);
    }
    return const Center(child: Text('Chart error'));
  }
}

Widget _buildBarChart(Map<String, Map<String, double>> daily) {
  try {
    final keys = daily.keys.toList()..sort();
    if (keys.isEmpty) return const Center(child: Text('No daily averages'));

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      final vals = daily[k]!;
      final pm = vals['pm25'] ?? 0.0;
      final co2 = vals['co2'] ?? 0.0;
      final co = vals['co'] ?? 0.0;
      groups.add(BarChartGroupData(x: i, barsSpace: 3, barRods: [
        BarChartRodData(
          toY: pm,
          color: Colors.redAccent,
          width: 7,
          borderRadius: BorderRadius.circular(3),
        ),
        BarChartRodData(
          toY: co2,
          color: Colors.teal,
          width: 7,
          borderRadius: BorderRadius.circular(3),
        ),
        BarChartRodData(
          toY: co,
          color: Colors.green.shade400,
          width: 7,
          borderRadius: BorderRadius.circular(3),
        ),
      ]));
    }

    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= keys.length) {
                  return const SizedBox.shrink();
                }
                final parts = keys[idx].split('-');
                final label = selectedTabIndex == 0
                    ? "${parts[2].padLeft(2, '0')}:00"
                    : "${parts[1].padLeft(2, '0')}/${parts[2].padLeft(2, '0')}";
                return Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.black45));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  } catch (e, st) {
    if (kDebugMode) {
      print('Error building bar chart: $e');
      print(st);
    }
    return const Center(child: Text('Bar chart error'));
  }
}

  Widget _buildChartBox(String title, double height) {
    final int days = selectedTabIndex == 0 ? 1 : (selectedTabIndex == 1 ? 7 : 30);
    _historyCache[selectedTabIndex] ??= _fetchHistory(days);

    return FutureBuilder<Map<String, dynamic>>(
      future: _historyCache[selectedTabIndex],
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return SizedBox(
            height: height,
            child: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final data = snap.data ?? {'points': [], 'daily': {}, 'start': DateTime.now()};
        final points = (data['points'] as List<dynamic>?) ?? [];
        final daily = (data['daily'] as Map?)?.cast<String, Map<String, double>>() ?? {};
        final start = data['start'] as DateTime? ?? DateTime.now();

        if (points.isEmpty) {
          return SizedBox(
            height: height,
            child: const Center(child: Text('No history data')),
          );
        }

        return SizedBox(
          height: height,
          child: Column(
            children: [
              Expanded(child: _buildLineChart(points, start)),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  double _toDouble(dynamic v) {
    try {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is bool) return v ? 1.0 : 0.0;
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return 0.0;
        // Normalize common formatting: commas as thousands separators
        final normalized = s.replaceAll(',', '');
        final parsed = double.tryParse(normalized);
        if (parsed != null) return parsed;
        // Try extracting a numeric substring (e.g. "value: 12.3")
        final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?').firstMatch(normalized);
        if (match != null) return double.tryParse(match.group(0)!) ?? 0.0;
        return 0.0;
      }
      if (v is Timestamp) return v.toDate().millisecondsSinceEpoch.toDouble();
      if (v is DateTime) return v.millisecondsSinceEpoch.toDouble();
      if (v is GeoPoint) {
        // GeoPoint cannot be converted to a single scalar reliably.
        if (kDebugMode) print('[_toDouble] received GeoPoint for conversion; returning 0.0');
        return 0.0;
      }
      // For maps / lists / other types, attempt best-effort conversion
      if (v is Map || v is List) return 0.0;
    } catch (e) {
      if (kDebugMode) print('[_toDouble] conversion error for value=$v -> $e');
    }
    return 0.0;
  }

  // Local PPM calculation (kept here to avoid depending on other state classes).
  double _localCalculatePPM(double ratio, double a, double b) {
    if (ratio.isNaN || ratio <= 0) return 0.0;
    const double minRatio = 0.01;
    const double maxRatio = 100.0;
    double safeRatio = (ratio).clamp(minRatio, maxRatio).toDouble();
    double val = (a * pow(safeRatio, b)).toDouble();
    if (val.isNaN || val.isInfinite) return 0.0;
    return (val.clamp(0.0, 10000.0) as double);
  }

  double _localCorrectionFactor(double t, double h) {
    return -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
  }

  Map<String, double> _estimateGases(Map<String, dynamic> m) {
    double mq2_v = _toDouble(m['mq2_v']);
    double mq9_v = _toDouble(m['mq9_v']);
    double mq135_v = _toDouble(m['mq135_v']);
    double temp = _toDouble(m['temperature']);
    double hum = _toDouble(m['humidity']);

    if (mq2_v > 20) mq2_v = mq2_v * (5.0 / 1023.0);
    if (mq9_v > 20) mq9_v = mq9_v * (5.0 / 1023.0);
    if (mq135_v > 20) mq135_v = mq135_v * (5.0 / 1023.0);

    const double fallbackRatio = 100.0;
    double r2 = (mq2_v > 0) ? ((5.0 - mq2_v) / mq2_v) : fallbackRatio;
    double r9 = (mq9_v > 0) ? ((5.0 - mq9_v) / mq9_v) : fallbackRatio;
    double r135 = (mq135_v > 0) ? ((5.0 - mq135_v) / mq135_v) : fallbackRatio;

    double lpg = _localCalculatePPM(r2, 574.25, -2.222);
    double coEst = _localCalculatePPM(r9, 1000.5, -1.969);
    double correctionFactor = _localCorrectionFactor(temp, hum).clamp(0.1, 10.0).toDouble();
    double co2Est = _localCalculatePPM(r135 / correctionFactor, 110.47, -2.862);
    double nh3 = _localCalculatePPM(r135, 102.2, -2.473);

    double co = _toDouble(m['co'] ?? 0);
    double co2 = _toDouble(m['co2'] ?? m['co2_est']);
    if (co == 0) co = coEst;
    if (co2 == 0) co2 = co2Est;

    return {'lpg': lpg, 'co': co, 'co2': co2, 'nh3': nh3};
  }

  Future<Map<String, dynamic>> _fetchHistory(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    try {
      final qSnap = await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.trackerId)
          .collection('readings')
          .orderBy('timestamp', descending: true)
          .limit(1000)
          .get();

      if (kDebugMode) {
        print('[_fetchHistory] fetched ${qSnap.docs.length} docs for tracker ${widget.trackerId} (days=$days)');
        for (var i = 0; i < qSnap.docs.length && i < 5; i++) {
          try {
            print('[_fetchHistory] doc[$i]: ${qSnap.docs[i].data()}');
          } catch (e) {
            print('[_fetchHistory] failed to print doc[$i]: $e');
          }
        }
      }

      final List<Map<String, dynamic>> points = [];
      final Map<String, List<double>> dailyPm = {};
      final Map<String, List<double>> dailyCo2 = {};
      final Map<String, List<double>> dailyCo = {};

      for (var d in qSnap.docs.reversed) {
        final m = d.data() as Map<String, dynamic>;
        DateTime? dt;
        final ts = m['timestamp'];
        if (ts is Timestamp) dt = ts.toDate();
        else if (ts is DateTime) dt = ts;
        else if (ts is String) dt = DateTime.tryParse(ts);
        if (dt == null) continue;
        if (dt.isBefore(start)) continue;

        final pm25 = _toDouble(m['pm25']);
        final gases = _estimateGases(m);
        final double co = gases['co']!;
        final double co2 = gases['co2']!;

        points.add({'t': dt, 'pm25': pm25, 'co2': co2, 'co': co});

        final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        dailyPm.putIfAbsent(dayKey, () => []).add(pm25);
        dailyCo2.putIfAbsent(dayKey, () => []).add(co2);
        dailyCo.putIfAbsent(dayKey, () => []).add(co);
      }

      double avg(List<double> l) => l.isEmpty ? 0.0 : l.reduce((a, b) => a + b) / l.length;

      final Map<String, Map<String, double>> daily = {};
      if (kDebugMode) {
        print('[_fetchHistory] processed points count=${points.length}');
        try {
          print('[_fetchHistory] sample points=${points.take(5).toList()}');
        } catch (e) {
          print('[_fetchHistory] failed to print sample points: $e');
        }
      }

      for (var k in dailyPm.keys) {
        daily[k] = {
          'pm25': avg(dailyPm[k]!),
          'co2': avg(dailyCo2[k] ?? []),
          'co': avg(dailyCo[k] ?? []),
        };
      }

      return {'points': points, 'daily': daily, 'start': start};
    } catch (e, st) {
      if (kDebugMode) {
        print('Error fetching history: $e');
        print(st);
      }
      return {'points': [], 'daily': {}, 'start': start};
    }

  }
}