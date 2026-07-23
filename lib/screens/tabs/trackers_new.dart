import 'package:flutter/material.dart';
import 'tracker_details_page.dart';

class TrackersNewPage extends StatefulWidget {
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
  State<TrackersNewPage> createState() => _TrackersNewPageState();
}

class _TrackersNewPageState extends State<TrackersNewPage> {
  // Active trackers list state
  final List<Map<String, String>> _activeTrackers = [
    {"name": "Tracker Name", "location": "Location"},
    {"name": "Tracker Name", "location": "Location"},
  ];

  // List of available nearby trackers to select from the pop-up
  final List<Map<String, String>> _availableTrackers = [
    {"name": "Tracker Name", "location": "Location"},
    {"name": "Tracker Name", "location": "Location"},
  ];

  // Function to show the "Add New Tracker" modal pop-up
  void _showAddTrackerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Trackers",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _availableTrackers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            "No nearby trackers found.",
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ),
                      )
                    : Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _availableTrackers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            final tracker = _availableTrackers[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                tracker["name"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              subtitle: Text(
                                tracker["location"]!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0052FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _activeTrackers.add({
                                      "name": tracker["name"]!,
                                      "location": tracker["location"]!,
                                    });
                                    _availableTrackers.removeAt(index);
                                  });
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text("Add"),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0052FF),
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
                  Text(
                    "${_activeTrackers.length} active devices",
                    style: const TextStyle(
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
                    onTap: () => _showAddTrackerDialog(context),
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

                  // Active Trackers List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeTrackers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _activeTrackers[index];
                      return TrackerCard(
                        key: ValueKey("${item['name']}_$index"),
                        trackerName: item["name"]!,
                        locationName: item["location"]!,
                      );
                    },
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
}

// Stateful Tracker Card
class TrackerCard extends StatefulWidget {
  final String trackerName;
  final String locationName;

  const TrackerCard({
    super.key,
    required this.trackerName,
    required this.locationName,
  });

  @override
  State<TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<TrackerCard> {
  // HIDE AQI INFO BOX BY DEFAULT
  bool _showAqiInfo = false;

  final List<Map<String, String>> _placeholderReadings = [
    {"label": "PM1.0", "value": "--", "unit": "µg/m³"},
    {"label": "PM2.5", "value": "--", "unit": "µg/m³"},
    {"label": "PM10", "value": "--", "unit": "µg/m³"},
    {"label": "CO", "value": "--", "unit": "ppm"},
    {"label": "CO₂", "value": "--", "unit": "ppm"},
    {"label": "O₃", "value": "--", "unit": "ppb"},
    {"label": "Temp", "value": "--", "unit": "°C"},
    {"label": "Humid", "value": "--", "unit": "%"},
  ];

  @override
  Widget build(BuildContext context) {
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
              // Card Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.trackerName,
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

              // Location row
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF475569)),
                  const SizedBox(width: 4),
                  Text(
                    widget.locationName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AQI Row
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

                  // Status Chip
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

                  // "What is AQI?" Toggle Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAqiInfo = !_showAqiInfo;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                        color: const Color(0xFFEFF6FF),
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

              // INLINE AQI INFO CARD (Hidden by default, shown when _showAqiInfo == true)
              if (_showAqiInfo) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "AQI (Air Quality Index) measures how clean or polluted the air is. Lower numbers are better. 0–50 is Good, 51–100 is Moderate, 101–150 is Unhealthy for Sensitive Groups, 151–200 is Unhealthy, 201–300 is Very Unhealthy, and 301–500 is Hazardous.",
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAqiInfo = false;
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Last Updated Time String
              const Text(
                "Update time",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // AQI Scale Slider
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

              // Sensor Readings Grid Title
              const Text(
                "Current Readings",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),

              // Sensor Readings Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _placeholderReadings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  var item = _placeholderReadings[index];
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