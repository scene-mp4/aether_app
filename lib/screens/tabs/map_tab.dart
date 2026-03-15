import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import '../bottom_navbar.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final String apiKey = "3daccd08-5d7f-41ba-af56-1ce0402607f5";
  Map? airData;

  final List<WeightedLatLng> heatMapData = [
    WeightedLatLng(LatLng(14.5764, 121.0851), 1.0),
    WeightedLatLng(LatLng(14.5770, 121.0860), 1.0),
    WeightedLatLng(LatLng(14.5750, 121.0840), 1.0),
    WeightedLatLng(LatLng(14.5995, 120.9842), 1.0),
    WeightedLatLng(LatLng(14.6000, 120.9850), 1.0),
    WeightedLatLng(LatLng(14.5980, 120.9830), 1.0),
    WeightedLatLng(LatLng(14.6091, 121.0223), 1.0),
    WeightedLatLng(LatLng(14.6100, 121.0230), 1.0),
    WeightedLatLng(LatLng(14.6080, 121.0210), 1.0),
    WeightedLatLng(LatLng(14.6760, 121.0437), 1.0),
    WeightedLatLng(LatLng(14.6770, 121.0450), 1.0),
    WeightedLatLng(LatLng(14.6750, 121.0420), 1.0),
    WeightedLatLng(LatLng(14.5200, 121.0100), 1.0),
    WeightedLatLng(LatLng(14.6500, 120.9800), 1.0),
    WeightedLatLng(LatLng(14.7000, 121.0500), 1.0),
    WeightedLatLng(LatLng(14.4800, 120.9900), 1.0),
  ];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAQI();
  }

  Future fetchAQI() async {
    final url = Uri.parse(
        "https://api.airvisual.com/v2/nearest_city?lat=14.5764&lon=121.0851&key=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          airData = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        debugPrint("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Metro Manila Air Quality"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : airData == null
              ? const Center(child: Text("Failed to load AQI data"))
              : Stack(
                  children: [
                    // --- MAP fills entire screen ---
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(14.5764, 121.0851),
                        initialZoom: 11.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        ),
                        HeatMapLayer(
                          heatMapDataSource:
                              InMemoryHeatMapDataSource(data: heatMapData),
                          heatMapOptions: HeatMapOptions(
                            gradient: {
                              0.0: Colors.green,
                              0.25: Colors.blue,
                              0.55: Colors.yellow,
                              0.85: Colors.orange,
                              1.0: Colors.red,
                            },
                            minOpacity: 0.8,
                            radius: 200,
                          ),
                        ),
                      ],
                    ),

                    // --- AQI OVERLAY on top of map ---
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          // AQI main card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("AQI",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey)),
                                    Text(
                                      airData!['data']['current']['pollution']
                                              ['aqius']
                                          .toString(),
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Main pollutant: ${airData!['data']['current']['pollution']['mainus']}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                // AQI color indicator
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _aqiColor(airData!['data']['current']
                                        ['pollution']['aqius']),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _aqiLabel(airData!['data']['current']
                                          ['pollution']['aqius']),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Weather info row
                          Row(
                            children: [
                              Expanded(
                                child: _overlayInfoCard(
                                  "🌡 Temp",
                                  "${airData!['data']['current']['weather']['tp']}°C",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _overlayInfoCard(
                                  "💧 Humidity",
                                  "${airData!['data']['current']['weather']['hu']}%",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _overlayInfoCard(
                                  "🌬 Wind",
                                  "${airData!['data']['current']['weather']['ws']} m/s",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _overlayInfoCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy\nSensitive";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very\nUnhealthy";
    return "Hazardous";
  }
}