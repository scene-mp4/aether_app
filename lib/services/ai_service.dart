import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '../stores/app_data_store.dart';

class AiService {
  // API key is loaded from --dart-define at build time.
  // Never hardcode the key here — use the setup instructions in .env.example.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late GenerativeModel _model;
  late ChatSession     _chat;

  AiService() {
    _initSession();
  }

  void _initSession() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are AETHER Assistant, an air quality expert embedded in the '
        'AETHER indoor air quality monitoring app for senior healthcare '
        'facilities in the Philippines.\n\n'
        'Your role:\n'
        '- Help healthcare staff understand sensor readings and AQI scores\n'
        '- Explain what pollutants mean in plain, non-technical language\n'
        '- Recommend practical actions to protect elderly residents\n'
        '- Interpret trends and alert conditions\n\n'
        'Guidelines:\n'
        '- Be concise — keep replies under 120 words unless more detail is asked for\n'
        '- Be calm and non-alarmist unless a situation is genuinely dangerous\n'
        '- Always relate advice to the specific readings shown if provided\n'
        '- Never make medical diagnoses or replace emergency protocols\n'
        '- If CO is at dangerous levels, be direct and urgent\n'
        '- Use simple language appropriate for nursing and care staff',
      ),
    );
    _chat = _model.startChat();
  }

  String _buildContext(BuildContext context) {
    try {
      final store    = Provider.of<AppDataStore>(context, listen: false);
      final trackers = store.trackers;
      if (trackers.isEmpty) return '';

      final buf = StringBuffer();
      buf.writeln('=== CURRENT SENSOR READINGS ===');
      for (final t in trackers) {
        final r = store.readingFor(t.id);
        if (r == null) continue;
        buf.writeln('Tracker: ${t.deviceName}'
            '${t.location.isNotEmpty ? ' (${t.location})' : ''}');
        buf.writeln('  Overall IAQI: ${r.iaqi} — ${r.iaqiLabel}');
        buf.writeln('  CO:       ${r.coPpm.toStringAsFixed(1)} ppm'
            '${r.coAlert ? '  ← ALERT' : ''}');
        buf.writeln('  CO₂:      ${r.co2Ppm.toStringAsFixed(0)} ppm'
            '${r.co2Alert ? '  ← ELEVATED' : ''}');
        buf.writeln('  PM2.5:    ${r.pm25Ugm3.toStringAsFixed(1)} µg/m³'
            '${r.pm25Alert ? '  ← ELEVATED' : ''}');
        buf.writeln('  PM10:     ${r.pm10Ugm3.toStringAsFixed(1)} µg/m³');
        buf.writeln('  LPG:      ${r.lpgPpm.toStringAsFixed(0)} ppm'
            '${r.lpgAlert ? '  ← ALERT' : ''}');
        buf.writeln('  Temp:     ${r.temperatureC.toStringAsFixed(1)}°C');
        buf.writeln('  Humidity: ${r.humidityPct.toStringAsFixed(0)}%');
        buf.writeln('  Heat Index: ${r.heatIndexC.toStringAsFixed(1)}°C');
        buf.writeln();
      }
      buf.writeln('=== END READINGS ===');
      return buf.toString();
    } catch (e, st) {
      if (kDebugMode) {
        print('[AiService] _buildContext error: $e');
        print(st);
      }
      return '';
    }
  }

  Future<String> query(String prompt, {BuildContext? context}) async {
    // Guard: catch placeholder key before making any network call
    if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.trim().isEmpty) {
      if (kDebugMode) print('[AiService] API key not set.');
      return 'Gemini API key is not configured. '
          'Replace YOUR_GEMINI_API_KEY in ai_service.dart '
          'with your key from aistudio.google.com.';
    }

    try {
      String fullMessage = prompt;
      if (context != null && context.mounted) {
        final sensorCtx = _buildContext(context);
        if (sensorCtx.isNotEmpty) {
          fullMessage = '$sensorCtx\nStaff question: $prompt';
        }
      }

      if (kDebugMode) {
        print('[AiService] Sending to Gemini...');
        print('[AiService] Message length: ${fullMessage.length} chars');
      }

      final response = await _chat.sendMessage(Content.text(fullMessage));

      if (kDebugMode) {
        print('[AiService] Response received.');
        print('[AiService] Response text: ${response.text}');
      }

      return response.text?.trim() ??
          'Gemini returned an empty response. Please try again.';

    } on GenerativeAIException catch (e, st) {
      // Catches all errors thrown by the google_generative_ai SDK
      if (kDebugMode) {
        print('[AiService] GenerativeAIException: ${e.message}');
        print(st);
      }
      final msg = e.message.toLowerCase();
      if (msg.contains('api key') || msg.contains('api_key') ||
          msg.contains('invalid') || msg.contains('401')) {
        return 'Invalid Gemini API key. Check your key in ai_service.dart.';
      }
      if (msg.contains('quota') || msg.contains('429') ||
          msg.contains('resource exhausted')) {
        return 'Gemini quota exceeded. Wait a moment and try again.';
      }
      if (msg.contains('blocked') || msg.contains('safety')) {
        return 'The response was blocked by Gemini safety filters. '
            'Try rephrasing your question.';
      }
      return 'Gemini error: ${e.message}';

    } catch (e, st) {
      // Catches network errors, timeouts, and anything else
      if (kDebugMode) {
        print('[AiService] Unexpected error: $e');
        print('[AiService] Error type: ${e.runtimeType}');
        print(st);
      }
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('network') ||
          msg.contains('connection')) {
        return 'No internet connection. Check your network and try again.';
      }
      if (msg.contains('timeout')) {
        return 'Request timed out. Check your connection and try again.';
      }
      // Return the raw error in debug mode so you can see exactly what failed
      if (kDebugMode) {
        return 'Error (debug): ${e.runtimeType}: $e';
      }
      return 'Something went wrong. Please try again.';
    }
  }

  void reset() {
    _initSession();
    if (kDebugMode) print('[AiService] Chat session reset');
  }
}