import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SummaryTab extends StatefulWidget {
  @override
  _SummaryTabState createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final Color backgroundMint = const Color(0xFFD7EEEB);

  // Helpers copied/adapted from trackers_info
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
    if (ratio.isNaN) return 0.0;
    const double minRatio = 0.01;
    const double maxRatio = 100.0;
    double safeRatio = ratio.clamp(minRatio, maxRatio);
    double val = a * pow(safeRatio, b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0) as double;
  }

  double getCorrectionFactor(double t, double h) {
    return -0.00035 * pow(t, 2) + 0.0177 * t - 0.0000179 * pow(h, 2) + 0.00699 * h - 0.1689;
  }

  int getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo = (co / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

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

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 3)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAQILegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _legendItem(Colors.green, 'Good 0–50'),
          _legendItem(Colors.yellow.shade800, 'Fair 51–100'),
          _legendItem(Colors.orange, 'Unhealthy(S) 101–150'),
          _legendItem(Colors.red, 'Very Unhealthy 151–200'),
          _legendItem(Colors.purple, 'Acutely Unhealthy 201–300'),
          _legendItem(const Color(0xFF800000), 'Emergency 301–500'),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchLatestForDevice(DocumentSnapshot device) async {
    final readings = await device.reference.collection('readings').orderBy('timestamp', descending: true).limit(1).get();
    if (readings.docs.isEmpty) return {};
    return readings.docs.first.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _gatherDevicesWithReadings() async {
    final devicesSnap = await FirebaseFirestore.instance.collection('devices').where('owner_id', isEqualTo: currentUserId).get();
    final results = <Map<String, dynamic>>[];
    for (var d in devicesSnap.docs) {
      final latest = await _fetchLatestForDevice(d);
      // Normalize location field which may be stored as GeoPoint or String
      final raw = (d.data() as Map<String, dynamic>)['location'];
      String locStr = '';
      if (raw != null) {
        if (raw is GeoPoint) {
          locStr = '${raw.latitude.toStringAsFixed(4)}, ${raw.longitude.toStringAsFixed(4)}';
        } else if (raw is String) {
          locStr = raw;
        } else if (raw is Map) {
          try {
            final lat = raw['latitude'] ?? raw['lat'];
            final lng = raw['longitude'] ?? raw['lng'] ?? raw['lon'];
            locStr = '${lat.toString()}, ${lng.toString()}';
          } catch (_) {
            locStr = raw.toString();
          }
        } else {
          locStr = raw.toString();
        }
      }

      results.add({
        'id': d.id,
        'name': (d.data() as Map<String, dynamic>)['device_name'] ?? 'Unnamed',
        'location': locStr,
        'reading': latest,
      });
    }
    return results;
  }

  double _averageForKey(List<Map<String, dynamic>> devices, String key) {
    final vals = devices.map((d) {
      final r = d['reading'] as Map<String, dynamic>;
      return (r[key] ?? 0).toDouble();
    }).where((v) => v != 0).toList();
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  DateTime? _latestTimestamp(List<Map<String, dynamic>> devices) {
    DateTime? latest;
    for (var d in devices) {
      final r = d['reading'] as Map<String, dynamic>;
      final ts = r['timestamp'];
      if (ts == null) continue;
      DateTime dt;
      try {
        if (ts is DateTime) dt = ts;
        else if (ts is Timestamp) dt = ts.toDate();
        else continue;
      } catch (_) {
        continue;
      }
      if (latest == null || dt.isAfter(latest)) latest = dt;
    }
    return latest;
  }

  int _computeIAQIFromReading(Map<String, dynamic> r) {
    if (r.isEmpty) return 0;
    double t = (r['temperature'] ?? 0).toDouble();
    double h = (r['humidity'] ?? 0).toDouble();
    double pm25 = (r['pm2_5'] ?? 0).toDouble();
    double v2 = (r['mq2_v'] ?? 0).toDouble();
    double v9 = (r['mq9_v'] ?? 0).toDouble();
    double v135 = (r['mq135_v'] ?? 0).toDouble();

          // Use 5.0V reference (Arduino Uno) to compute sensor resistance ratios
          double r2 = (v2 > 0) ? (5.0 - v2) / v2 : 0.0;
          double r9 = (v9 > 0) ? (5.0 - v9) / v9 : 0.0;
          double r135 = (v135 > 0) ? (5.0 - v135) / v135 : 0.0;

    double lpg = calculatePPM(r2, 574.25, -2.222);
    double co = calculatePPM(r9, 1000.5, -1.969);
    double co2 = calculatePPM(r135 / (getCorrectionFactor(t, h).clamp(0.1, 10)), 110.47, -2.862);
    double nh3 = calculatePPM(r135, 102.2, -2.473);

    int pmAqi = calculatePM25AQI(pm25);
    return getCompositeIAQI(co, co2, nh3, pmAqi);
  }

  double calculateAbsoluteHumidity(double temp, double hum) {
    return (6.112 * exp((17.67 * temp) / (temp + 243.5)) * hum * 2.1674) / (273.15 + temp);
  }

  Color _getTempColor(double t) {
    if (t >= 18 && t <= 26) return Colors.green;
    if ((t >= 10 && t < 18) || (t > 26 && t <= 30)) return Colors.yellow.shade800;
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

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.black87, fontSize: 11)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundMint,
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gatherDevicesWithReadings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final devices = snapshot.data ?? [];

          if (devices.isEmpty) {
            return const Center(child: Text('No trackers linked to this account.'));
          }

          final iaqis = devices.map((d) => _computeIAQIFromReading(d['reading'] as Map<String, dynamic>)).toList();
          final total = devices.length;
          final avg = iaqis.isNotEmpty ? (iaqis.reduce((a, b) => a + b) / iaqis.length).round() : 0;

          final statusCounts = <String, int>{};
          for (var aqi in iaqis) {
            final status = _getStatus(aqi);
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          final pm25Avg = _averageForKey(devices, 'pm2_5');
          final co2Avg = _averageForKey(devices, 'co2') == 0 ? _averageForKey(devices, 'co2_est') : _averageForKey(devices, 'co2');
          final lastUpdated = _latestTimestamp(devices);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              // Overall card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0,4))],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Indoor Air Quality', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenWidth = MediaQuery.of(context).size.width;
                        final double circleSize = screenWidth * 0.22;
                        final double size = circleSize.clamp(80.0, 140.0);
                        final double fontSize = (size / 4).clamp(18.0, 32.0);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circle
                            Container(
                              height: size,
                              width: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: _getColor(avg), width: 6),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$avg', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: _getColor(avg))),
                                    const SizedBox(height: 6),
                                    const Text('AQI Average', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColor(avg), shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(_getStatus(avg), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Last updated: ${lastUpdated != null ? TimeOfDay.fromDateTime(lastUpdated).format(context) : '—'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // AQI Legend
              _buildAQILegend(),

              const SizedBox(height: 8),

              // Tracker Summary header
              const Text('Tracker Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              // PM2.5 card
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PM2.5', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(children: [Text('${pm25Avg.toStringAsFixed(1)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width:6), const Text('µg/m³ average', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.circle, color: Colors.yellow.shade800, size:10), const SizedBox(width:6), const Text('Moderate', style: TextStyle(fontSize:12))])),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox.shrink(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // CO2 card (simple)
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CO₂', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Row(children: [Text('${co2Avg.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width:6), const Text('ppm average', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.circle, color: Colors.orange.shade700, size:10), const SizedBox(width:6), const Text('Moderate', style: TextStyle(fontSize:12))])),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox.shrink(),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Detailed per-tracker metrics (moved into Tracker Summary)
              ...devices.map((d) {
                final reading = d['reading'] as Map<String, dynamic>;
                final aqi = _computeIAQIFromReading(reading);
                final color = _getColor(aqi);
                final status = _getStatus(aqi);

                double t = (reading['temperature'] ?? 0).toDouble();
                double h = (reading['humidity'] ?? 0).toDouble();
                double pm25 = (reading['pm2_5'] ?? 0).toDouble();
                double v2 = (reading['mq2_v'] ?? 0).toDouble();
                double v9 = (reading['mq9_v'] ?? 0).toDouble();
                double v135 = (reading['mq135_v'] ?? 0).toDouble();

                // Heuristic: convert raw ADC counts (>20) to volts using 5V ref.
                if (v2 > 20) v2 = v2 * (5.0 / 1023.0);
                if (v9 > 20) v9 = v9 * (5.0 / 1023.0);
                if (v135 > 20) v135 = v135 * (5.0 / 1023.0);

                const double fallbackRatio = 100.0;
                double r2 = (v2 > 0) ? ((5.0 - v2) / v2) : fallbackRatio;
                double r9 = (v9 > 0) ? ((5.0 - v9) / v9) : fallbackRatio;
                double r135 = (v135 > 0) ? ((5.0 - v135) / v135) : fallbackRatio;

                double lpg = calculatePPM(r2, 574.25, -2.222);
                double co = calculatePPM(r9, 1000.5, -1.969);
                double co2 = calculatePPM(r135 / (getCorrectionFactor(t, h).clamp(0.1, 10)), 110.47, -2.862);
                double nh3 = calculatePPM(r135, 102.2, -2.473);
                double absHum = calculateAbsoluteHumidity(t, h);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(d['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('$aqi', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(status, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _metricChip('Temp', '${t.toStringAsFixed(1)}°C', _getTempColor(t)),
                            _metricChip('Hum', '${h.toStringAsFixed(0)}%', _getHumidityColor(h)),
                            _metricChip('Abs Hum', '${absHum.toStringAsFixed(2)} g/m³', Colors.indigo),
                            _metricChip('PM2.5', '${pm25.toStringAsFixed(1)} µg/m³', _getColor(calculatePM25AQI(pm25))),
                            _metricChip('LPG', '${lpg.toStringAsFixed(1)} ppm', _getLPGColor(lpg)),
                            _metricChip('CO', '${co.toStringAsFixed(1)} ppm', _getCOColor(co)),
                            _metricChip('CO₂', '${co2.toStringAsFixed(0)} ppm', _getCO2Color(co2)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
