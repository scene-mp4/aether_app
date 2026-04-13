import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  // ── Calibration constants ─────────────────────────────────────────────────
  // These are the clean-air Ro values for each sensor (in kΩ).
  // IMPORTANT: Replace these with your own measured values after running
  // the calibration procedure in clean outdoor air for 3+ minutes.
  // Clean-air Rs/Ro ratios from datasheets:
  //   MQ-2:   Rs/Ro = 9.83  → Ro = Rs_clean / 9.83
  //   MQ-9:   Rs/Ro = 9.9   → Ro = Rs_clean / 9.9
  //   MQ-135: Rs/Ro = 3.6   → Ro = Rs_clean / 3.6
      static const double Ro_MQ2   = 6.55;
      static const double Ro_MQ9   = 8.2;
      static const double Ro_MQ135 = 70.3; // kΩ — replace with calibrated value

  // Load resistor values on your sensor modules (measure with multimeter
  // between GND and AOUT on each module board — commonly 1kΩ or 10kΩ).
  static const double RL_MQ2   = 5.0;  // kΩ
  static const double RL_MQ9   = 5.0;  // kΩ
  static const double RL_MQ135 = 10.0; // kΩ

  // Supply voltage of Arduino Uno ADC reference
  static const double Vc = 5.0;

  // ── Rs/Ro ratio from sensor output voltage ────────────────────────────────
  // FIX: Added RL and Ro parameters so the ratio is properly calibrated.
  // Previously the formula was missing Ro division entirely.
  double getRsRatio(double vout, double rl, double ro) {
    if (vout <= 0 || vout >= Vc) return 100.0; // fallback for bad readings
    double rs = ((Vc - vout) / vout) * rl;
    return rs / ro;
  }

  // ── PPM from Rs/Ro ratio using power-law curve ────────────────────────────
  double calculatePPM(double ratio, double a, double b) {
    if (ratio.isNaN || ratio <= 0) return 0.0;
    const double minRatio = 0.01;
    const double maxRatio = 100.0;
    double safeRatio = ratio.clamp(minRatio, maxRatio);
    double val = a * pow(safeRatio, b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0);
  }

  // ── Temperature & humidity correction for MQ-135 ─────────────────────────
  // Source: Baumbach correction model adapted for MQ-135
  double getCorrectionFactor(double t, double h) {
    double cf = -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
    return cf.clamp(0.1, 10.0);
  }

  // ── Absolute humidity (g/m³) ──────────────────────────────────────────────
  // Source: August-Roche-Magnus approximation
  double calculateAbsoluteHumidity(double temp, double hum) {
    return (6.112 * exp((17.67 * temp) / (temp + 243.5)) * hum * 2.1674) /
        (273.15 + temp);
  }

  // ── EPA PM2.5 AQI piecewise formula ──────────────────────────────────────
  int calculatePM25AQI(double concentration) {
    if (concentration <= 0) return 0;
    final List<List<double>> bp = [
      [0.0,   12.0,    0,  50],
      [12.1,  35.4,   51, 100],
      [35.5,  55.4,  101, 150],
      [55.5, 150.4,  151, 200],
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

  // ── Composite IAQI — worst sub-index across all pollutants ───────────────
  int getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo  = (co  / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

  // ── Estimate all gas concentrations from a Firestore reading map ──────────
  // FIX: Uses corrected getRsRatio() with RL and Ro.
  // FIX: Reads 'pm2_5' (correct field name from Arduino) instead of 'pm25'.
  Map<String, double> _estimateGasesFromMap(Map<String, dynamic> m) {
    double mq2_v   = _toDouble(m['mq2_v']);
    double mq9_v   = _toDouble(m['mq9_v']);
    double mq135_v = _toDouble(m['mq135_v']);
    double temp    = _toDouble(m['temperature']);
    double hum     = _toDouble(m['humidity']);

    // Heuristic: if voltage looks like raw ADC (>20), convert to volts.
    if (mq2_v   > 20) mq2_v   = mq2_v   * (Vc / 1023.0);
    if (mq9_v   > 20) mq9_v   = mq9_v   * (Vc / 1023.0);
    if (mq135_v > 20) mq135_v = mq135_v * (Vc / 1023.0);

    // FIX: getRsRatio now includes RL and Ro for a properly calibrated ratio.
    double r2   = getRsRatio(mq2_v,   RL_MQ2,   Ro_MQ2);
    double r9   = getRsRatio(mq9_v,   RL_MQ9,   Ro_MQ9);
    double r135 = getRsRatio(mq135_v, RL_MQ135, Ro_MQ135);

    double lpg  = calculatePPM(r2, 574.25, -2.222);
    double co   = calculatePPM(r9, 1000.5, -1.969);

    double correctionFactor = getCorrectionFactor(temp, hum);
    double co2 = calculatePPM(r135, 110.47, -2.862) * correctionFactor;
    double nh3  = calculatePPM(r135, 102.2, -2.473);

    // Override with explicit Firestore fields if present
    double coOverride  = _toDouble(m['co']);
    double co2Override = _toDouble(m['co2'] ?? m['co2_est']);
    if (coOverride  > 0) co  = coOverride;
    if (co2Override > 0) co2 = co2Override;

    return {'lpg': lpg, 'co': co, 'co2': co2, 'nh3': nh3};
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }

  // ── Color & status helpers ────────────────────────────────────────────────

  Color _getColor(num aqi) {
    if (aqi <= 50)  return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade800;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return const Color(0xFF800000);
  }

  String _getStatus(num aqi) {
    if (aqi <= 50)  return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy (Sensitive)";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  // FIX: Widened comfort range to 30°C — 33°C is normal indoors in the PH.
  Color _getTempColor(double t) {
    if (t >= 18 && t <= 30) return Colors.green;
    if ((t > 30 && t <= 35) || (t >= 10 && t < 18))
      return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getTempStatus(double t) {
    if (t >= 18 && t <= 30) return "Comfort";
    if (t > 30 && t <= 35)  return "Warm";
    if (t < 18 && t >= 10)  return "Cool";
    return "Extreme";
  }

  Color _getHumidityColor(double h) {
    if (h >= 30 && h <= 60) return Colors.green;
    if (h > 60 && h <= 80)  return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getHumidityStatus(double h) {
    if (h >= 30 && h <= 60) return "Ideal";
    if (h > 60 && h <= 80)  return "Moderate";
    return "High Risk";
  }

  Color _getLPGColor(double ppm) {
    if (ppm <= 200)  return Colors.green;
    if (ppm <= 1000) return Colors.orange;
    return Colors.red;
  }

  String _getLPGStatus(double ppm) {
    if (ppm <= 200)  return "Safe";
    if (ppm <= 1000) return "Warning";
    return "Dangerous";
  }

  Color _getCOColor(double ppm) {
    if (ppm <= 9)  return Colors.green;
    if (ppm <= 35) return Colors.yellow.shade800;
    return Colors.red;
  }

  String _getCOStatus(double ppm) {
    if (ppm <= 9)  return "Normal";
    if (ppm <= 35) return "Caution";
    if (ppm <= 70) return "Harmful";
    return "Alert";
  }

  Color _getCO2Color(double ppm) {
    if (ppm <= 800)  return Colors.green;
    if (ppm <= 1500) return Colors.yellow.shade800;
    if (ppm <= 2500) return Colors.orange;
    return Colors.red;
  }

  String _getCO2Status(double ppm) {
    if (ppm <= 800)  return "Excellent";
    if (ppm <= 1500) return "Moderate";
    if (ppm <= 2500) return "Poor";
    return "High";
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

          final hasReading =
              snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final data = hasReading
              ? snapshot.data!.docs.first.data() as Map<String, dynamic>
              : <String, dynamic>{};

          double t  = _toDouble(hasReading ? data['temperature'] : 0);
          double h  = _toDouble(hasReading ? data['humidity']    : 0);

          // FIX: Read 'pm2_5' to match the field name sent by the Arduino.
          // Previously read 'pm25' which never matched, causing 0.0 µg/m³.
          double pm25 = 0.0;
          if (hasReading) {
            final rawPm = data['pm2_5'];
            if (rawPm is num) {
              pm25 = rawPm.toDouble();
            } else if (rawPm is String) {
              pm25 = double.tryParse(rawPm) ?? 0.0;
            }
          }

          final gases = _estimateGasesFromMap(data);
          double lpg = gases['lpg']!;
          double co  = gases['co']!;
          double co2 = gases['co2']!;
          double nh3 = gases['nh3']!;

          int pmAqi     = calculatePM25AQI(pm25);
          int finalIAQI = getCompositeIAQI(co, co2, nh3, pmAqi);
          double absHum = calculateAbsoluteHumidity(t, h);

          if (kDebugMode) {
            final v2   = _toDouble(data['mq2_v']);
            final v9   = _toDouble(data['mq9_v']);
            final v135 = _toDouble(data['mq135_v']);
            print('--- Tracker Debug (${widget.trackerName}) ---');
            print('voltages  → v2: $v2  v9: $v9  v135: $v135');
            print('ratios    → r2: ${getRsRatio(v2, RL_MQ2, Ro_MQ2).toStringAsFixed(3)}'
                '  r9: ${getRsRatio(v9, RL_MQ9, Ro_MQ9).toStringAsFixed(3)}'
                '  r135: ${getRsRatio(v135, RL_MQ135, Ro_MQ135).toStringAsFixed(3)}');
            print('gases     → lpg: $lpg  co: $co  co2: $co2  nh3: $nh3');
            print('pm25: $pm25  pmAqi: $pmAqi  finalIAQI: $finalIAQI');
          }

          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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
              _buildPollutantTile("Temperature",
                  t.toStringAsFixed(1), "°C",
                  _getTempStatus(t), _getTempColor(t)),
              _buildPollutantTile("Humidity",
                  h.toStringAsFixed(0), "%",
                  _getHumidityStatus(h), _getHumidityColor(h)),
              _buildPollutantTile("Absolute Humidity",
                  absHum.toStringAsFixed(2), "g/m³",
                  "Water Vapor", Colors.indigo),
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
              _buildPollutantTile("PM2.5 Dust",
                  pm25.toStringAsFixed(1), "µg/m³",
                  "AQI: $pmAqi", _getColor(pmAqi)),
              _buildPollutantTile("LPG / Smoke",
                  lpg.toStringAsFixed(1), "ppm",
                  _getLPGStatus(lpg), _getLPGColor(lpg)),
              _buildPollutantTile("CO (Monoxide)",
                  co.toStringAsFixed(1), "ppm",
                  _getCOStatus(co), _getCOColor(co)),
              _buildPollutantTile("CO₂ (Est.)",
                  co2.toStringAsFixed(0), "ppm",
                  _getCO2Status(co2), _getCO2Color(co2)),
              const SizedBox(height: 30),
              _buildSectionCard(
                title: "History",
                child: SlidingHistoryContent(trackerId: widget.trackerId),
              ),
              const SizedBox(height: 20),
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

  // ── Edit dialog ───────────────────────────────────────────────────────────

  void _showEditDialog() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nameController =
        TextEditingController(text: widget.trackerName);
    final allowed = [
      'comfort room', 'living room', 'dining area', 'kitchen', 'bedroom'
    ];
    String selectedLocation =
        allowed.contains(widget.trackerLocation.toLowerCase())
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
                decoration:
                    const InputDecoration(labelText: 'Tracker name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                items: const [
                  DropdownMenuItem(
                      value: 'comfort room',
                      child: Text('Comfort Room')),
                  DropdownMenuItem(
                      value: 'living room',
                      child: Text('Living Room')),
                  DropdownMenuItem(
                      value: 'dining area',
                      child: Text('Dining Area')),
                  DropdownMenuItem(
                      value: 'kitchen', child: Text('Kitchen')),
                  DropdownMenuItem(
                      value: 'bedroom', child: Text('Bedroom')),
                ],
                onChanged: (v) {
                  if (v != null) selectedLocation = v;
                },
                decoration:
                    const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Name cannot be empty')));
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('devices')
                      .doc(widget.trackerId)
                      .update({
                    'device_name': newName,
                    'location': selectedLocation,
                  });
                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'trackers.${widget.trackerId}.device_name':
                          newName,
                      'trackers.${widget.trackerId}.location':
                          selectedLocation,
                    }).catchError((_) async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'trackers': {
                          widget.trackerId: {
                            'device_name': newName,
                            'location': selectedLocation
                          }
                        }
                      }, SetOptions(merge: true));
                    });
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tracker updated')));
                  setState(() {});
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update failed: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ── Advice widget ─────────────────────────────────────────────────────────

  Widget _buildDynamicAdvice(
      double t, double h, double lpg, double co, double co2, int pmAqi) {
    if (co > 35) {
      return _buildAdviceBox(
        Colors.red,
        Icons.warning_amber_rounded,
        "CO Alert — Ventilate Now",
        "Carbon monoxide is at a dangerous level. Open windows and doors immediately and move to fresh air.",
      );
    } else if (lpg > 200 || pmAqi > 100) {
      return _buildAdviceBox(
        Colors.orange,
        Icons.warning_amber_rounded,
        "Action Required",
        "High pollutants detected. Open windows for ventilation.",
      );
    } else if (co2 > 1500) {
      return _buildAdviceBox(
        Colors.orange,
        Icons.air,
        "Poor Ventilation",
        "CO₂ levels are elevated. Let in fresh air to avoid drowsiness.",
      );
    } else if (t > 35 || h > 80) {
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

  // ── UI component builders ─────────────────────────────────────────────────

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
          const Text("Air Quality Summary",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(loc,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                Text("$aqi",
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const Text("IAQI",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _getStatus(aqi),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 18),
          ),
          Text("Last updated: $time",
              style:
                  const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPollutantTile(String label, String value, String unit,
      String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey)),
            Text("$value $unit",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildAdviceBox(
      Color color, IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── SlidingHistoryContent ─────────────────────────────────────────────────────

class SlidingHistoryContent extends StatefulWidget {
  final String trackerId;
  const SlidingHistoryContent({Key? key, required this.trackerId})
      : super(key: key);

  @override
  _SlidingHistoryContentState createState() =>
      _SlidingHistoryContentState();
}

class _SlidingHistoryContentState extends State<SlidingHistoryContent> {
  int selectedTabIndex = 0;
  final List<String> tabs = ["Today", "7 Days", "30 Days"];
  final Map<int, Future<Map<String, dynamic>>> _historyCache = {};

  // ── Calibration constants (mirrored from parent) ──────────────────────────
  static const double Ro_MQ2   = 6.55;
  static const double Ro_MQ9   = 8.2;
  static const double Ro_MQ135 = 70.3;
  static const double RL_MQ2   = 5.0;
  static const double RL_MQ9   = 5.0;
  static const double RL_MQ135 = 10.0;
  static const double Vc       = 5.0;

  double _getRsRatio(double vout, double rl, double ro) {
    if (vout <= 0 || vout >= Vc) return 100.0;
    double rs = ((Vc - vout) / vout) * rl;
    return rs / ro;
  }

  double _localCalculatePPM(double ratio, double a, double b) {
    if (ratio.isNaN || ratio <= 0) return 0.0;
    double safeRatio = ratio.clamp(0.01, 100.0);
    double val = a * pow(safeRatio, b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0);
  }

  double _localCorrectionFactor(double t, double h) {
    double cf = -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
    return cf.clamp(0.1, 10.0);
  }

  Map<String, double> _estimateGases(Map<String, dynamic> m) {
    double mq2_v   = _toDouble(m['mq2_v']);
    double mq9_v   = _toDouble(m['mq9_v']);
    double mq135_v = _toDouble(m['mq135_v']);
    double temp    = _toDouble(m['temperature']);
    double hum     = _toDouble(m['humidity']);

    if (mq2_v   > 20) mq2_v   = mq2_v   * (Vc / 1023.0);
    if (mq9_v   > 20) mq9_v   = mq9_v   * (Vc / 1023.0);
    if (mq135_v > 20) mq135_v = mq135_v * (Vc / 1023.0);

    // FIX: corrected Rs/Ro with RL and Ro
    double r2   = _getRsRatio(mq2_v,   RL_MQ2,   Ro_MQ2);
    double r9   = _getRsRatio(mq9_v,   RL_MQ9,   Ro_MQ9);
    double r135 = _getRsRatio(mq135_v, RL_MQ135, Ro_MQ135);

    double co  = _localCalculatePPM(r9, 1000.5, -1.969);
    double cf  = _localCorrectionFactor(temp, hum);
    double co2 = _localCalculatePPM(r135 / cf, 110.47, -2.862);

    double coOverride  = _toDouble(m['co']);
    double co2Override = _toDouble(m['co2'] ?? m['co2_est']);
    if (coOverride  > 0) co  = coOverride;
    if (co2Override > 0) co2 = co2Override;

    return {'co': co, 'co2': co2};
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(',', '');
      return double.tryParse(s) ?? 0.0;
    }
    if (v is Timestamp) return v.toDate().millisecondsSinceEpoch.toDouble();
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab switcher
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment:
                  Alignment(-1.0 + (selectedTabIndex * 1.0), 0),
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
                    onTap: () =>
                        setState(() => selectedTabIndex = index),
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
          ]),
        ),
        const SizedBox(height: 25),
        _buildChartBox(180.0),
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
          _legendItem(Colors.teal, 'CO₂'),
          const SizedBox(width: 16),
          _legendItem(Colors.green.shade400, 'CO'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(
        width: 14,
        height: 4,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 5),
      Text(label,
          style:
              const TextStyle(fontSize: 11, color: Colors.black54)),
    ]);
  }

  Widget _buildLineChart(List<dynamic> points, DateTime start) {
    try {
      final spotsPm  = <FlSpot>[];
      final spotsCo2 = <FlSpot>[];
      final spotsCo  = <FlSpot>[];

      for (var p in points) {
        final dt     = p['t'] as DateTime;
        final x      = dt.difference(start).inMinutes / 60.0;
        final pmVal  = (p['pm25'] as double);
        final co2Val = (p['co2'] as double);
        final coVal  = (p['co'] as double);
        if (pmVal.isFinite)  spotsPm.add(FlSpot(x, pmVal));
        if (co2Val.isFinite) spotsCo2.add(FlSpot(x, co2Val));
        if (coVal.isFinite)  spotsCo.add(FlSpot(x, coVal));
      }

      if (spotsPm.isEmpty)  spotsPm.add(FlSpot(0, 0));
      if (spotsCo2.isEmpty) spotsCo2.add(FlSpot(0, 0));
      if (spotsCo.isEmpty)  spotsCo.add(FlSpot(0, 0));

      final maxX     = spotsPm.isNotEmpty ? spotsPm.last.x : 24.0;
      final interval = ((maxX / 5).clamp(1, maxX)).toDouble();

      return LineChart(LineChartData(
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
                final label =
                    start.add(Duration(minutes: minutes));
                final fmt = selectedTabIndex == 0
                    ? "${label.hour.toString().padLeft(2, '0')}:00"
                    : "${label.month}/${label.day}";
                return Text(fmt,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: Colors.black45),
              ),
            ),
          ),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              getDotPainter: (spot, _, __, ___) =>
                  FlDotCirclePainter(
                      radius: 3,
                      color: Colors.teal,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent),
            ),
            barWidth: 2,
          ),
          LineChartBarData(
            spots: spotsCo,
            color: Colors.green.shade400,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) =>
                  FlDotCirclePainter(
                      radius: 3,
                      color: Colors.green.shade400,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent),
            ),
            barWidth: 2,
          ),
          LineChartBarData(
            spots: spotsPm,
            color: Colors.redAccent,
            isCurved: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) =>
                  FlDotCirclePainter(
                      radius: 3,
                      color: Colors.redAccent,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent),
            ),
            barWidth: 2,
          ),
        ],
      ));
    } catch (e, st) {
      if (kDebugMode) print('Error building line chart: $e\n$st');
      return const Center(child: Text('Chart error'));
    }
  }

  Widget _buildChartBox(double height) {
    final int days =
        selectedTabIndex == 0 ? 1 : (selectedTabIndex == 1 ? 7 : 30);
    _historyCache[selectedTabIndex] ??= _fetchHistory(days);

    return FutureBuilder<Map<String, dynamic>>(
      future: _historyCache[selectedTabIndex],
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
              height: height,
              child:
                  const Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return SizedBox(
              height: height,
              child: Center(child: Text('Error: ${snap.error}')));
        }
        final data = snap.data ??
            {'points': [], 'daily': {}, 'start': DateTime.now()};
        final points =
            (data['points'] as List<dynamic>?) ?? [];
        final start =
            data['start'] as DateTime? ?? DateTime.now();

        if (points.isEmpty) {
          return SizedBox(
              height: height,
              child: const Center(child: Text('No history data')));
        }

        return SizedBox(
          height: height,
          child: Column(children: [
            Expanded(child: _buildLineChart(points, start)),
            _buildLegend(),
          ]),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchHistory(int days) async {
    final now   = DateTime.now();
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
        print('[_fetchHistory] fetched ${qSnap.docs.length} docs '
            'for tracker ${widget.trackerId} (days=$days)');
      }

      final List<Map<String, dynamic>> points = [];

      for (var d in qSnap.docs.reversed) {
        final m = d.data() as Map<String, dynamic>;

        DateTime? dt;
        final ts = m['timestamp'];
        if (ts is Timestamp)      dt = ts.toDate();
        else if (ts is DateTime)  dt = ts;
        else if (ts is String)    dt = DateTime.tryParse(ts);
        if (dt == null)           continue;
        if (dt.isBefore(start))   continue;

        // FIX: Read 'pm2_5' to match Arduino field name.
        final pm25  = _toDouble(m['pm2_5']);
        final gases = _estimateGases(m);

        points.add({
          't':    dt,
          'pm25': pm25,
          'co2':  gases['co2']!,
          'co':   gases['co']!,
        });
      }

      if (kDebugMode) {
        print('[_fetchHistory] processed ${points.length} points');
      }

      return {'points': points, 'start': start};
    } catch (e, st) {
      if (kDebugMode) {
        print('Error fetching history: $e\n$st');
      }
      return {'points': [], 'start': start};
    }
  }
}