import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../bottom_navbar.dart'; // keep your existing bottom nav import

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final String apiKey = "YOUR_API_KEY"; // replace with your IQAir API key
  Map? airData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAQI();
  }

  Future fetchAQI() async {
    final url = Uri.parse(
        "https://api.airvisual.com/v2/nearest_city?lat=14.5764&lon=121.0851&key=3daccd08-5d7f-41ba-af56-1ce0402607f5");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          airData = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        debugPrint("Failed to fetch AQI: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Error fetching AQI: $e");
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
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Card(
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                "AQI",
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                airData!['data']['current']['pollution']['aqius']
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Main pollutant: ${airData!['data']['current']['pollution']['mainus']}",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          infoCard(
                              "🌡 Temp",
                              "${airData!['data']['current']['weather']['tp']}°C"),
                          infoCard(
                              "💧 Humidity",
                              "${airData!['data']['current']['weather']['hu']}%"),
                          infoCard(
                              "🌬 Wind",
                              "${airData!['data']['current']['weather']['ws']} m/s"),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget infoCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}