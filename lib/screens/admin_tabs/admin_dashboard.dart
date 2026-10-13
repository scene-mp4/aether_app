import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';
import '/models/tracker_info.dart';
import 'package:pollutracker_app/screens/tabs/notifications_screen.dart';
import 'admin_theme.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger admin history fetch for all trackers so the chart has data.
    // Uses Future.microtask to stay outside the build phase.
    Future.microtask(() {
      if (!mounted) return;
      final store = context.read<AppDataStore>();
      for (final t in store.allTrackers) {
        if (store.historyFor(t.id) == null) {
          store.fetchHistory(t.id, days: 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final trackers = store.allTrackers;
        final readings = trackers
            .map((t) => store.allReadingFor(t.id))
            .whereType<TrackerReading>()
            .toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          endDrawer: const NotificationsScreen(), //[cite: 1, 3]
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, readings),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCardsGrid(trackers, readings),
                      const SizedBox(height: 16),
                      _buildAirQualityChartCard(store, trackers),
                      const SizedBox(height: 16),
                      _buildPollutantDistributionCard(readings),
                      const SizedBox(height: 16),
                      _buildFacilityStatusCard(trackers, readings, store),
                      const SizedBox(height: 16),
                      _buildRecentAlertsCard(trackers, readings),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, List<TrackerReading> readings) {
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
                      Text('AETHER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          )),
                      Text('Admin Portal',
                          style: TextStyle(
                            color: Color(0xFFC7D2FE),
                            fontSize: 11,
                          )),
                    ],
                  ),
                ],
              ),
              // Notification bell — badge count derived from live alerts
              Builder(
                builder: (innerContext) {
                    return GestureDetector(
                      onTap: () => Scaffold.of(innerContext).openEndDrawer(),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 26,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  // ── Stat cards grid ────────────────────────────────────────────────────────
  Widget _buildStatCardsGrid(
      List<TrackerInfo> trackers, List<TrackerReading> readings) {
    final totalTrackers = trackers.length;
    final criticalAlerts =
        readings.where((r) => r.coAlert || r.pm25Alert).length;
    final avgAqi = readings.isEmpty
        ? 0
        : (readings.map((r) => r.iaqi).reduce((a, b) => a + b) /
                readings.length)
            .round();

    final aqiLabel = _aqiLabel(avgAqi);

    // Active users — fetch count from Firestore via FutureBuilder
    return _ActiveUsersStatGrid(
      totalTrackers:  totalTrackers,
      criticalAlerts: criticalAlerts,
      avgAqi:         avgAqi,
      aqiLabel:       aqiLabel,
    );
  }

  // ── AQI line chart ─────────────────────────────────────────────────────────
  // FIX: Uses live allReadingFor readings instead of history which may not
  // have loaded yet. Shows current snapshot of all trackers as a bar-style
  // comparison rather than a time series, so it always has data to display.
  Widget _buildAirQualityChartCard(
      AppDataStore store, List<TrackerInfo> trackers) {
    final liveReadings = trackers
        .map((t) => store.allReadingFor(t.id))
        .where((r) => r != null)
        .map((r) => r!)
        .toList();

    // Try history if available for time-series view
    final historyReadings = trackers
        .map((t) => store.historyFor(t.id))
        .where((h) => h != null && h.readings.isNotEmpty)
        .expand((h) => h!.readings)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Use history if loaded, otherwise fall back to live snapshot
    final chartReadings = historyReadings.isNotEmpty
        ? historyReadings
        : liveReadings;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Air Quality Index',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              Text(
                historyReadings.isNotEmpty ? '24h history' : 'Live snapshot',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (chartReadings.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 40, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 8),
                    Text('Waiting for readings…',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                painter: _AqiChartPainter(readings: chartReadings),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _ChartLegendItem(color: Color(0xFFEAB308), label: 'PM2.5'),
              _ChartLegendItem(color: Color(0xFF3B82F6), label: 'CO₂'),
              _ChartLegendItem(color: Color(0xFFEF4444), label: 'CO'),
              _ChartLegendItem(color: Color(0xFFA855F7), label: 'O₃'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pollutant distribution pie chart ──────────────────────────────────────
  Widget _buildPollutantDistributionCard(List<TrackerReading> readings) {
    // Compute average contributions — normalise each to percentage of their sum
    double pm25 = 0, pm10 = 0, co2 = 0, co = 0, o3 = 0;
    if (readings.isNotEmpty) {
      pm25 = readings.map((r) => r.pm25Ugm3).reduce((a, b) => a + b);
      pm10 = readings.map((r) => r.pm10Ugm3).reduce((a, b) => a + b);
      // Scale CO₂ / CO / O₃ to a comparable unit (normalise by typical max)
      co2  = readings.map((r) => r.co2Ppm / 2500 * 100).reduce((a, b) => a + b);
      co   = readings.map((r) => r.coPpm  / 50   * 100).reduce((a, b) => a + b);
      o3   = readings.map((r) => r.o3Ppm  * 1000 / 100 * 100).reduce((a, b) => a + b);
    }
    final total = pm25 + pm10 + co2 + co + o3;
    final slices = total == 0
        ? [0.35, 0.28, 0.20, 0.10, 0.07] // fallback proportions
        : [pm25, pm10, co2, co, o3]
            .map((v) => v / total)
            .toList();

    final labels = [
      'PM2.5 ${(slices[0] * 100).toStringAsFixed(0)}%',
      'PM10 ${(slices[1]  * 100).toStringAsFixed(0)}%',
      'CO₂ ${(slices[2]   * 100).toStringAsFixed(0)}%',
      'CO ${(slices[3]    * 100).toStringAsFixed(0)}%',
      'O₃ ${(slices[4]    * 100).toStringAsFixed(0)}%',
    ];

    // Raw values for legend (non-normalised averages)
    final rawValues = readings.isEmpty
        ? <double>[0, 0, 0, 0, 0]
        : [
            readings.map((r) => r.pm25Ugm3).reduce((a, b) => a + b) / readings.length,
            readings.map((r) => r.pm10Ugm3).reduce((a, b) => a + b) / readings.length,
            readings.map((r) => r.co2Ppm).reduce((a, b) => a + b) / readings.length,
            readings.map((r) => r.coPpm).reduce((a, b) => a + b) / readings.length,
            readings.map((r) => r.o3Ppm * 1000).reduce((a, b) => a + b) / readings.length,
          ];
    const legendColors = [
      Color(0xFFEAB308),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFFA855F7),
    ];
    const legendNames = ['PM2.5', 'PM10', 'CO₂', 'CO', 'O₃'];
    const legendUnits = ['µg/m³', 'µg/m³', 'ppm', 'ppm', 'ppb'];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pollutant Distribution',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(
            readings.isEmpty
                ? 'No live data — showing default proportions'
                : 'Based on current readings across all trackers',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Donut chart — no labels on canvas
              SizedBox(
                height: 160,
                width: 160,
                child: CustomPaint(
                  painter: _PieChartPainter(slices: slices),
                ),
              ),
              const SizedBox(width: 20),
              // FIX: Flutter legend replaces misaligned canvas labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(legendNames.length, (i) {
                    final pct = (slices[i] * 100).toStringAsFixed(1);
                    final val = rawValues[i].toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: legendColors[i],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(legendNames[i],
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: adminPrimaryTextColor(context))),
                                  Text('$pct%',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: legendColors[i])),
                                ],
                              ),
                              Text(
                                readings.isEmpty
                                    ? '—'
                                    : '$val ${legendUnits[i]}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: adminSecondaryTextColor(context)),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Facility status ────────────────────────────────────────────────────────
  Widget _buildFacilityStatusCard(
      List<TrackerInfo> trackers,
      List<TrackerReading> readings,
      AppDataStore store) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Facility Status',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (trackers.isEmpty)
            const Text('No trackers linked.',
                style:
                    TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
          else
            ...trackers.map((t) {
              // FIX: use allReadingFor — admin reads from allLatestReadings,
              // not the per-user latestReadings map
              final r    = store.allReadingFor(t.id);
              final aqi  = r?.iaqi ?? 0;
              final data = _aqiStatusData(aqi, r == null);
              return _FacilityStatusItem(
                title:       t.deviceName,
                subtitle:    t.location.isNotEmpty ? t.location : 'No location set',
                aqi:         aqi,
                status:      data.label,
                statusColor: data.bgColor,
                textColor:   data.textColor,
              );
            }),
        ],
      ),
    );
  }

  // ── Recent alerts ──────────────────────────────────────────────────────────
  Widget _buildRecentAlertsCard(
      List<TrackerInfo> trackers, List<TrackerReading> readings) {
    // Build alert list from live data — only trackers with active alerts
    final alerts = <Map<String, dynamic>>[];
    for (int i = 0; i < trackers.length; i++) {
      final r = i < readings.length ? readings[i] : null;
      if (r == null) continue;
      if (r.coAlert) {
        alerts.add({
          'location': trackers[i].deviceName,
          'detail':
              'CO: ${r.coPpm.toStringAsFixed(1)} ppm — ventilate immediately',
          'status': 'CO Alert',
          'statusBg':   const Color(0xFFFEE2E2),
          'statusText': const Color(0xFFDC2626),
        });
      }
      if (r.pm25Alert) {
        alerts.add({
          'location': trackers[i].deviceName,
          'detail':
              'PM2.5: ${r.pm25Ugm3.toStringAsFixed(1)} µg/m³ (AQI ${r.pm25Aqi})',
          'status': 'Unhealthy',
          'statusBg':   const Color(0xFFFEF3C7),
          'statusText': const Color(0xFFB45309),
        });
      }
      if (r.lpgAlert) {
        alerts.add({
          'location': trackers[i].deviceName,
          'detail':
              'LPG/Smoke: ${r.lpgPpm.toStringAsFixed(0)} ppm — check sources',
          'status': 'Gas Alert',
          'statusBg':   const Color(0xFFFFF7ED),
          'statusText': const Color(0xFFC2410C),
        });
      }
      if (r.co2Alert) {
        alerts.add({
          'location': trackers[i].deviceName,
          'detail': 'CO₂: ${r.co2Ppm.toStringAsFixed(0)} ppm — poor ventilation',
          'status': 'Stuffy Air',
          'statusBg':   const Color(0xFFEFF6FF),
          'statusText': const Color(0xFF2563EB),
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Alerts',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(children: const [
                Icon(Icons.check_circle_outline,
                    color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 8),
                Text('No active alerts — all trackers within safe ranges.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF166534))),
              ]),
            )
          else
            ...alerts.asMap().entries.map((entry) {
              final a = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: entry.key < alerts.length - 1 ? 10 : 0),
                child: _AlertItem(
                  location:        a['location'],
                  detail:          a['detail'],
                  time:            'Just now',
                  status:          a['status'],
                  statusBgColor:   a['statusBg'],
                  statusTextColor: a['statusText'],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _aqiLabel(int aqi) {
    if (aqi <= 50)  return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy (Sensitive)';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  ({String label, Color bgColor, Color textColor}) _aqiStatusData(
      int aqi, bool noData) {
    if (noData) return (
      label: 'No data',
      bgColor: const Color(0xFFF1F5F9),
      textColor: const Color(0xFF94A3B8),
    );
    if (aqi <= 50)  return (label: 'Good',     bgColor: const Color(0xFFDCFCE7), textColor: const Color(0xFF15803D));
    if (aqi <= 100) return (label: 'Moderate', bgColor: const Color(0xFFFEF9C3), textColor: const Color(0xFF92400E));
    if (aqi <= 150) return (label: 'Sensitive',bgColor: const Color(0xFFFFEDD5), textColor: const Color(0xFFC2410C));
    if (aqi <= 200) return (label: 'Unhealthy',bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFFDC2626));
    return (label: 'Hazardous', bgColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF7C3AED));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Active Users + Stat Grid — fetches user count from Firestore
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveUsersStatGrid extends StatelessWidget {
  final int    totalTrackers;
  final int    criticalAlerts;
  final int    avgAqi;
  final String aqiLabel;

  const _ActiveUsersStatGrid({
    required this.totalTrackers,
    required this.criticalAlerts,
    required this.avgAqi,
    required this.aqiLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .get(),
      builder: (context, snap) {
        final userCount = snap.hasData ? snap.data!.docs.length : 0;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _StatCard(
              icon:        Icons.monitor_heart,
              iconBgColor: const Color(0xFF3B82F6),
              title:       'Total Trackers',
              value:       '$totalTrackers',
              subtitle:    '$totalTrackers device${totalTrackers == 1 ? '' : 's'} linked',
            ),
            _StatCard(
              icon:        Icons.people,
              iconBgColor: const Color(0xFF22C55E),
              title:       'Active Users',
              value:       '$userCount',
              subtitle:    snap.connectionState == ConnectionState.waiting
                               ? 'Loading…'
                               : '$userCount account${userCount == 1 ? '' : 's'}',
            ),
            _StatCard(
              icon:        Icons.warning_rounded,
              iconBgColor: criticalAlerts > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              title:       'Active Alerts',
              value:       '$criticalAlerts',
              subtitle:    criticalAlerts == 0
                  ? 'All trackers normal'
                  : '$criticalAlerts tracker${criticalAlerts == 1 ? '' : 's'} need attention',
            ),
            _StatCard(
              icon:        Icons.air,
              iconBgColor: const Color(0xFFEAB308),
              title:       'Average AQI',
              value:       '$avgAqi',
              subtitle:    aqiLabel,
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stat Card
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconBgColor;
  final String   title;
  final String   value;
  final String   subtitle;

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
        color: adminCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
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
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: adminSecondaryTextColor(context),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: adminPrimaryTextColor(context),
                  height: 1.0)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: adminSecondaryTextColor(context),
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}


class _ChartLegendItem extends StatelessWidget {
  final Color  color;
  final String label;
  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    ]);
  }
}

class _FacilityStatusItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int    aqi;
  final String status;
  final Color  statusColor;
  final Color  textColor;

  const _FacilityStatusItem({
    required this.title,
    required this.subtitle,
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
        color: adminSubtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                        color: adminPrimaryTextColor(context))),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10, color: adminSecondaryTextColor(context))),
            Text('AQI: $aqi',
                style: TextStyle(
                    fontSize: 10, color: adminSecondaryTextColor(context))),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String location;
  final String detail;
  final String time;
  final String status;
  final Color  statusBgColor;
  final Color  statusTextColor;

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
        color: adminIsDark(context)
            ? const Color(0xFF382D18)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(location,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: adminPrimaryTextColor(context))),
              Text(time,
                  style: TextStyle(
                      fontSize: 10, color: adminSecondaryTextColor(context))),
            ],
          ),
          const SizedBox(height: 2),
          Text(detail,
              style: TextStyle(
                  fontSize: 11, color: adminSecondaryTextColor(context))),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AQI Line Chart Painter — live data version
// Plots PM2.5, CO₂, CO, O₃ lines from actual history readings.
// Falls back to a flat line when no history is available.
// ═══════════════════════════════════════════════════════════════════════════════

class _AqiChartPainter extends CustomPainter {
  final List<TrackerReading> readings;
  const _AqiChartPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    const double padLeft   = 32.0;
    const double padBottom = 24.0;
    final double chartW = size.width  - padLeft;
    final double chartH = size.height - padBottom;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Y axis
    for (final val in [0, 150, 300, 450, 600]) {
      final y = chartH - (val / 600) * chartH;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width, y), gridPaint);
      tp.text = TextSpan(
          text: '$val',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10));
      tp.layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 6, y - 6));
    }

    // X axis labels — use actual timestamps if available
    final xLabels = readings.isEmpty
        ? ['00:00', '04:00', '08:00', '12:00', '20:00']
        : _buildXLabels(readings);
    for (int i = 0; i < xLabels.length; i++) {
      final x = padLeft + (i / (xLabels.length - 1)) * chartW;
      tp.text = TextSpan(
          text: xLabels[i],
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 16));
    }

    if (readings.isEmpty) return;

    // Subsample to at most 20 points
    final sub = _subsample(readings, 20);

    void drawLine(
        List<double> values, Color color, double maxVal) {
      if (values.isEmpty) return;
      final pts = <Offset>[];
      for (int i = 0; i < sub.length; i++) {
        final x = padLeft + (i / (sub.length - 1)) * chartW;
        final y = chartH -
            (values[i].clamp(0.0, maxVal) / maxVal) * chartH;
        pts.add(Offset(x, y));
      }
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke);
      for (final pt in pts) {
        canvas.drawCircle(pt, 3.0, Paint()..color = color);
      }
    }

    drawLine(sub.map((r) => r.pm25Ugm3).toList(),
        const Color(0xFFEAB308), 150);
    drawLine(sub.map((r) => r.co2Ppm / 4.0).toList(),
        const Color(0xFF3B82F6), 600);   // CO₂ scaled: 2400 ppm → 600
    drawLine(sub.map((r) => r.coPpm * 10).toList(),
        const Color(0xFFEF4444), 600);   // CO scaled: 60 ppm → 600
    drawLine(sub.map((r) => r.o3Ppm * 6000).toList(),
        const Color(0xFFA855F7), 600);   // O₃ ppb scaled
  }

  List<String> _buildXLabels(List<TrackerReading> r) {
    const want = 5;
    if (r.length <= want) {
      return r.map((x) =>
              '${x.timestamp.hour.toString().padLeft(2, '0')}:00')
          .toList();
    }
    final step = (r.length / (want - 1)).floor();
    final out  = <String>[];
    for (int i = 0; i < r.length; i += step) {
      out.add(
          '${r[i].timestamp.hour.toString().padLeft(2, '0')}:00');
    }
    if (out.length < want)
      out.add(
          '${r.last.timestamp.hour.toString().padLeft(2, '0')}:00');
    return out.take(want).toList();
  }

  List<TrackerReading> _subsample(List<TrackerReading> r, int max) {
    if (r.length <= max) return r;
    final step = (r.length / max).ceil();
    final out  = <TrackerReading>[];
    for (int i = 0; i < r.length; i += step) out.add(r[i]);
    return out;
  }

  @override
  bool shouldRepaint(covariant _AqiChartPainter old) =>
      old.readings.length != readings.length;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pie Chart Painter — live proportions version
// ═══════════════════════════════════════════════════════════════════════════════

class _PieChartPainter extends CustomPainter {
  final List<double> slices;

  // FIX: labels removed from painter — now rendered as a Flutter legend
  // widget alongside the chart, which positions correctly on all screen sizes.
  const _PieChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;

    const colors = [
      Color(0xFFEAB308),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFFA855F7),
    ];

    double startAngle = -pi / 2;

    for (int i = 0; i < slices.length; i++) {
      if (slices[i] <= 0) continue;
      final sweep = slices[i] * 2 * pi;
      // Slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()..color = colors[i]..style = PaintingStyle.fill,
      );
      // White gap between slices
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      startAngle += sweep;
    }

    // White donut hole
    canvas.drawCircle(
      center, radius * 0.52,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) =>
      old.slices != slices;
}