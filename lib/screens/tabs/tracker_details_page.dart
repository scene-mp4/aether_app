import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/app_data_store.dart';
import '../../models/tracker_reading.dart';
import 'tracker_history_tab.dart';
import 'tracker_climate_tab.dart';
import 'tracker_advice_tab.dart';

class TrackerDetailsPage extends StatefulWidget {
  final String deviceId;
  final String trackerName;
  final String location;

  const TrackerDetailsPage({
    super.key,
    required this.deviceId,
    required this.trackerName,
    required this.location,
  });

  @override
  State<TrackerDetailsPage> createState() => _TrackerDetailsPageState();
}

class _TrackerDetailsPageState extends State<TrackerDetailsPage> {
  int  _selectedTabIndex      = 0;
  int  _bottomNavIndex        = 0;
  bool _isAqiReferenceExpanded = false;

  final List<String> _tabs = ['Pollutants', 'History', 'Climate', 'Advice'];

  final List<Color> _scaleColors = const [
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
  ];

  // ── AQI helpers ─────────────────────────────────────────────────────────────
  Color _aqiColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFF22C55E);
    if (aqi <= 100) return const Color(0xFFEAB308);
    if (aqi <= 150) return const Color(0xFFF97316);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFF9333EA);
    return const Color(0xFF7F1D1D);
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50)  return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy (Sensitive)';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _safeBreathe(int aqi) {
    if (aqi <= 50)  return 'Safe to Breathe';
    if (aqi <= 100) return 'Acceptable';
    if (aqi <= 150) return 'Sensitive Groups';
    if (aqi <= 200) return 'Limit Exposure';
    if (aqi <= 300) return 'Avoid Exposure';
    return 'Evacuate';
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'No readings yet';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  // ── Pollutant card data built from live reading ───────────────────────────
  List<Map<String, dynamic>> _buildPollutantData(TrackerReading? r) {
    String fmt(double v, int decimals) =>
        r == null ? '--' : v.toStringAsFixed(decimals);

    int _pmIndex(double v, List<double> breaks) {
      for (int i = 0; i < breaks.length; i++) {
        if (v <= breaks[i]) return i;
      }
      return breaks.length;
    }

    String _pmStatus(int idx) {
      const labels = ['Good', 'Moderate', 'Polluted', 'Very Polluted', 'Severely Polluted'];
      return idx < labels.length ? labels[idx] : 'Severely Polluted';
    }

    Color _pmColor(int idx) {
      const colors = [
        Color(0xFF22C55E), Color(0xFFEAB308), Color(0xFFF97316),
        Color(0xFFEF4444), Color(0xFF7F1D1D),
      ];
      return idx < colors.length ? colors[idx] : colors.last;
    }

    final pm1Idx  = r == null ? 0 : _pmIndex(r.pm1Ugm3,  [14, 34, 61, 95]);
    final pm25Idx = r == null ? 0 : _pmIndex(r.pm25Ugm3, [20, 50, 90, 140]);
    final pm10Idx = r == null ? 0 : _pmIndex(r.pm10Ugm3, [30, 75, 125, 200]);
    final coIdx   = r == null ? 0 : _pmIndex(r.coPpm,    [1.7, 8.7, 10, 15]);
    final co2Idx  = r == null ? 0 : _pmIndex(r.co2Ppm,   [599, 999, 1499, 2499]);
    final o3Idx   = r == null ? 0 : _pmIndex(r.o3Ppm * 1000, [50, 100, 150, 200]);

    return [
      {
        "id": "PM1.0",
        "name": "PM1.0",
        "value": fmt(r?.pm1Ugm3 ?? 0, 1),
        "unit": "µg/m³",
        "status": _pmStatus(pm1Idx),
        "statusColor": _pmColor(pm1Idx),
        "currentRangeIndex": pm1Idx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Ultra-fine particles smaller than 1 micrometer. They penetrate deep into the lungs and may enter the bloodstream.",
        "goodHeadline": "Good below 14 µg/m³ (Shittu et al., 2025)",
        "thresholds": [
          {"label": "Good",              "range": "0–14 µg/m³",   "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "15–34 µg/m³",  "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "35–61 µg/m³",  "color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "62–95 µg/m³",  "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "96+ µg/m³",    "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "PM2.5",
        "name": "PM2.5",
        "value": fmt(r?.pm25Ugm3 ?? 0, 1),
        "unit": "µg/m³",
        "status": _pmStatus(pm25Idx),
        "statusColor": _pmColor(pm25Idx),
        "currentRangeIndex": pm25Idx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Fine particles smaller than 2.5 micrometers. Linked to respiratory and cardiovascular diseases, especially in older adults.",
        "goodHeadline": "Good below 20 µg/m³ (Shittu et al., 2025)",
        "thresholds": [
          {"label": "Good",              "range": "0–20 µg/m³",   "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "21–50 µg/m³",  "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "51–90 µg/m³",  "color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "91–140 µg/m³", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "141+ µg/m³",   "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "PM10",
        "name": "PM10",
        "value": fmt(r?.pm10Ugm3 ?? 0, 1),
        "unit": "µg/m³",
        "status": _pmStatus(pm10Idx),
        "statusColor": _pmColor(pm10Idx),
        "currentRangeIndex": pm10Idx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Coarser particles smaller than 10 micrometers. They irritate the nose, throat, and airways when inhaled.",
        "goodHeadline": "Good below 30 µg/m³ (Shittu et al., 2025)",
        "thresholds": [
          {"label": "Good",              "range": "0–30 µg/m³",    "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "31–75 µg/m³",   "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "76–125 µg/m³",  "color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "126–200 µg/m³", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "201+ µg/m³",    "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "CO",
        "name": "CO",
        "value": fmt(r?.coPpm ?? 0, 1),
        "unit": "ppm",
        "status": _pmStatus(coIdx),
        "statusColor": _pmColor(coIdx),
        "currentRangeIndex": coIdx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Carbon monoxide — a colorless, odorless gas produced by incomplete combustion. High levels are life-threatening.",
        "goodHeadline": "Good below 1.7 ppm (Rosca et al., 2026)",
        "thresholds": [
          {"label": "Good",              "range": "0–1.7 ppm",    "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "1.8–8.7 ppm",  "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "8.8–10 ppm",   "color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "10.1–15 ppm",  "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "15.1+ ppm",    "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "CO2",
        "name": "CO₂",
        "value": fmt(r?.co2Ppm ?? 0, 0),
        "unit": "ppm",
        "status": _pmStatus(co2Idx),
        "statusColor": _pmColor(co2Idx),
        "currentRangeIndex": co2Idx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Carbon dioxide from breathing. Builds up in rooms with many people and poor ventilation, causing drowsiness.",
        "goodHeadline": "Good below 600 ppm (Rosca et al., 2026)",
        "footnote": "CO₂ is not part of the EPA AQI.",
        "thresholds": [
          {"label": "Good",              "range": "0–599 ppm",    "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "600–999 ppm",  "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "1000–1499 ppm","color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "1500–2499 ppm","color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "2500+ ppm",    "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "O3",
        "name": "O₃",
        // o3_ppm from Cloud Function → convert to ppb for display
        "value": r == null ? '--' : (r.o3Ppm * 1000).toStringAsFixed(1),
        "unit": "ppb",
        "status": _pmStatus(o3Idx),
        "statusColor": _pmColor(o3Idx),
        "currentRangeIndex": o3Idx,
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description": "Ground-level ozone formed by chemical reactions between oxides of nitrogen and volatile organic compounds.",
        "goodHeadline": "Good below 50 ppb (Rosca et al., 2026)",
        "thresholds": [
          {"label": "Good",              "range": "0–50 ppb",   "color": const Color(0xFF22C55E)},
          {"label": "Moderate",          "range": "51–100 ppb", "color": const Color(0xFFEAB308)},
          {"label": "Polluted",          "range": "101–150 ppb","color": const Color(0xFFF97316)},
          {"label": "Very Polluted",     "range": "151–200 ppb","color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "201+ ppb",   "color": const Color(0xFF7F1D1D)},
        ],
      },
    ];
  }

  late List<Map<String, dynamic>> _pollutantData;

  @override
  void initState() {
    super.initState();
    // Initial build with whatever the store already has
    final store = context.read<AppDataStore>();
    _pollutantData = _buildPollutantData(store.readingFor(widget.deviceId));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final reading = store.readingFor(widget.deviceId);

        // Rebuild pollutant data whenever the reading changes,
        // but preserve the infoExpanded / thresholdExpanded toggle state.
        final newData = _buildPollutantData(reading);
        for (int i = 0; i < _pollutantData.length && i < newData.length; i++) {
          newData[i]['infoExpanded']      = _pollutantData[i]['infoExpanded'];
          newData[i]['thresholdExpanded'] = _pollutantData[i]['thresholdExpanded'];
        }
        _pollutantData = newData;

        final iaqi      = reading?.iaqi      ?? 0;
        final aqiColor  = _aqiColor(iaqi);
        final aqiLabel  = _aqiLabel(iaqi);
        final safeLabel = _safeBreathe(iaqi);
        final updatedAt = _timeAgo(reading?.timestamp);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          floatingActionButton: const AiAssistant(),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopHeader(
                  context,
                  iaqi:       iaqi,
                  aqiColor:   aqiColor,
                  aqiLabel:   aqiLabel,
                  safeLabel:  safeLabel,
                  updatedAt:  updatedAt,
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  selectedTabIndex: _selectedTabIndex,
                  child: _buildTabBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 12, bottom: 24),
                  child: _selectedTabIndex == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAqiReferenceCard(),
                            const SizedBox(height: 12),
                            _buildCurrentAqiPositionCard(
                                iaqi, aqiColor, aqiLabel),
                            const SizedBox(height: 16),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.4),
                                children: [
                                  TextSpan(text: "Tap "),
                                  TextSpan(
                                    text: "More Info ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0052FF)),
                                  ),
                                  TextSpan(
                                      text:
                                          "on each card to see what the pollutant means and its full threshold scale."),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Pollutant thresholds are based on Shittu et al. (2025) and Rosca et al. (2026) indoor air quality classifications.",
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            _buildPollutantGrid(),
                            const SizedBox(height: 24),
                          ],
                        )
                      : _selectedTabIndex == 1
                          ? TrackerHistoryTab(deviceId: widget.deviceId)
                          : _selectedTabIndex == 2
                              ? TrackerClimateTab(deviceId: widget.deviceId)
                              : TrackerAdviceTab(
                                  deviceId: widget.deviceId,
                                  reading:  reading,
                                ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _bottomNavIndex,
            selectedItemColor: const Color(0xFF0052FF),
            unselectedItemColor: const Color(0xFF64748B),
            type: BottomNavigationBarType.fixed,
            onTap: (i) => setState(() => _bottomNavIndex = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes), label: "Trackers"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined), label: "Summary"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.stacked_line_chart_rounded),
                  label: "Analytics"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: "Settings"),
            ],
          ),
        );
      },
    );
  }

  // ── Top header ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(
    BuildContext context, {
    required int    iaqi,
    required Color  aqiColor,
    required String aqiLabel,
    required String safeLabel,
    required String updatedAt,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 16),
      color: const Color(0xFF0052FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.trackerName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(widget.location,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70)),
            ]),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Air Quality Index (AQI)",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$iaqi',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 8),
                      Text('— $aqiLabel',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: aqiColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(safeLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Text(updatedAt,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = index),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEFF6FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0052FF)
                      : const Color(0xFF64748B),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── AQI position card ──────────────────────────────────────────────────────
  Widget _buildCurrentAqiPositionCard(
      int iaqi, Color aqiColor, String aqiLabel) {
    // Which segment is highlighted (0–5)
    int highlightIndex;
    if (iaqi <= 50)       highlightIndex = 0;
    else if (iaqi <= 100) highlightIndex = 1;
    else if (iaqi <= 150) highlightIndex = 2;
    else if (iaqi <= 200) highlightIndex = 3;
    else if (iaqi <= 300) highlightIndex = 4;
    else                  highlightIndex = 5;

    final List<Color> segmentColors = const [
      Color(0xFF4ADE80),
      Color(0xFFFEF08A),
      Color(0xFFFED7AA),
      Color(0xFFFECDD3),
      Color(0xFFF3E8FF),
      Color(0xFFE2E8F0),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.trackerName} — Current AQI position",
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: List.generate(segmentColors.length, (index) =>
                  Expanded(
                    child: Container(
                      height: 12,
                      margin: EdgeInsets.only(
                          right: index < segmentColors.length - 1 ? 2.0 : 0.0),
                      color: segmentColors[index],
                    ),
                  )),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(segmentColors.length, (index) =>
                Expanded(
                  child: Center(
                    child: index == highlightIndex
                        ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: aqiColor, shape: BoxShape.circle),
                          )
                        : const SizedBox(height: 7),
                  ),
                )),
          ),
          const SizedBox(height: 4),
          Text(
            "AQI $iaqi — $aqiLabel",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: aqiColor),
          ),
        ],
      ),
    );
  }

  // ── AQI reference card (unchanged from original) ──────────────────────────
  Widget _buildAqiReferenceCard() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(
              () => _isAqiReferenceExpanded = !_isAqiReferenceExpanded),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.info_outline,
                    size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "AQI Category Reference (US EPA 2024)",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155)),
                  ),
                ),
                Icon(
                  _isAqiReferenceExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF64748B),
                ),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Row(
                  children: _scaleColors.map((c) => Expanded(
                        child: Container(height: 6, color: c),
                      )).toList(),
                ),
              ),
            ]),
          ),
        ),
        if (_isAqiReferenceExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Column(children: [
              const SizedBox(height: 4),
              _aqiCategoryItem("Good", "AQI 0–50",
                  "Little to no health risk.",
                  const Color(0xFF4CAF50), const Color(0xFFF0FDF4),
                  const Color(0xFFBBF7D0), const Color(0xFFDCFCE7), const Color(0xFF166534)),
              _aqiCategoryItem("Moderate", "AQI 51–100",
                  "Generally acceptable, but may concern unusually sensitive individuals.",
                  const Color(0xFFD97706), const Color(0xFFFEFCE8),
                  const Color(0xFFFEF08A), const Color(0xFFFEF08A), const Color(0xFF854D0E)),
              _aqiCategoryItem("Unhealthy for Sensitive Groups", "AQI 101–150",
                  "Older adults, children, and people with respiratory or heart conditions may be affected.",
                  const Color(0xFFEA580C), const Color(0xFFFFF7ED),
                  const Color(0xFFFFEDD5), const Color(0xFFFFEDD5), const Color(0xFF9A3412)),
              _aqiCategoryItem("Unhealthy", "AQI 151–200",
                  "General public may begin to experience health effects.",
                  const Color(0xFFDC2626), const Color(0xFFFEF2F2),
                  const Color(0xFFFECACA), const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
              _aqiCategoryItem("Very Unhealthy", "AQI 201–300",
                  "Health warnings of emergency conditions.",
                  const Color(0xFF9333EA), const Color(0xFFFAF5FF),
                  const Color(0xFFE9D5FF), const Color(0xFFF3E8FF), const Color(0xFF6B21A8)),
              _aqiCategoryItem("Hazardous", "AQI 301+",
                  "Emergency conditions. Entire population likely seriously affected.",
                  const Color(0xFF7F1D1D), const Color(0xFFFEF2F2),
                  const Color(0xFFFECACA), const Color(0xFF7F1D1D), Colors.white),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Source: United States Environmental Protection Agency (2024)",
                  style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8)),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _aqiCategoryItem(
      String title, String range, String desc,
      Color dot, Color bg, Color border, Color badgeBg, Color badgeText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: dot)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: badgeBg, borderRadius: BorderRadius.circular(4)),
            child: Text(range,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeText)),
          ),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(desc,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF475569), height: 1.3)),
        ),
      ]),
    );
  }

  // ── Pollutant grid ─────────────────────────────────────────────────────────
  Widget _buildPollutantGrid() {
    List<Widget> left = [], right = [];
    for (int i = 0; i < _pollutantData.length; i++) {
      final card = _buildPollutantCard(_pollutantData[i]);
      if (i % 2 == 0) {
        left.add(card);
        left.add(const SizedBox(height: 12));
      } else {
        right.add(card);
        right.add(const SizedBox(height: 12));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ],
    );
  }

  Widget _buildPollutantCard(Map<String, dynamic> item) {
    final bool  isInfoExpanded      = item["infoExpanded"]      ?? false;
    final bool  isThresholdExpanded = item["thresholdExpanded"] ?? false;
    final Color statusColor         = item["statusColor"]       ?? const Color(0xFF22C55E);

    final List<Color> miniBarColors = const [
      Color(0xFF4ADE80), Color(0xFFFEF08A), Color(0xFFFED7AA),
      Color(0xFFFECDD3), Color(0xFFE2E8F0),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item["name"],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() {
                  item["infoExpanded"] = !isInfoExpanded;
                  if (!item["infoExpanded"]) item["thresholdExpanded"] = false;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInfoExpanded
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.info_outline,
                        size: 11,
                        color: isInfoExpanded
                            ? Colors.white
                            : const Color(0xFF2563EB)),
                    const SizedBox(width: 3),
                    Text("More Info",
                        style: TextStyle(
                            fontSize: 9,
                            color: isInfoExpanded
                                ? Colors.white
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item["value"],
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          Text(item["unit"],
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(item["status"],
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: List.generate(miniBarColors.length, (i) => Expanded(
                    child: Container(
                      height: 8,
                      margin: EdgeInsets.only(
                          right: i < miniBarColors.length - 1 ? 1.5 : 0),
                      color: miniBarColors[i],
                    ),
                  )),
            ),
          ),
          const SizedBox(height: 2),
          Row(children: [
            const SizedBox(width: 4),
            Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle)),
          ]),
          Text(item["status"],
              style: TextStyle(
                  fontSize: 9,
                  color: statusColor,
                  fontWeight: FontWeight.bold)),

          if (isInfoExpanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["description"] ?? "",
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E3A8A),
                            height: 1.3)),
                    if (item["goodHeadline"] != null) ...[
                      const SizedBox(height: 6),
                      Text(item["goodHeadline"],
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8))),
                    ],
                  ]),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(
                  () => item["thresholdExpanded"] = !isThresholdExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("View Threshold Scale",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155))),
                    Icon(
                      isThresholdExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            if (isThresholdExpanded) ...[
              const SizedBox(height: 10),
              const Text("THRESHOLD RANGES",
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              if (item["thresholds"] != null)
                Column(
                  children: List.generate(
                    (item["thresholds"] as List).length,
                    (index) {
                      final t = item["thresholds"][index];
                      final bool isCurrent =
                          index == (item["currentRangeIndex"] ?? -1);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(
                                  color: const Color(0xFF86EFAC), width: 1)
                              : null,
                        ),
                        child: Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: t["color"] ?? Colors.grey,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(t["label"] ?? "",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: const Color(0xFF334155))),
                          const Spacer(),
                          Text(t["range"] ?? "",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isCurrent
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF64748B),
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          if (isCurrent) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text("← Now",
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D))),
                            ),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
              if (item["footnote"] != null) ...[
                const SizedBox(height: 4),
                Text(item["footnote"],
                    style: const TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8))),
              ],
              const SizedBox(height: 2),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Source: Shittu et al. (2025) and Rosca et al. (2026)",
                    style: TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8))),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Sticky tab bar delegate (unchanged) ───────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final int    selectedTabIndex;

  _StickyTabBarDelegate(
      {required this.child, required this.selectedTabIndex});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override double get maxExtent => 48.0;
  @override double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate old) =>
      old.selectedTabIndex != selectedTabIndex || old.child != child;
}