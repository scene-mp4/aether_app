import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trackers_info.dart';

class TrackersTab extends StatefulWidget {
  @override
  _TrackersTabState createState() => _TrackersTabState();
}

class _TrackersTabState extends State<TrackersTab> {
  bool _showDetails = false;
  Map<String, dynamic>? _selectedTrackerData;
  String _selectedTrackerId = "";
  String? _unlinkingId;
  final Map<String, StreamSubscription<QuerySnapshot>> _readingSubs = {};
  final Map<String, String> _lastReadingIds = {};
  Set<String> _subscribedTrackerIds = {};
  final Map<String, bool> _lastAlertedHigh = {};
  final Map<String, Timer> _creationTimers = {};
  // top notification banner state
  String? _topNotificationMessage;
  bool _topNotificationAlert = false;
  bool _topNotificationVisible = false;
  Timer? _topNotificationTimer;
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? "";

  final List<String> _allowedLocations = [
    'comfort room',
    'living room',
    'dining area',
    'kitchen',
    'bedroom'
  ];

  // ── Calibration constants (must match trackers_info.dart) ─────────────────
  static const double Ro_MQ2   = 2.7;
  static const double Ro_MQ9   = 6;
  static const double Ro_MQ135 = 18;
  static const double RL_MQ2   = 5.0;
  static const double RL_MQ9   = 5.0;
  static const double RL_MQ135 = 10.0;
  static const double Vc       = 5.0;

  // ── Rs/Ro ratio ───────────────────────────────────────────────────────────
  // FIX: Includes RL and Ro — previously missing Ro division entirely.
  double _getRsRatio(double vout, double rl, double ro) {
    if (vout <= 0 || vout >= Vc) return 100.0;
    double rs = ((Vc - vout) / vout) * rl;
    return rs / ro;
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
      if (!mounted) return;
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

  // ── PPM from Rs/Ro ratio ──────────────────────────────────────────────────
  double _calculatePPM(double ratio, double a, double b) {
    if (ratio <= 0 || ratio.isNaN) return 0.0;
    double safeRatio = ratio.clamp(0.01, 100.0);
    double val = a * pow(safeRatio, b);
    if (val.isNaN || val.isInfinite) return 0.0;
    return val.clamp(0.0, 10000.0);
  }

  // ── Temperature & humidity correction for MQ-135 ─────────────────────────
  // FIX: Clamped and applied as multiplier on result (not divisor on ratio).
  double _getCorrectionFactor(double t, double h) {
    double cf = -0.00035 * pow(t, 2) +
        0.0177 * t -
        0.0000179 * pow(h, 2) +
        0.00699 * h -
        0.1689;
    return cf.clamp(0.1, 10.0);
  }

  // ── EPA PM2.5 AQI piecewise formula ──────────────────────────────────────
  int _calculatePM25AQI(double concentration) {
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
        return (((r[3] - r[2]) / (r[1] - r[0])) *
                    (concentration - r[0]) +
                r[2])
            .round();
      }
    }
    return 500;
  }

  // ── Composite IAQI ────────────────────────────────────────────────────────
  int _getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo  = (co  / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

  // ── Compute all gases + IAQI from a raw Firestore reading map ────────────
  // FIX: Uses corrected _getRsRatio with RL + Ro.
  // FIX: CO2 correction applied as multiplier on result (not divisor on ratio).
  // FIX: CO2 floored at 420 ppm (outdoor baseline).
  // FIX: Reads 'pm2_5' to match Arduino field name (was 'pm25').
  Map<String, dynamic> _computeMetrics(Map<String, dynamic> r) {
    double t    = _toDouble(r['temperature']);
    double h    = _toDouble(r['humidity']);
    double pm25 = _toDouble(r['pm2_5']);
    double v2   = _toDouble(r['mq2_v']);
    double v9   = _toDouble(r['mq9_v']);
    double v135 = _toDouble(r['mq135_v']);

    if (v2   > 20) v2   = v2   * (Vc / 1023.0);
    if (v9   > 20) v9   = v9   * (Vc / 1023.0);
    if (v135 > 20) v135 = v135 * (Vc / 1023.0);

    double ratio2   = _getRsRatio(v2,   RL_MQ2,   Ro_MQ2);
    double ratio9   = _getRsRatio(v9,   RL_MQ9,   Ro_MQ9);
    double ratio135 = _getRsRatio(v135, RL_MQ135, Ro_MQ135);

    double lpg = _calculatePPM(ratio2,   574.25, -2.222);
    double co  = _calculatePPM(ratio9,  1000.5,  -1.969);
    double nh3 = _calculatePPM(ratio135, 102.2,  -2.473);

    double cf     = _getCorrectionFactor(t, h);
    double rawCo2 = _calculatePPM(ratio135, 110.47, -2.862) * cf;
    double co2    = rawCo2 < 420 ? 420.0 : rawCo2;

    double coOverride  = _toDouble(r['co']);
    double co2Override = _toDouble(r['co2'] ?? r['co2_est']);
    if (coOverride  > 0) co  = coOverride;
    if (co2Override > 0) co2 = co2Override;

    int pmAqi = _calculatePM25AQI(pm25);
    int iaqi  = _getCompositeIAQI(co, co2, nh3, pmAqi);

    return {
      'temp':  t,
      'hum':   h,
      'pm25':  pm25,
      'lpg':   lpg,
      'co':    co,
      'co2':   co2,
      'nh3':   nh3,
      'pmAqi': pmAqi,
      'iaqi':  iaqi,
    };
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

  // FIX: Widened comfort threshold to 30°C to match other tabs.
  Color _getTempColor(double t) {
    if (t >= 18 && t <= 30) return Colors.green;
    if ((t > 30 && t <= 35) || (t >= 10 && t < 18))
      return Colors.yellow.shade800;
    return Colors.red;
  }

  // FIX: Widened ideal humidity range to 60% to match other tabs.
  Color _getHumidityColor(double h) {
    if (h >= 30 && h <= 60) return Colors.green;
    if (h > 60 && h <= 80)  return Colors.yellow.shade800;
    return Colors.red;
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

  Color _getLPGColor(double ppm) {
    if (ppm <= 200)  return Colors.green;
    if (ppm <= 1000) return Colors.orange;
    return Colors.red;
  }

  // ── Tracker actions ───────────────────────────────────────────────────────

  Future<void> _linkTracker(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(docId)
          .update({'owner_id': currentUserId});
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Tracker successfully linked!")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Link failed: $e')));
    }
  }

  void _confirmUnlink(String docId, Map<String, dynamic> tracker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Tracker'),
        content: Text(
            'Are you sure you want to unlink '
            '"${tracker['device_name'] ?? 'this tracker'}"? '
            'It will no longer be available to your account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _unlinkingId = docId);
              _unlinkTracker(docId);
            },
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkTracker(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(docId)
          .update({'owner_id': ""});

      if (currentUserId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({'trackers.$docId': FieldValue.delete()})
            .catchError((_) async {});
      }

      if (_selectedTrackerId == docId) {
        setState(() {
          _showDetails = false;
          _selectedTrackerId = '';
          _selectedTrackerData = null;
        });
      }

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tracker unlinked')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unlink failed: $e')));
    } finally {
      if (mounted)
        setState(() {
          if (_unlinkingId == docId) _unlinkingId = null;
        });
    }
  }

  void _showAvailableTrackers() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .where('owner_id', isEqualTo: "")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final available = snapshot.data!.docs;
          if (available.isEmpty)
            return const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No available trackers found."));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (context, index) {
              final data =
                  available[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.add_link),
                title:
                    Text(data['device_name'] ?? "Unknown Device"),
                subtitle: Text("ID: ${available[index].id}"),
                onTap: () {
                  Navigator.pop(context);
                  _linkTracker(available[index].id);
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Location string helper ────────────────────────────────────────────────

  String _locString(dynamic rawLoc) {
    if (rawLoc == null) return 'No location set';
    if (rawLoc is GeoPoint)
      return '${rawLoc.latitude.toStringAsFixed(4)}, '
          '${rawLoc.longitude.toStringAsFixed(4)}';
    if (rawLoc is String) return rawLoc;
    if (rawLoc is Map) {
      try {
        final lat = rawLoc['latitude'] ?? rawLoc['lat'];
        final lng =
            rawLoc['longitude'] ?? rawLoc['lng'] ?? rawLoc['lon'];
        return '${lat.toString()}, ${lng.toString()}';
      } catch (_) {
        return rawLoc.toString();
      }
    }
    return rawLoc.toString();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showDetails && _selectedTrackerData != null) {
      return TrackersInfo(
        trackerId: _selectedTrackerId,
        trackerName:
            _selectedTrackerData!['device_name'] ?? "Unknown",
        trackerLocation:
            _locString(_selectedTrackerData!['location']),
        onBack: () => setState(() => _showDetails = false),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAF5),
          appBar: AppBar(
            title: const Text(
              "My Trackers",
              style: TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('devices')
                .where('owner_id', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No trackers linked to this account.",
                      style: TextStyle(color: Colors.grey)),
                );
              }

              final userTrackers = snapshot.data!.docs;

              // schedule reading subscription updates after this frame to avoid
              // doing subscription management during build (can freeze UI).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _updateReadingSubscriptions(userTrackers);
              });

              return ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                children: [
                  for (final doc in userTrackers) ...[
                    _buildTrackerTile(doc),
                    _buildSummaryCard(doc),
                  ],
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF4B5563),
            onPressed: _showAvailableTrackers,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),

        // Top notification banner
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
                  if (_topNotificationAlert)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _topNotificationVisible = false;
                        });
                        if (_selectedTrackerId.isNotEmpty) {
                          setState(() {
                            _showDetails = true;
                          });
                        }
                      },
                      child: const Text('View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
      ],
    );
  }

  // ── Tracker list tile ─────────────────────────────────────────────────────

  Widget _buildTrackerTile(DocumentSnapshot doc) {
    final tracker = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTrackerData = tracker;
        _selectedTrackerId = doc.id;
        _showDetails = true;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6)
          ],
        ),
        child: Row(children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD1EBE9),
            child:
                Icon(Icons.location_on, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tracker['device_name'] ?? 'Unnamed',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151)),
                ),
                const SizedBox(height: 4),
                Text(
                  _locString(tracker['location']),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Colors.black54, size: 20),
              onPressed: () =>
                  _showEditTrackerDialog(doc.id, tracker),
            ),
            if (_unlinkingId == doc.id)
              const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))))
            else
              IconButton(
                icon: const Icon(Icons.link_off,
                    color: Colors.redAccent, size: 20),
                onPressed: () =>
                    _confirmUnlink(doc.id, tracker),
                tooltip: 'Unlink tracker',
              ),
            const Icon(Icons.chevron_right,
                color: Colors.grey),
          ]),
        ]),
      ),
    );
  }

  // ── Air quality summary card (one per tracker) ────────────────────────────
  // Shows IAQI dial, status, and all key pollutant metric chips.
  // Displays a CO alert banner if CO exceeds 35 ppm.

  Widget _buildSummaryCard(DocumentSnapshot doc) {
    final tracker = doc.data() as Map<String, dynamic>;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('devices')
          .doc(doc.id)
          .collection('readings')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: CircularProgressIndicator()),
          );
        }

        if (!s.hasData || s.data!.docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: Text('No readings yet',
                    style: TextStyle(color: Colors.grey))),
          );
        }

        final r       = s.data!.docs.first.data()
            as Map<String, dynamic>;
        final metrics = _computeMetrics(r);

        final int    iaqi  = metrics['iaqi']  as int;
        final double temp  = metrics['temp']  as double;
        final double hum   = metrics['hum']   as double;
        final double pm25  = metrics['pm25']  as double;
        final double lpg   = metrics['lpg']   as double;
        final double co    = metrics['co']    as double;
        final double co2   = metrics['co2']   as double;
        final int    pmAqi = metrics['pmAqi'] as int;
        final Color  color = _getColor(iaqi);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header: location label + IAQI dial ──────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Air Quality Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          _locString(tracker['location']),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            _getStatus(iaqi),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // IAQI circle dial
                  Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: color, width: 5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text('$iaqi',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold)),
                          const Text('IAQI',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Metric chips ─────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metricChip(
                    icon: Icons.thermostat,
                    label: 'Temp',
                    value: '${temp.toStringAsFixed(1)}°C',
                    color: _getTempColor(temp),
                  ),
                  _metricChip(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${hum.toStringAsFixed(0)}%',
                    color: _getHumidityColor(hum),
                  ),
                  _metricChip(
                    icon: Icons.grain,
                    label: 'PM2.5',
                    value:
                        '${pm25.toStringAsFixed(1)} µg/m³',
                    color: _getColor(pmAqi),
                    badge: 'AQI $pmAqi',
                  ),
                  _metricChip(
                    icon: Icons.local_fire_department_outlined,
                    label: 'LPG/Smoke',
                    value: '${lpg.toStringAsFixed(1)} ppm',
                    color: _getLPGColor(lpg),
                  ),
                  _metricChip(
                    icon: Icons.warning_amber_outlined,
                    label: 'CO',
                    value: '${co.toStringAsFixed(1)} ppm',
                    color: _getCOColor(co),
                    badge: _getCOStatus(co),
                  ),
                  _metricChip(
                    icon: Icons.air,
                    label: 'CO₂ (Est.)',
                    value:
                        '${co2.toStringAsFixed(0)} ppm',
                    color: _getCO2Color(co2),
                    badge: _getCO2Status(co2),
                  ),
                ],
              ),

              // ── CO alert banner ──────────────────────────────────
              if (co > 35) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.shade300),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'CO level is elevated — '
                        'ventilate this area immediately.',
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Notifications: subscribe to each tracker's latest reading and show a SnackBar
  void _updateReadingSubscriptions(List<DocumentSnapshot> trackers) {
    final ids = trackers.map((d) => d.id).toSet();

    // cancel subs that are no longer needed
    final removed = _subscribedTrackerIds.difference(ids);
    for (var id in removed) {
      _readingSubs[id]?.cancel();
      _readingSubs.remove(id);
      _lastReadingIds.remove(id);
      _lastAlertedHigh.remove(id);
      _creationTimers[id]?.cancel();
      _creationTimers.remove(id);
    }

    // subscribe to new trackers (stagger creation to avoid bursts)
    final added = ids.difference(_subscribedTrackerIds).toList();
    for (int idx = 0; idx < added.length; idx++) {
      final id = added[idx];
      final int docIndex = trackers.indexWhere((d) => d.id == id);
      if (docIndex == -1) continue;
      final doc = trackers[docIndex];
      // schedule creation with a small stagger to avoid freezing/network bursts
      _creationTimers[id]?.cancel();
      _creationTimers[id] = Timer(Duration(milliseconds: 100 * idx), () {
        try {
          final trackerName = (doc.data() as Map<String, dynamic>)['device_name'] ?? 'Tracker';
          final sub = FirebaseFirestore.instance
              .collection('devices')
              .doc(doc.id)
              .collection('readings')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots()
              .listen((snap) {
            if (!mounted) return;
            if (snap.docs.isEmpty) return;
            final rdoc = snap.docs.first;
            final rid = rdoc.id;
            // initial read: register id but don't notify
            if (_lastReadingIds[doc.id] == null) {
              _lastReadingIds[doc.id] = rid;
              return;
            }
            if (_lastReadingIds[doc.id] == rid) return;
            _lastReadingIds[doc.id] = rid;

            // compute IAQI for notification
            try {
              final r = rdoc.data() as Map<String, dynamic>;
              final metrics = _computeMetrics(r);
              final iaqi = metrics['iaqi'] ?? 0;
              final text = '$trackerName updated — IAQI $iaqi';

              // regular update notification (top banner)
              if (mounted) {
                _showTopNotification(text, alert: false, seconds: 3);
              }

              // high-alert notification (only when crossing threshold)
              const int alertThreshold = 200; // IAQI threshold for alert
              final wasAlerted = _lastAlertedHigh[doc.id] ?? false;
              if (iaqi >= alertThreshold && !wasAlerted) {
                _lastAlertedHigh[doc.id] = true;
                if (mounted) {
                  // set selected tracker so the 'View' action on the banner can open details
                  setState(() {
                    _selectedTrackerId = doc.id;
                    _selectedTrackerData = doc.data() as Map<String, dynamic>;
                  });
                  _showTopNotification('ALERT: $trackerName IAQI $iaqi — immediate action recommended', alert: true, seconds: 6);
                }
              } else if (iaqi < alertThreshold && wasAlerted) {
                // clear alerted state when it falls back
                _lastAlertedHigh[doc.id] = false;
              }
            } catch (_) {
              // ignore parse errors
            }
          }, onError: (e) {
            // log or ignore subscription errors
          });
          _readingSubs[doc.id] = sub;
        } catch (e) {
          // ignore creation errors
        } finally {
          _creationTimers.remove(id);
        }
      });
    }

    _subscribedTrackerIds = ids;
  }

  @override
  void dispose() {
    for (var s in _readingSubs.values) {
      s.cancel();
    }
    _readingSubs.clear();
    for (var t in _creationTimers.values) {
      t.cancel();
    }
    _creationTimers.clear();
    _lastReadingIds.clear();
    _lastAlertedHigh.clear();
    _topNotificationTimer?.cancel();
    super.dispose();
  }

  // ── Metric chip ───────────────────────────────────────────────────────────

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? badge,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.black54)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
            if (badge != null)
              Text(badge,
                  style:
                      TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ]),
    );
  }

  // ── Edit tracker dialog ───────────────────────────────────────────────────

  void _showEditTrackerDialog(
      String docId, Map<String, dynamic> tracker) {
    final nameController =
        TextEditingController(text: tracker['device_name'] ?? '');
    final rawLoc = tracker['location'];
    String curLoc = rawLoc is String ? rawLoc : '';
    String selectedLocation =
        _allowedLocations.contains(curLoc.toLowerCase())
            ? curLoc.toLowerCase()
            : _allowedLocations.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Tracker name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              items: _allowedLocations
                  .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(_capitalize(l))))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedLocation = v;
              },
              decoration: const InputDecoration(
                  labelText: 'Location'),
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
                        content:
                            Text('Name cannot be empty')));
                return;
              }
              try {
                await FirebaseFirestore.instance
                    .collection('devices')
                    .doc(docId)
                    .update({
                  'device_name': newName,
                  'location': selectedLocation,
                });
                if (currentUserId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .update({
                    'trackers.$docId.device_name': newName,
                    'trackers.$docId.location':
                        selectedLocation,
                  }).catchError((_) async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserId)
                        .set({
                      'trackers': {
                        docId: {
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
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Update failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}