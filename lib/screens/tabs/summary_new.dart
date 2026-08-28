import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';

class SummaryNewPage extends StatefulWidget {
  const SummaryNewPage({super.key});

  @override
  State<SummaryNewPage> createState() => _SummaryNewPageState();
}

class _SummaryNewPageState extends State<SummaryNewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );

  // ── AQI Info Card toggle ──────────────────────────────────────────────────
  bool _showAqiInfo = false;

  // ── Manual expand state ───────────────────────────────────────────────────
  bool _isManualExpanded = true;
  bool _isRespiratoryExpanded = false;
  bool _isCardiovascularExpanded = false;
  bool _isNeurologicalExpanded = false;
  bool _isSystemicExpanded = false;
  bool _isDosExpanded = false;
  bool _isDontsExpanded = false;

  // ── UI expand state ───────────────────────────────────────────────────────
  final Map<String, bool> _expandedMetrics = {
    'PM1.0': false,
    'PM2.5': false,
    'PM10': false,
    'CO': false,
    'CO₂': false,
    'O₃': false,
    'Temp': false,
    'Humidity': false,
  };

  // ── Shared UI styling constants ──────────────────────────────────────────
  static final BoxDecoration _cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ── AQI helpers ───────────────────────────────────────────────────────────
  Color _aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF22C55E);
    if (aqi <= 100) return const Color(0xFFEAB308);
    if (aqi <= 150) return const Color(0xFFF97316);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFFA855F7);
    return const Color(0xFF881337);
  }

  Color _aqiBgColor(int aqi) {
    if (aqi <= 50) return const Color(0xFFDCFCE7);
    if (aqi <= 100) return const Color(0xFFFEF9C3);
    if (aqi <= 150) return const Color(0xFFFFEDD5);
    if (aqi <= 200) return const Color(0xFFFEE2E2);
    if (aqi <= 300) return const Color(0xFFF3E8FF);
    return const Color(0xFFFFE4E6);
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // ── Metric status helpers ─────────────────────────────────────────────────
  String _pm25Status(double v) {
    if (v <= 12) return 'Good';
    if (v <= 35) return 'Moderate';
    if (v <= 55) return 'Sensitive';
    if (v <= 150) return 'Unhealthy';
    return 'Hazardous';
  }

  Color _pm25StatusBg(double v) {
    if (v <= 12) return const Color(0xFFDCFCE7);
    if (v <= 35) return const Color(0xFFFEF9C3);
    if (v <= 55) return const Color(0xFFFFEDD5);
    return const Color(0xFFFEE2E2);
  }

  Color _pm25StatusText(double v) {
    if (v <= 12) return const Color(0xFF166534);
    if (v <= 35) return const Color(0xFFA16207);
    if (v <= 55) return const Color(0xFFC2410C);
    return const Color(0xFF991B1B);
  }

  String _co2Status(double v) {
    if (v <= 800) return 'Excellent';
    if (v <= 1000) return 'Good';
    if (v <= 1500) return 'Moderate';
    return 'Poor';
  }

  Color _co2StatusBg(double v) {
    if (v <= 800) return const Color(0xFFDCFCE7);
    if (v <= 1000) return const Color(0xFFDCFCE7);
    if (v <= 1500) return const Color(0xFFFEF9C3);
    return const Color(0xFFFFEDD5);
  }

  Color _co2StatusText(double v) {
    if (v <= 800) return const Color(0xFF166534);
    if (v <= 1000) return const Color(0xFF166534);
    if (v <= 1500) return const Color(0xFFA16207);
    return const Color(0xFFC2410C);
  }

  String _tempStatus(double v) {
    if (v >= 18 && v <= 30) return 'Comfortable';
    if (v > 30 && v <= 35) return 'Warm';
    if (v < 18 && v >= 10) return 'Cool';
    return 'Extreme';
  }

  Color _tempStatusBg(double v) {
    if (v >= 18 && v <= 30) return const Color(0xFFDCFCE7);
    if (v > 30 && v <= 35) return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _tempStatusText(double v) {
    if (v >= 18 && v <= 30) return const Color(0xFF166534);
    if (v > 30 && v <= 35) return const Color(0xFFA16207);
    return const Color(0xFF991B1B);
  }

  String _humStatus(double v) {
    if (v >= 30 && v <= 60) return 'Ideal';
    if (v > 60 && v <= 80) return 'Moderate';
    return 'High Risk';
  }

  Color _humStatusBg(double v) {
    if (v >= 30 && v <= 60) return const Color(0xFFDCFCE7);
    if (v > 60 && v <= 80) return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _humStatusText(double v) {
    if (v >= 30 && v <= 60) return const Color(0xFF166534);
    if (v > 60 && v <= 80) return const Color(0xFFA16207);
    return const Color(0xFF991B1B);
  }

  String _coStatus(double v) {
    if (v <= 9) return 'Normal';
    if (v <= 35) return 'Caution';
    return 'Alert';
  }

  Color _coStatusBg(double v) {
    if (v <= 9) return const Color(0xFFDCFCE7);
    if (v <= 35) return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _coStatusText(double v) {
    if (v <= 9) return const Color(0xFF166534);
    if (v <= 35) return const Color(0xFFA16207);
    return const Color(0xFF991B1B);
  }

  // ── Safe average helper ───────────────────────────────────────────────────
  double _avg(List<double> vals) {
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '--';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  DateTime? _latestTimestamp(List<TrackerReading> readings) {
    if (readings.isEmpty) return null;
    return readings
        .map((r) => r.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          backgroundColor: const Color(0xFFF8FAFC),
          body: Column(
            children: [
              _buildHeaderBanner(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildHeaderDashboardGrid(readings, trackers.length),
                            if (_showAqiInfo) ...[
                              const SizedBox(height: 12),
                              _buildAqiExplanationCard(),
                            ],
                          ],
                        ),
                      ),
                      _buildTabBar(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.75,
                        child: store.loading && readings.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildOverviewTab(readings),
                                  _buildReadingsTab(readings),
                                  _buildManualTab(),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── AQI EXPLANATION CARD ─────────────────────────────────────────────────
  Widget _buildAqiExplanationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "The Overall AQI (Air Quality Index) measures how clean or polluted the air is based on the average of all collected AQI (Air Quality Index) in each tracker.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1E40AF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildAqiLegendRow(const Color(0xFF22C55E), "0–50", "Good", const Color(0xFF166534)),
          _buildAqiLegendRow(const Color(0xFFEAB308), "51–100", "Moderate", const Color(0xFFA16207)),
          _buildAqiLegendRow(const Color(0xFFF97316), "101–150", "Unhealthy for Sensitive Groups", const Color(0xFFC2410C)),
          _buildAqiLegendRow(const Color(0xFFEF4444), "151–200", "Unhealthy", const Color(0xFF991B1B)),
          _buildAqiLegendRow(const Color(0xFFA855F7), "201–300", "Very Unhealthy", const Color(0xFF6B21A8)),
          _buildAqiLegendRow(const Color(0xFF881337), "301+", "Hazardous", const Color(0xFF881337)),
        ],
      ),
    );
  }

  Widget _buildAqiLegendRow(Color dotColor, String range, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              range,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER BANNER ──────────────────────────────────────────────────────────
// ── HEADER BANNER ──────────────────────────────────────────────────────────
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0052FF),
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Summary",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "All trackers · Overall air quality",
            style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE)),
          ),
        ],
      ),
    );
  }

  // ── HEADER DASHBOARD GRID ──────────────────────────────────────────────────
Widget _buildHeaderDashboardGrid(List<TrackerReading> readings, int totalTrackers) {
    final avgAqi = readings.isEmpty
        ? 0
        : (_avg(readings.map((r) => r.iaqi.toDouble()).toList())).round();
    final alertCount = readings.where((r) => r.coAlert == true).length;
    final aqiColor = readings.isEmpty ? const Color(0xFF94A3B8) : _aqiColor(avgAqi);
    final aqiLabel = readings.isEmpty ? '--' : _aqiLabel(avgAqi);
    final lastDt = _latestTimestamp(readings);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Overall AQI",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      lastDt != null ? 'Updated ${_timeAgo(lastDt)}' : 'Updated --',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  readings.isEmpty ? '--' : '$avgAqi',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: aqiColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: readings.isEmpty
                        ? const Color(0xFFF1F5F9)
                        : _aqiBgColor(avgAqi),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aqiLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: aqiColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // AQI Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (avgAqi / 500).clamp(0.05, 1.0),
                      child: Container(color: aqiColor),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Good", style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    Text("Hazardous", style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 12),
                // "What is AQI?" Button moved below the bar
                InkWell(
                  onTap: () => setState(() => _showAqiInfo = !_showAqiInfo),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, size: 13, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          "What is AQI?",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
Expanded(
          flex: 4,
          child: Column(
            children: [
              // TRACKERS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: _cardDecoration,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.sensors, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Trackers",
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalTrackers',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ACTIVE ALERTS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Active Alerts",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$alertCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // ── TAB BAR ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(10),
        tabs: const [
          Tab(icon: Icon(Icons.eco_outlined, size: 16), text: "Tracker Overview"),
          Tab(icon: Icon(Icons.query_stats_outlined, size: 16), text: "Pollutants"),
          Tab(icon: Icon(Icons.menu_book_outlined, size: 16), text: "Manual"),
        ],
      ),
    );
  }

  // ── TAB 1: TRACKER OVERVIEW ───────────────────────────────────────────────
  Widget _buildOverviewTab(List<TrackerReading> readings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: _buildTrackerStatusSection(readings),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration,
            child: _buildRankingsSection(readings),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerStatusSection(List<TrackerReading> readings) {
    int good = 0, moderate = 0, sensitive = 0, unhealthy = 0, veryUnhealthy = 0, hazardous = 0;

    for (final r in readings) {
      if (r.iaqi <= 50) good++;
      else if (r.iaqi <= 100) moderate++;
      else if (r.iaqi <= 150) sensitive++;
      else if (r.iaqi <= 200) unhealthy++;
      else if (r.iaqi <= 300) veryUnhealthy++;
      else hazardous++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tracker Status",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 14),
        _buildStatusRow(const Color(0xFF22C55E), "Good", "AQI 0–50", '$good'),
        _buildStatusRow(const Color(0xFFEAB308), "Moderate", "AQI 51–100", '$moderate'),
        _buildStatusRow(const Color(0xFFF97316), "Unhealthy for Sensitive Groups", "AQI 101–150", '$sensitive'),
        _buildStatusRow(const Color(0xFFEF4444), "Unhealthy", "AQI 151–200", '$unhealthy'),
        _buildStatusRow(const Color(0xFFA855F7), "Very Unhealthy", "AQI 201–300", '$veryUnhealthy'),
        _buildStatusRow(const Color(0xFF881337), "Hazardous", "AQI 301+", '$hazardous', isLast: true),
      ],
    );
  }

  Widget _buildStatusRow(Color color, String label, String range, String count, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(range, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Text(count, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildRankingsSection(List<TrackerReading> readings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Individual Tracker/s AQI Rankings",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        const Text(
          "AQI values per tracker — lower is better",
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        if (readings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No rankings available", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          )
        else
          ...readings.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final r = entry.value;
            final val = r.iaqi;
            final color = _aqiColor(val);
            final factor = (val / 500).clamp(0.05, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('T$idx', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: factor,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$val',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── TAB 2: POLLUTANT AVERAGES ─────────────────────────────────────────────
  Widget _buildReadingsTab(List<TrackerReading> readings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.sensors, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text(
                  "Average Readings (All Trackers)",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              "PM2.5 and CO₂ are the most safety-critical, shown larger.",
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            _buildPollutantGrid(readings),
          ],
        ),
      ),
    );
  }

Widget _buildPollutantGrid(List<TrackerReading> readings) {
    final pm1 = _avg(readings.map((r) => r.pm1Ugm3).toList());
    final pm25 = _avg(readings.map((r) => r.pm25Ugm3).toList());
    final pm10 = _avg(readings.map((r) => r.pm10Ugm3).toList());
    final co = _avg(readings.map((r) => r.coPpm).toList());
    final co2 = _avg(readings.map((r) => r.co2Ppm).toList());
    final o3 = _avg(readings.map((r) => r.o3Ppm * 1000).toList());
    final temp = _avg(readings.map((r) => r.temperatureC).toList());
    final hum = _avg(readings.map((r) => r.humidityPct).toList());

    final hasData = readings.isNotEmpty;
    String fmt(double v, int d) => hasData ? v.toStringAsFixed(d) : '0.0';

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPollutantCard(
                "PM2.5", fmt(pm25, 1), "µg/m³",
                hasData ? _pm25Status(pm25) : 'Good',
                hasData ? _pm25StatusBg(pm25) : const Color(0xFFDCFCE7),
                hasData ? _pm25StatusText(pm25) : const Color(0xFF166534),
                true,
                isLarge: true,
                infoText: "PM2.5 are fine dust particles that come from smoke, cooking, or outdoor pollution.\n\nSafe below 12 µg/m³ (WHO guideline).",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPollutantCard(
                "CO₂", fmt(co2, 0), "ppm",
                hasData ? _co2Status(co2) : 'Excellent',
                hasData ? _co2StatusBg(co2) : const Color(0xFFDCFCE7),
                hasData ? _co2StatusText(co2) : const Color(0xFF166534),
                true,
                isLarge: true,
                infoText: "CO₂ builds up in rooms with many people and poor air circulation.\n\nGood below 800 ppm · Stuffy above 1000 ppm.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPollutantCard(
                "PM1.0", fmt(pm1, 1), "µg/m³",
                hasData ? _pm25Status(pm1) : 'Good',
                hasData ? _pm25StatusBg(pm1) : const Color(0xFFDCFCE7),
                hasData ? _pm25StatusText(pm1) : const Color(0xFF166534),
                true,
                infoText: "PM1.0 are ultra-fine particles smaller than 1 micron that penetrate deep into airways.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPollutantCard(
                "PM10", fmt(pm10, 1), "µg/m³",
                hasData ? _pm25Status(pm10) : 'Good',
                hasData ? _pm25StatusBg(pm10) : const Color(0xFFDCFCE7),
                hasData ? _pm25StatusText(pm10) : const Color(0xFF166534),
                true,
                infoText: "PM10 includes inhalable dust, pollen, and mold particles.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPollutantCard(
                "CO", fmt(co, 1), "ppm",
                hasData ? _coStatus(co) : 'Normal',
                hasData ? _coStatusBg(co) : const Color(0xFFDCFCE7),
                hasData ? _coStatusText(co) : const Color(0xFF166534),
                true,
                infoText: "Carbon Monoxide is an odorless gas produced by incomplete combustion.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPollutantCard(
                "O₃", fmt(o3, 1), "ppb",
                hasData ? (o3 <= 70 ? 'Good' : 'Elevated') : 'Good',
                hasData ? (o3 <= 70 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3)) : const Color(0xFFDCFCE7),
                hasData ? (o3 <= 70 ? const Color(0xFF166534) : const Color(0xFFA16207)) : const Color(0xFF166534),
                false,
                infoText: "Ground-level Ozone can irritate the respiratory system, especially for sensitive groups.",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPollutantCard(
                "Temp", fmt(temp, 1), "°C",
                hasData ? _tempStatus(temp) : 'Comfortable',
                hasData ? _tempStatusBg(temp) : const Color(0xFFDCFCE7),
                hasData ? _tempStatusText(temp) : const Color(0xFF166534),
                true,
                infoText: "Indoor temperature affects overall thermal comfort and room circulation.",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPollutantCard(
                "Humidity", fmt(hum, 1), "%",
                hasData ? _humStatus(hum) : 'Ideal',
                hasData ? _humStatusBg(hum) : const Color(0xFFDCFCE7),
                hasData ? _humStatusText(hum) : const Color(0xFF166534),
                true,
                infoText: "Optimal humidity is between 30% and 60% to limit mold and dust mite growth.",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPollutantCard(
    String keyName,
    String value,
    String unit,
    String statusLabel,
    Color statusBgColor,
    Color statusTextColor,
    bool isDownTrend, {
    bool isLarge = false,
    required String infoText,
  }) {
    final isExpanded = _expandedMetrics[keyName] ?? false;

    return Container(
      padding: EdgeInsets.all(isLarge ? 14 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            keyName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isLarge ? 26 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isDownTrend ? Icons.trending_down : Icons.trending_up,
                size: 18,
                color: isDownTrend ? const Color(0xFF22C55E) : const Color(0xFFF97316),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(unit, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() {
              _expandedMetrics[keyName] = !isExpanded;
            }),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  const Text(
                    "More Info",
                    style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                infoText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1E40AF),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 3: HEALTH SUPERVISING MANUAL ───────────────────────────────────────
Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Manual Header Banner
            const Text(
              "Health Supervising Manual",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Common illnesses senior citizens may develop from indoor air pollutants, with do's and don'ts.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
            ),

            if (_isManualExpanded) ...[
              const SizedBox(height: 16),

              // SECTION A
              const Text(
                "SECTION A — RESPIRATORY ILLNESSES",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              _buildManualSectionCard(
                title: "Respiratory Illnesses",
                isExpanded: _isRespiratoryExpanded,
                onTap: () => setState(() => _isRespiratoryExpanded = !_isRespiratoryExpanded),
                children: const [
                  _ManualIllnessItem(
                    dotColor: Color(0xFFEF4444),
                    title: "Chronic Obstructive Pulmonary Disease (COPD)",
                    triggers: "PM2.5, PM10, CO, O₃",
                    symptoms: "persistent cough, shortness of breath, wheezing",
                  ),
                  _ManualIllnessItem(
                    dotColor: Color(0xFFF97316),
                    title: "Asthma",
                    triggers: "PM2.5, O₃, CO₂ (elevated)",
                    symptoms: "wheezing, chest tightness, difficulty breathing",
                  ),
                  _ManualIllnessItem(
                    dotColor: Color(0xFFEAB308),
                    title: "Pneumonia",
                    triggers: "PM2.5, poor ventilation, humidity extremes",
                    symptoms: "fever, cough with phlegm, chest pain",
                  ),
                  _ManualIllnessItem(
                    dotColor: Color(0xFF3B82F6),
                    title: "Lung Cancer (long-term exposure)",
                    triggers: "PM2.5, PM1.0, O₃",
                    symptoms: "persistent cough, blood in sputum, unexplained weight loss",
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // SECTION B
              const Text(
                "SECTION B — CARDIOVASCULAR ILLNESSES",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              _buildManualSectionCard(
                title: "Cardiovascular Illnesses",
                isExpanded: _isCardiovascularExpanded,
                onTap: () => setState(() => _isCardiovascularExpanded = !_isCardiovascularExpanded),
                children: const [
                  _ManualIllnessItem(
                    dotColor: Color(0xFFEF4444),
                    title: "Ischemic Heart Disease",
                    triggers: "PM2.5, CO, O₃",
                    symptoms: "chest pain, shortness of breath, fatigue",
                  ),
                  _ManualIllnessItem(
                    dotColor: Color(0xFFA855F7),
                    title: "Stroke",
                    triggers: "PM2.5, PM10, CO",
                    symptoms: "sudden numbness, confusion, trouble speaking or walking",
                  ),
                  _ManualIllnessItem(
                    dotColor: Color(0xFF06B6D4),
                    title: "Hypertension (worsening)",
                    triggers: "CO, PM2.5, temperature extremes",
                    symptoms: "headaches, dizziness, elevated blood pressure readings",
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // DO'S AND DON'TS
              const Text(
                "DO'S AND DON'TS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // DO'S CARD (GREEN)
              _buildDosDontsCard(
                title: "Do's — Recommended Actions",
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                headerTextColor: const Color(0xFF15803D),
                iconColor: const Color(0xFF16A34A),
                isExpanded: _isDosExpanded,
                onTap: () => setState(() => _isDosExpanded = !_isDosExpanded),
                children: const [
                  _DosDontsItem(
                    icon: Icons.check,
                    iconColor: Color(0xFF16A34A),
                    boldText: "Ventilate regularly",
                    normalText: "open windows for at least 10 minutes every hour when outdoor air quality allows",
                  ),
                  _DosDontsItem(
                    icon: Icons.check,
                    iconColor: Color(0xFF16A34A),
                    boldText: "Act on alerts immediately",
                    normalText: "when CO alert is active, open all doors and windows and move residents to fresh air",
                  ),
                  _DosDontsItem(
                    icon: Icons.check,
                    iconColor: Color(0xFF16A34A),
                    boldText: "Monitor high-risk residents first",
                    normalText: "elderly residents with existing heart or lung conditions are most affected by poor air quality",
                  ),
                  _DosDontsItem(
                    icon: Icons.check,
                    iconColor: Color(0xFF16A34A),
                    boldText: "Keep sensors unobstructed",
                    normalText: "ensure tracker units are not blocked by furniture or placed near cooking areas",
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // DON'TS CARD (RED)
              _buildDosDontsCard(
                title: "Don'ts — Actions to Avoid",
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                headerTextColor: const Color(0xFFB91C1C),
                iconColor: const Color(0xFFDC2626),
                isExpanded: _isDontsExpanded,
                onTap: () => setState(() => _isDontsExpanded = !_isDontsExpanded),
                children: const [
                  _DosDontsItem(
                    icon: Icons.close,
                    iconColor: Color(0xFFDC2626),
                    boldText: "Do not smoke indoors",
                    normalText: "smoking significantly worsens indoor air quality for all residents",
                  ),
                  _DosDontsItem(
                    icon: Icons.close,
                    iconColor: Color(0xFFDC2626),
                    boldText: "Do not burn fuels in unventilated spaces",
                    normalText: "gas stoves or heaters need proper ventilation",
                  ),
                  _DosDontsItem(
                    icon: Icons.close,
                    iconColor: Color(0xFFDC2626),
                    boldText: "Do not remain in high-pollutant areas",
                    normalText: "move to a cleaner area if readings are Polluted or worse",
                  ),
                  _DosDontsItem(
                    icon: Icons.close,
                    iconColor: Color(0xFFDC2626),
                    boldText: "Do not perform heavy physical activity when air quality is poor",
                    normalText: "exertion increases pollutant intake into the lungs",
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // FOOTER CITATION
              const Text(
                "Sources: Ndlovu et al. (2024); World Health Organization (2025); Lemos et al. (2024)",
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── SECTION CARD HELPER ──────────────────────────────────────────────────
  Widget _buildManualSectionCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF64748B),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ],
        ],
      ),
    );
  }

  // ── DO'S AND DON'TS CONTAINER HELPER ─────────────────────────────────────
  Widget _buildDosDontsCard({
    required String title,
    required Color bgColor,
    required Color borderColor,
    required Color headerTextColor,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: headerTextColor,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: iconColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ],
        ],
      ),
    );
  }
}

// ── ILLNESS ITEM TILE ───────────────────────────────────────────────────────
class _ManualIllnessItem extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String triggers;
  final String symptoms;
  final bool isLast;

  const _ManualIllnessItem({
    required this.dotColor,
    required this.title,
    required this.triggers,
    required this.symptoms,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
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
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    children: [
                      const TextSpan(
                        text: "Triggered by: ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      TextSpan(text: triggers),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    children: [
                      const TextSpan(
                        text: "Symptoms: ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
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
}

// ── DO'S AND DON'TS ITEM TILE ───────────────────────────────────────────────
class _DosDontsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String boldText;
  final String normalText;
  final bool isLast;

  const _DosDontsItem({
    required this.icon,
    required this.iconColor,
    required this.boldText,
    required this.normalText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.35),
                children: [
                  TextSpan(
                    text: "$boldText — ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  TextSpan(text: normalText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}