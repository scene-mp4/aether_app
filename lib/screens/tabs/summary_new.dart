import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';
import '/models/tracker_info.dart';

class SummaryNewPage extends StatefulWidget {
  const SummaryNewPage({super.key});

  @override
  State<SummaryNewPage> createState() => _SummaryNewPageState();
}

class _SummaryNewPageState extends State<SummaryNewPage> {
  // ── Manual expand state (kept as-is) ─────────────────────────────────────
  bool _isManualExpanded       = false;
  bool _isRespiratoryExpanded  = false;
  bool _isCardiovascularExpanded = false;
  bool _isDosExpanded          = false;
  bool _isDontsExpanded        = false;

  // ── UI expand state ───────────────────────────────────────────────────────
  bool _isAqiInfoExpanded = false;
  final Map<String, bool> _expandedMetrics = {
    'PM1.0':    false,
    'PM2.5':    false,
    'PM10':     false,
    'CO':       false,
    'CO₂':      false,
    'O₃':       false,
    'Temp':     false,
    'Humidity': false,
  };

  // ── AQI helpers ───────────────────────────────────────────────────────────
  Color _aqiColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFF16A34A);
    if (aqi <= 100) return const Color(0xFFA16207);
    if (aqi <= 150) return const Color(0xFFC2410C);
    if (aqi <= 200) return const Color(0xFFDC2626);
    if (aqi <= 300) return const Color(0xFF7C3AED);
    return const Color(0xFF881337);
  }

  Color _aqiBgColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFFDCFCE7);
    if (aqi <= 100) return const Color(0xFFFEF9C3);
    if (aqi <= 150) return const Color(0xFFFFEDD5);
    if (aqi <= 200) return const Color(0xFFFEE2E2);
    if (aqi <= 300) return const Color(0xFFF3E8FF);
    return const Color(0xFFFFE4E6);
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50)  return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // ── Metric status helpers ─────────────────────────────────────────────────
  String _pm25Status(double v) {
    if (v <= 12)  return 'Good';
    if (v <= 35)  return 'Moderate';
    if (v <= 55)  return 'Sensitive';
    if (v <= 150) return 'Unhealthy';
    return 'Hazardous';
  }

  Color _pm25StatusBg(double v) {
    if (v <= 12)  return const Color(0xFFDCFCE7);
    if (v <= 35)  return const Color(0xFFFEF9C3);
    if (v <= 55)  return const Color(0xFFFFEDD5);
    return const Color(0xFFFEE2E2);
  }

  Color _pm25StatusText(double v) {
    if (v <= 12)  return const Color(0xFF16A34A);
    if (v <= 35)  return const Color(0xFFA16207);
    if (v <= 55)  return const Color(0xFFC2410C);
    return const Color(0xFFDC2626);
  }

  String _co2Status(double v) {
    if (v <= 800)  return 'Excellent';
    if (v <= 1000) return 'Good';
    if (v <= 1500) return 'Moderate';
    return 'Poor';
  }

  Color _co2StatusBg(double v) {
    if (v <= 800)  return const Color(0xFFDCFCE7);
    if (v <= 1000) return const Color(0xFFDCFCE7);
    if (v <= 1500) return const Color(0xFFFEF9C3);
    return const Color(0xFFFFEDD5);
  }

  Color _co2StatusText(double v) {
    if (v <= 800)  return const Color(0xFF16A34A);
    if (v <= 1000) return const Color(0xFF16A34A);
    if (v <= 1500) return const Color(0xFFA16207);
    return const Color(0xFFC2410C);
  }

  String _tempStatus(double v) {
    if (v >= 18 && v <= 30) return 'Comfortable';
    if (v > 30 && v <= 35)  return 'Warm';
    if (v < 18 && v >= 10)  return 'Cool';
    return 'Extreme';
  }

  Color _tempStatusBg(double v) {
    if (v >= 18 && v <= 30) return const Color(0xFFDCFCE7);
    if (v > 30 && v <= 35)  return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _tempStatusText(double v) {
    if (v >= 18 && v <= 30) return const Color(0xFF16A34A);
    if (v > 30 && v <= 35)  return const Color(0xFFA16207);
    return const Color(0xFFDC2626);
  }

  String _humStatus(double v) {
    if (v >= 30 && v <= 60) return 'Ideal';
    if (v > 60 && v <= 80)  return 'Moderate';
    return 'High Risk';
  }

  Color _humStatusBg(double v) {
    if (v >= 30 && v <= 60) return const Color(0xFFDCFCE7);
    if (v > 60 && v <= 80)  return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _humStatusText(double v) {
    if (v >= 30 && v <= 60) return const Color(0xFF16A34A);
    if (v > 60 && v <= 80)  return const Color(0xFFA16207);
    return const Color(0xFFDC2626);
  }

  String _coStatus(double v) {
    if (v <= 9)  return 'Normal';
    if (v <= 35) return 'Caution';
    return 'Alert';
  }

  Color _coStatusBg(double v) {
    if (v <= 9)  return const Color(0xFFDCFCE7);
    if (v <= 35) return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _coStatusText(double v) {
    if (v <= 9)  return const Color(0xFF16A34A);
    if (v <= 35) return const Color(0xFFA16207);
    return const Color(0xFFDC2626);
  }

  // ── Safe average helper ───────────────────────────────────────────────────
  double _avg(List<double> vals) {
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '--';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Most recent timestamp across all trackers ──────────────────────────────
  DateTime? _latestTimestamp(List<TrackerReading> readings) {
    if (readings.isEmpty) return null;
    return readings
        .map((r) => r.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final trackers = store.trackers;
        final readings = trackers
            .map((t) => store.readingFor(t.id))
            .whereType<TrackerReading>()
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Column(
            children: [
              _buildHeaderBanner(trackers.length, readings.length),
              Expanded(
                child: store.loading && readings.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverallAqiCard(readings),
                              const SizedBox(height: 16),
                              _buildTrackerStatusCard(readings),
                              const SizedBox(height: 16),
                              _buildAverageReadingsCard(readings),
                              const SizedBox(height: 16),
                              _buildIndividualTrackersCard(store, trackers),
                              const SizedBox(height: 16),
                              _buildHealthManualCard(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 1. HEADER BANNER ───────────────────────────────────────────────────────
  Widget _buildHeaderBanner(int total, int active) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 20),
      decoration: const BoxDecoration(color: Color(0xFF0052FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tracker Summary",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            "$total tracker${total == 1 ? '' : 's'} · $active with readings · Overall Air Quality",
            style:
                const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── 2. OVERALL AQI CARD ────────────────────────────────────────────────────
  Widget _buildOverallAqiCard(List<TrackerReading> readings) {
    final avgAqi = readings.isEmpty
        ? 0
        : (_avg(readings.map((r) => r.iaqi.toDouble()).toList())).round();
    final color     = _aqiColor(avgAqi);
    final label     = _aqiLabel(avgAqi);
    final progress  = (avgAqi / 500).clamp(0.0, 1.0);
    final lastDt    = _latestTimestamp(readings);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overall AQI (Average)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              InkWell(
                onTap: () =>
                    setState(() => _isAqiInfoExpanded = !_isAqiInfoExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(children: const [
                    Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text("What is AQI?",
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ],
          ),
          if (_isAqiInfoExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "The Overall AQI (Air Quality Index) measures how clean or polluted the air is based on the average of all collected AQI in each tracker.",
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                        height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  _buildAqiLegendRow(
                      const Color(0xFF22C55E), "0–50", "Good"),
                  _buildAqiLegendRow(
                      const Color(0xFFEAB308), "51–100", "Moderate"),
                  _buildAqiLegendRow(const Color(0xFFEA580C), "101–150",
                      "Unhealthy for Sensitive Groups"),
                  _buildAqiLegendRow(
                      const Color(0xFFEF4444), "151–200", "Unhealthy"),
                  _buildAqiLegendRow(const Color(0xFFA855F7), "201–300",
                      "Very Unhealthy"),
                  _buildAqiLegendRow(
                      const Color(0xFF881337), "301+", "Hazardous"),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                readings.isEmpty ? '--' : '$avgAqi',
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _aqiBgColor(avgAqi),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(children: [
            Container(
              width: 180,
              height: 8,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4)),
            ),
            Container(
              width: 180 * progress,
              height: 8,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lastDt != null ? 'Updated ${_timeAgo(lastDt)}' : '--',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              Row(children: const [
                Text("Good",
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8))),
                SizedBox(width: 100),
                Text("Hazardous",
                    style: TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8))),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAqiLegendRow(Color color, String range, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text("$range  ",
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF1E40AF))),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );
  }

  // ── 3. TRACKER STATUS CARD ────────────────────────────────────────────────
  Widget _buildTrackerStatusCard(List<TrackerReading> readings) {
    // Count trackers in each AQI bucket
    int good = 0, moderate = 0, sensitive = 0,
        unhealthy = 0, veryUnhealthy = 0, hazardous = 0;

    for (final r in readings) {
      if (r.iaqi <= 50)       good++;
      else if (r.iaqi <= 100) moderate++;
      else if (r.iaqi <= 150) sensitive++;
      else if (r.iaqi <= 200) unhealthy++;
      else if (r.iaqi <= 300) veryUnhealthy++;
      else                    hazardous++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tracker Status",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text("How many trackers are in each range right now",
              style:
                  TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          _buildStatusRow(const Color(0xFF22C55E), "Good",
              "AQI 0–50", '$good'),
          _buildStatusRow(const Color(0xFFEAB308), "Moderate",
              "AQI 51–100", '$moderate'),
          _buildStatusRow(const Color(0xFFF97316),
              "Unhealthy for Sensitive Groups",
              "AQI 101–150", '$sensitive'),
          _buildStatusRow(const Color(0xFFEF4444), "Unhealthy",
              "AQI 151–200", '$unhealthy'),
          _buildStatusRow(const Color(0xFFA855F7), "Very Unhealthy",
              "AQI 201–300", '$veryUnhealthy'),
          _buildStatusRow(const Color(0xFF881337), "Hazardous",
              "AQI 301+", '$hazardous',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      Color color, String label, String range, String count,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Text(range,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        Text(count,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ]),
    );
  }

  // ── 4. AVERAGE READINGS CARD ──────────────────────────────────────────────
  Widget _buildAverageReadingsCard(List<TrackerReading> readings) {
    // Compute averages — fall back to 0 when no readings
    final pm1  = _avg(readings.map((r) => r.pm1Ugm3).toList());
    final pm25 = _avg(readings.map((r) => r.pm25Ugm3).toList());
    final pm10 = _avg(readings.map((r) => r.pm10Ugm3).toList());
    final co   = _avg(readings.map((r) => r.coPpm).toList());
    final co2  = _avg(readings.map((r) => r.co2Ppm).toList());
    // o3Ppm is in ppm — display as ppb
    final o3   = _avg(readings.map((r) => r.o3Ppm * 1000).toList());
    final temp = _avg(readings.map((r) => r.temperatureC).toList());
    final hum  = _avg(readings.map((r) => r.humidityPct).toList());

    final hasData = readings.isNotEmpty;
    String fmt(double v, int d) =>
        hasData ? v.toStringAsFixed(d) : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Average Readings (All Trackers)",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _gridRow([
            _buildGridTile(
              "PM1.0", fmt(pm1, 1), "µg/m³",
              hasData ? _pm25Status(pm1)     : '--',
              hasData ? _pm25StatusBg(pm1)   : const Color(0xFFF1F5F9),
              hasData ? _pm25StatusText(pm1) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "PM1.0 are extremely tiny particles — smaller than 1/70th "
                  "of a human hair. They float in the air and can be inhaled "
                  "deep into the lungs.\n\nSafe below 10 µg/m³",
            ),
            _buildGridTile(
              "PM2.5", fmt(pm25, 1), "µg/m³",
              hasData ? _pm25Status(pm25)     : '--',
              hasData ? _pm25StatusBg(pm25)   : const Color(0xFFF1F5F9),
              hasData ? _pm25StatusText(pm25) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "PM2.5 are fine dust particles — about 30 times smaller "
                  "than a grain of sand. They come from smoke, cooking, or "
                  "outdoor pollution entering the building.\n\nSafe below "
                  "12 µg/m³ (WHO guideline)",
            ),
          ]),
          const SizedBox(height: 10),
          _gridRow([
            _buildGridTile(
              "PM10", fmt(pm10, 1), "µg/m³",
              hasData ? _pm25Status(pm10)     : '--',
              hasData ? _pm25StatusBg(pm10)   : const Color(0xFFF1F5F9),
              hasData ? _pm25StatusText(pm10) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "PM10 are larger dust particles you can sometimes see "
                  "floating in a beam of light. They come from dust, pollen, "
                  "and dirt tracked indoors.\n\nSafe below 54 µg/m³",
            ),
            _buildGridTile(
              "CO", fmt(co, 1), "ppm",
              hasData ? _coStatus(co)     : '--',
              hasData ? _coStatusBg(co)   : const Color(0xFFF1F5F9),
              hasData ? _coStatusText(co) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "CO (Carbon Monoxide) is a colorless, odorless gas produced "
                  "when fuel is burned incompletely — from gas stoves, heaters, "
                  "or car exhaust nearby. High levels are very dangerous.\n\n"
                  "Safe below 9 ppm",
            ),
          ]),
          const SizedBox(height: 10),
          _gridRow([
            _buildGridTile(
              "CO₂", fmt(co2, 0), "ppm",
              hasData ? _co2Status(co2)     : '--',
              hasData ? _co2StatusBg(co2)   : const Color(0xFFF1F5F9),
              hasData ? _co2StatusText(co2) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "CO₂ (Carbon Dioxide) is the gas people exhale when "
                  "breathing. It builds up in rooms with many people and poor "
                  "air circulation, causing stuffiness and tiredness.\n\n"
                  "Good below 800 ppm · Stuffy above 1000 ppm",
            ),
            _buildGridTile(
              "O₃", fmt(o3, 1), "ppb",
              hasData ? (o3 <= 70 ? 'Good' : 'Elevated') : '--',
              hasData
                  ? (o3 <= 70
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF9C3))
                  : const Color(0xFFF1F5F9),
              hasData
                  ? (o3 <= 70
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFA16207))
                  : const Color(0xFF94A3B8),
              isDownTrend: false,
              infoText:
                  "O₃ (Ozone) at ground level is an irritant. It can irritate "
                  "the throat and lungs, especially for residents with asthma "
                  "or other breathing conditions.\n\nSafe below 70 ppb",
            ),
          ]),
          const SizedBox(height: 10),
          _gridRow([
            _buildGridTile(
              "Temp", fmt(temp, 1), "°C",
              hasData ? _tempStatus(temp)     : '--',
              hasData ? _tempStatusBg(temp)   : const Color(0xFFF1F5F9),
              hasData ? _tempStatusText(temp) : const Color(0xFF94A3B8),
              isDownTrend: true,
              infoText:
                  "This is the air temperature inside the monitored room. "
                  "Elderly and ill residents are more sensitive to heat and "
                  "cold than healthy adults.\n\nComfortable range: 18–30°C",
            ),
            _buildGridTile(
              "Humidity", fmt(hum, 0), "%",
              hasData ? _humStatus(hum)     : '--',
              hasData ? _humStatusBg(hum)   : const Color(0xFFF1F5F9),
              hasData ? _humStatusText(hum) : const Color(0xFF94A3B8),
              isDownTrend: false,
              infoText:
                  "Humidity measures how much moisture is in the air. Too "
                  "much causes stuffiness and mold; too little causes dry "
                  "skin and irritated airways.\n\nComfortable range: 30–60%",
            ),
          ]),
        ],
      ),
    );
  }

  Widget _gridRow(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );

  Widget _buildGridTile(
    String label,
    String value,
    String unit,
    String status,
    Color statusBgColor,
    Color statusTextColor, {
    required bool isDownTrend,
    required String infoText,
  }) {
    final isExpanded = _expandedMetrics[label] ?? false;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Row(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(width: 4),
            Icon(
              isDownTrend
                  ? Icons.trending_down
                  : Icons.trending_up,
              size: 16,
              color: isDownTrend
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEA580C),
            ),
          ]),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(unit,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(
                () => _expandedMetrics[label] = !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline,
                      size: 12, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  const Text("More Info",
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500)),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 12,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(infoText,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E40AF),
                      height: 1.35)),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. INDIVIDUAL TRACKERS CARD ───────────────────────────────────────────
  Widget _buildIndividualTrackersCard(
      AppDataStore store, List<TrackerInfo> trackers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Individual Trackers",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          if (trackers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No trackers linked yet.',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trackers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final info    = trackers[index];
                final reading = store.readingFor(info.id);
                return _buildTrackerItem(info, reading);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrackerItem(TrackerInfo info, TrackerReading? r) {
    final iaqi     = r?.iaqi     ?? 0;
    final color    = _aqiColor(iaqi);
    final bgColor  = _aqiBgColor(iaqi);
    final label    = _aqiLabel(iaqi);
    final hasData  = r != null;

    String fmt(double v, int d, String suffix) =>
        hasData ? '${v.toStringAsFixed(d)}$suffix' : '--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(info.deviceName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Text(
                info.location.isNotEmpty
                    ? info.location
                    : 'No location set',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                hasData ? '$iaqi' : '--',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _buildMiniTile(
                  "PM2.5",
                  fmt(r?.pm25Ugm3 ?? 0, 1, ''))),
          const SizedBox(width: 6),
          Expanded(
              child: _buildMiniTile(
                  "CO₂",
                  fmt(r?.co2Ppm ?? 0, 0, ''))),
          const SizedBox(width: 6),
          Expanded(
              child: _buildMiniTile(
                  "Temp",
                  fmt(r?.temperatureC ?? 0, 1, '°'))),
          const SizedBox(width: 6),
          Expanded(
              child: _buildMiniTile(
                  "Humid",
                  fmt(r?.humidityPct ?? 0, 0, '%'))),
        ]),

        // CO alert badge if active
        if (r?.coAlert == true) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(children: const [
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text('CO Alert — ventilate immediately',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626))),
            ]),
          ),
        ],

        // Last updated
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            r != null ? 'Updated ${_timeAgo(r.timestamp)}' : 'No readings yet',
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ),
      ]),
    );
  }

  Widget _buildMiniTile(String label, String val) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
      ]),
    );
  }

  // ── 6. HEALTH MANUAL CARD ──────────────────────
  Widget _buildHealthManualCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Health Supervising Manual",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isManualExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(
                    () => _isManualExpanded = !_isManualExpanded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Common illnesses senior citizens may develop from indoor air "
            "pollutants, with do's and don'ts.",
            style: TextStyle(
                fontSize: 12, color: Color(0xFF64748B), height: 1.3),
          ),
          if (_isManualExpanded) ...[
            const SizedBox(height: 16),
            _buildSectionHeader("SECTION A — RESPIRATORY ILLNESSES"),
            const SizedBox(height: 8),
            _buildDropdownContainer(
              title: "Respiratory Illnesses",
              isExpanded: _isRespiratoryExpanded,
              onTap: () => setState(() =>
                  _isRespiratoryExpanded = !_isRespiratoryExpanded),
              content: Column(children: [
                _buildDiseaseItem(
                  dotColor: const Color(0xFFEF4444),
                  name: "Chronic Obstructive Pulmonary Disease (COPD)",
                  triggeredBy: "PM2.5, PM10, CO, O₃",
                  symptoms:
                      "persistent cough, shortness of breath, wheezing",
                ),
                _buildDiseaseItem(
                  dotColor: const Color(0xFFF97316),
                  name: "Asthma",
                  triggeredBy: "PM2.5, O₃, CO₂ (elevated)",
                  symptoms:
                      "wheezing, chest tightness, difficulty breathing",
                ),
                _buildDiseaseItem(
                  dotColor: const Color(0xFFEAB308),
                  name: "Pneumonia",
                  triggeredBy: "PM2.5, poor ventilation, humidity extremes",
                  symptoms: "fever, cough with phlegm, chest pain",
                ),
                _buildDiseaseItem(
                  dotColor: const Color(0xFF3B82F6),
                  name: "Lung Cancer (long-term exposure)",
                  triggeredBy: "PM2.5, PM1.0, O₃",
                  symptoms:
                      "persistent cough, blood in sputum, unexplained weight loss",
                  isLast: true,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _buildSectionHeader("SECTION B — CARDIOVASCULAR ILLNESSES"),
            const SizedBox(height: 8),
            _buildDropdownContainer(
              title: "Cardiovascular Illnesses",
              isExpanded: _isCardiovascularExpanded,
              onTap: () => setState(() =>
                  _isCardiovascularExpanded = !_isCardiovascularExpanded),
              content: Column(children: [
                _buildDiseaseItem(
                  dotColor: const Color(0xFFEF4444),
                  name: "Ischemic Heart Disease",
                  triggeredBy: "PM2.5, CO, O₃",
                  symptoms:
                      "chest pain, shortness of breath, fatigue",
                ),
                _buildDiseaseItem(
                  dotColor: const Color(0xFF9333EA),
                  name: "Stroke",
                  triggeredBy: "PM2.5, PM10, CO",
                  symptoms:
                      "sudden numbness, confusion, trouble speaking or walking",
                ),
                _buildDiseaseItem(
                  dotColor: const Color(0xFF06B6D4),
                  name: "Hypertension (worsening)",
                  triggeredBy: "CO, PM2.5, temperature extremes",
                  symptoms:
                      "headaches, dizziness, elevated blood pressure readings",
                  isLast: true,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader("DO'S AND DON'TS"),
            const SizedBox(height: 8),
            _buildDropdownContainer(
              title: "Do's — Recommended Actions",
              isExpanded: _isDosExpanded,
              onTap: () =>
                  setState(() => _isDosExpanded = !_isDosExpanded),
              titleColor: const Color(0xFF166534),
              headerBgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              arrowColor: const Color(0xFF16A34A),
              content: Column(children: [
                _buildDoDontItem(
                  icon: Icons.check,
                  iconColor: const Color(0xFF22C55E),
                  title: "Ventilate regularly",
                  description:
                      "open windows for at least 10 minutes every hour when outdoor air quality allows",
                ),
                _buildDoDontItem(
                  icon: Icons.check,
                  iconColor: const Color(0xFF22C55E),
                  title: "Act on alerts immediately",
                  description:
                      "when CO alert is active, open all doors and windows and move residents to fresh air",
                ),
                _buildDoDontItem(
                  icon: Icons.check,
                  iconColor: const Color(0xFF22C55E),
                  title: "Monitor high-risk residents first",
                  description:
                      "elderly residents with existing heart or lung conditions are most affected by poor air quality",
                ),
                _buildDoDontItem(
                  icon: Icons.check,
                  iconColor: const Color(0xFF22C55E),
                  title: "Keep sensors unobstructed",
                  description:
                      "ensure tracker units are not blocked by furniture or placed near cooking areas",
                  isLast: true,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _buildDropdownContainer(
              title: "Don'ts — Actions to Avoid",
              isExpanded: _isDontsExpanded,
              onTap: () => setState(
                  () => _isDontsExpanded = !_isDontsExpanded),
              titleColor: const Color(0xFF991B1B),
              headerBgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              arrowColor: const Color(0xFFEF4444),
              content: Column(children: [
                _buildDoDontItem(
                  icon: Icons.close,
                  iconColor: const Color(0xFFEF4444),
                  title: "Do not smoke indoors",
                  description:
                      "smoking significantly worsens indoor air quality for all residents",
                ),
                _buildDoDontItem(
                  icon: Icons.close,
                  iconColor: const Color(0xFFEF4444),
                  title: "Do not burn fuels in unventilated spaces",
                  description:
                      "gas stoves or heaters need proper ventilation",
                ),
                _buildDoDontItem(
                  icon: Icons.close,
                  iconColor: const Color(0xFFEF4444),
                  title: "Do not remain in high-pollutant areas",
                  description:
                      "move to a cleaner area if readings are Polluted or worse",
                ),
                _buildDoDontItem(
                  icon: Icons.close,
                  iconColor: const Color(0xFFEF4444),
                  title:
                      "Do not perform heavy physical activity when air quality is poor",
                  description:
                      "exertion increases pollutant intake into the lungs",
                  isLast: true,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const Text(
              "Sources: Ndlovu et al. (2024); World Health Organization (2025); Lemos et al. (2024)",
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5));
  }

  Widget _buildDropdownContainer({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    Color titleColor       = const Color(0xFF1E293B),
    Color headerBgColor    = const Color(0xFFF8FAFC),
    Color borderColor      = const Color(0xFFE2E8F0),
    Color arrowColor       = const Color(0xFF64748B),
  }) {
    return Container(
      decoration: BoxDecoration(
          color: headerBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor)),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: arrowColor,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: content,
          ),
      ]),
    );
  }

  Widget _buildDiseaseItem({
    required Color dotColor,
    required String name,
    required String triggeredBy,
    required String symptoms,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                    children: [
                      const TextSpan(
                          text: "Triggered by: ",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569))),
                      TextSpan(text: triggeredBy),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                    children: [
                      const TextSpan(
                          text: "Symptoms: ",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569))),
                      TextSpan(text: symptoms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoDontItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35),
                children: [
                  TextSpan(
                      text: "$title — ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}