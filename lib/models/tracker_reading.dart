// lib/models/tracker_reading.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TrackerReading {
  // ── Identity ───────────────────────────────────────────────────────────────
  final String deviceId;
  final String readingId;      // document ID — matches readings/{id} raw doc
  final String locationName;
  final DateTime timestamp;

  // ── Gas concentrations (ppm) ───────────────────────────────────────────────
  final double lpgPpm;
  final double smokePpm;
  final double coPpm;
  final double co2Ppm;
  final double nh3Ppm;
  final double o3Ppm;

  // ── Particulate matter (µg/m³) ─────────────────────────────────────────────
  final double pm1Ugm3;
  final double pm25Ugm3;
  final double pm10Ugm3;

  // ── Climate ────────────────────────────────────────────────────────────────
  final double temperatureC;
  final double humidityPct;
  final double absHumidityGm3;
  final double heatIndexC;

  // ── AQI ────────────────────────────────────────────────────────────────────
  final int    pm25Aqi;
  final int    iaqi;
  final String iaqiLabel;

  // ── Alert flags ────────────────────────────────────────────────────────────
  final bool coAlert;
  final bool lpgAlert;
  final bool pm25Alert;
  final bool co2Alert;

  const TrackerReading({
    required this.deviceId,
    required this.readingId,
    required this.locationName,
    required this.timestamp,
    required this.lpgPpm,
    required this.smokePpm,
    required this.coPpm,
    required this.co2Ppm,
    required this.nh3Ppm,
    required this.o3Ppm,
    required this.pm1Ugm3,
    required this.pm25Ugm3,
    required this.pm10Ugm3,
    required this.temperatureC,
    required this.humidityPct,
    required this.absHumidityGm3,
    required this.heatIndexC,
    required this.pm25Aqi,
    required this.iaqi,
    required this.iaqiLabel,
    required this.coAlert,
    required this.lpgAlert,
    required this.pm25Alert,
    required this.co2Alert,
  });

  // ── Parse from a readings_computed Firestore document ─────────────────────
  factory TrackerReading.fromDocument(DocumentSnapshot doc) {
    final data     = doc.data() as Map<String, dynamic>? ?? {};
    final deviceId = data['device_id'] as String? ?? '';
    return TrackerReading._fromMap(deviceId, doc.id, data);
  }

  // ── Parse from the devices/{id}.latest summary field ──────────────────────
  factory TrackerReading.fromLatest(
      String deviceId, String readingId, Map<String, dynamic> data) {
    return TrackerReading._fromMap(deviceId, readingId, data);
  }

  // ── Shared internal constructor ────────────────────────────────────────────
  factory TrackerReading._fromMap(
      String deviceId, String readingId, Map<String, dynamic> d) {
    return TrackerReading(
      deviceId:       deviceId,
      readingId:      readingId,
      locationName:   _str(d['location_name'] ?? d['location']),
      timestamp:      _parseTimestamp(d['timestamp']),
      lpgPpm:         _dbl(d['lpg_ppm']),
      smokePpm:       _dbl(d['smoke_ppm']),
      coPpm:          _dbl(d['co_ppm']),
      co2Ppm:         _dbl(d['co2_ppm']),
      nh3Ppm:         _dbl(d['nh3_ppm']),
      o3Ppm:          _dbl(d['o3_ppm']),
      pm1Ugm3:        _dbl(d['pm1_ugm3']),
      pm25Ugm3:       _dbl(d['pm25_ugm3']),
      pm10Ugm3:       _dbl(d['pm10_ugm3']),
      temperatureC:   _dbl(d['temperature_c']),
      humidityPct:    _dbl(d['humidity_pct']),
      absHumidityGm3: _dbl(d['abs_humidity_gm3']),
      heatIndexC:     _dbl(d['heat_index_c']),
      pm25Aqi:        _int(d['pm25_aqi']),
      iaqi:           _int(d['iaqi']),
      iaqiLabel:      _str(d['iaqi_label']),
      coAlert:        d['co_alert']   == true,
      lpgAlert:       d['lpg_alert']  == true,
      pm25Alert:      d['pm25_alert'] == true,
      co2Alert:       d['co2_alert']  == true,
    );
  }

  // ── Type helpers ───────────────────────────────────────────────────────────
  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is num)    return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is num)    return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _str(dynamic v) => v?.toString() ?? '';

static DateTime _parseTimestamp(dynamic v) {
  if (v == null)          return DateTime.now();
  if (v is Timestamp)     return v.toDate();
  if (v is DateTime)      return v;
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (kDebugMode && parsed == null) {
      print('[TrackerReading] Failed to parse timestamp: "$v"');
    }
    return parsed ?? DateTime.now();
  }
  return DateTime.now();
}
}