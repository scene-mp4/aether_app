import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackersInfo extends StatefulWidget {
  final VoidCallback onBack;
  final String trackerName;      // Added
  final String trackerLocation;  // Added

  TrackersInfo({
    required this.onBack,
    required this.trackerName,
    required this.trackerLocation,
  });

  @override
  _TrackersInfoState createState() => _TrackersInfoState();
}

class _TrackersInfoState extends State<TrackersInfo> {
  final Color primaryGreen = const Color(0xFFD1EBE9);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: widget.onBack,
          ),
          title: Text(
            widget.trackerName, // Dynamic Title
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sensor_data')
                .doc('sensor_1') // You can also pass and use a sensor ID here
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Connection Error"));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final num aqiValue = data['aqi'] ?? 0;
              final String timestamp = data['last_updated'] ?? "09:36 PM";
              
              // Use the location passed from the list if Firestore is empty
              final String location = data['location'] ?? widget.trackerLocation;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                children: [
                  _buildAQICard(aqiValue.toInt(), timestamp, location),
                  const SizedBox(height: 30),
                  const Text("Pollutant Levels",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 15),
                  _buildPollutantTile("PM2.5", "${data['pm25'] ?? 0}", "µg/m³",
                      _getStatus(aqiValue), _getColor(aqiValue)),
                  _buildPollutantTile("CO₂", "${data['co2'] ?? 0}", "ppm",
                      "Normal", Colors.green),
                  _buildPollutantTile("CO", "${data['co'] ?? 0}", "ppm", "Safe",
                      Colors.green),
                  const SizedBox(height: 30),
                  _buildSectionCard(
                    title: "History",
                    child: SlidingHistoryContent(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: "Advice",
                    child: Column(
                      children: [
                        _buildAdviceBox(
                            Colors.orange,
                            Icons.warning_amber_rounded,
                            "Moderate Air Quality",
                            "Sensitive groups should reduce outdoor activities."),
                        const SizedBox(height: 12),
                        _buildAdviceBox(Colors.blue, Icons.info_outline,
                            "Health Recommendation", "Use air purifiers indoors."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- UI Helpers ---

  Widget _buildAQICard(int aqi, String time, String loc) {
    Color statusColor = _getColor(aqi);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Text("Air Quality Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$aqi",
                    style:
                        const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text("AQI", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(_getStatus(aqi),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: statusColor, fontSize: 18)),
          Text("Last updated: $time",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPollutantTile(
      String label, String value, String unit, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("$value $unit",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        child,
      ]),
    );
  }

  Widget _buildAdviceBox(Color color, IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(fontSize: 12)),
        ]))
      ]),
    );
  }

  Color _getColor(num aqi) => aqi <= 50
      ? Colors.green
      : (aqi <= 100 ? Colors.yellow.shade800 : Colors.orange);
  String _getStatus(num aqi) =>
      aqi <= 50 ? "Good" : (aqi <= 100 ? "Moderate" : "Unhealthy");
}

class SlidingHistoryContent extends StatefulWidget {
  @override
  _SlidingHistoryContentState createState() => _SlidingHistoryContentState();
}

class _SlidingHistoryContentState extends State<SlidingHistoryContent> {
  int selectedTabIndex = 0;
  final List<String> tabs = ["Today", "7 Days", "30 Days"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
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
                children: List.generate(
                    tabs.length,
                    (index) => Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => selectedTabIndex = index),
                            child: Center(
                              child: Text(
                                tabs[index],
                                style: TextStyle(
                                    color: selectedTabIndex == index
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                            ),
                          ),
                        )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _buildChartBox("Graph for ${tabs[selectedTabIndex]}", 180),
        const SizedBox(height: 20),
        Text("${tabs[selectedTabIndex]} Averages",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 10),
        _buildChartBox("Bar Chart Placeholder", 150),
      ],
    );
  }

  Widget _buildChartBox(String text, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }
}