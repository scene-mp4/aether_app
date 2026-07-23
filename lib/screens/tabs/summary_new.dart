import 'package:flutter/material.dart';

class SummaryNewPage extends StatefulWidget {
  const SummaryNewPage({super.key});

  @override
  State<SummaryNewPage> createState() => _SummaryNewPageState();
}

class _SummaryNewPageState extends State<SummaryNewPage> {
  // Manual parent state
  bool _isManualExpanded = false;

  // Manual sub-sections state
  bool _isRespiratoryExpanded = false;
  bool _isCardiovascularExpanded = false;
  bool _isDosExpanded = false;
  bool _isDontsExpanded = false;

  // Track expanded state for AQI header banner and each average reading grid item
  bool _isAqiInfoExpanded = false;
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
              InkWell(
                onTap: () {
                  setState(() {
                    _isAqiInfoExpanded = !_isAqiInfoExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
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
                    "The Overall AQI (Air Quality Index) measures how clean or polluted the air is based on the average of all collected AQI (Air Quality Index) in each tracker.",
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  _buildAqiLegendRow(const Color(0xFF22C55E), "0–50", "Good"),
                  _buildAqiLegendRow(const Color(0xFFEAB308), "51–100", "Moderate"),
                  _buildAqiLegendRow(const Color(0xFFEA580C), "101–150", "Unhealthy for Sensitive Groups"),
                  _buildAqiLegendRow(const Color(0xFFEF4444), "151–200", "Unhealthy"),
                  _buildAqiLegendRow(const Color(0xFFA855F7), "201–300", "Very Unhealthy"),
                  _buildAqiLegendRow(const Color(0xFF881337), "301+", "Hazardous"),
                ],
              ),
            ),
          ],
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

  Widget _buildAqiLegendRow(Color color, String range, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            "$range  ",
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGridTile(
                  "PM1.0", "5.2", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "PM1.0 are extremely tiny particles — smaller than 1/70th of a human hair. They float in the air and can be inhaled deep into the lungs.\n\nSafe below 10 µg/m³",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridTile(
                  "PM2.5", "9", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "PM2.5 are fine dust particles — about 30 times smaller than a grain of sand. They come from smoke, cooking, or outdoor pollution entering the building.\n\nSafe below 12 µg/m³ (WHO guideline)",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGridTile(
                  "PM10", "18.5", "µg/m³", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "PM10 are larger dust particles you can sometimes see floating in a beam of light. They come from dust, pollen, and dirt tracked indoors.\n\nSafe below 54 µg/m³",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridTile(
                  "CO", "1.2", "ppm", "Normal", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "CO (Carbon Monoxide) is a colorless, odorless gas produced when fuel is burned incompletely — from gas stoves, heaters, or car exhaust nearby. High levels are very dangerous.\n\nSafe below 9 ppm",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGridTile(
                  "CO₂", "420", "ppm", "Excellent", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "CO₂ (Carbon Dioxide) is the gas people exhale when breathing. It builds up in rooms with many people and poor air circulation, causing stuffiness and tiredness.\n\nGood below 800 ppm · Stuffy above 1000 ppm",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridTile(
                  "O₃", "22", "ppb", "Good", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: false,
                  infoText: "O₃ (Ozone) at ground level is an irritant. It can irritate the throat and lungs, especially for residents with asthma or other breathing conditions.\n\nSafe below 70 ppb",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildGridTile(
                  "Temp", "25.5", "°C", "Comfortable", const Color(0xFFDCFCE7), const Color(0xFF16A34A),
                  isDownTrend: true,
                  infoText: "This is the air temperature inside the monitored room. Elderly and ill residents are more sensitive to heat and cold than healthy adults.\n\nComfortable range: 20–26°C",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGridTile(
                  "Humidity", "55", "%", "Moderate", const Color(0xFFFEF9C3), const Color(0xFFA16207),
                  isDownTrend: false,
                  infoText: "Humidity measures how much moisture is in the air. Too much causes stuffiness and mold; too little causes dry skin and irritated airways.\n\nComfortable range: 40–60%",
                ),
              ),
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
    required String infoText,
  }) {
    bool isExpanded = _expandedMetrics[label] ?? false;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _expandedMetrics[label] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  const Text(
                    "More Info",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                infoText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF1E40AF),
                  height: 1.35,
                ),
              ),
            ),
          ],
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
          // Header Row
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

          // Sub-Sections when Main Card is Expanded
          if (_isManualExpanded) ...[
            const SizedBox(height: 16),

            // SECTION A — RESPIRATORY ILLNESSES
            _buildSectionHeader("SECTION A — RESPIRATORY ILLNESSES"),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              title: "Respiratory Illnesses (4)",
              isExpanded: _isRespiratoryExpanded,
              onTap: () {
                setState(() {
                  _isRespiratoryExpanded = !_isRespiratoryExpanded;
                });
              },
              content: Column(
                children: [
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFEA580C),
                    name: "Asthma",
                    triggeredBy: "PM2.5, PM10, O₃",
                    symptoms: "Wheezing, breathlessness, coughing",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFEF4444),
                    name: "COPD (Chronic Obstructive Pulmonary Disease)",
                    triggeredBy: "PM2.5, CO",
                    symptoms: "Chronic cough, breathlessness, fatigue",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFEAB308),
                    name: "Bronchitis",
                    triggeredBy: "PM10, CO",
                    symptoms: "Persistent cough with mucus, chest discomfort",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFEF4444),
                    name: "Pneumonia",
                    triggeredBy: "PM2.5, PM10",
                    symptoms: "Fever, difficulty breathing, chest pain",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // SECTION B — CARDIOVASCULAR ILLNESSES
            _buildSectionHeader("SECTION B — CARDIOVASCULAR ILLNESSES"),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              title: "Cardiovascular Illnesses (4)",
              isExpanded: _isCardiovascularExpanded,
              onTap: () {
                setState(() {
                  _isCardiovascularExpanded = !_isCardiovascularExpanded;
                });
              },
              content: Column(
                children: [
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFA855F7),
                    name: "Hypertension (High Blood Pressure)",
                    triggeredBy: "CO, PM2.5",
                    symptoms: "Headache, dizziness, chest pain",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFA855F7),
                    name: "Ischemic Heart Disease",
                    triggeredBy: "CO, PM2.5, O₃",
                    symptoms: "Chest pain, fatigue, shortness of breath",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFDC2626),
                    name: "Heart Failure",
                    triggeredBy: "Prolonged PM2.5, CO exposure",
                    symptoms: "Breathlessness, tiredness, irregular heartbeat",
                  ),
                  _buildDiseaseItem(
                    dotColor: const Color(0xFFDC2626),
                    name: "Stroke",
                    triggeredBy: "PM2.5, CO",
                    symptoms: "Sudden dizziness, confusion, difficulty speaking",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // SECTION C — DO'S
            _buildSectionHeader("SECTION C — DO'S"),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              title: "What to Do",
              titleColor: const Color(0xFF166534),
              headerBgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFDCFCE7),
              arrowColor: const Color(0xFF22C55E),
              isExpanded: _isDosExpanded,
              onTap: () {
                setState(() {
                  _isDosExpanded = !_isDosExpanded;
                });
              },
              content: Column(
                children: [
                  _buildDoDontItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF22C55E),
                    title: "Improve indoor ventilation",
                    description: "open windows or run air circulation when pollutant levels rise",
                  ),
                  _buildDoDontItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF22C55E),
                    title: "Monitor real-time air quality",
                    description: "use AETHER readings to check current air quality before extended activities",
                  ),
                  _buildDoDontItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF22C55E),
                    title: "Seek medical check-up",
                    description: "if symptoms like coughing, breathlessness, or dizziness persist, consult a doctor",
                  ),
                  _buildDoDontItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF22C55E),
                    title: "Continue prescribed medications",
                    description: "do not stop ongoing respiratory or heart-related medication",
                  ),
                  _buildDoDontItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF22C55E),
                    title: "Use protective masks",
                    description: "wear an appropriate mask when pollutant levels are elevated",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // SECTION D — DON'TS
            _buildSectionHeader("SECTION D — DON'TS"),
            const SizedBox(height: 6),
            _buildDropdownContainer(
              title: "What Not to Do",
              titleColor: const Color(0xFF991B1B),
              headerBgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFEE2E2),
              arrowColor: const Color(0xFFEF4444),
              isExpanded: _isDontsExpanded,
              onTap: () {
                setState(() {
                  _isDontsExpanded = !_isDontsExpanded;
                });
              },
              content: Column(
                children: [
                  _buildDoDontItem(
                    icon: Icons.close,
                    iconColor: const Color(0xFFEF4444),
                    title: "Do not smoke indoors",
                    description: "smoking significantly worsens indoor air quality for all residents",
                  ),
                  _buildDoDontItem(
                    icon: Icons.close,
                    iconColor: const Color(0xFFEF4444),
                    title: "Do not burn fuels in unventilated spaces",
                    description: "gas stoves or heaters need proper ventilation",
                  ),
                  _buildDoDontItem(
                    icon: Icons.close,
                    iconColor: const Color(0xFFEF4444),
                    title: "Do not remain in high-pollutant areas",
                    description: "move to a cleaner area if readings are Polluted or worse",
                  ),
                  _buildDoDontItem(
                    icon: Icons.close,
                    iconColor: const Color(0xFFEF4444),
                    title: "Do not perform heavy physical activity when air quality is poor",
                    description: "exertion increases pollutant intake into the lungs",
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footnote Sources
            const Text(
              "Sources: Ndlovu et al. (2024); World Health Organization (2025); Lemos et al. (2024)",
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Section Header Text Helper
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  // Dropdown Box Outer Shell Widget
  Widget _buildDropdownContainer({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
    Color titleColor = const Color(0xFF1E293B),
    Color headerBgColor = const Color(0xFFF8FAFC),
    Color borderColor = const Color(0xFFE2E8F0),
    Color arrowColor = const Color(0xFF64748B),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
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
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
        ],
      ),
    );
  }

  // Illness Item Row Builder
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
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    children: [
                      const TextSpan(
                        text: "Triggered by: ",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                      TextSpan(text: triggeredBy),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    children: [
                      const TextSpan(
                        text: "Symptoms: ",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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

  // Do's / Don'ts Row Builder
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
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                children: [
                  TextSpan(
                    text: "$title — ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
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