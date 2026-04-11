import 'package:flutter/material.dart';
import 'dart:math';
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
  String _selectedTrackerId = "";
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  final List<String> _allowedLocations = ['comfort room', 'living room', 'dining area', 'kitchen', 'bedroom'];

  // --- IAQI helpers (copied minimal set to render summary card) ---
  int calculatePM25AQI(double concentration) {
    if (concentration <= 0) return 0;
    final List<List<double>> bp = [
      [0.0, 12.0, 0, 50],
      [12.1, 35.4, 51, 100],
      [35.5, 55.4, 101, 150],
      [55.5, 150.4, 151, 200],
      [150.5, 250.4, 201, 300],
      [250.5, 350.4, 301, 400],
      [350.5, 500.4, 401, 500],
    ];
    for (var r in bp) {
      if (concentration >= r[0] && concentration <= r[1]) {
        return (((r[3] - r[2]) / (r[1] - r[0])) * (concentration - r[0]) + r[2])
            .round();
      }
    }
    return 500;
  }

  double calculatePPM(double ratio, double a, double b) {
    if (ratio <= 0 || ratio.isNaN) return 0.0;
    return a * pow(ratio, b);
  }

  double getCorrectionFactor(double t, double h) {
    return -0.00035 * pow(t, 2) + 0.0177 * t - 0.0000179 * pow(h, 2) + 0.00699 * h - 0.1689;
  }

  int getCompositeIAQI(double co, double co2, double nh3, int pmAqi) {
    double iCo = (co / 200).clamp(0, 1) * 500;
    double iCo2 = (co2 / 5000).clamp(0, 1) * 500;
    double iNh3 = (nh3 / 300).clamp(0, 1) * 500;
    return [iCo, iCo2, iNh3, pmAqi.toDouble()].reduce(max).toInt();
  }

  Color _getColor(num aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade800;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return const Color(0xFF800000);
  }

  String _getStatus(num aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy (Sensitive)";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

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

  // Confirm and unlink a tracker from this user
  void _confirmUnlink(String docId, Map<String, dynamic> tracker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unlink Tracker'),
          content: Text('Are you sure you want to unlink "${tracker['device_name'] ?? 'this tracker'}"? It will no longer be available to your account.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                await _unlinkTracker(docId);
              },
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unlinkTracker(String docId) async {
    try {
      // clear owner on the device document
      await FirebaseFirestore.instance.collection('devices').doc(docId).update({'owner_id': ""});

      // remove tracker entry from user's document if exists
      if (currentUserId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
          'trackers.$docId': FieldValue.delete(),
        }).catchError((_) async {
          // ignore if user doc doesn't exist
        });
      }

      // if currently viewing details for this tracker, close it
      if (_selectedTrackerId == docId) {
        setState(() {
          _showDetails = false;
          _selectedTrackerId = '';
          _selectedTrackerData = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracker unlinked')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unlink failed: $e')));
    }
  }

  void _showAvailableTrackers() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('devices')
              .where('owner_id', isEqualTo: "") // Shows devices with no owner
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
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
      // Normalize location which may be a GeoPoint in Firestore
      String locationStr = "Unknown Location";
      final rawLoc = _selectedTrackerData!['location'];
      if (rawLoc != null) {
        if (rawLoc is GeoPoint) {
          locationStr = "${rawLoc.latitude.toStringAsFixed(4)}, ${rawLoc.longitude.toStringAsFixed(4)}";
        } else if (rawLoc is String) {
          locationStr = rawLoc;
        } else if (rawLoc is Map) {
          try {
            final lat = rawLoc['latitude'] ?? rawLoc['lat'] ?? rawLoc['lat'];
            final lng = rawLoc['longitude'] ?? rawLoc['lng'] ?? rawLoc['lon'];
            locationStr = "${lat.toString()}, ${lng.toString()}";
          } catch (_) {
            locationStr = rawLoc.toString();
          }
        } else {
          locationStr = rawLoc.toString();
        }
      }

      return TrackersInfo(
        trackerId: _selectedTrackerId,
        trackerName: _selectedTrackerData!['device_name'] ?? "Unknown",
        trackerLocation: locationStr,
        onBack: () => setState(() => _showDetails = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF5),
      appBar: AppBar(
        title: const Text(
          "My Trackers",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
              child: Text(
                "No trackers linked to this account.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final userTrackers = snapshot.data!.docs;

          // Build a scrollable list inserting the AQI summary between first and second trackers
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              // Build tracker widgets and insert summary after the first tracker
              for (int i = 0; i < userTrackers.length; i++) ...[
                (() {
                  final doc = userTrackers[i];
                  final tracker = doc.data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTrackerData = tracker;
                        _selectedTrackerId = doc.id;
                        _showDetails = true;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFD1EBE9),
                            child: Icon(
                              Icons.location_on,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tracker['device_name'] ?? 'Unnamed',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (() {
                                    final rawLoc = tracker['location'];
                                    if (rawLoc == null) return 'No location set';
                                    if (rawLoc is GeoPoint) return '${rawLoc.latitude.toStringAsFixed(4)}, ${rawLoc.longitude.toStringAsFixed(4)}';
                                    if (rawLoc is String) return rawLoc;
                                    return rawLoc.toString();
                                  })(),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black54, size: 20),
                                onPressed: () => _showEditTrackerDialog(doc.id, tracker),
                              ),
                              IconButton(
                                icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmUnlink(doc.id, tracker),
                                tooltip: 'Unlink tracker',
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                })(),

                // insert summary after first tracker (show even when only one tracker remains)
                if (i == 0)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .doc(userTrackers.first.id)
                        .collection('readings')
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, s2) {
                      if (!s2.hasData || s2.data!.docs.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('No readings yet')),
                        );
                      }

                      final r = s2.data!.docs.first.data() as Map<String, dynamic>;
                      double t = (r['temperature'] ?? 0).toDouble();
                      double h = (r['humidity'] ?? 0).toDouble();
                      double pm25 = (r['pm25'] ?? 0).toDouble();
                      double v2 = (r['mq2_v'] ?? 0).toDouble();
                      double v9 = (r['mq9_v'] ?? 0).toDouble();
                      double v135 = (r['mq135_v'] ?? 0).toDouble();

                      if (v2 > 20) v2 = v2 * (5.0 / 1023.0);
                      if (v9 > 20) v9 = v9 * (5.0 / 1023.0);
                      if (v135 > 20) v135 = v135 * (5.0 / 1023.0);

                      double r2 = (v2 > 0) ? (5.0 - v2) / v2 : 0.0;
                      double r9 = (v9 > 0) ? (5.0 - v9) / v9 : 0.0;
                      double r135 = (v135 > 0) ? (5.0 - v135) / v135 : 0.0;

                      double lpg = calculatePPM(r2, 574.25, -2.222);
                      double co = calculatePPM(r9, 1000.5, -1.969);
                      double co2 = calculatePPM(r135 / (getCorrectionFactor(t, h).clamp(0.1, 10)), 110.47, -2.862);
                      int pmAqi = calculatePM25AQI(pm25);
                      int finalIAQI = getCompositeIAQI(co, co2, 0.0, pmAqi);

                      // derive a human-friendly location string from the tracker document
                      final parentTrackerDoc = userTrackers.first;
                      final parentTracker = parentTrackerDoc.data() as Map<String, dynamic>;
                      String summaryLocation = 'Unknown Location';
                      final locRaw = parentTracker['location'];
                      if (locRaw != null) {
                        if (locRaw is GeoPoint) {
                          summaryLocation = '${locRaw.latitude.toStringAsFixed(4)}, ${locRaw.longitude.toStringAsFixed(4)}';
                        } else if (locRaw is String) {
                          summaryLocation = locRaw;
                        } else if (locRaw is Map) {
                          try {
                            final lat = locRaw['latitude'] ?? locRaw['lat'] ?? locRaw['lat'];
                            final lng = locRaw['longitude'] ?? locRaw['lng'] ?? locRaw['lon'];
                            summaryLocation = '${lat.toString()}, ${lng.toString()}';
                          } catch (_) {
                            summaryLocation = locRaw.toString();
                          }
                        } else {
                          summaryLocation = locRaw.toString();
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Air Quality Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(summaryLocation, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _getColor(finalIAQI), width: 6)),
                              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$finalIAQI', style: TextStyle(color: _getColor(finalIAQI), fontSize: 26, fontWeight: FontWeight.bold)), const Text('IAQI', style: TextStyle(color: Colors.grey))])),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
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

  void _showEditTrackerDialog(String docId, Map<String, dynamic> tracker) {
    final nameController = TextEditingController(text: tracker['device_name'] ?? '');
    // derive current location string if available
    String curLoc = '';
    final rawLoc = tracker['location'];
    if (rawLoc != null) {
      if (rawLoc is GeoPoint) curLoc = '${rawLoc.latitude.toStringAsFixed(4)}, ${rawLoc.longitude.toStringAsFixed(4)}';
      else if (rawLoc is String) curLoc = rawLoc;
      else curLoc = rawLoc.toString();
    }

    String selectedLocation = _allowedLocations.contains(curLoc.toLowerCase()) ? curLoc.toLowerCase() : _allowedLocations.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Tracker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tracker name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                items: _allowedLocations
                    .map((l) => DropdownMenuItem(value: l, child: Text(_capitalize(l))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) selectedLocation = v;
                },
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('devices').doc(docId).update({
                    'device_name': newName,
                    'location': selectedLocation,
                  });

                  if (currentUserId.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
                      'trackers.$docId.device_name': newName,
                      'trackers.$docId.location': selectedLocation,
                    }).catchError((_) async {
                      await FirebaseFirestore.instance.collection('users').doc(currentUserId).set({
                        'trackers': {
                          docId: {'device_name': newName, 'location': selectedLocation}
                        }
                      }, SetOptions(merge: true));
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tracker updated')));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
