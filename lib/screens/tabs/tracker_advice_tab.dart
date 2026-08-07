import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/app_data_store.dart';
import '../../models/tracker_reading.dart';
import '../../models/tracker_history.dart';

class TrackerAdviceTab extends StatelessWidget {
  final String          deviceId;
  final TrackerReading? reading;

  const TrackerAdviceTab({
    super.key,
    required this.deviceId,
    this.reading,
  });

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

  String _summaryLine(TrackerReading r) {
    if (r.coAlert)    return 'CO alert active — immediate action required.';
    if (r.iaqi > 200) return 'Very unhealthy air — limit all occupant exposure.';
    if (r.iaqi > 150) return 'Unhealthy air — take protective measures.';
    if (r.iaqi > 100) return 'Sensitive groups may be affected — monitor closely.';
    if (r.iaqi > 50)  return 'Acceptable air quality — watch for changes.';
    return 'All conditions are within safe ranges.';
  }

  // ── Sensor value lookup ───────────────────────────────────────────────────
  double? _getValue(String trigger, TrackerReading r) {
    switch (trigger) {
      case 'co_ppm':           return r.coPpm;
      case 'co2_ppm':          return r.co2Ppm;
      case 'pm1_ugm3':         return r.pm1Ugm3;
      case 'pm25_ugm3':        return r.pm25Ugm3;
      case 'pm10_ugm3':        return r.pm10Ugm3;
      case 'lpg_ppm':          return r.lpgPpm;
      case 'smoke_ppm':        return r.smokePpm;
      case 'nh3_ppm':          return r.nh3Ppm;
      case 'o3_ppm':           return r.o3Ppm;
      case 'iaqi':             return r.iaqi.toDouble();
      case 'pm25_aqi':         return r.pm25Aqi.toDouble();
      case 'temperature_c':    return r.temperatureC;
      case 'humidity_pct':     return r.humidityPct;
      case 'abs_humidity_gm3': return r.absHumidityGm3;
      case 'heat_index_c':     return r.heatIndexC;
      case 'co_alert':         return r.coAlert   ? 1.0 : 0.0;
      case 'lpg_alert':        return r.lpgAlert  ? 1.0 : 0.0;
      case 'pm25_alert':       return r.pm25Alert ? 1.0 : 0.0;
      case 'co2_alert':        return r.co2Alert  ? 1.0 : 0.0;
      default:                 return null;
    }
  }

  bool _evaluate(Map<String, dynamic> entry, TrackerReading r) {
    final trigger    = entry['trigger']    as String?;
    final comparator = entry['comparator'] as String?;
    final raw        = entry['threshold'];
    if (trigger == null || comparator == null || raw == null) return false;
    final value     = _getValue(trigger, r);
    if (value == null) return false;
    final threshold = (raw as num).toDouble();
    switch (comparator) {
      case 'gt':  return value >  threshold;
      case 'gte': return value >= threshold;
      case 'lt':  return value <  threshold;
      case 'lte': return value <= threshold;
      case 'eq':  return value == threshold;
      default:    return false;
    }
  }

  ({Color icon, Color bg, Color border, Color badge}) _severityColors(String s) {
    switch (s) {
      case 'critical':
        return (icon: const Color(0xFFEF4444), bg: const Color(0xFFFEF2F2),
                border: const Color(0xFFFECACA), badge: const Color(0xFFEF4444));
      case 'warning':
        return (icon: const Color(0xFFD97706), bg: const Color(0xFFFEFCE8),
                border: const Color(0xFFFEF08A), badge: const Color(0xFFD97706));
      default:
        return (icon: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF),
                border: const Color(0xFFBFDBFE), badge: const Color(0xFF2563EB));
    }
  }

  IconData _severityIcon(String s) {
    switch (s) {
      case 'critical': return Icons.warning_amber_rounded;
      case 'warning':  return Icons.error_outline;
      default:         return Icons.info_outline;
    }
  }

  _AdviceItem _toAdviceItem(Map<String, dynamic> entry, TrackerReading r) {
    final severity = (entry['severity'] as String?) ?? 'info';
    final colors   = _severityColors(severity);
    final rawAct   = entry['actions'];
    final actions  = rawAct is List
        ? rawAct.map((e) => e.toString()).toList()
        : <String>[];
    final trigger  = entry['trigger'] as String? ?? '';
    final rawVal   = _getValue(trigger, r);
    String message = (entry['message'] as String?) ?? '';
    if (rawVal != null) {
      final fmt = rawVal % 1 == 0
          ? rawVal.toInt().toString()
          : rawVal.toStringAsFixed(1);
      message = message.replaceAll('{value}', fmt);
    }
    return _AdviceItem(
      category:     (entry['category'] as String?) ?? 'Air Quality',
      icon:         _severityIcon(severity),
      iconColor:    colors.icon,
      bgColor:      colors.bg,
      borderColor:  colors.border,
      severity:     severity[0].toUpperCase() + severity.substring(1),
      severityColor: colors.badge,
      headline:     (entry['title']   as String?) ?? 'Air Quality Alert',
      details:      message,
      actions:      actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final r       = reading ?? store.readingFor(deviceId);
        final history = store.historyFor(deviceId);
        final hasData = r != null;

        final iaqi     = r?.iaqi ?? 0;
        final aqiLabel = _aqiLabel(iaqi);
        final aqiColor = _aqiColor(iaqi);

        final List<_AdviceItem> matched = hasData
            ? store.adviceEntries
                .where((e) => _evaluate(e, r!))
                .map((e) => _toAdviceItem(e, r!))
                .toList()
            : [];

        // History trend item
        if (hasData && history != null && history.readings.length >= 6) {
          final half = history.readings.length ~/ 2;
          double avg(List<TrackerReading> rs) =>
              rs.map((x) => x.pm25Ugm3).reduce((a, b) => a + b) / rs.length;
          final fp = avg(history.readings.sublist(0, half));
          final sp = avg(history.readings.sublist(half));
          if (sp > fp * 1.2) {
            matched.add(_AdviceItem(
              category:     'Air Quality Trend',
              icon:         Icons.trending_up,
              iconColor:    const Color(0xFFD97706),
              bgColor:      const Color(0xFFFEFCE8),
              borderColor:  const Color(0xFFFEF08A),
              severity:     'Warning',
              severityColor: const Color(0xFFD97706),
              headline:     'PM2.5 is trending upward',
              details:      'Recent readings show PM2.5 has increased by '
                  '${((sp - fp) / fp * 100).toStringAsFixed(0)}% '
                  'over the monitored period.',
              actions: const [
                'Investigate potential pollution sources nearby',
                'Improve ventilation before levels worsen',
                'Consider running an air purifier proactively',
              ],
            ));
          }
        }

        // All good fallback
        if (hasData && matched.isEmpty) {
          matched.add(_AdviceItem(
            category:     'All Metrics',
            icon:         Icons.check_circle_outline,
            iconColor:    const Color(0xFF22C55E),
            bgColor:      const Color(0xFFF0FDF4),
            borderColor:  const Color(0xFFDCFCE7),
            severity:     'Good',
            severityColor: const Color(0xFF22C55E),
            headline:     'Air quality is good — no action needed',
            details:      'All monitored pollutants are within safe ranges. '
                'Current conditions are suitable for all occupants including '
                'elderly residents.',
            actions: const [
              'Maintain current ventilation practices',
              'Continue regular sensor checks',
              'Keep windows open when outdoor air quality allows',
            ],
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(hasData, iaqi, aqiLabel, aqiColor, r),
            const SizedBox(height: 16),
            const Text('Advice for Healthcare Staff',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(
              hasData
                  ? '${matched.length} recommendation${matched.length == 1 ? '' : 's'} based on current readings'
                  : 'Recommendations will appear once sensor data is received.',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            if (!hasData)
              _buildNoDataCard()
            else ...[
              ...matched.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdviceCard(item: item),
                  )),
              const SizedBox(height: 4),
              _buildBestPracticesCard(),
            ],
            const SizedBox(height: 16),
            _buildDisclaimer(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

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
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3)),
          child: Center(
            child: Text(hasData ? '$iaqi' : '--',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasData ? label : 'Waiting for readings',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(
              hasData ? _summaryLine(r!) : 'Connect your tracker to see advice.',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF475569), height: 1.3),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(children: [
        Icon(Icons.sensors_off_outlined, size: 40, color: Color(0xFF94A3B8)),
        SizedBox(height: 12),
        Text('No readings available',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569))),
        SizedBox(height: 6),
        Text(
          'Make sure your tracker is powered on and connected to WiFi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
        ),
      ]),
    );
  }

  Widget _buildBestPracticesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              'Elderly residents with heart or lung conditions are most sensitive to air quality changes.'),
          ('Respond early',
              'Act on caution-level alerts before they escalate.'),
          ('Keep sensors clear',
              'Ensure sensor units are not blocked by furniture or placed near cooking areas.'),
        ].map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      children: [
                        TextSpan(
                            text: '${p.$1}: ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155))),
                        TextSpan(text: p.$2),
                      ],
                    ),
                  ),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'This advice is generated from sensor readings and established '
            'air quality guidelines (WHO, EPA, OSHA). It does not replace '
            'professional medical or safety judgement.',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
          ),
        ),
      ]),
    );
  }
}

class _AdviceItem {
  final String       category;
  final IconData     icon;
  final Color        iconColor;
  final Color        bgColor;
  final Color        borderColor;
  final String       severity;
  final Color        severityColor;
  final String       headline;
  final String       details;
  final List<String> actions;
  const _AdviceItem({
    required this.category, required this.icon, required this.iconColor,
    required this.bgColor, required this.borderColor, required this.severity,
    required this.severityColor, required this.headline, required this.details,
    required this.actions,
  });
}

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
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
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(item.severity,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: item.severityColor)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.headline,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.3)),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF64748B), size: 20),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Text(item.details,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF475569), height: 1.5)),
              if (item.actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Recommended Actions',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    ...item.actions.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: item.iconColor,
                                    shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(a,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF334155),
                                        height: 1.3)),
                              ),
                            ],
                          ),
                        )),
                  ]),
                ),
              ],
            ]),
          ),
      ]),
    );
  }
}