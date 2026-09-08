import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../stores/app_data_store.dart';
import '../../models/tracker_reading.dart';
import '../../models/tracker_history.dart';

class TrackerHistoryTab extends StatefulWidget {
  final String deviceId;
  const TrackerHistoryTab({super.key, required this.deviceId});

  @override
  State<TrackerHistoryTab> createState() => _TrackerHistoryTabState();
}

class _TrackerHistoryTabState extends State<TrackerHistoryTab> {
  // Each chart has its own independent day selection
  int _pmDays  = 1;
  int _coDays  = 1;
  int _co2Days = 1;

  bool _fetchTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetchTriggered) {
      _fetchTriggered = true;
      Future.microtask(() {
        if (mounted) {
          context.read<AppDataStore>().fetchHistory(widget.deviceId, days: 1);
        }
      });
    }
  }

  // ── Each chart fetches independently only if more days are needed ─────────
  // FIX: Instead of calling a shared _refetch that replaces the whole history,
  // we keep the maximum days fetched and filter per-chart in _filterReadings.
  int get _maxDays => [_pmDays, _coDays, _co2Days].reduce((a, b) => a > b ? a : b);

  void _onDaysChanged(String chart, int days) {
    setState(() {
      if (chart == 'pm')  _pmDays  = days;
      if (chart == 'co')  _coDays  = days;
      if (chart == 'co2') _co2Days = days;
    });
    // Only refetch if the new selection requires more data than we have
    final store = context.read<AppDataStore>();
    final history = store.historyFor(widget.deviceId);
    final needsMore = history == null ||
        history.from == null ||
        DateTime.now().difference(history.from!).inDays < days - 1;
    if (needsMore) {
      store.fetchHistory(widget.deviceId, days: days, forceRefresh: true);
    }
  }

  // ── Filter readings to the requested day window ────────────────────────────
  // FIX: Each chart calls this independently so changing one chart's time
  // period only affects that chart's data, not the others.
  List<TrackerReading> _filterReadings(
      List<TrackerReading> all, int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    return all.where((r) => r.timestamp.isAfter(from)).toList();
  }

  // ── Chart helpers ─────────────────────────────────────────────────────────
  List<TrackerReading> _subsample(List<TrackerReading> readings,
      {int max = 40}) {
    if (readings.length <= max) return readings;
    final step = (readings.length / max).ceil();
    final out  = <TrackerReading>[];
    for (int i = 0; i < readings.length; i += step) out.add(readings[i]);
    return out;
  }

  List<double> _normalise(List<TrackerReading> readings,
      double Function(TrackerReading) pick, double maxVal) {
    if (readings.isEmpty) return const [0.0];
    return readings.map((r) {
      final v = pick(r).clamp(0.0, maxVal);
      return maxVal > 0 ? v / maxVal : 0.0;
    }).toList();
  }

  List<String> _xLabels(List<TrackerReading> readings, int days) {
    if (readings.isEmpty) return const ['--'];
    const wantedLabels = 5;
    final step =
        (readings.length / wantedLabels).ceil().clamp(1, readings.length);
    final labels = <String>[];
    for (int i = 0; i < readings.length; i += step) {
      final dt = readings[i].timestamp;
      labels.add(days == 1
          ? '${dt.hour.toString().padLeft(2, '0')}:00'
          : '${dt.month}/${dt.day}');
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final history = store.historyFor(widget.deviceId);
        final loading = store.historyLoadingFor(widget.deviceId);
        final allReadings = history?.readings ?? const <TrackerReading>[];

        // FIX: Each chart gets its own independently filtered list of readings.
        // Changing _pmDays only triggers a rebuild of the PM card's data,
        // not the CO or CO₂ cards, because they use different filtered lists.
        final pmReadings  = _filterReadings(allReadings, _pmDays);
        final coReadings  = _filterReadings(allReadings, _coDays);
        final co2Readings = _filterReadings(allReadings, _co2Days);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistorySummaryCard(history: history, loading: loading),
            const SizedBox(height: 16),

            // ── PM chart ────────────────────────────────────────────────────
            // FIX: buildPainter now receives pmReadings (independently filtered)
            // so it only re-renders when PM's own day selection changes.
            _ChartCard(
              title:   'Particulate Matter History',
              days:    _pmDays,
              loading: loading && pmReadings.isEmpty,
              hasData: pmReadings.isNotEmpty,
              onDaysChanged: (d) => _onDaysChanged('pm', d),
              legend: Row(children: const [
                _DotLegend(color: Color(0xFF8B4513), label: 'PM1.0'),
                SizedBox(width: 8),
                _DotLegend(color: Color(0xFFEAB308), label: 'PM2.5'),
                SizedBox(width: 8),
                _DotLegend(color: Color(0xFFEA580C), label: 'PM10'),
              ]),
              buildPainter: () {
                final sub = _subsample(pmReadings);
                // FIX: Multi-line painter — draws PM1, PM2.5, PM10 separately
                return MultiLineChartPainter(
                  xLabels: _xLabels(sub, _pmDays),
                  lines: [
                    ChartLine(
                      color: const Color(0xFF8B4513),
                      points: _normalise(sub, (r) => r.pm1Ugm3, 40),
                    ),
                    ChartLine(
                      color: const Color(0xFFEAB308),
                      points: _normalise(sub, (r) => r.pm25Ugm3, 40),
                    ),
                    ChartLine(
                      color: const Color(0xFFEA580C),
                      points: _normalise(sub, (r) => r.pm10Ugm3, 40),
                    ),
                  ],
                  yLabels: const ['40', '30', '20', '10', '0'],
                );
              },
            ),
            const SizedBox(height: 16),

            // ── CO & O₃ chart ───────────────────────────────────────────────
            _ChartCard(
              title:    'CO & O₃ History',
              subtitle: 'CO in ppm · O₃ in ppb',
              days:     _coDays,
              loading:  loading && coReadings.isEmpty,
              hasData:  coReadings.isNotEmpty,
              onDaysChanged: (d) => _onDaysChanged('co', d),
              legend: Row(children: const [
                _DotLegend(color: Color(0xFFEF4444), label: 'CO (ppm)'),
                SizedBox(width: 12),
                _DotLegend(color: Color(0xFF0D9488), label: 'O₃ (ppb ÷10)'),
              ]),
              buildPainter: () {
                final sub = _subsample(coReadings);
                return MultiLineChartPainter(
                  xLabels: _xLabels(sub, _coDays),
                  lines: [
                    ChartLine(
                      color: const Color(0xFFEF4444),
                      points: _normalise(sub, (r) => r.coPpm, 20),
                    ),
                    ChartLine(
                      color: const Color(0xFF0D9488),
                      // O₃ stored as ppm → *1000 = ppb, normalise to 100 ppb max
                      points: _normalise(
                          sub, (r) => r.o3Ppm * 1000, 100),
                    ),
                  ],
                  yLabels: const ['20', '15', '10', '5', '0'],
                );
              },
            ),
            const SizedBox(height: 16),

            // ── CO₂ chart ───────────────────────────────────────────────────
            _ChartCard(
              title:    'CO₂ History',
              subtitle: 'Carbon Dioxide in ppm',
              days:     _co2Days,
              loading:  loading && co2Readings.isEmpty,
              hasData:  co2Readings.isNotEmpty,
              onDaysChanged: (d) => _onDaysChanged('co2', d),
              legend: const _DotLegend(
                  color: Color(0xFF3B82F6), label: 'CO₂ (ppm)'),
              buildPainter: () {
                final sub = _subsample(co2Readings);
                return MultiLineChartPainter(
                  xLabels: _xLabels(sub, _co2Days),
                  lines: [
                    ChartLine(
                      color: const Color(0xFF3B82F6),
                      points: _normalise(sub, (r) => r.co2Ppm, 2500),
                    ),
                  ],
                  yLabels: const ['2500', '1500', '800', '400', '0'],
                );
              },
            ),
            const SizedBox(height: 16),

            _RecommendationsCard(history: history),
            const SizedBox(height: 16),

            // ── Download button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DownloadHistoryModal(
                    deviceId: widget.deviceId,
                    readings: allReadings,
                  ),
                ),
                icon: const Icon(Icons.download_rounded,
                    color: Colors.white, size: 20),
                label: const Text('Download History Data',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// History summary card
// ═══════════════════════════════════════════════════════════════════════════════

class _HistorySummaryCard extends StatelessWidget {
  final TrackerHistory? history;
  final bool            loading;
  const _HistorySummaryCard({required this.history, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.info_outline, size: 20, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('History Summary',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 12),
          if (loading && history == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Fetching history…',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 13)),
                ]),
              ),
            )
          else if (history == null || history!.readings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No history data available yet.',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 13)),
              ),
            )
          else
            _buildContent(history!),
        ],
      ),
    );
  }

  Widget _buildContent(TrackerHistory history) {
    final readings = history.readings;
    final pm25     = readings.map((r) => r.pm25Ugm3).toList();
    final co2      = readings.map((r) => r.co2Ppm).toList();

    final minPm25 = pm25.reduce((a, b) => a < b ? a : b);
    final maxPm25 = pm25.reduce((a, b) => a > b ? a : b);
    final minCo2  = co2.reduce((a, b) => a < b ? a : b);
    final maxCo2  = co2.reduce((a, b) => a > b ? a : b);

    String ov = '--', md = '--', ev = '--';
    final third = readings.length ~/ 3;
    if (third > 0) {
      double avg(List<TrackerReading> rs) =>
          rs.map((r) => r.pm25Ugm3).reduce((a, b) => a + b) / rs.length;
      ov = 'Avg PM2.5: ${avg(readings.sublist(0, third)).toStringAsFixed(1)} µg/m³';
      md = 'Avg PM2.5: ${avg(readings.sublist(third, third * 2)).toStringAsFixed(1)} µg/m³';
      ev = 'Avg PM2.5: ${avg(readings.sublist(third * 2)).toStringAsFixed(1)} µg/m³';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PM2.5 ranged from ${minPm25.toStringAsFixed(1)} to '
          '${maxPm25.toStringAsFixed(1)} µg/m³. '
          'CO₂ ranged from ${minCo2.toStringAsFixed(0)} to '
          '${maxCo2.toStringAsFixed(0)} ppm.',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        const SizedBox(height: 16),
        _SummaryBlock('Overnight Baseline', ov,
            const Color(0xFF3B82F6), const Color(0xFFEFF6FF),
            const Color(0xFFBFDBFE)),
        const SizedBox(height: 10),
        _SummaryBlock('Midday Period', md,
            const Color(0xFFF97316), const Color(0xFFFFF7ED),
            const Color(0xFFFFEDD5)),
        const SizedBox(height: 10),
        _SummaryBlock('Evening Period', ev,
            const Color(0xFF22C55E), const Color(0xFFF0FDF4),
            const Color(0xFFDCFCE7)),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final String title, desc;
  final Color  dot, bg, border;
  const _SummaryBlock(this.title, this.desc, this.dot, this.bg, this.border);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: dot)),
        ]),
        const SizedBox(height: 6),
        Text(desc,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF334155), height: 1.4)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Generic chart card
// FIX: buildPainter is now a VoidCallback-style getter (() => Painter)
// so each card builds its painter from its own independently filtered data.
// ═══════════════════════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String           title;
  final String?          subtitle;
  final int              days;
  final bool             loading;
  final bool             hasData;
  final ValueChanged<int> onDaysChanged;
  final Widget           legend;
  final MultiLineChartPainter Function() buildPainter;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.days,
    required this.loading,
    required this.hasData,
    required this.onDaysChanged,
    required this.legend,
    required this.buildPainter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + time frame selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.2)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time-frame buttons — only affect THIS card
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TFButton(label: '1D', days: 1,  selected: days == 1,  onTap: () => onDaysChanged(1)),
                  const SizedBox(width: 4),
                  _TFButton(label: '7D', days: 7,  selected: days == 7,  onTap: () => onDaysChanged(7)),
                  const SizedBox(width: 4),
                  _TFButton(label: '30D', days: 30, selected: days == 30, onTap: () => onDaysChanged(30)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          legend,
          const SizedBox(height: 12),

          // Chart area
          SizedBox(
            height: 140,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : !hasData
                    ? const Center(
                        child: Text('No data available.',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13)))
                    : CustomPaint(
                        size: Size.infinite,
                        painter: buildPainter(),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final int    days;
  final bool   selected;
  final VoidCallback onTap;
  const _TFButton(
      {required this.label, required this.days,
       required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                color: selected ? Colors.white : const Color(0xFF475569))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Recommendations card
// ═══════════════════════════════════════════════════════════════════════════════

class _RecommendationsCard extends StatelessWidget {
  final TrackerHistory? history;
  const _RecommendationsCard({required this.history});

  @override
  Widget build(BuildContext context) {
    String rec1Title = 'PM2.5 Trend';
    String rec1Desc  = 'Not enough data yet for trend analysis.';
    String rec2Title = 'CO₂ Ventilation';
    String rec2Desc  = 'Not enough data yet for trend analysis.';

    if (history != null && history!.readings.length >= 4) {
      final r    = history!.readings;
      final half = r.length ~/ 2;

      double avgPm(List<TrackerReading> rs) =>
          rs.map((x) => x.pm25Ugm3).reduce((a, b) => a + b) / rs.length;
      double avgCo2(List<TrackerReading> rs) =>
          rs.map((x) => x.co2Ppm).reduce((a, b) => a + b) / rs.length;

      final firstPm   = avgPm(r.sublist(0, half));
      final secondPm  = avgPm(r.sublist(half));
      final secondCo2 = avgCo2(r.sublist(half));

      if (secondPm > firstPm * 1.1) {
        rec1Title = 'PM2.5 Rising';
        rec1Desc  = 'PM2.5 is trending upward. Consider improving ventilation.';
      } else if (secondPm < firstPm * 0.9) {
        rec1Title = 'PM2.5 Improving';
        rec1Desc  = 'PM2.5 is trending downward. Current ventilation is working well.';
      } else {
        rec1Title = 'PM2.5 Stable';
        rec1Desc  = 'PM2.5 levels are stable. Maintain current ventilation practices.';
      }

      if (secondCo2 > 1500) {
        rec2Title = 'CO₂ Elevated';
        rec2Desc  = 'CO₂ is high — open windows or increase air circulation.';
      } else if (secondCo2 > 1000) {
        rec2Title = 'CO₂ Building Up';
        rec2Desc  = 'CO₂ is gradually increasing. Ensure ventilation is adequate.';
      } else {
        rec2Title = 'CO₂ Well Controlled';
        rec2Desc  = 'CO₂ levels are within a healthy range.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommendations Based on History',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _RecItem(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFFD97706),
            title: rec1Title,
            description: rec1Desc,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
          ),
          const SizedBox(height: 10),
          _RecItem(
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF2563EB),
            title: rec2Title,
            description: rec2Desc,
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
          ),
        ],
      ),
    );
  }
}

class _RecItem extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title, description;
  final Color    bgColor, borderColor;
  const _RecItem({
    required this.icon, required this.iconColor,
    required this.title, required this.description,
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
          Icon(icon, color: iconColor, size: 22),
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
                Text(description,
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

// ═══════════════════════════════════════════════════════════════════════════════
// Download modal — generates and shares a real CSV file
// ═══════════════════════════════════════════════════════════════════════════════

class DownloadHistoryModal extends StatefulWidget {
  final String              deviceId;
  final List<TrackerReading> readings;
  const DownloadHistoryModal(
      {super.key, required this.deviceId, required this.readings});

  @override
  State<DownloadHistoryModal> createState() => _DownloadHistoryModalState();
}

class _DownloadHistoryModalState extends State<DownloadHistoryModal> {
  DateTime?  _startDate;
  DateTime?  _endDate;
  TimeOfDay  _startTime = const TimeOfDay(hour: 0,  minute: 0);
  TimeOfDay  _endTime   = const TimeOfDay(hour: 23, minute: 59);
  bool       _generating = false;

  final Map<String, bool> _pollutants = {
    'PM1.0': true, 'PM2.5': true, 'PM10': true,
    'CO': true, 'CO₂': true, 'O₃': true,
    'Temperature': true, 'Humidity': true,
    'LPG': false, 'NH3': false, 'Smoke': false,
    'IAQI': true,
  };

  bool get _allSelected => _pollutants.values.every((v) => v);
  bool get _canDownload => _startDate != null && _endDate != null;

  Future<void> _pickDate(bool isStart) async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (p != null && mounted) {
      setState(() => isStart ? _startDate = p : _endDate = p);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final p = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (p != null && mounted) {
      setState(() => isStart ? _startTime = p : _endTime = p);
    }
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'dd/mm/yyyy'
      : '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final p = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:${t.minute.toString().padLeft(2, '0')} $p';
  }

  // ── Generate and share CSV ─────────────────────────────────────────────────
  Future<void> _generate() async {
    if (!_canDownload) return;
    setState(() => _generating = true);

    try {
      // Build start/end DateTime from date + time pickers
      final start = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _startTime.hour, _startTime.minute,
      );
      final end = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime.hour, _endTime.minute,
      );

      // Filter readings to selected date/time window
      final filtered = widget.readings
          .where((r) =>
              r.timestamp.isAfter(start) &&
              r.timestamp.isBefore(end.add(const Duration(minutes: 1))))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (filtered.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No readings found in the selected date range.')));
        }
        setState(() => _generating = false);
        return;
      }

      // Build CSV header
      final cols = <String>['Timestamp', 'Date', 'Time'];
      if (_pollutants['PM1.0']!)      cols.add('PM1.0 (µg/m³)');
      if (_pollutants['PM2.5']!)      cols.add('PM2.5 (µg/m³)');
      if (_pollutants['PM10']!)       cols.add('PM10 (µg/m³)');
      if (_pollutants['CO']!)         cols.add('CO (ppm)');
      if (_pollutants['CO₂']!)        cols.add('CO2 (ppm)');
      if (_pollutants['O₃']!)         cols.add('O3 (ppb)');
      if (_pollutants['Temperature']!) cols.add('Temperature (°C)');
      if (_pollutants['Humidity']!)   cols.add('Humidity (%)');
      if (_pollutants['LPG']!)        cols.add('LPG (ppm)');
      if (_pollutants['NH3']!)        cols.add('NH3 (ppm)');
      if (_pollutants['Smoke']!)      cols.add('Smoke (ppm)');
      if (_pollutants['IAQI']!)       cols.add('IAQI');

      final buffer = StringBuffer();
      buffer.writeln(cols.join(','));

      // Build CSV rows
      for (final r in filtered) {
        final row = <String>[
          r.timestamp.toIso8601String(),
          '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2,'0')}-${r.timestamp.day.toString().padLeft(2,'0')}',
          '${r.timestamp.hour.toString().padLeft(2,'0')}:${r.timestamp.minute.toString().padLeft(2,'0')}',
        ];
        if (_pollutants['PM1.0']!)      row.add(r.pm1Ugm3.toStringAsFixed(2));
        if (_pollutants['PM2.5']!)      row.add(r.pm25Ugm3.toStringAsFixed(2));
        if (_pollutants['PM10']!)       row.add(r.pm10Ugm3.toStringAsFixed(2));
        if (_pollutants['CO']!)         row.add(r.coPpm.toStringAsFixed(2));
        if (_pollutants['CO₂']!)        row.add(r.co2Ppm.toStringAsFixed(1));
        if (_pollutants['O₃']!)         row.add((r.o3Ppm * 1000).toStringAsFixed(2));
        if (_pollutants['Temperature']!) row.add(r.temperatureC.toStringAsFixed(1));
        if (_pollutants['Humidity']!)   row.add(r.humidityPct.toStringAsFixed(0));
        if (_pollutants['LPG']!)        row.add(r.lpgPpm.toStringAsFixed(2));
        if (_pollutants['NH3']!)        row.add(r.nh3Ppm.toStringAsFixed(2));
        if (_pollutants['Smoke']!)      row.add(r.smokePpm.toStringAsFixed(2));
        if (_pollutants['IAQI']!)       row.add(r.iaqi.toString());
        buffer.writeln(row.join(','));
      }

      // Write to temp file and share
      final dir  = await getTemporaryDirectory();
      final name = '${widget.deviceId}_'
          '${start.year}${start.month.toString().padLeft(2,'0')}${start.day.toString().padLeft(2,'0')}'
          '_to_'
          '${end.year}${end.month.toString().padLeft(2,'0')}${end.day.toString().padLeft(2,'0')}'
          '.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsString(buffer.toString());

      // Share the file — on Android this opens the share sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'AETHER Readings — ${widget.deviceId}',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')));
      }
    }

    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.file_download_outlined,
                    color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Download History Data',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close,
                    color: Color(0xFF64748B), size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              '${widget.readings.length} readings available — select range and format.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Date range
            const Text('Date Range',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _PickerField(
                  label: 'Start Date',
                  value: _fmtDate(_startDate),
                  icon: Icons.calendar_today_outlined,
                  isPlaceholder: _startDate == null,
                  onTap: () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _PickerField(
                  label: 'End Date',
                  value: _fmtDate(_endDate),
                  icon: Icons.calendar_today_outlined,
                  isPlaceholder: _endDate == null,
                  onTap: () => _pickDate(false))),
            ]),
            const SizedBox(height: 16),

            // Time range
            const Text('Time Range',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _PickerField(
                  label: 'Start Time',
                  value: _fmtTime(_startTime),
                  icon: Icons.access_time_rounded,
                  isPlaceholder: false,
                  onTap: () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(child: _PickerField(
                  label: 'End Time',
                  value: _fmtTime(_endTime),
                  icon: Icons.access_time_rounded,
                  isPlaceholder: false,
                  onTap: () => _pickTime(false))),
            ]),
            const SizedBox(height: 20),

            // Pollutant selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Columns to Include',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                GestureDetector(
                  onTap: () => setState(
                      () => _pollutants.updateAll((_, __) => !_allSelected)),
                  child: Text(_allSelected ? 'Deselect All' : 'Select All',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _pollutants.keys.map((p) {
                final sel = _pollutants[p]!;
                return GestureDetector(
                  onTap: () => setState(() => _pollutants[p] = !sel),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(p,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF475569))),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            if (!_canDownload) ...[
              Row(children: const [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFFD97706), size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Please select both a start and end date.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canDownload && !_generating
                      ? _generate
                      : null,
                  icon: _generating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.download, size: 18),
                  label: Text(_generating ? 'Generating…' : 'Download CSV',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFBFDBFE),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String     label, value;
  final IconData   icon;
  final bool       isPlaceholder;
  final VoidCallback onTap;
  const _PickerField({
    required this.label, required this.value, required this.icon,
    required this.isPlaceholder, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        color: isPlaceholder
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A))),
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DotLegend extends StatelessWidget {
  final Color  color;
  final String label;
  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Multi-line chart painter
// FIX: Replaced single-line ChartPainter with MultiLineChartPainter so the
// PM card can draw PM1.0, PM2.5, and PM10 as separate lines on one canvas.
// The old ChartPainter only ever drew one line regardless of the legend shown.
// ═══════════════════════════════════════════════════════════════════════════════

class ChartLine {
  final Color        color;
  final List<double> points; // normalised 0.0–1.0
  const ChartLine({required this.color, required this.points});
}

class MultiLineChartPainter extends CustomPainter {
  final List<String>    yLabels;
  final List<String>    xLabels;
  final List<ChartLine> lines;

  MultiLineChartPainter({
    required this.yLabels,
    required this.xLabels,
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad   = 34.0;
    const double bottomPad = 20.0;
    final double chartW    = size.width  - leftPad;
    final double chartH    = size.height - bottomPad;

    final gridPaint = Paint()
      ..color       = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Y-axis labels and horizontal grid lines
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartH * (i / (yLabels.length - 1));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      tp.text = TextSpan(
          text: yLabels[i],
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    // X-axis labels
    for (int i = 0; i < xLabels.length; i++) {
      final x = leftPad +
          chartW * (i / (xLabels.length - 1).clamp(1, xLabels.length));
      tp.text = TextSpan(
          text: xLabels[i],
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartH + 4));
    }

    // Draw each line
    for (final line in lines) {
      final pts = line.points;
      if (pts.length < 2) continue;

      final offsets = <Offset>[];
      for (int i = 0; i < pts.length; i++) {
        final x = leftPad + chartW * (i / (pts.length - 1));
        final y = chartH * (1.0 - pts[i].clamp(0.0, 1.0));
        offsets.add(Offset(x, y));
      }

      // Gradient fill under each line
      final fillPath = Path()
        ..moveTo(offsets.first.dx, chartH)
        ..lineTo(offsets.first.dx, offsets.first.dy);
      for (int i = 0; i < offsets.length - 1; i++) {
        final cp1 = Offset(
            offsets[i].dx + (offsets[i + 1].dx - offsets[i].dx) / 2,
            offsets[i].dy);
        final cp2 = Offset(
            offsets[i].dx + (offsets[i + 1].dx - offsets[i].dx) / 2,
            offsets[i + 1].dy);
        fillPath.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy,
            offsets[i + 1].dx, offsets[i + 1].dy);
      }
      fillPath.lineTo(offsets.last.dx, chartH);
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [
              line.color.withOpacity(0.12),
              line.color.withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartH))
          ..style = PaintingStyle.fill,
      );

      // Smooth line
      final linePath = Path()..moveTo(offsets[0].dx, offsets[0].dy);
      for (int i = 0; i < offsets.length - 1; i++) {
        final cp1 = Offset(
            offsets[i].dx + (offsets[i + 1].dx - offsets[i].dx) / 2,
            offsets[i].dy);
        final cp2 = Offset(
            offsets[i].dx + (offsets[i + 1].dx - offsets[i].dx) / 2,
            offsets[i + 1].dy);
        linePath.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy,
            offsets[i + 1].dx, offsets[i + 1].dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color       = line.color
          ..strokeWidth = 2.0
          ..style       = PaintingStyle.stroke
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MultiLineChartPainter old) =>
      old.lines.length != lines.length ||
      old.xLabels.length != xLabels.length;
}