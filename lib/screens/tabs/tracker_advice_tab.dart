import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/app_data_store.dart';
import '../../models/tracker_reading.dart';
import '../../models/tracker_history.dart';

class TrackerAdviceTab extends StatelessWidget {
  final String          deviceId;
  final TrackerReading? reading; // optional — already resolved by parent

  const TrackerAdviceTab({
    super.key,
    required this.deviceId,
    this.reading,
  });

  // ── AQI helpers ────────────────────────────────────────────────────────────
  Color _aqiColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFF22C55E);
    if (aqi <= 100) return const Color(0xFFEAB308);
    if (aqi <= 150) return const Color(0xFFF97316);
    if (aqi <= 200) return const Color(0xFFEF4444);
    if (aqi <= 300) return const Color(0xFF9333EA);
    return const Color(0xFF7F1D1D);
  }

  String _aqiLabel(int aqi) {
    if (aqi <= 50)  return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  // ── Derive overall risk level from reading ─────────────────────────────────
  // Returns 0=good, 1=moderate, 2=unhealthy, 3=dangerous
  int _riskLevel(TrackerReading r) {
    if (r.coAlert || r.iaqi > 200)  return 3;
    if (r.pm25Alert || r.iaqi > 100) return 2;
    if (r.lpgAlert || r.iaqi > 50)  return 1;
    return 0;
  }

  // ── Build the full list of advice items from live data ─────────────────────
  List<_AdviceItem> _buildAdvice(TrackerReading r, TrackerHistory? history) {
    final items = <_AdviceItem>[];
    final risk  = _riskLevel(r);

    // ── CO (Carbon Monoxide) ────────────────────────────────────────────────
    if (r.coAlert || r.coPpm > 9) {
      final urgent = r.coPpm > 35;
      items.add(_AdviceItem(
        category:    'Carbon Monoxide (CO)',
        icon:        Icons.warning_amber_rounded,
        iconColor:   urgent ? const Color(0xFFEF4444) : const Color(0xFFD97706),
        bgColor:     urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFEFCE8),
        borderColor: urgent ? const Color(0xFFFECACA) : const Color(0xFFFEF08A),
        severity:    urgent ? 'Alert' : 'Caution',
        severityColor: urgent
            ? const Color(0xFFEF4444)
            : const Color(0xFFD97706),
        headline: urgent
            ? 'Dangerous CO level detected — act immediately'
            : 'Elevated CO detected — monitor closely',
        details: urgent
            ? 'CO is at ${r.coPpm.toStringAsFixed(1)} ppm, which is above the '
              'safe threshold of 35 ppm. Open all windows and doors immediately. '
              'Move all occupants, especially elderly residents, to fresh air. '
              'Identify and switch off any combustion sources (gas appliances, '
              'generators, vehicles nearby).'
            : 'CO is at ${r.coPpm.toStringAsFixed(1)} ppm (normal: 0–9 ppm). '
              'Ensure adequate ventilation. Check gas appliances are properly '
              'maintained and that kitchen exhausts are working.',
        actions: urgent
            ? const [
                'Open all windows and doors',
                'Move occupants to fresh air',
                'Switch off gas appliances',
                'Call emergency services if residents feel unwell',
              ]
            : const [
                'Improve room ventilation',
                'Check kitchen and cooking area exhaust fans',
                'Schedule gas appliance maintenance',
              ],
      ));
    }

    // ── LPG / Smoke ─────────────────────────────────────────────────────────
    if (r.lpgAlert || r.lpgPpm > 200) {
      final urgent = r.lpgPpm > 1000;
      items.add(_AdviceItem(
        category:    'LPG / Combustible Gas',
        icon:        Icons.local_fire_department_outlined,
        iconColor:   urgent ? const Color(0xFFEF4444) : const Color(0xFFF97316),
        bgColor:     urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED),
        borderColor: urgent ? const Color(0xFFFECACA) : const Color(0xFFFFEDD5),
        severity:    urgent ? 'Dangerous' : 'Elevated',
        severityColor: urgent
            ? const Color(0xFFEF4444)
            : const Color(0xFFF97316),
        headline: urgent
            ? 'High combustible gas — possible leak'
            : 'Combustible gas elevated above baseline',
        details: urgent
            ? 'LPG reading is ${r.lpgPpm.toStringAsFixed(0)} ppm — significantly '
              'above the safe threshold. Do NOT use any open flames or electrical '
              'switches. Ventilate immediately and evacuate if odour is strong.'
            : 'LPG/smoke reading is ${r.lpgPpm.toStringAsFixed(0)} ppm. '
              'This may be from cooking or nearby activity. '
              'Ensure exhaust fans are active and the area is well ventilated.',
        actions: urgent
            ? const [
                'Do NOT use open flames or light switches',
                'Evacuate the area immediately',
                'Ventilate by opening windows from outside',
                'Call the gas provider if leak is suspected',
              ]
            : const [
                'Turn on kitchen exhaust fans',
                'Open windows to ventilate',
                'Check for any cooking or burning activity nearby',
              ],
      ));
    }

    // ── PM2.5 ───────────────────────────────────────────────────────────────
    if (r.pm25Alert || r.pm25Aqi > 50) {
      final urgent = r.pm25Aqi > 150;
      items.add(_AdviceItem(
        category:    'Fine Particles (PM2.5)',
        icon:        Icons.grain,
        iconColor:   urgent ? const Color(0xFFEF4444) : const Color(0xFFEAB308),
        bgColor:     urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFEFCE8),
        borderColor: urgent ? const Color(0xFFFECACA) : const Color(0xFFFEF08A),
        severity:    urgent ? 'Unhealthy' : 'Moderate',
        severityColor: urgent
            ? const Color(0xFFEF4444)
            : const Color(0xFFD97706),
        headline: urgent
            ? 'Fine particle levels are unhealthy'
            : 'Moderate fine particle levels',
        details: 'PM2.5 is ${r.pm25Ugm3.toStringAsFixed(1)} µg/m³ '
            '(AQI: ${r.pm25Aqi}). Fine particles this small can penetrate deep '
            'into the lungs and are especially harmful to elderly residents with '
            'existing respiratory or cardiovascular conditions.',
        actions: urgent
            ? const [
                'Keep elderly residents in filtered air areas',
                'Close windows if outdoor air is the source',
                'Run air purifiers if available',
                'Limit physical activity indoors',
              ]
            : const [
                'Consider running an air purifier',
                'Sensitive residents should reduce physical activity',
                'Monitor levels — if rising, improve ventilation',
              ],
      ));
    }

    // ── CO₂ ─────────────────────────────────────────────────────────────────
    if (r.co2Ppm > 1000) {
      final urgent = r.co2Ppm > 2000;
      items.add(_AdviceItem(
        category:    'Carbon Dioxide (CO₂)',
        icon:        Icons.air,
        iconColor:   urgent ? const Color(0xFFF97316) : const Color(0xFF3B82F6),
        bgColor:     urgent ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
        borderColor: urgent ? const Color(0xFFFFEDD5) : const Color(0xFFBFDBFE),
        severity:    urgent ? 'Poor Air' : 'Stuffy',
        severityColor: urgent
            ? const Color(0xFFF97316)
            : const Color(0xFF3B82F6),
        headline: urgent
            ? 'Very high CO₂ — significant ventilation needed'
            : 'Elevated CO₂ indicates poor ventilation',
        details: 'CO₂ is at ${r.co2Ppm.toStringAsFixed(0)} ppm '
            '(ideal: below 1000 ppm). High CO₂ in a room indicates the air is '
            'not being refreshed. This leads to drowsiness and reduced '
            'concentration — particularly concerning in care environments.',
        actions: urgent
            ? const [
                'Open multiple windows immediately',
                'Run ventilation fans or HVAC on fresh air mode',
                'Reduce occupancy in the affected room',
                'Check HVAC filters — they may be blocked',
              ]
            : const [
                'Open a window or door to let in fresh air',
                'Turn on a ventilation fan',
                'Take a short break outdoors if possible',
              ],
      ));
    }

    // ── Temperature ─────────────────────────────────────────────────────────
    if (r.temperatureC > 35 || r.temperatureC < 10) {
      final tooHot  = r.temperatureC > 35;
      items.add(_AdviceItem(
        category:  'Temperature',
        icon:      Icons.thermostat,
        iconColor: tooHot
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6),
        bgColor:     tooHot ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
        borderColor: tooHot ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
        severity:    tooHot ? 'Too Hot' : 'Too Cold',
        severityColor: tooHot
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6),
        headline: tooHot
            ? 'High temperature — heat stress risk for elderly'
            : 'Low temperature — cold stress risk',
        details: tooHot
            ? 'Temperature is ${r.temperatureC.toStringAsFixed(1)}°C. '
              'Elderly residents are at increased risk of heat exhaustion and '
              'heat stroke above 35°C. Ensure cooling is available and residents '
              'stay hydrated.'
            : 'Temperature is ${r.temperatureC.toStringAsFixed(1)}°C. '
              'Cold environments increase the risk of hypothermia, especially '
              'for elderly and immunocompromised residents.',
        actions: tooHot
            ? const [
                'Turn on air conditioning or fans',
                'Offer cool drinks to all residents',
                'Check on residents with heart or respiratory conditions',
                'Draw curtains to block direct sunlight',
              ]
            : const [
                'Increase heating in affected areas',
                'Ensure residents are dressed warmly',
                'Provide warm drinks',
                'Check heating system is functioning correctly',
              ],
      ));
    }

    // ── Humidity ────────────────────────────────────────────────────────────
    if (r.humidityPct > 80 || r.humidityPct < 20) {
      final tooHigh = r.humidityPct > 80;
      items.add(_AdviceItem(
        category:    'Humidity',
        icon:        Icons.water_drop_outlined,
        iconColor:   tooHigh
            ? const Color(0xFFEF4444)
            : const Color(0xFFEAB308),
        bgColor:     const Color(0xFFEFF6FF),
        borderColor: const Color(0xFFBFDBFE),
        severity:    tooHigh ? 'High Risk' : 'Very Dry',
        severityColor: tooHigh
            ? const Color(0xFFEF4444)
            : const Color(0xFFD97706),
        headline: tooHigh
            ? 'High humidity — mould and respiratory risk'
            : 'Very dry air — respiratory irritation risk',
        details: tooHigh
            ? 'Humidity is ${r.humidityPct.toStringAsFixed(0)}% '
              '(ideal: 30–60%). Prolonged high humidity encourages mould and '
              'dust mite growth, worsening respiratory conditions.'
            : 'Humidity is ${r.humidityPct.toStringAsFixed(0)}% '
              '(ideal: 30–60%). Very dry air irritates the respiratory tract '
              'and may worsen asthma.',
        actions: tooHigh
            ? const [
                'Run a dehumidifier if available',
                'Increase ventilation by opening windows',
                'Check for water leaks or wet surfaces',
                'Monitor residents with asthma or allergies',
              ]
            : const [
                'Use a humidifier to add moisture to the air',
                'Ensure residents drink adequate fluids',
                'Avoid using heating that further dries the air',
              ],
      ));
    }

    // ── History-based trend advice ──────────────────────────────────────────
    if (history != null && history.readings.length >= 6) {
      final recentReadings = history.readings;
      final half = recentReadings.length ~/ 2;

      double avgPm(List<TrackerReading> rs) =>
          rs.map((x) => x.pm25Ugm3).reduce((a, b) => a + b) / rs.length;

      final firstPm  = avgPm(recentReadings.sublist(0, half));
      final secondPm = avgPm(recentReadings.sublist(half));

      if (secondPm > firstPm * 1.2) {
        items.add(_AdviceItem(
          category:    'Air Quality Trend',
          icon:        Icons.trending_up,
          iconColor:   const Color(0xFFD97706),
          bgColor:     const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          severity:    'Rising',
          severityColor: const Color(0xFFD97706),
          headline:    'PM2.5 is trending upward',
          details:     'Recent readings show PM2.5 has increased by '
              '${((secondPm - firstPm) / firstPm * 100).toStringAsFixed(0)}% '
              'over the monitored period. If this trend continues, air quality '
              'may deteriorate further.',
          actions: const [
            'Investigate potential pollution sources nearby',
            'Improve ventilation before levels worsen',
            'Consider running an air purifier proactively',
          ],
        ));
      }
    }

    // ── All good ────────────────────────────────────────────────────────────
    if (items.isEmpty) {
      items.add(_AdviceItem(
        category:    'All Metrics',
        icon:        Icons.check_circle_outline,
        iconColor:   const Color(0xFF22C55E),
        bgColor:     const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFDCFCE7),
        severity:    'Good',
        severityColor: const Color(0xFF22C55E),
        headline:    'Air quality is good — no action needed',
        details:     'All monitored pollutants are within safe ranges. '
            'Current conditions are suitable for all occupants including '
            'elderly residents. Continue monitoring and maintain current '
            'ventilation practices.',
        actions: const [
          'Maintain current ventilation practices',
          'Continue regular sensor checks',
          'Keep windows open when outdoor air quality allows',
        ],
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        // Use pre-resolved reading from parent if provided,
        // otherwise pull from store directly.
        final r       = reading ?? store.readingFor(deviceId);
        final history = store.historyFor(deviceId);
        final hasData = r != null;

        final iaqi      = r?.iaqi      ?? 0;
        final aqiLabel  = _aqiLabel(iaqi);
        final aqiColor  = _aqiColor(iaqi);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Overall status banner ──────────────────────────────────────
            _buildStatusBanner(hasData, iaqi, aqiLabel, aqiColor, r),
            const SizedBox(height: 16),

            // ── Intro text ─────────────────────────────────────────────────
            const Text(
              'Advice for Healthcare Staff',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Recommendations below are based on current sensor readings '
              'and recent trends. Priority items appear first.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4),
            ),
            const SizedBox(height: 16),

            // ── No data state ──────────────────────────────────────────────
            if (!hasData)
              _buildNoDataCard()

            // ── Advice cards ───────────────────────────────────────────────
            else ...[
              ..._buildAdvice(r!, history)
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdviceCard(item: item),
                      )),

              // ── General best practices (always shown) ──────────────────
              const SizedBox(height: 4),
              _buildBestPracticesCard(),
            ],

            // ── Disclaimer ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildDisclaimer(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(bool hasData, int iaqi, String label,
      Color color, TrackerReading? r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                hasData ? '$iaqi' : '--',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? label : 'Waiting for readings',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData
                      ? _summaryLine(r!)
                      : 'Connect your tracker to see advice.',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _summaryLine(TrackerReading r) {
    if (r.coAlert) return 'CO alert active — immediate action required.';
    if (r.iaqi > 200)
      return 'Very unhealthy air — limit all occupant exposure.';
    if (r.iaqi > 150) return 'Unhealthy air — take protective measures.';
    if (r.iaqi > 100)
      return 'Sensitive groups may be affected — monitor closely.';
    if (r.iaqi > 50)
      return 'Acceptable air quality — watch for changes.';
    return 'All conditions are within safe ranges.';
  }

  // ── No data card ───────────────────────────────────────────────────────────
  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.sensors_off_outlined,
              size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('No readings available',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569))),
          SizedBox(height: 6),
          Text(
            'Make sure your tracker is powered on and connected to WiFi. '
            'Advice will appear once sensor data is received.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── General best practices card ────────────────────────────────────────────
  Widget _buildBestPracticesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.health_and_safety_outlined,
                color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Text('General Best Practices',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 12),
          ...[
            ('Ventilate regularly',
                'Open windows for at least 10 minutes every hour when outdoor air quality allows.'),
            ('Monitor high-risk residents',
                'Elderly residents with heart or lung conditions are most '
                    'sensitive to air quality changes. Check on them first.'),
            ('Respond early',
                'Act on caution-level alerts before they escalate. '
                    'It is easier to prevent poor air quality than to resolve it.'),
            ('Keep sensors clear',
                'Ensure sensor units are not blocked by furniture, curtains, '
                    'or placed near cooking areas where readings may be misleading.'),
          ].map((pair) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle,
                        size: 6,
                        color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.4),
                          children: [
                            TextSpan(
                                text: '${pair.$1}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155))),
                            TextSpan(text: pair.$2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline,
              size: 16, color: Color(0xFF94A3B8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This advice is generated from sensor readings and established '
              'air quality guidelines (WHO, EPA, OSHA). It is intended to '
              'assist healthcare staff — it does not replace professional '
              'medical or safety judgement. Always follow your facility\'s '
              'emergency protocols for critical situations.',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}


// Data model for a single advice item

class _AdviceItem {
  final String        category;
  final IconData      icon;
  final Color         iconColor;
  final Color         bgColor;
  final Color         borderColor;
  final String        severity;
  final Color         severityColor;
  final String        headline;
  final String        details;
  final List<String>  actions;

  const _AdviceItem({
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.severity,
    required this.severityColor,
    required this.headline,
    required this.details,
    required this.actions,
  });
}


// Advice card widget

class _AdviceCard extends StatefulWidget {
  final _AdviceItem item;
  const _AdviceCard({required this.item});

  @override
  State<_AdviceCard> createState() => _AdviceCardState();
}

class _AdviceCardState extends State<_AdviceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      decoration: BoxDecoration(
        color: item.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card header ──────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        color: item.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item.category,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.severityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(item.severity,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: item.severityColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item.headline,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                height: 1.3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────────────────────
          if (_expanded)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Detail text
                  Text(item.details,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.5)),
                  const SizedBox(height: 12),

                  // Recommended actions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recommended Actions',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155))),
                        const SizedBox(height: 8),
                        ...item.actions.map((action) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: item.iconColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(action,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                            height: 1.3)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}