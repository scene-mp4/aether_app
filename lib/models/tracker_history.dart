// lib/models/tracker_history.dart
import 'tracker_reading.dart';

/// Holds the cached history for one tracker.
/// Keeps readings sorted oldest → newest at all times.
class TrackerHistory {
  final String deviceId;

  // Readings sorted oldest → newest
  final List<TrackerReading> readings;

  // Pagination cursor — the oldest document fetched so far.
  // Used to load more history without re-fetching what we already have.
  final dynamic oldestCursor;

  // Whether there are older readings still available in Firestore
  final bool hasMore;

  // Which time range is currently loaded
  final DateTime? from;
  final DateTime? to;

  const TrackerHistory({
    required this.deviceId,
    required this.readings,
    this.oldestCursor,
    this.hasMore = true,
    this.from,
    this.to,
  });

  TrackerHistory copyWith({
    List<TrackerReading>? readings,
    dynamic oldestCursor,
    bool? hasMore,
    DateTime? from,
    DateTime? to,
  }) {
    return TrackerHistory(
      deviceId:      deviceId,
      readings:      readings      ?? this.readings,
      oldestCursor:  oldestCursor  ?? this.oldestCursor,
      hasMore:       hasMore       ?? this.hasMore,
      from:          from          ?? this.from,
      to:            to            ?? this.to,
    );
  }

  // Convenience: readings within a specific time window
  List<TrackerReading> readingsBetween(DateTime from, DateTime to) {
    return readings
        .where((r) =>
            r.timestamp.isAfter(from) &&
            r.timestamp.isBefore(to))
        .toList();
  }

  // Last N readings — for charts that only show recent data
  List<TrackerReading> latest(int count) {
    if (readings.length <= count) return readings;
    return readings.sublist(readings.length - count);
  }
}