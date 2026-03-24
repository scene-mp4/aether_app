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
  bool _showDetails = false;
  Map<String, dynamic>? _selectedTrackerData;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Update the owner_id to the current user's UID
  Future<void> _linkTracker(String docId) async {
    await FirebaseFirestore.instance
        .collection('devices') // Correct collection name
        .doc(docId)
        .update({'owner_id': currentUserId});
    
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tracker successfully linked!")),
    );
  }

  void _showAvailableTrackers() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('devices')
              .where('owner_id', isEqualTo: "") // Shows devices with no owner
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final available = snapshot.data!.docs;

            if (available.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No available trackers found."),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, index) {
                var data = available[index].data() as Map<String, dynamic>;
                // FIX: Use 'device_name' instead of 'name'
                return ListTile(
                  leading: const Icon(Icons.add_link),
                  title: Text(data['device_name'] ?? "Unknown Device"), 
                  subtitle: Text("ID: ${available[index].id}"),
                  onTap: () => _linkTracker(available[index].id),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showDetails && _selectedTrackerData != null) {
      return TrackersInfo(
        // FIX: Ensure parameters match your field names
        trackerName: _selectedTrackerData!['device_name'] ?? "Unknown",
        trackerLocation: _selectedTrackerData!['location'] ?? "Unknown Location",
        onBack: () => setState(() => _showDetails = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        title: const Text("My Trackers", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices') // Correct collection name
            .where('owner_id', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No trackers linked to this account.", style: TextStyle(color: Colors.grey)),
            );
          }

          final userTrackers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: userTrackers.length,
            itemBuilder: (context, index) {
              final tracker = userTrackers[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTrackerData = tracker;
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
                              // FIX: Use 'device_name'
                              tracker['device_name'] ?? "Unnamed",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                            ),
                            Text(
                              tracker['location'] ?? "No location set",
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4B5563),
        onPressed: _showAvailableTrackers,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}