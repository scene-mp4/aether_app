import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Lightweight AI service wrapper.
///
/// This is a placeholder implementation. Replace `query()` body with
/// real Google Gemini API calls and supply credentials via secure storage.
class AiService {
  AiService();

  /// Query the assistant. The [context] injection should be built in the
  /// caller; here we accept a simple prompt string and return a reply.
  Future<String> query(String prompt) async {
    // For now, return a canned response after a short delay to simulate
    // network latency. Replace this with real API integration.
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      // Example of how you might call a REST endpoint (not enabled here).
      // final resp = await http.post(
      //   Uri.parse('https://api.example.com/generate'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'prompt': prompt}),
      // );
      // if (resp.statusCode == 200) {
      //   final data = jsonDecode(resp.body);
      //   return data['text'] as String? ?? 'No reply';
      // }

      // Fallback simulated reply that demonstrates context-awareness.
      if (prompt.toLowerCase().contains('aqi') || prompt.toLowerCase().contains('pm2')) {
        return 'Based on the current readings, PM2.5 is high — consider increasing ventilation and wearing a mask indoors. I can explain what each pollutant means.';
      }

      return 'Hi — I\'m your AETHER assistant. Ask me about air quality, readings, or what actions to take.';
    } catch (e) {
      if (kDebugMode) print('AiService error: $e');
      rethrow;
    }
  }
}
