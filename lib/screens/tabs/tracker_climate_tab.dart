import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/app_data_store.dart';
import '../../models/tracker_reading.dart';
import '../../models/tracker_history.dart';
import 'tracker_history_tab.dart' show ChartPainter;

class TrackerClimateTab extends StatefulWidget {
  final String deviceId;
  const TrackerClimateTab({super.key, required this.deviceId});

  @override
  State<TrackerClimateTab> createState() => _TrackerClimateTabState();
}

class _TrackerClimateTabState extends State<TrackerClimateTab> {
  int  _tempDays = 1;
  int  _humDays  = 1;
  bool _fetchTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetchTriggered) {
      _fetchTriggered = true;
      Future.microtask(() {
        if (mounted) {
          context.read<AppDataStore>().fetchHistory(
            widget.deviceId,
            days: 1,
          );
        }
      });
    }
  }

  void _refetch(int days) {
    context.read<AppDataStore>().fetchHistory(
      widget.deviceId,
      days: days,
      forceRefresh: true,
    );
  }

  List<TrackerReading> _subsample(List<TrackerReading> r, {int max = 30}) {
    if (r.length <= max) return r;
    final step = (r.length / max).ceil();
    final out  = <TrackerReading>[];
    for (int i = 0; i < r.length; i += step) out.add(r[i]);
    return out;
  }

  List<double> _normalise(List<TrackerReading> r,
      double Function(TrackerReading) pick, double maxVal) {
    if (r.isEmpty) return const [0.0];
    return r.map((x) {
      final v = pick(x).clamp(0.0, maxVal);
      return maxVal > 0 ? v / maxVal : 0.0;
    }).toList();
  }

  List<String> _xLabels(List<TrackerReading> r, int days) {
    if (r.isEmpty) return const ['--'];
    const want = 5;
    final step = (r.length / want).ceil().clamp(1, r.length);
    final out  = <String>[];
    for (int i = 0; i < r.length; i += step) {
      final dt = r[i].timestamp;
      out.add(days == 1
          ? '${dt.hour.toString().padLeft(2, '0')}:00'
          : '${dt.month}/${dt.day}');
    }
    return out;
  }

  // ── Status helpers ────────────────────────────────────────────────────────
  String _tempStatus(double t) {
    if (t < 10)            return 'Extreme Cold';
    if (t < 18)            return 'Cool';
    if (t <= 30)           return 'Comfort';
    if (t <= 35)           return 'Warm';
    return                        'Extreme Heat';
  }

  Color _tempColor(double t) {
    if (t < 10)  return const Color(0xFF3B82F6);
    if (t < 18)  return const Color(0xFF60A5FA);
    if (t <= 30) return const Color(0xFF22C55E);
    if (t <= 35) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }

  String _humStatus(double h) {
    if (h < 20)  return 'Very Dry';
    if (h < 30)  return 'Dry';
    if (h <= 60) return 'Ideal';
    if (h <= 80) return 'Moderate';
    return              'High Risk';
  }

  Color _humColor(double h) {
    if (h < 20)  return const Color(0xFFEF4444);
    if (h < 30)  return const Color(0xFFEAB308);
    if (h <= 60) return const Color(0xFF22C55E);
    if (h <= 80) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }

  String _absHumStatus(double a) {
    if (a < 6)   return 'Very Dry';
    if (a <= 10) return 'Comfortable Dry';
    if (a <= 14) return 'Comfortable';
    if (a <= 18) return 'Humid';
    return              'Very Humid';
  }

  String _heatIdxStatus(double h) {
    if (h < 27)  return 'Comfortable';
    if (h <= 32) return 'Caution';
    if (h <= 39) return 'Extreme Caution';
    if (h <= 51) return 'Danger';
    return              'Extreme Danger';
  }

  Color _heatIdxColor(double h) {
    if (h < 27)  return const Color(0xFF22C55E);
    if (h <= 32) return const Color(0xFFEAB308);
    if (h <= 39) return const Color(0xFFF97316);
    if (h <= 51) return const Color(0xFFEF4444);
    return const Color(0xFF7F1D1D);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final reading = store.readingFor(widget.deviceId);
        final history = store.historyFor(widget.deviceId);
        final loading = store.historyLoadingFor(widget.deviceId);

        final temp    = reading?.temperatureC   ?? 0.0;
        final hum     = reading?.humidityPct    ?? 0.0;
        final absHum  = reading?.absHumidityGm3 ?? 0.0;
        final heatIdx = reading?.heatIndexC     ?? 0.0;
        final hasData = reading != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current climate metrics grid ──────────────────────────────
            _buildCurrentMetricsCard(hasData, temp, hum, absHum, heatIdx),
            const SizedBox(height: 16),

            // ── Temperature history ───────────────────────────────────────
            _buildChartCard(
              title:   'Temperature History',
              days:    _tempDays,
              loading: loading,
              history: history,
              legend:  Row(children: const [
                _Dot(color: Color(0xFFEF4444)), SizedBox(width: 4),
                Text('Temperature (°C)',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ]),
              onDaysChanged: (d) {
                setState(() => _tempDays = d);
                _refetch(d);
              },
              buildPainter: (r, days) {
                final sub = _subsample(r);
                return ChartPainter(
                  lineColor:        const Color(0xFFEF4444),
                  yLabels:          const ['40', '35', '30', '25', '20'],
                  xLabels:          _xLabels(sub, days),
                  normalizedPoints: _normalise(sub, (x) => x.temperatureC - 20, 20),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Humidity history ──────────────────────────────────────────
            _buildChartCard(
              title:   'Humidity History',
              days:    _humDays,
              loading: loading,
              history: history,
              legend:  Row(children: const [
                _Dot(color: Color(0xFF3B82F6)), SizedBox(width: 4),
                Text('Relative Humidity (%)',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ]),
              onDaysChanged: (d) {
                setState(() => _humDays = d);
                _refetch(d);
              },
              buildPainter: (r, days) {
                final sub = _subsample(r);
                return ChartPainter(
                  lineColor:        const Color(0xFF3B82F6),
                  yLabels:          const ['100', '80', '60', '40', '0'],
                  xLabels:          _xLabels(sub, days),
                  normalizedPoints: _normalise(sub, (x) => x.humidityPct, 100),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Comfort analysis card ─────────────────────────────────────
            _buildComfortCard(hasData, temp, hum, absHum, heatIdx),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ── Current metrics grid ──────────────────────────────────────────────────
  Widget _buildCurrentMetricsCard(
    bool hasData, double temp, double hum, double absHum, double heatIdx) {
    String fmt(double v, int d) =>
        hasData ? v.toStringAsFixed(d) : '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Climate',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _MetricTile(
                label:  'Temperature',
                value:  '${fmt(temp, 1)} °C',
                status: _tempStatus(temp),
                color:  _tempColor(temp),
                icon:   Icons.thermostat,
              ),
              _MetricTile(
                label:  'Humidity',
                value:  '${fmt(hum, 0)} %',
                status: _humStatus(hum),
                color:  _humColor(hum),
                icon:   Icons.water_drop_outlined,
              ),
              _MetricTile(
                label:  'Absolute Humidity',
                value:  '${fmt(absHum, 2)} g/m³',
                status: _absHumStatus(absHum),
                color:  const Color(0xFF6366F1),
                icon:   Icons.cloud_outlined,
              ),
              _MetricTile(
                label:  'Heat Index',
                value:  '${fmt(heatIdx, 1)} °C',
                status: _heatIdxStatus(heatIdx),
                color:  _heatIdxColor(heatIdx),
                icon:   Icons.wb_sunny_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart card ────────────────────────────────────────────────────────────
  Widget _buildChartCard({
    required String title,
    required int    days,
    required bool   loading,
    required TrackerHistory? history,
    required Widget legend,
    required ValueChanged<int> onDaysChanged,
    required ChartPainter Function(List<TrackerReading>, int) buildPainter,
  }) {
    final readings = history?.readings ?? const [];
    final hasData  = readings.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
              ),
              ...[1, 7, 30].map((d) {
                final label   = d == 1 ? 'Today' : d == 7 ? '7D' : '30D';
                final selected = days == d;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => onDaysChanged(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF475569))),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          legend,
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: () {
              if (loading && !hasData)
                return const Center(child: CircularProgressIndicator());
              if (!hasData)
                return const Center(
                    child: Text('No data available.',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13)));
              return CustomPaint(
                size: Size.infinite,
                painter: buildPainter(readings, days),
              );
            }(),
          ),
        ],
      ),
    );
  }

  // ── Comfort analysis card ─────────────────────────────────────────────────
  Widget _buildComfortCard(
    bool hasData, double temp, double hum, double absHum, double heatIdx) {
    String comfortSummary =
        'Connect your tracker and wait for readings to appear.';
    String ventAdvice   = '--';
    String humAdvice    = '--';
    Color  comfortColor = const Color(0xFF22C55E);

    if (hasData) {
      // Overall comfort
      if (temp >= 18 && temp <= 30 && hum >= 30 && hum <= 60) {
        comfortSummary = 'Conditions are comfortable for occupants.';
        comfortColor   = const Color(0xFF22C55E);
      } else if (temp > 35 || hum > 80) {
        comfortSummary =
            'Conditions may cause heat stress, especially for elderly residents.';
        comfortColor   = const Color(0xFFEF4444);
      } else {
        comfortSummary =
            'Conditions are slightly outside the ideal comfort range.';
        comfortColor   = const Color(0xFFEAB308);
      }

      // Ventilation
      if (temp > 30 && hum > 70) {
        ventAdvice =
            'High temperature and humidity detected. Run air conditioning or fans.';
      } else if (hum > 80) {
        ventAdvice =
            'Very high humidity — risk of mould growth. Increase ventilation.';
      } else {
        ventAdvice = 'Ventilation appears adequate for current conditions.';
      }

      // Humidity
      if (hum < 30) {
        humAdvice =
            'Air is dry. Consider using a humidifier to improve respiratory comfort.';
      } else if (hum > 70) {
        humAdvice =
            'Humidity is high. Use a dehumidifier or improve airflow.';
      } else {
        humAdvice = 'Humidity is within the ideal range for comfort and health.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comfort Analysis',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: comfortColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: comfortColor.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: comfortColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(comfortSummary,
                      style: TextStyle(
                          fontSize: 13,
                          color: comfortColor,
                          fontWeight: FontWeight.w600,
                          height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (hasData) ...[
            _AdviceItem(
              icon: Icons.air_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Ventilation',
              text: ventAdvice,
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
            ),
            const SizedBox(height: 10),
            _AdviceItem(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF0891B2),
              title: 'Humidity Management',
              text: humAdvice,
              bgColor: const Color(0xFFECFEFF),
              borderColor: const Color(0xFFA5F3FC),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared private widgets ────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String  label;
  final String  value;
  final String  status;
  final Color   color;
  final IconData icon;
  const _MetricTile({
    required this.label, required this.value,
    required this.status, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF64748B))),
          ]),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(status,
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _AdviceItem extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   text;
  final Color    bgColor;
  final Color    borderColor;
  const _AdviceItem({
    required this.icon, required this.iconColor,
    required this.title, required this.text,
    required this.bgColor, required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}