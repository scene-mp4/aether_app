import 'package:flutter/material.dart';
import 'tracker_details_page.dart';

class TrackersNewPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const TrackersNewPage({
    super.key,
    this.title = 'Trackers Page',
    this.icon = Icons.construction,
    this.message = 'This page is under construction.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Soft grayish-blue background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header section matching the original design exactly
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 48, bottom: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0052FF), // Primary vibrant blue
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Trackers",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "-- active devices", // Placeholder count
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70, 
                    ),
                  ),
                ],
              ),
            ),

            // Padding wrapper for dashboard items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // "Add New Tracker" button
                  GestureDetector(
                    onTap: () {
                      debugPrint("Add tracker clicked!");
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0052FF),
                          style: BorderStyle.solid, 
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: Color(0xFF0052FF), size: 20),
                          SizedBox(width: 6),
                          Text(
                            "Add New Tracker",
                            style: TextStyle(
                              color: Color(0xFF0052FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // =================== TRACKER 1 PLACEHOLDER ===================
                  _buildTrackerPlaceholderCard(
                    context,
                    trackerPlaceholderName: "Tracker Name",
                    locationPlaceholder: "Location",
                  ),
                  const SizedBox(height: 16),

                  // =================== TRACKER 2 PLACEHOLDER ===================
                  _buildTrackerPlaceholderCard(
                    context,
                    trackerPlaceholderName: "Tracker Name",
                    locationPlaceholder: "Location",
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a complete placeholder card without const issues
  Widget _buildTrackerPlaceholderCard(
    BuildContext context, {
    required String trackerPlaceholderName,
    required String locationPlaceholder,
  }) {
    // Standard blank sensor structure for the current readings grid
    final List<Map<String, String>> placeholderReadings = [
      {"label": "PM1.0", "value": "--", "unit": "µg/m³"},
      {"label": "PM2.5", "value": "--", "unit": "µg/m³"},
      {"label": "PM10", "value": "--", "unit": "µg/m³"},
      {"label": "CO", "value": "--", "unit": "ppm"},
      {"label": "CO₂", "value": "--", "unit": "ppm"},
      {"label": "O₃", "value": "--", "unit": "ppb"},
      {"label": "Temp", "value": "--", "unit": "°C"},
      {"label": "Humid", "value": "--", "unit": "%"},
    ];

return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrackerDetailsPage(),
      ),
    );
  },
  child: Card(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header Row (Tracker Name, Arrow Icon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(
                  trackerPlaceholderName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF475569), 
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF64748B), 
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Location row with Map Pin Icon
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF475569)),
                const SizedBox(width: 4),
                Text(
                  locationPlaceholder,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569), 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AQI and Status Row (Empty/Loading State) with the added "What is AQI?" info button
            Row(
              children: [
                const Text(
                  "--",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF334155), 
                  ),
                ),
                const SizedBox(width: 10),
                
                // Status Chip Container Placeholder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0), 
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Status",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569), 
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // =================== "WHAT IS AQI?" BUTTON ===================
                GestureDetector(
                  onTap: () {
                    debugPrint("What is AQI? clicked!");
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
                      color: const Color(0xFFEFF6FF), // Light blue background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline, 
                          size: 12, 
                          color: Color(0xFF0052FF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "What is AQI?",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0052FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Last Updated Time String
            const Text(
              "Update time",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B), 
              ),
            ),
            const SizedBox(height: 12),

            // AQI Mini Scale slider representation (Greyed out)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("0 — Good", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text("500 — Hazardous", style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0, 
                    minHeight: 8,
                    backgroundColor: Color(0xFFE2E8F0), 
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),

            // "Current Readings" Label
            const Text(
              "Current Readings",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155), 
              ),
            ),
            const SizedBox(height: 10),

            // Grid View of the 8 Sensor reading blocks (All set to "--")
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), 
              itemCount: placeholderReadings.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, 
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.05, 
              ),
              itemBuilder: (context, index) {
                var item = placeholderReadings[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item["label"]!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569), 
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item["value"]!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B), 
                        ),
                      ),
                      Text(
                        item["unit"]!,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B), 
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
      ),
        ),
      ),
    );
  }
}