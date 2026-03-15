import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trackers_info.dart';

class TrackersTab extends StatefulWidget {
  @override
  _TrackersTabState createState() => _TrackersTabState();
}

class _TrackersTabState extends State<TrackersTab> {
  final Color customBgColor = const Color(0xFFF8FAF5);
  bool _showDetails = false;
  
  // To store the clicked tracker info
  Map<String, String>? _selectedTrackerData;

  final List<Map<String, String>> trackers = [
    {"name": "Tracker 1", "location": "Kitchen"},
    {"name": "Tracker 2", "location": "Living Room"},
    {"name": "Tracker 3", "location": "Master Bedroom"},
  ];

  @override
  Widget build(BuildContext context) {
    if (_showDetails && _selectedTrackerData != null) {
      return TrackersInfo(
        trackerName: _selectedTrackerData!['name']!,
        trackerLocation: _selectedTrackerData!['location']!,
        onBack: () {
          setState(() {
            _showDetails = false;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAF5),
      appBar: AppBar(
        title: const Text("My Trackers", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: trackers.length,
        itemBuilder: (context, index) {
          final tracker = trackers[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTrackerData = tracker; // Save the clicked data
                _showDetails = true;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFD1EBE9),
                    child: Icon(Icons.location_on, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trackers[index]['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          trackers[index]['location']!,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}