import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:async';

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

  // top notification banner state (local to this screen)
  String? _topNotificationMessage;
  bool _topNotificationAlert = false;
  bool _topNotificationVisible = false;
  Timer? _topNotificationTimer;
  String? _lastReadingId;

  // ── Calibration constants ─────────────────────────────────────────────────
  static const double Ro_MQ2   = 2.7;
  static const double Ro_MQ9   = 6;
  static const double Ro_MQ135 = 18;
  static const double RL_MQ2   = 5.0;
  static const double RL_MQ9   = 5.0;
  static const double RL_MQ135 = 10.0;
  static const double Vc       = 5.0;

  double getRsRatio(double vout, double rl, double ro) {
    if (vout <= 0 || vout >= Vc) return 100.0;
    double rs = ((Vc - vout) / vout) * rl;
    return rs / ro;
  }

  double calculatePPM(double ratio, double a, double b) {
    if (ratio.isNaN || ratio <= 0) return 0.0;
    double safeRatio = ratio.clamp(0.01, 100.0);
    double val = a * pow(safeRatio, b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0);
  }

  double getCorrectionFactor(double t, double h) {
    double cf = -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
    return cf.clamp(0.1, 10.0);
  }

  double calculateAbsoluteHumidity(double temp, double hum) {
    return (6.112 * exp((17.67 * temp) / (temp + 243.5)) * hum * 2.1674) /
        (273.15 + temp);
  }

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

  int getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo  = (co  / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

  Map<String, double> _estimateGasesFromMap(Map<String, dynamic> m) {
    double mq2_v   = _toDouble(m['mq2_v']);
    double mq9_v   = _toDouble(m['mq9_v']);
    double mq135_v = _toDouble(m['mq135_v']);
    double temp    = _toDouble(m['temperature']);
    double hum     = _toDouble(m['humidity']);

    if (mq2_v   > 20) mq2_v   = mq2_v   * (Vc / 1023.0);
    if (mq9_v   > 20) mq9_v   = mq9_v   * (Vc / 1023.0);
    if (mq135_v > 20) mq135_v = mq135_v * (Vc / 1023.0);

    double r2   = getRsRatio(mq2_v,   RL_MQ2,   Ro_MQ2);
    double r9   = getRsRatio(mq9_v,   RL_MQ9,   Ro_MQ9);
    double r135 = getRsRatio(mq135_v, RL_MQ135, Ro_MQ135);

    double lpg    = calculatePPM(r2, 574.25, -2.222);
    double co     = calculatePPM(r9, 1000.5, -1.969);
    double cf     = getCorrectionFactor(temp, hum);
    double rawCo2 = calculatePPM(r135, 110.47, -2.862) * cf;
    double co2    = rawCo2 < 420 ? 420.0 : rawCo2;
    double nh3    = calculatePPM(r135, 102.2, -2.473);

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
        title: Text(widget.trackerName,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: Stack(children: [
        StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.trackerId)
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final hasReading =
              snapshot.hasData && snapshot.data!.docs.isNotEmpty;
          final data = hasReading
              ? snapshot.data!.docs.first.data() as Map<String, dynamic>
              : <String, dynamic>{};

          double t  = _toDouble(hasReading ? data['temperature'] : 0);
          double h  = _toDouble(hasReading ? data['humidity']    : 0);

          double pm25 = 0.0;
          if (hasReading) {
            final rawPm = data['pm2_5'];
            if (rawPm is num)         pm25 = rawPm.toDouble();
            else if (rawPm is String) pm25 = double.tryParse(rawPm) ?? 0.0;
          }

          final gases   = _estimateGasesFromMap(data);
          double lpg    = gases['lpg']!;
          double co     = gases['co']!;
          double co2    = gases['co2']!;
          double nh3    = gases['nh3']!;

          int pmAqi     = calculatePM25AQI(pm25);
          int finalIAQI = getCompositeIAQI(co, co2, nh3, pmAqi);

          // Notifications: detect new reading and show banner (use post-frame to avoid setState during build)
          final currentReadingId = hasReading ? snapshot.data!.docs.first.id : null;
          if (hasReading && currentReadingId != null) {
            if (_lastReadingId == null) {
              _lastReadingId = currentReadingId; // initial load - don't notify
            } else if (_lastReadingId != currentReadingId) {
              _lastReadingId = currentReadingId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showTopNotification('${widget.trackerName} updated — IAQI $finalIAQI', alert: finalIAQI >= 200, seconds: finalIAQI >= 200 ? 6 : 3);
              });
            }
          }
          double absHum = calculateAbsoluteHumidity(t, h);

          if (kDebugMode) {
            double v135  = _toDouble(data['mq135_v']);
            double rs135 = ((Vc - v135) / v135) * RL_MQ135;
            print('Suggested Ro_MQ135 = ${rs135 / 3.6} (from voltage $v135)');
            double v9  = _toDouble(data['mq9_v']);
            double rs9 = ((Vc - v9) / v9) * RL_MQ9;
            print('Suggested Ro_MQ9   = ${rs9 / 9.9} (from voltage $v9)');
            double v2  = _toDouble(data['mq2_v']);
            double rs2 = ((Vc - v2) / v2) * RL_MQ2;
            print('Suggested Ro_MQ2   = ${rs2 / 9.83} (from voltage $v2)');
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 10),
            children: [
              _buildAQICard(finalIAQI, "Just now",
                  widget.trackerLocation),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: "Advice",
                child: _buildDynamicAdvice(
                    t, h, lpg, co, co2, pmAqi),
              ),
              const SizedBox(height: 30),

              // ── Air Metrics ──────────────────────────────────────
              const Text("Air Metrics",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151))),
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
              const SizedBox(height: 12),

              // NEW: Climate history chart
              _buildSectionCard(
                title: "Climate History",
                child: ClimateHistoryContent(
                    trackerId: widget.trackerId),
              ),

              const Divider(height: 40, thickness: 1),

              // ── Pollutants ───────────────────────────────────────
              const Text("Pollutants",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151))),
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

              // Pollutant history chart (with toggles + zoom/pan)
              _buildSectionCard(
                title: "Pollutant History",
                child: SlidingHistoryContent(
                    trackerId: widget.trackerId),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        ),

        // Top notification banner (local)
        if (_topNotificationVisible && _topNotificationMessage != null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.decelerate,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _topNotificationAlert ? Colors.red.shade700 : Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _topNotificationAlert ? Colors.red.shade900 : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _topNotificationAlert ? Icons.error_outline : Icons.notifications,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _topNotificationAlert ? 'ALERT' : 'Update',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _topNotificationMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _hideTopNotification();
                    },
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  void dispose() {
    _topNotificationTimer?.cancel();
    super.dispose();
  }

  void _showTopNotification(String message, {bool alert = false, int seconds = 3}) {
    _topNotificationTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _topNotificationMessage = message;
      _topNotificationAlert = alert;
      _topNotificationVisible = true;
    });
    _topNotificationTimer = Timer(Duration(seconds: seconds), () {
      _hideTopNotification();
    });
  }

  void _hideTopNotification() {
    _topNotificationTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _topNotificationVisible = false;
      _topNotificationMessage = null;
      _topNotificationAlert = false;
    });
  }

  // ── Edit dialog ───────────────────────────────────────────────────────────

  void _showEditDialog() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final nameController =
        TextEditingController(text: widget.trackerName);
    final allowed = [
      'comfort room', 'living room', 'dining area',
      'kitchen', 'bedroom'
    ];
    String selectedLocation =
        allowed.contains(widget.trackerLocation.toLowerCase())
            ? widget.trackerLocation.toLowerCase()
            : 'comfort room';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tracker'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameController,
            decoration:
                const InputDecoration(labelText: 'Tracker name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedLocation,
            items: const [
              DropdownMenuItem(value: 'comfort room', child: Text('Comfort Room')),
              DropdownMenuItem(value: 'living room',  child: Text('Living Room')),
              DropdownMenuItem(value: 'dining area',  child: Text('Dining Area')),
              DropdownMenuItem(value: 'kitchen',      child: Text('Kitchen')),
              DropdownMenuItem(value: 'bedroom',      child: Text('Bedroom')),
            ],
            onChanged: (v) { if (v != null) selectedLocation = v; },
            decoration: const InputDecoration(labelText: 'Location'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
                    'trackers.${widget.trackerId}.device_name': newName,
                    'trackers.${widget.trackerId}.location': selectedLocation,
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
                    const SnackBar(content: Text('Tracker updated')));
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
      ),
    );
  }

  // ── Advice ────────────────────────────────────────────────────────────────

  Widget _buildDynamicAdvice(double t, double h, double lpg,
      double co, double co2, int pmAqi) {
    if (co > 35) {
      return _buildAdviceBox(Colors.red, Icons.warning_amber_rounded,
          "CO Alert — Ventilate Now",
          "Carbon monoxide is at a dangerous level. Open windows and doors immediately.");
    } else if (lpg > 200 || pmAqi > 100) {
      return _buildAdviceBox(Colors.orange, Icons.warning_amber_rounded,
          "Action Required",
          "High pollutants detected. Open windows for ventilation.");
    } else if (co2 > 1500) {
      return _buildAdviceBox(Colors.orange, Icons.air,
          "Poor Ventilation",
          "CO₂ levels are elevated. Let in fresh air to avoid drowsiness.");
    } else if (t > 35 || h > 80) {
      return _buildAdviceBox(Colors.blue, Icons.thermostat,
          "Comfort Alert",
          "Environment is outside the ideal range. Consider adjusting your HVAC.");
    } else {
      return _buildAdviceBox(Colors.green, Icons.check_circle_outline,
          "Air is Healthy",
          "Everything looks great! No significant pollutants detected.");
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildAQICard(int aqi, String time, String loc) {
    Color statusColor = _getColor(aqi);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        const Text("Air Quality Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ]),
        ),
        const SizedBox(height: 15),
        Text(_getStatus(aqi),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                fontSize: 18)),
        Text("Last updated: $time",
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
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
          ]),
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
              ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ClimateHistoryContent
// Plots Temperature, Humidity, and Absolute Humidity on a shared chart.
// Each metric is individually togglable. Chart supports pinch-to-zoom + pan.
// ═══════════════════════════════════════════════════════════════════════════════

class ClimateHistoryContent extends StatefulWidget {
  final String trackerId;
  const ClimateHistoryContent({Key? key, required this.trackerId})
      : super(key: key);

  @override
  _ClimateHistoryContentState createState() =>
      _ClimateHistoryContentState();
}

class _ClimateHistoryContentState
    extends State<ClimateHistoryContent> {
  int selectedTabIndex = 0;
  final List<String> tabs = ["Today", "7 Days", "30 Days"];
  final Map<int, Future<Map<String, dynamic>>> _cache = {};

  bool _showTemp   = true;
  bool _showHum    = true;
  bool _showAbsHum = false; // different scale — off by default

  double _minX   = 0;
  double _maxX   = 24;
  double _minY   = 0;
  double _maxY   = 100;
  bool   _zoomed = false;

  static const double Vc = 5.0;

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    if (v is Timestamp)
      return v.toDate().millisecondsSinceEpoch.toDouble();
    return 0.0;
  }

  double _absHum(double t, double h) =>
      (6.112 * exp((17.67 * t) / (t + 243.5)) * h * 2.1674) /
      (273.15 + t);

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

      final List<Map<String, dynamic>> points = [];
      for (var d in qSnap.docs.reversed) {
        final m  = d.data() as Map<String, dynamic>;
        DateTime? dt;
        final ts = m['timestamp'];
        if (ts is Timestamp)     dt = ts.toDate();
        else if (ts is DateTime) dt = ts;
        else if (ts is String)   dt = DateTime.tryParse(ts);
        if (dt == null || dt.isBefore(start)) continue;
        final t = _toDouble(m['temperature']);
        final h = _toDouble(m['humidity']);
        points.add({
          't':      dt,
          'temp':   t,
          'hum':    h,
          'absHum': _absHum(t, h),
        });
      }
      return {'points': points, 'start': start};
    } catch (e, st) {
      if (kDebugMode) print('ClimateHistory error: $e\n$st');
      return {'points': [], 'start': start};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabSwitcher(),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: [
        _toggleChip('Temp', Colors.orange, _showTemp,
            (v) => setState(() { _showTemp = v; _zoomed = false; })),
        _toggleChip('Humidity', Colors.blue, _showHum,
            (v) => setState(() { _showHum = v; _zoomed = false; })),
        _toggleChip('Abs Hum', Colors.indigo, _showAbsHum,
            (v) => setState(() { _showAbsHum = v; _zoomed = false; })),
      ]),
      const SizedBox(height: 6),
      const Text('Pinch to zoom  •  Drag to pan  •  Tap Reset to fit',
          style: TextStyle(fontSize: 10, color: Colors.black38)),
      const SizedBox(height: 10),
      _buildChartBox(),
    ]);
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12)),
      child: Stack(children: [
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
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Row(
          children: List.generate(tabs.length, (i) => Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                selectedTabIndex = i;
                _cache.remove(i);
                _zoomed = false;
              }),
              child: Center(
                child: Text(tabs[i],
                    style: TextStyle(
                        color: selectedTabIndex == i
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ),
          )),
        ),
      ]),
    );
  }

  Widget _toggleChip(String label, Color color, bool active,
      ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: active ? color : Colors.grey.shade400,
                  shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? color : Colors.grey,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildChartBox() {
    final int days =
        selectedTabIndex == 0 ? 1 : (selectedTabIndex == 1 ? 7 : 30);
    _cache[selectedTabIndex] ??= _fetchHistory(days);

    return FutureBuilder<Map<String, dynamic>>(
      future: _cache[selectedTabIndex],
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()));

        final data   = snap.data ?? {'points': [], 'start': DateTime.now()};
        final points = (data['points'] as List<dynamic>?) ?? [];
        final start  = data['start'] as DateTime? ?? DateTime.now();

        if (points.isEmpty)
          return const SizedBox(
              height: 220,
              child: Center(
                  child: Text('No history data',
                      style: TextStyle(color: Colors.grey))));

        final spotsTemp   = <FlSpot>[];
        final spotsHum    = <FlSpot>[];
        final spotsAbsHum = <FlSpot>[];

        for (var p in points) {
          final x = (p['t'] as DateTime).difference(start).inMinutes / 60.0;
          if (_showTemp)   spotsTemp.add(FlSpot(x, p['temp'] as double));
          if (_showHum)    spotsHum.add(FlSpot(x, p['hum'] as double));
          if (_showAbsHum) spotsAbsHum.add(FlSpot(x, p['absHum'] as double));
        }

        final allY = [
          if (_showTemp)   ...spotsTemp.map((s) => s.y),
          if (_showHum)    ...spotsHum.map((s) => s.y),
          if (_showAbsHum) ...spotsAbsHum.map((s) => s.y),
        ];
        final dataMaxY = allY.isNotEmpty ? allY.reduce(max) * 1.15 : 100.0;
        final dataMinY = allY.isNotEmpty
            ? (allY.reduce(min) * 0.85).clamp(0.0, double.infinity)
            : 0.0;
        final dataMaxX = points.isNotEmpty
            ? (points.last['t'] as DateTime).difference(start).inMinutes / 60.0
            : 24.0;

        if (!_zoomed) {
          _minX = 0; _maxX = dataMaxX;
          _minY = dataMinY; _maxY = dataMaxY;
        }

        final interval = ((_maxX - _minX) / 5).clamp(0.5, _maxX).toDouble();

        final bars = <LineChartBarData>[
          if (_showTemp   && spotsTemp.isNotEmpty)   _bar(spotsTemp,   Colors.orange),
          if (_showHum    && spotsHum.isNotEmpty)    _bar(spotsHum,    Colors.blue),
          if (_showAbsHum && spotsAbsHum.isNotEmpty) _bar(spotsAbsHum, Colors.indigo),
        ];

        return Column(children: [
          SizedBox(
            height: 220,
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoomed = true;
                  if (details.scale == 1.0) {
                    final dx = -details.focalPointDelta.dx /
                        context.size!.width * (_maxX - _minX) * 2;
                    final range = _maxX - _minX;
                    _minX = (_minX + dx).clamp(0.0, dataMaxX - range);
                    _maxX = _minX + range;
                  } else {
                    final mid   = (_minX + _maxX) / 2;
                    final half  = ((_maxX - _minX) / details.scale / 2)
                        .clamp(0.5, dataMaxX / 2);
                    _minX = (mid - half).clamp(0.0, dataMaxX);
                    _maxX = (mid + half).clamp(_minX + 0.5, dataMaxX);
                  }
                });
              },
              child: LineChart(LineChartData(
                minX: _minX, maxX: _maxX,
                minY: _minY, maxY: _maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots.map((s) =>
                        LineTooltipItem(s.y.toStringAsFixed(1),
                            const TextStyle(
                                color: Colors.white, fontSize: 11))).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final label = start.add(
                            Duration(minutes: (v * 60).round()));
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
                      reservedSize: 38,
                      getTitlesWidget: (v, meta) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black45)),
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: bars,
              )),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (_showTemp)   _dot(Colors.orange,  'Temp (°C)'),
            if (_showTemp)   const SizedBox(width: 12),
            if (_showHum)    _dot(Colors.blue,    'Humidity (%)'),
            if (_showHum)    const SizedBox(width: 12),
            if (_showAbsHum) _dot(Colors.indigo,  'Abs Hum (g/m³)'),
            const Spacer(),
            if (_zoomed)
              TextButton.icon(
                onPressed: () => setState(() {
                  _zoomed = false;
                  _minX = 0; _maxX = dataMaxX;
                  _minY = dataMinY; _maxY = dataMaxY;
                }),
                icon: const Icon(Icons.fit_screen, size: 14),
                label: const Text('Reset',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ]),
        ]);
      },
    );
  }

  Widget _dot(Color color, String label) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black54)),
      ]);

  LineChartBarData _bar(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        color: color,
        isCurved: true,
        barWidth: 2,
        dotData: FlDotData(
          show: spots.length < 60,
          getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
              radius: 2.5,
              color: color,
              strokeWidth: 0,
              strokeColor: Colors.transparent),
        ),
        belowBarData: BarAreaData(
            show: true, color: color.withOpacity(0.06)),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SlidingHistoryContent — Pollutant chart (PM2.5 / CO₂ / CO)
// Per-metric toggle + pinch-to-zoom + drag-to-pan.
// ═══════════════════════════════════════════════════════════════════════════════

class SlidingHistoryContent extends StatefulWidget {
  final String trackerId;
  const SlidingHistoryContent({Key? key, required this.trackerId})
      : super(key: key);

  @override
  _SlidingHistoryContentState createState() =>
      _SlidingHistoryContentState();
}

class _SlidingHistoryContentState
    extends State<SlidingHistoryContent> {
  int selectedTabIndex = 0;
  final List<String> tabs = ["Today", "7 Days", "30 Days"];
  final Map<int, Future<Map<String, dynamic>>> _historyCache = {};

  bool _showPM25 = true;
  bool _showCO2  = true;
  bool _showCO   = true;

  double _minX   = 0;
  double _maxX   = 24;
  double _minY   = 0;
  double _maxY   = 500;
  bool   _zoomed = false;

  static const double Ro_MQ9   = 7.3;
  static const double Ro_MQ135 = 78.9;
  static const double RL_MQ9   = 5.0;
  static const double RL_MQ135 = 10.0;
  static const double Vc       = 5.0;

  double _getRsRatio(double vout, double rl, double ro) {
    if (vout <= 0 || vout >= Vc) return 100.0;
    return (((Vc - vout) / vout) * rl) / ro;
  }

  double _localPPM(double ratio, double a, double b) {
    if (ratio.isNaN || ratio <= 0) return 0.0;
    double val = a * pow(ratio.clamp(0.01, 100.0), b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0);
  }

  double _cf(double t, double h) =>
      (-0.00035 * pow(t, 2) + 0.0177 * t -
              0.0000179 * pow(h, 2) + 0.00699 * h - 0.1689)
          .clamp(0.1, 10.0);

  Map<String, double> _estimateGases(Map<String, dynamic> m) {
    double v9   = _toDouble(m['mq9_v']);
    double v135 = _toDouble(m['mq135_v']);
    double t    = _toDouble(m['temperature']);
    double h    = _toDouble(m['humidity']);

    if (v9   > 20) v9   = v9   * (Vc / 1023.0);
    if (v135 > 20) v135 = v135 * (Vc / 1023.0);

    double r9   = _getRsRatio(v9,   RL_MQ9,   Ro_MQ9);
    double r135 = _getRsRatio(v135, RL_MQ135, Ro_MQ135);

    double co     = _localPPM(r9, 1000.5, -1.969);
    double rawCo2 = _localPPM(r135, 110.47, -2.862) * _cf(t, h);
    double co2    = rawCo2 < 420 ? 420.0 : rawCo2;

    double coOv  = _toDouble(m['co']);
    double co2Ov = _toDouble(m['co2'] ?? m['co2_est']);
    if (coOv  > 0) co  = coOv;
    if (co2Ov > 0) co2 = co2Ov;

    return {'co': co, 'co2': co2};
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim().replaceAll(',', '')) ?? 0.0;
    if (v is Timestamp) return v.toDate().millisecondsSinceEpoch.toDouble();
    return 0.0;
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

      if (kDebugMode)
        print('[_fetchHistory] ${qSnap.docs.length} docs (days=$days)');

      final List<Map<String, dynamic>> points = [];
      for (var d in qSnap.docs.reversed) {
        final m  = d.data() as Map<String, dynamic>;
        DateTime? dt;
        final ts = m['timestamp'];
        if (ts is Timestamp)     dt = ts.toDate();
        else if (ts is DateTime) dt = ts;
        else if (ts is String)   dt = DateTime.tryParse(ts);
        if (dt == null || dt.isBefore(start)) continue;

        final pm25  = _toDouble(m['pm2_5']);
        final gases = _estimateGases(m);
        points.add({
          't':    dt,
          'pm25': pm25,
          'co2':  gases['co2']!,
          'co':   gases['co']!,
        });
      }

      if (kDebugMode) print('[_fetchHistory] ${points.length} points');
      return {'points': points, 'start': start};
    } catch (e, st) {
      if (kDebugMode) print('Error fetching history: $e\n$st');
      return {'points': [], 'start': start};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildTabSwitcher(),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: [
        _toggleChip('PM2.5', Colors.redAccent, _showPM25,
            (v) => setState(() { _showPM25 = v; _zoomed = false; })),
        _toggleChip('CO₂', Colors.teal, _showCO2,
            (v) => setState(() { _showCO2 = v; _zoomed = false; })),
        _toggleChip('CO', Colors.green.shade600, _showCO,
            (v) => setState(() { _showCO = v; _zoomed = false; })),
      ]),
      const SizedBox(height: 6),
      const Text('Pinch to zoom  •  Drag to pan  •  Tap Reset to fit',
          style: TextStyle(fontSize: 10, color: Colors.black38)),
      const SizedBox(height: 10),
      _buildChartBox(),
    ]);
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12)),
      child: Stack(children: [
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
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Row(
          children: List.generate(tabs.length, (i) => Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                selectedTabIndex = i;
                _zoomed = false;
              }),
              child: Center(
                child: Text(tabs[i],
                    style: TextStyle(
                        color: selectedTabIndex == i
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ),
          )),
        ),
      ]),
    );
  }

  Widget _toggleChip(String label, Color color, bool active,
      ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: active ? color : Colors.grey.shade400,
                  shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? color : Colors.grey,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildChartBox() {
    final int days =
        selectedTabIndex == 0 ? 1 : (selectedTabIndex == 1 ? 7 : 30);
    _historyCache[selectedTabIndex] ??= _fetchHistory(days);

    return FutureBuilder<Map<String, dynamic>>(
      future: _historyCache[selectedTabIndex],
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()));
        if (snap.hasError)
          return SizedBox(
              height: 220,
              child: Center(child: Text('Error: ${snap.error}')));

        final data   = snap.data ?? {'points': [], 'start': DateTime.now()};
        final points = (data['points'] as List<dynamic>?) ?? [];
        final start  = data['start'] as DateTime? ?? DateTime.now();

        if (points.isEmpty)
          return const SizedBox(
              height: 220,
              child: Center(
                  child: Text('No history data',
                      style: TextStyle(color: Colors.grey))));

        final spotsPm  = <FlSpot>[];
        final spotsCo2 = <FlSpot>[];
        final spotsCo  = <FlSpot>[];

        for (var p in points) {
          final x = (p['t'] as DateTime).difference(start).inMinutes / 60.0;
          if (_showPM25) spotsPm.add(FlSpot(x, p['pm25'] as double));
          if (_showCO2)  spotsCo2.add(FlSpot(x, p['co2']  as double));
          if (_showCO)   spotsCo.add(FlSpot(x,  p['co']   as double));
        }

        final allY = [
          if (_showPM25) ...spotsPm.map((s) => s.y),
          if (_showCO2)  ...spotsCo2.map((s) => s.y),
          if (_showCO)   ...spotsCo.map((s) => s.y),
        ];
        final dataMaxY =
            allY.isNotEmpty ? allY.reduce(max) * 1.15 : 500.0;
        final dataMinY = allY.isNotEmpty
            ? (allY.reduce(min) * 0.85).clamp(0.0, double.infinity)
            : 0.0;
        final dataMaxX = points.isNotEmpty
            ? (points.last['t'] as DateTime)
                .difference(start)
                .inMinutes /
                60.0
            : 24.0;

        if (!_zoomed) {
          _minX = 0; _maxX = dataMaxX;
          _minY = dataMinY; _maxY = dataMaxY;
        }

        final interval =
            ((_maxX - _minX) / 5).clamp(0.5, _maxX).toDouble();

        final bars = <LineChartBarData>[
          if (_showPM25 && spotsPm.isNotEmpty)  _bar(spotsPm,  Colors.redAccent),
          if (_showCO2  && spotsCo2.isNotEmpty) _bar(spotsCo2, Colors.teal),
          if (_showCO   && spotsCo.isNotEmpty)  _bar(spotsCo,  Colors.green.shade600),
        ];

        return Column(children: [
          SizedBox(
            height: 220,
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoomed = true;
                  if (details.scale == 1.0) {
                    final dx = -details.focalPointDelta.dx /
                        context.size!.width * (_maxX - _minX) * 2;
                    final range = _maxX - _minX;
                    _minX = (_minX + dx).clamp(0.0, dataMaxX - range);
                    _maxX = _minX + range;
                  } else {
                    final mid  = (_minX + _maxX) / 2;
                    final half = ((_maxX - _minX) / details.scale / 2)
                        .clamp(0.5, dataMaxX / 2);
                    _minX = (mid - half).clamp(0.0, dataMaxX);
                    _maxX = (mid + half).clamp(_minX + 0.5, dataMaxX);
                  }
                });
              },
              child: LineChart(LineChartData(
                minX: _minX, maxX: _maxX,
                minY: _minY, maxY: _maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots.map((s) =>
                        LineTooltipItem(s.y.toStringAsFixed(1),
                            const TextStyle(
                                color: Colors.white, fontSize: 11))).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final label = start.add(
                            Duration(minutes: (v * 60).round()));
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
                              fontSize: 10, color: Colors.black45)),
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: bars,
              )),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (_showPM25) _dot(Colors.redAccent,      'PM2.5'),
            if (_showPM25) const SizedBox(width: 12),
            if (_showCO2)  _dot(Colors.teal,           'CO₂'),
            if (_showCO2)  const SizedBox(width: 12),
            if (_showCO)   _dot(Colors.green.shade600, 'CO'),
            const Spacer(),
            if (_zoomed)
              TextButton.icon(
                onPressed: () => setState(() {
                  _zoomed = false;
                  _minX = 0; _maxX = dataMaxX;
                  _minY = dataMinY; _maxY = dataMaxY;
                }),
                icon: const Icon(Icons.fit_screen, size: 14),
                label: const Text('Reset',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ]),
        ]);
      },
    );
  }

  Widget _dot(Color color, String label) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]);

  LineChartBarData _bar(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        color: color,
        isCurved: true,
        barWidth: 2,
        dotData: FlDotData(
          show: spots.length < 60,
          getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
              radius: 2.5,
              color: color,
              strokeWidth: 0,
              strokeColor: Colors.transparent),
        ),
        belowBarData: BarAreaData(
            show: true, color: color.withOpacity(0.06)),
      );
}