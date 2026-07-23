import 'package:flutter/material.dart';
import 'tracker_history_tab.dart';
import 'tracker_climate_tab.dart';
import 'tracker_advice_tab.dart';

class TrackerDetailsPage extends StatefulWidget {
  final String trackerName;
  final String location;

  const TrackerDetailsPage({
    super.key,
    this.trackerName = 'Tracker Name',
    this.location = 'Location',
  });

  @override
  State<TrackerDetailsPage> createState() => _TrackerDetailsPageState();
}

class _TrackerDetailsPageState extends State<TrackerDetailsPage> {
  int _selectedTabIndex = 0; // Top tab index
  int _bottomNavIndex = 0;   // Bottom bar index
  bool _isAqiReferenceExpanded = false;

  final List<String> _tabs = ['Pollutants', 'History', 'Climate', 'Advice'];

  // Colors matching the standard AQI air quality scale
  final List<Color> _scaleColors = const [
    Color(0xFF4CAF50), // Good (Green)
    Color(0xFFFFC107), // Moderate (Yellow)
    Color(0xFFFF9800), // Sensitive/Polluted (Orange)
    Color(0xFFF44336), // Unhealthy / Very Polluted (Red)
    Color(0xFF9C27B0), // Very Unhealthy / Severely Polluted (Purple/Brown)
  ];

  // Pollutant Data Model List with State
  late List<Map<String, dynamic>> _pollutantData;

  @override
  void initState() {
    super.initState();
    _initializePollutantData();
  }

  void _initializePollutantData() {
    _pollutantData = [
      {
        "id": "PM1.0",
        "name": "PM1.0",
        "value": "5.2",
        "unit": "µg/m³",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Ultra-fine particles smaller than 1 micrometer. They penetrate deep into the lungs and may enter the bloodstream.",
        "goodHeadline": "Good below 14 µg/m³ (ATMO, 2025)",
        "currentRangeIndex": 0,
        "thresholds": [
          {"label": "Good", "range": "0–14 µg/m³", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "15–34 µg/m³", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "35–61 µg/m³", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "62–95 µg/m³", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "96+ µg/m³", "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "PM2.5",
        "name": "PM2.5",
        "value": "9",
        "unit": "µg/m³",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Fine particles smaller than 2.5 micrometers. Linked to respiratory and cardiovascular diseases, especially in older adults.",
        "goodHeadline": "Good below 20 µg/m³ (ATMO, 2025)",
        "currentRangeIndex": 0,
        "thresholds": [
          {"label": "Good", "range": "0–20 µg/m³", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "21–50 µg/m³", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "51–90 µg/m³", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "91–140 µg/m³", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "141+ µg/m³", "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "PM10",
        "name": "PM10",
        "value": "18.5",
        "unit": "µg/m³",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Coarser particles smaller than 10 micrometers. They irritate the nose, throat, and airways when inhaled.",
        "goodHeadline": "Good below 30 µg/m³ (ATMO, 2025)",
        "currentRangeIndex": 0,
        "thresholds": [
          {"label": "Good", "range": "0–30 µg/m³", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "31–75 µg/m³", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "76–125 µg/m³", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "126–200 µg/m³", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "201+ µg/m³", "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "CO",
        "name": "CO",
        "value": "1.2",
        "unit": "ppm",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Carbon monoxide — a colorless, odorless gas produced by incomplete combustion. High levels are life-threatening.",
        "goodHeadline": "Good below 1.7 ppm (ATMO, 2025)",
        "currentRangeIndex": 0,
        "thresholds": [
          {"label": "Good", "range": "0–1.7 ppm", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "1.8–8.7 ppm", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "8.8–10 ppm", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "10.1–15 ppm", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "15.1–999 ppm", "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "CO2",
        "name": "CO₂",
        "value": "420",
        "unit": "ppm",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Carbon dioxide from breathing. Builds up in rooms with many people and poor ventilation, causing drowsiness and poor concentration.",
        "goodHeadline": "Good below 600 ppm (ATMO, 2025)",
        "currentRangeIndex": 0,
        "footnote":
            "CO₂ is not part of the EPA AQI. Ranges are based on ATMO (2025) indoor air quality guidelines.",
        "thresholds": [
          {"label": "Good", "range": "0–599 ppm", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "600–999 ppm", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "1000–1499 ppm", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "1500–2499 ppm", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "2500+ ppm", "color": const Color(0xFF7F1D1D)},
        ],
      },
      {
        "id": "O3",
        "name": "O₃",
        "value": "22",
        "unit": "ppb",
        "status": "Good",
        "infoExpanded": false,
        "thresholdExpanded": false,
        "description":
            "Ground-level ozone formed by chemical reactions between oxides of nitrogen and volatile organic compounds.",
        "goodHeadline": "Good below 50 ppb (ATMO, 2025)",
        "currentRangeIndex": 0,
        "thresholds": [
          {"label": "Good", "range": "0–50 ppb", "color": const Color(0xFF22C55E)},
          {"label": "Moderate", "range": "51–100 ppb", "color": const Color(0xFFEAB308)},
          {"label": "Polluted", "range": "101–150 ppb", "color": const Color(0xFFF97316)},
          {"label": "Very Polluted", "range": "151–200 ppb", "color": const Color(0xFFEF4444)},
          {"label": "Severely Polluted", "range": "201+ ppb", "color": const Color(0xFF7F1D1D)},
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56.0),
          child: CustomScrollView(
            slivers: [
              // 1. Blue Top Header
              SliverToBoxAdapter(
                child: _buildTopHeader(context),
              ),

              // 2. Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  selectedTabIndex: _selectedTabIndex,
                  child: _buildTabBar(),
                ),
              ),

              // 3. Main Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: _selectedTabIndex == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAqiReferenceCard(),
                            const SizedBox(height: 12),
                            _buildCurrentAqiPositionCard(),
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
                              "Pollutant thresholds are based on ATMO (2025) indoor air quality classifications.",
                              style:
                                  TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            _buildPollutantGrid(),
                            const SizedBox(height: 24),
                          ],
                        )
                      : _selectedTabIndex == 1
                          ? const TrackerHistoryTab()
                          : _selectedTabIndex == 2
                              ? const TrackerClimateTab()
                              :_selectedTabIndex == 3
                                  ? const TrackerAdviceTab()
                                    : Center(
                                        child: Text(
                                          _tabs[_selectedTabIndex],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex < 4 ? _bottomNavIndex : 0,
        selectedItemColor: const Color(0xFF0052FF),
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes), label: "Trackers"),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: "Summary"),
          BottomNavigationBarItem(
              icon: Icon(Icons.stacked_line_chart_rounded), label: "Analytics"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // Header Section
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 16),
      color: const Color(0xFF0052FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trackerName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.location,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Air Quality Index (AQI)",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: const [
                        Text(
                          "42",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "— Good",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Safe to Breathe",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Updated 2 min ago",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Custom Sticky Tab Bar
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // Multi Segment Bar Helper Widget for Reference Cards
  Widget _buildMultiSegmentBar({
    required double height,
    required int highlightIndex,
    required List<Color> colors,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Row(
        children: List.generate(colors.length, (index) {
          return Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(
                right: index < colors.length - 1 ? 2.0 : 0.0,
              ),
              color: colors[index],
            ),
          );
        }),
      ),
    );
  }

  // AQI Category Reference Card
  Widget _buildAqiReferenceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isAqiReferenceExpanded = !_isAqiReferenceExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "AQI Category Reference (US EPA 2024)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      Icon(
                        _isAqiReferenceExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildMultiSegmentBar(
                    height: 6,
                    highlightIndex: -1,
                    colors: _scaleColors,
                  ),
                ],
              ),
            ),
          ),
          if (_isAqiReferenceExpanded)
            Padding(
              padding: const EdgeInsets.only(
                  left: 12.0, right: 12.0, bottom: 12.0),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _buildAqiCategoryItem(
                    title: "Good",
                    range: "AQI 0–50",
                    description:
                        "Little to no health risk. Air quality is satisfactory.",
                    dotColor: const Color(0xFF4CAF50),
                    bgColor: const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFFBBF7D0),
                    badgeBgColor: const Color(0xFFDCFCE7),
                    badgeTextColor: const Color(0xFF166534),
                  ),
                  _buildAqiCategoryItem(
                    title: "Moderate",
                    range: "AQI 51–100",
                    description:
                        "Generally acceptable, but may concern unusually sensitive individuals.",
                    dotColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEFCE8),
                    borderColor: const Color(0xFFFEF08A),
                    badgeBgColor: const Color(0xFFFEF08A),
                    badgeTextColor: const Color(0xFF854D0E),
                  ),
                  _buildAqiCategoryItem(
                    title: "Unhealthy for Sensitive Groups",
                    range: "AQI 101–150",
                    description:
                        "Older adults, children, and people with respiratory or heart conditions may be affected.",
                    dotColor: const Color(0xFFEA580C),
                    bgColor: const Color(0xFFFFF7ED),
                    borderColor: const Color(0xFFFFEDD5),
                    badgeBgColor: const Color(0xFFFFEDD5),
                    badgeTextColor: const Color(0xFF9A3412),
                  ),
                  _buildAqiCategoryItem(
                    title: "Unhealthy",
                    range: "AQI 151–200",
                    description:
                        "General public may begin to experience health effects.",
                    dotColor: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    badgeBgColor: const Color(0xFFFEE2E2),
                    badgeTextColor: const Color(0xFF991B1B),
                  ),
                  _buildAqiCategoryItem(
                    title: "Very Unhealthy",
                    range: "AQI 201–300",
                    description:
                        "Health warnings of emergency conditions. Everyone is at increased risk.",
                    dotColor: const Color(0xFF9333EA),
                    bgColor: const Color(0xFFFAF5FF),
                    borderColor: const Color(0xFFE9D5FF),
                    badgeBgColor: const Color(0xFFF3E8FF),
                    badgeTextColor: const Color(0xFF6B21A8),
                  ),
                  _buildAqiCategoryItem(
                    title: "Hazardous",
                    range: "AQI 301+",
                    description:
                        "Emergency conditions. Entire population is likely to be seriously affected.",
                    dotColor: const Color(0xFF7F1D1D),
                    bgColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                    badgeBgColor: const Color(0xFF7F1D1D),
                    badgeTextColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Source: United States Environmental Protection Agency (2024)",
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAqiCategoryItem({
    required String title,
    required String range,
    required String description,
    required Color dotColor,
    required Color bgColor,
    required Color borderColor,
    required Color badgeBgColor,
    required Color badgeTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: dotColor),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  range,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              description,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF475569), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // Current AQI Position Card
  Widget _buildCurrentAqiPositionCard() {
    const int highlightIndex = 0; // 0-indexed position (0 = Good)
    const String aqiLabel = "AQI 42 — Good";
    const Color activeColor = Color(0xFF22C55E); // Green

    final List<Color> segmentColors = [
      const Color(0xFF4ADE80), // Active segment color (Good)
      const Color(0xFFFEF08A), // Moderate (Light Yellow)
      const Color(0xFFFED7AA), // Polluted / Sensitive (Light Orange)
      const Color(0xFFFECDD3), // Very Polluted / Unhealthy (Light Red)
      const Color(0xFFF3E8FF), // Severely Polluted (Light Purple)
      const Color(0xFFE2E8F0), // Hazardous (Light Slate/Grey)
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.trackerName} — Current AQI position",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          
          // 1. Segmented Bar with rounded outer edges
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: List.generate(segmentColors.length, (index) {
                return Expanded(
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(
                      right: index < segmentColors.length - 1 ? 2.0 : 0.0,
                    ),
                    color: segmentColors[index],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),

          // 2. Indicator Dot
          Row(
            children: List.generate(segmentColors.length, (index) {
              return Expanded(
                child: Center(
                  child: index == highlightIndex
                      ? Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox(height: 7),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),

          // 3. Status Label
          const Text(
            aqiLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Pollutant Grid
  Widget _buildPollutantGrid() {
    List<Widget> leftColumn = [];
    List<Widget> rightColumn = [];

    for (int i = 0; i < _pollutantData.length; i++) {
      Widget card = _buildPollutantCard(_pollutantData[i]);
      if (i % 2 == 0) {
        leftColumn.add(card);
        leftColumn.add(const SizedBox(height: 12));
      } else {
        rightColumn.add(card);
        rightColumn.add(const SizedBox(height: 12));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftColumn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightColumn,
          ),
        ),
      ],
    );
  }

  // Pollutant Card with View Threshold Scale Dropdown
  Widget _buildPollutantCard(Map<String, dynamic> item) {
    final bool isInfoExpanded = item["infoExpanded"] ?? false;
    final bool isThresholdExpanded = item["thresholdExpanded"] ?? false;

    // Standard scale colors
    final List<Color> miniBarColors = const [
      Color(0xFF4ADE80),
      Color(0xFFFEF08A),
      Color(0xFFFED7AA),
      Color(0xFFFECDD3),
      Color(0xFFE2E8F0),
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
          // Header Row: Title & More Info Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item["name"],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    item["infoExpanded"] = !isInfoExpanded;
                    if (!item["infoExpanded"]) {
                      item["thresholdExpanded"] = false;
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInfoExpanded
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 11,
                        color: isInfoExpanded
                            ? Colors.white
                            : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "More Info",
                        style: TextStyle(
                          fontSize: 9,
                          color: isInfoExpanded
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Current Value
          Text(
            item["value"],
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            item["unit"],
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item["status"],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Mini Segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: List.generate(miniBarColors.length, (index) {
                return Expanded(
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(
                      right: index < miniBarColors.length - 1 ? 1.5 : 0.0,
                    ),
                    color: miniBarColors[index],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 2),

          // Mini Indicator Dot & Text
          Row(
            children: [
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Text(
            "Good",
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
            ),
          ),

          // Expanded Details ("More Info" Content)
          if (isInfoExpanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["description"] ?? "",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A8A),
                      height: 1.3,
                    ),
                  ),
                  if (item["goodHeadline"] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item["goodHeadline"],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Dropdown Button: View Threshold Scale
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  item["thresholdExpanded"] = !isThresholdExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "View Threshold Scale",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
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

            // Threshold Scale Range List
            if (isThresholdExpanded) ...[
              const SizedBox(height: 10),
              const Text(
                "THRESHOLD RANGES",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
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
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: t["color"] ?? Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t["label"] ?? "",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              t["range"] ?? "",
                              style: TextStyle(
                                fontSize: 9,
                                color: isCurrent
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF64748B),
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "← Now",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (item["footnote"] != null) ...[
                const SizedBox(height: 4),
                Text(
                  item["footnote"],
                  style: const TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
              const SizedBox(height: 2),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Source: ATMO (2025)",
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }
}

// Delegate for Sticky TabBar
// Delegate for Sticky TabBar
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final int selectedTabIndex; // Add active tab index tracker

  _StickyTabBarDelegate({
    required this.child,
    required this.selectedTabIndex,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    // Rebuild when active tab index or child changes so UI updates immediately
    return oldDelegate.selectedTabIndex != selectedTabIndex ||
        oldDelegate.child != child;
  }
}