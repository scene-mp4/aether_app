import 'package:flutter/material.dart';

class SummaryNewPage extends StatefulWidget {
  const SummaryNewPage({super.key});

  @override
  State<SummaryNewPage> createState() => _SummaryNewPageState();
}

class _SummaryNewPageState extends State<SummaryNewPage> {
  bool _isManualExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Blue Top Header Banner
              _buildHeaderBanner(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Overall AQI Card
                    _buildOverallAqiCard(),
                    const SizedBox(height: 16),

                    // 3. Tracker Status Breakdown Card
                    _buildTrackerStatusCard(),
                    const SizedBox(height: 16),

                    // 4. Average Readings Grid Card
                    _buildAverageReadingsCard(),
                    const SizedBox(height: 16),

                    // 5. Individual Trackers List Card
                    _buildIndividualTrackersCard(),
                    const SizedBox(height: 16),

                    // 6. Health Supervising Manual Card
                    _buildHealthManualCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER BANNER ---
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Summary",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "All trackers · Overall air quality",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFDBEAFE),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. OVERALL AQI CARD ---
  Widget _buildOverallAqiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Overall AQI (Average)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "78",
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA16207),
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: 12),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Moderate",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA16207),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Simple Visual Range Bar
                  Stack(
                    children: [
                      Container(
                        width: 180,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Updated 2 min ago",
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              Row(
                children: [
                  Text("Good", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  SizedBox(width: 100),
                  Text("Hazardous", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. TRACKER STATUS CARD ---
  Widget _buildTrackerStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tracker Status",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            "How many trackers are in each range right now",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(const Color(0xFF22C55E), "Good", "AQI 0–50", "1"),
          _buildStatusRow(const Color(0xFFEAB308), "Moderate", "AQI 51–100", "1"),
          _buildStatusRow(const Color(0xFFF97316), "Unhealthy for Sensitive Groups", "AQI 101–150", "1"),
          _buildStatusRow(const Color(0xFFEF4444), "Unhealthy", "AQI 151–200", "1"),
          _buildStatusRow(const Color(0xFFA855F7), "Very Unhealthy", "AQI 201–300", "1"),
          _buildStatusRow(const Color(0xFF881337), "Hazardous", "AQI 301+", "1", isLast: true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(Color color, String label, String range, String count, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  range,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. AVERAGE READINGS CARD ---
  Widget _buildAverageReadingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Average Readings (All Trackers)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              _buildGridTile("PM1.0", "5.2", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true, isSuperscript: true),
              _buildGridTile("PM2.5", "9", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true, isSuperscript: true),
              _buildGridTile("PM10", "18.5", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true, isSuperscript: true),
              _buildGridTile("CO", "1.2", "ppm", "Normal", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true),
              _buildGridTile("CO₂", "420", "ppm", "Excellent", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true, isSubscript: true),
              _buildGridTile("O₃", "22", "ppb", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: false, isSubscript: true),
              _buildGridTile("Temp", "25.5", "°C", "Comfortable", const Color(0xFFDCFCE7), const Color(0xFF16A34A), isDownTrend: true),
              _buildGridTile("Humidity", "55", "%", "Moderate", const Color(0xFFFEF9C3), const Color(0xFFA16207), isDownTrend: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile(
    String label,
    String value,
    String unit,
    String status,
    Color statusBgColor,
    Color statusTextColor, {
    required bool isDownTrend,
    bool isSuperscript = false,
    bool isSubscript = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          // Value & Trend
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isDownTrend ? Icons.trending_down : Icons.trending_up,
                size: 16,
                color: isDownTrend ? const Color(0xFF22C55E) : const Color(0xFFEA580C),
              ),
            ],
          ),

          // Unit & Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),

          // More Info Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline, size: 10, color: Color(0xFF2563EB)),
                SizedBox(width: 2),
                Text(
                  "More Info",
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, size: 10, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. INDIVIDUAL TRACKERS CARD ---
  Widget _buildIndividualTrackersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Individual Trackers",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Tracker 1
          _buildTrackerItem(
            name: "Tracker 1",
            location: "Main Building, Floor 1",
            aqi: "42",
            aqiStatus: "Good",
            aqiColor: const Color(0xFF16A34A),
            aqiBgColor: const Color(0xFFDCFCE7),
            pm25: "9",
            co2: "420",
            temp: "25.5°",
            humid: "55%",
          ),
          const SizedBox(height: 12),

          // Tracker 2
          _buildTrackerItem(
            name: "Tracker 2",
            location: "Senior Care Unit A",
            aqi: "68",
            aqiStatus: "Moderate",
            aqiColor: const Color(0xFFA16207),
            aqiBgColor: const Color(0xFFFEF9C3),
            pm25: "28.5",
            co2: "580",
            temp: "27.2°",
            humid: "62%",
          ),
          const SizedBox(height: 12),

          // Tracker 3
          _buildTrackerItem(
            name: "Tracker 3",
            location: "Therapy Wing",
            aqi: "125",
            aqiStatus: "Unhealthy",
            aqiColor: const Color(0xFFC2410C),
            aqiBgColor: const Color(0xFFFFEDD5),
            pm25: "65.2",
            co2: "850",
            temp: "29.8°",
            humid: "48%",
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerItem({
    required String name,
    required String location,
    required String aqi,
    required String aqiStatus,
    required Color aqiColor,
    required Color aqiBgColor,
    required String pm25,
    required String co2,
    required String temp,
    required String humid,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    aqi,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: aqiColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: aqiBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      aqiStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: aqiColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMiniTile("PM2.5", pm25)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniTile("CO₂", co2)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniTile("Temp", temp)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniTile("Humid", humid)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTile(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. HEALTH MANUAL CARD ---
  Widget _buildHealthManualCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Health Supervising Manual",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isManualExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() {
                    _isManualExpanded = !_isManualExpanded;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Common illnesses senior citizens may develop from indoor air pollutants, with do's and don'ts.",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
          ),
        ],
      ),
    );
  }
}