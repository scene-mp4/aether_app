// lib/models/tracker_info.dart

class TrackerInfo {
  final String id;
  final String deviceName;
  final String location;
  final String ownerId;

  const TrackerInfo({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.ownerId,
  });

  factory TrackerInfo.fromFirestore(String id, Map<String, dynamic> data) {
    return TrackerInfo(
      id:         id,
      deviceName: data['device_name'] ?? 'Unnamed',
      location:   data['location']    ?? '',
      ownerId:    data['owner_id']    ?? '',
    );
  }
}