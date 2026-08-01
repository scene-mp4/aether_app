import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';
import '/models/tracker_info.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PREDICTION ENGINE
//
// Algorithm: Weighted Moving Average (WMA) preprocessing →
//            Ordinary Least Squares (OLS) linear regression →
//            60-minute extrapolation
//
// Why two stages:
//   WMA   — removes transient spikes (e.g. someone opening a window for 5 min)
//            so OLS fits the genuine underlying trend rather than noise.
//   OLS   — fits the line y = mx + c that minimises Σ(residuals²) across
//            the smoothed window, then extends that line to t+60 minutes.
//
// Reference: Quaranta et al. (2017); standard IoT short-horizon forecasting.
// ═══════════════════════════════════════════════════════════════════════════════

class _PredictionResult {
  final double nowValue;      // most recent raw reading
  final double predicted;     // OLS-extrapolated value at t+60 min
  final double changePercent; // % change: (predicted - now) / now × 100
  final double rSquared;      // goodness-of-fit: 0.0 = no trend, 1.0 = perfect
  final String trend;         // 'rising' | 'falling' | 'stable'
  final bool   reliable;      // true when R² ≥ 0.4 and data points ≥ 5

  const _PredictionResult({
    required this.nowValue,
    required this.predicted,
    required this.changePercent,
    required this.rSquared,
    required this.trend,
    required this.reliable,
  });

  static const _PredictionResult empty = _PredictionResult(
    nowValue: 0, predicted: 0, changePercent: 0,
    rSquared: 0, trend: 'stable', reliable: false,
  );
}

/// Stage 1 — Weighted Moving Average
/// Weights: oldest reading = 1, newest = n (linear ramp).
/// Returns a smoothed list of the same length as [values].
List<double> _applyWMA(List<double> values, {int windowSize = 6}) {
  if (values.length <= 1) return List.of(values);
  final smoothed = <double>[];
  for (int i = 0; i < values.length; i++) {
    // Window runs from max(0, i-windowSize+1) to i (inclusive)
    final start  = max(0, i - windowSize + 1);
    final window = values.sublist(start, i + 1);
    final n      = window.length;
    // Weight k+1 for the k-th element (0-indexed), so newest = n
    double weightedSum = 0;
    double totalWeight = 0;
    for (int k = 0; k < n; k++) {
      final weight  = (k + 1).toDouble();
      weightedSum  += window[k] * weight;
      totalWeight  += weight;
    }
    smoothed.add(weightedSum / totalWeight);
  }
  return smoothed;
}

/// Stage 2 — Ordinary Least Squares (OLS) linear regression
/// Fits y = slope·x + intercept through [ys] using [xs] as time axis.
/// Returns slope, intercept, and R² (coefficient of determination).
({double slope, double intercept, double rSquared}) _ols(
    List<double> xs, List<double> ys) {
  assert(xs.length == ys.length && xs.isNotEmpty);
  final n     = xs.length.toDouble();
  final xMean = xs.reduce((a, b) => a + b) / n;
  final yMean = ys.reduce((a, b) => a + b) / n;

  double ssXY = 0, ssXX = 0, ssYY = 0;
  for (int i = 0; i < xs.length; i++) {
    final dx  = xs[i] - xMean;
    final dy  = ys[i] - yMean;
    ssXY     += dx * dy;
    ssXX     += dx * dx;
    ssYY     += dy * dy;
  }

  if (ssXX == 0) {
    // All x values are the same — perfectly flat, no slope
    return (slope: 0.0, intercept: yMean, rSquared: 1.0);
  }

  final slope      = ssXY / ssXX;
  final intercept  = yMean - slope * xMean;
  // R² = (SSxy)² / (SSxx · SSyy)  — proportion of variance explained by line
  final rSquared   = ssYY == 0 ? 1.0 : (ssXY * ssXY) / (ssXX * ssYY);

  return (slope: slope, intercept: intercept, rSquared: rSquared.clamp(0.0, 1.0));
}

/// Full prediction pipeline: WMA → OLS → extrapolate to [minutesAhead].
_PredictionResult _predict(
  List<TrackerReading> readings,
  double Function(TrackerReading) pick, {
  double floor       = 0.0,
  int    minutesAhead = 60,
}) {
  if (readings.isEmpty) return _PredictionResult.empty;

  final raw = readings.map(pick).toList();
  final now = raw.last;

  if (raw.length < 5) {
    // Not enough points for a meaningful regression
    return _PredictionResult(
      nowValue: now, predicted: now, changePercent: 0,
      rSquared: 0, trend: 'stable', reliable: false,
    );
  }

  // Use at most the last 12 readings (1 hour at 5-min intervals)
  final window     = raw.length > 12 ? raw.sublist(raw.length - 12) : raw;
  final smoothed   = _applyWMA(window);
  final n          = smoothed.length;

  // X axis = minutes elapsed (0, 5, 10, … (n-1)×5)
  final xs = List.generate(n, (i) => (i * 5).toDouble());

  final fit       = _ols(xs, smoothed);
  // Predict at t = last known time + minutesAhead
  final targetX   = xs.last + minutesAhead.toDouble();
  final raw_pred  = fit.slope * targetX + fit.intercept;
  final predicted = raw_pred.clamp(floor, double.infinity);

  final change    = now > 0 ? ((predicted - now) / now * 100) : 0.0;
  final trend     = change > 8 ? 'rising' : change < -8 ? 'falling' : 'stable';

  return _PredictionResult(
    nowValue:      now,
    predicted:     predicted,
    changePercent: change,
    rSquared:      fit.rSquared,
    trend:         trend,
    reliable:      fit.rSquared >= 0.4,
  );
}

/// Average predictions from multiple trackers into one result.
_PredictionResult _avgPrediction(List<_PredictionResult> results) {
  if (results.isEmpty) return _PredictionResult.empty;
  final now    = results.map((r) => r.nowValue).reduce((a, b) => a + b) / results.length;
  final pred   = results.map((r) => r.predicted).reduce((a, b) => a + b) / results.length;
  final r2     = results.map((r) => r.rSquared).reduce((a, b) => a + b) / results.length;
  final change = now > 0 ? ((pred - now) / now * 100) : 0.0;
  final trend  = change > 8 ? 'rising' : change < -8 ? 'falling' : 'stable';
  return _PredictionResult(
    nowValue:      now,
    predicted:     pred,
    changePercent: change,
    rSquared:      r2,
    trend:         trend,
    reliable:      results.any((r) => r.reliable),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// POLLUTANT METADATA
//
// FIX: maxChartFor now takes _PredictionResult (not double) so it can
// inspect both nowValue and predicted to set the correct chart ceiling.
// FIX: Removed `const` from _PollutantMeta instances — Dart does not
// allow const objects that hold non-const function references.
// ═══════════════════════════════════════════════════════════════════════════════

class _PollutantMeta {
  final String title;
  final String unit;
  final String safeLevelText;
  final String whatIsText;
  final String whyItMattersText;
  // FIX: correct type — receives _PredictionResult, not double
  final double Function(_PredictionResult) maxChartFor;
  final String Function(_PredictionResult) buildWhatToDo;

  // FIX: removed `const` keyword — closures cannot be const
  _PollutantMeta({
    required this.title,
    required this.unit,
    required this.safeLevelText,
    required this.whatIsText,
    required this.whyItMattersText,
    required this.maxChartFor,
    required this.buildWhatToDo,
  });
}

// ── What-to-do text generators ────────────────────────────────────────────────

String _wtdPm(_PredictionResult r) {
  if (r.predicted > 55)  return 'Particle levels are significantly elevated. Run air purifiers and improve ventilation immediately.';
  if (r.predicted > 12)  return 'Particle levels are rising. Keep ventilation going to prevent further buildup.';
  return 'Levels will remain within safe range. Continue normal monitoring.';
}

String _wtdCo(_PredictionResult r) {
  if (r.predicted > 35) return 'CO is approaching dangerous levels. Open windows and doors immediately and check gas appliances.';
  if (r.predicted > 9)  return 'CO is elevated. Improve ventilation and check combustion sources nearby.';
  return 'Carbon Monoxide remains within safe range. Continue regular HVAC checks.';
}

String _wtdCo2(_PredictionResult r) {
  if (r.predicted > 2000) return 'CO₂ is very high. Ventilate immediately — open multiple windows and run HVAC on fresh-air mode.';
  if (r.predicted > 1000) return 'CO₂ is building up. Open windows or run ventilation fans to let in fresh air.';
  return 'CO₂ is within a healthy range. Keep ventilation adequate.';
}

String _wtdO3(_PredictionResult r) {
  if (r.predicted > 70) return 'Ozone is elevated. Avoid using ozone-generating air purifiers and improve ventilation.';
  return 'Ozone remains at a safe level. Avoid using ozone-generating air purifiers in resident rooms.';
}

String _wtdTemp(_PredictionResult r) {
  if (r.predicted > 35) return 'Temperature is approaching heat-stress levels. Turn on cooling and offer water to all residents.';
  if (r.predicted > 30) return 'Temperature is warm. Consider adjusting the AC to keep residents comfortable.';
  return 'Temperature is within a comfortable range. Continue normal monitoring.';
}

String _wtdHum(_PredictionResult r) {
  if (r.predicted > 80) return 'Humidity is very high — mould risk. Run a dehumidifier and improve ventilation.';
  if (r.predicted > 60) return 'Humidity is rising. Monitor and run a dehumidifier if it climbs above 70%.';
  return 'Humidity is within a comfortable range. Continue monitoring.';
}

// ── Chart ceiling functions (FIX: now receive _PredictionResult) ──────────────

double _ceilPm  (_PredictionResult r) => max(r.nowValue, r.predicted) * 1.4 + 5;
double _ceilCo  (_PredictionResult r) => max(max(r.nowValue, r.predicted) * 1.4, 15.0);
double _ceilCo2 (_PredictionResult r) => max(max(r.nowValue, r.predicted) * 1.2, 1000.0);
double _ceilO3  (_PredictionResult r) => max(max(r.nowValue, r.predicted) * 1.4, 80.0);
double _ceilTemp(_PredictionResult r) => max(r.nowValue, r.predicted) + 5;
double _ceilHum (_PredictionResult r) => 100.0;

// ── Pollutant list (FIX: plain final list, not const) ─────────────────────────
final List<_PollutantMeta> _pollutantMeta = [
  _PollutantMeta(
    title: 'PM1.0 (Ultra-fine Particulate Matter)',
    unit: 'µg/m³',
    safeLevelText: 'Safe below 10 µg/m³',
    whatIsText:
        'PM1.0 are extremely tiny particles — smaller than 1/70th of a human hair. They float in the air and can be inhaled.',
    whyItMattersText:
        'Because they are so small, they can go deep into the lungs. High levels over time may affect breathing, especially for elderly residents.',
    maxChartFor:   _ceilPm,
    buildWhatToDo: _wtdPm,
  ),
  _PollutantMeta(
    title: 'PM2.5 (Fine Particulate Matter)',
    unit: 'µg/m³',
    safeLevelText: 'Safe below 12 µg/m³ (WHO guideline)',
    whatIsText:
        'PM2.5 are fine dust particles — about 30 times smaller than a grain of sand. They come from smoke, cooking, or outdoor pollution entering the building.',
    whyItMattersText:
        'They can pass through the nose and mouth and reach deep into the lungs. Regular exposure can worsen conditions like asthma or heart disease.',
    maxChartFor:   _ceilPm,
    buildWhatToDo: _wtdPm,
  ),
  _PollutantMeta(
    title: 'PM10 (Coarse Particulate Matter)',
    unit: 'µg/m³',
    safeLevelText: 'Safe below 54 µg/m³',
    whatIsText:
        'PM10 are larger dust particles you can sometimes see floating in a beam of light. They come from dust, pollen, and dirt tracked indoors.',
    whyItMattersText:
        'They can irritate the nose, throat, and airways. Residents with allergies or lung conditions are most sensitive.',
    maxChartFor:   _ceilPm,
    buildWhatToDo: _wtdPm,
  ),
  _PollutantMeta(
    title: 'CO (Carbon Monoxide)',
    unit: 'ppm',
    safeLevelText: 'Safe below 9 ppm (danger above 35 ppm)',
    whatIsText:
        'CO is a colorless, odorless gas produced when fuel is burned incompletely — from gas stoves, heaters, or car exhaust nearby.',
    whyItMattersText:
        'CO is very dangerous at high levels because it prevents your blood from carrying oxygen. Even small amounts over time cause headaches and dizziness.',
    maxChartFor:   _ceilCo,
    buildWhatToDo: _wtdCo,
  ),
  _PollutantMeta(
    title: 'CO₂ (Carbon Dioxide)',
    unit: 'ppm',
    safeLevelText: 'Good below 800 ppm · Stuffy above 1000 ppm',
    whatIsText:
        'CO₂ is the gas that people exhale when breathing. It builds up in rooms with many people and poor air circulation.',
    whyItMattersText:
        'At high levels CO₂ makes the air feel stuffy and can cause tiredness, headaches, and difficulty concentrating.',
    maxChartFor:   _ceilCo2,
    buildWhatToDo: _wtdCo2,
  ),
  _PollutantMeta(
    title: 'O₃ (Ozone)',
    unit: 'ppb',
    safeLevelText: 'Safe below 70 ppb',
    whatIsText:
        'O₃ is ozone — a gas that forms when sunlight reacts with other pollutants. At ground level indoors it is an irritant.',
    whyItMattersText:
        'Breathing ozone can irritate the throat and lungs. It is especially concerning for residents with asthma or COPD.',
    maxChartFor:   _ceilO3,
    buildWhatToDo: _wtdO3,
  ),
  _PollutantMeta(
    title: 'Temperature',
    unit: '°C',
    safeLevelText: 'Comfortable range: 18–30°C',
    whatIsText:
        'This is the air temperature inside the room being monitored. It rises when many people are present or ventilation is poor.',
    whyItMattersText:
        'Elderly and ill residents are more sensitive to heat. A too-warm room can cause dehydration, fatigue, and heat-related illness.',
    maxChartFor:   _ceilTemp,
    buildWhatToDo: _wtdTemp,
  ),
  _PollutantMeta(
    title: 'Humidity',
    unit: '%',
    safeLevelText: 'Comfortable range: 30–60%',
    whatIsText:
        'Humidity measures how much moisture is in the air. It rises in rooms with many people, after bathing, or during rainy weather.',
    whyItMattersText:
        'Too much humidity promotes mold growth and worsens breathing. Too little causes dry skin and irritated airways.',
    maxChartFor:   _ceilHum,
    buildWhatToDo: _wtdHum,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class AnalyticsNewPage extends StatefulWidget {
  const AnalyticsNewPage({super.key});

  @override
  State<AnalyticsNewPage> createState() => _AnalyticsNewPageState();
}

class _AnalyticsNewPageState extends State<AnalyticsNewPage> {
  final Set<int> _expandedCards     = {};
  final Set<int> _expandedInfoCards = {};

  // ── Trend colour / icon helpers ───────────────────────────────────────────
  Color    _trendColor(String t) => t == 'rising'
      ? const Color(0xFFEF4444)
      : t == 'falling'
          ? const Color(0xFF22C55E)
          : const Color(0xFF64748B);

  IconData _trendIcon(String t) => t == 'rising'
      ? Icons.trending_up
      : t == 'falling'
          ? Icons.trending_down
          : Icons.trending_flat;

  // ── Overall risk derived from predictions ─────────────────────────────────
  String _overallRisk(List<_PredictionResult> p) {
    if (p.length < 4) return 'No data';
    final co   = p[3].predicted;
    final pm25 = p[1].predicted;
    final co2  = p[4].predicted;
    if (co > 35 || pm25 > 150) return 'Very Polluted';
    if (co > 9  || pm25 > 55)  return 'Polluted';
    if (co2 > 1500 || pm25 > 35) return 'Moderate';
    return 'Good';
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Good':          return const Color(0xFF22C55E);
      case 'Moderate':      return const Color(0xFFEAB308);
      case 'Polluted':      return const Color(0xFFF97316);
      case 'Very Polluted': return const Color(0xFFEF4444);
      case 'Severely Polluted': return const Color(0xFFA855F7);
      case 'Hazardous':     return const Color(0xFF991B1B);
      default:              return const Color(0xFF94A3B8);
    }
  }

  // ── Build predictions from AppDataStore ──────────────────────────────────
  List<_PredictionResult> _buildPredictions(
      AppDataStore store, List<TrackerInfo> trackers) {
    // Collect all history lists from trackers that have data
    final allHistory = trackers
        .map((t) => store.historyFor(t.id))
        .where((h) => h != null && h.readings.isNotEmpty)
        .map((h) => h!.readings)
        .toList();

    // Helper: average OLS prediction across all trackers for one metric
    _PredictionResult avgFor(
      double Function(TrackerReading) pick, {
      double floor = 0.0,
    }) {
      if (allHistory.isEmpty) {
        // Fallback: use latest reading only, mark unreliable
        final latest = trackers
            .map((t) => store.readingFor(t.id))
            .whereType<TrackerReading>()
            .toList();
        if (latest.isEmpty) return _PredictionResult.empty;
        final now = latest.map(pick).reduce((a, b) => a + b) / latest.length;
        return _PredictionResult(
          nowValue:      now,
          predicted:     now,
          changePercent: 0,
          rSquared:      0,
          trend:         'stable',
          reliable:      false,
        );
      }
      final perTracker = allHistory
          .map((readings) => _predict(readings, pick, floor: floor))
          .toList();
      return _avgPrediction(perTracker);
    }

    return [
      avgFor((r) => r.pm1Ugm3),
      avgFor((r) => r.pm25Ugm3),
      avgFor((r) => r.pm10Ugm3),
      avgFor((r) => r.coPpm,         floor: 0),
      avgFor((r) => r.co2Ppm,        floor: 420),
      avgFor((r) => r.o3Ppm * 1000), // ppm → ppb
      avgFor((r) => r.temperatureC,  floor: 0),
      avgFor((r) => r.humidityPct,   floor: 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final trackers    = store.trackers;
        final predictions = _buildPredictions(store, trackers);
        final risk        = _overallRisk(predictions);
        final riskColor   = _riskColor(risk);

        // Trigger history fetch for any tracker that doesn't have it yet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final t in trackers) {
            if (store.historyFor(t.id) == null && mounted) {
              store.fetchHistory(t.id, days: 1);
            }
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 20),
                color: const Color(0xFF0052FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Predictive Analytics',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      trackers.isEmpty
                          ? '1-hour forecast · No trackers linked'
                          : '1-hour forecast · ${trackers.length} '
                            'tracker${trackers.length == 1 ? '' : 's'} '
                            '· WMA + OLS regression',
                      style: const TextStyle(
                          color: Color(0xFFBFDBFE), fontSize: 13),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRiskBanner(risk, riskColor, predictions),
                        const SizedBox(height: 12),
                        _buildHowToUseCard(),
                        const SizedBox(height: 12),
                        _buildRiskLevelGuide(),
                        const SizedBox(height: 20),

                        const Text('All Pollutant Forecasts',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap any card to expand and see the forecast chart.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pollutantMeta.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildPollutantCard(
                                index: index,
                                pred:  predictions[index],
                                meta:  _pollutantMeta[index],
                              ),
                        ),
                        const SizedBox(height: 24),

                        // Model attribution note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Forecasts use a two-stage model: '
                            '(1) Weighted Moving Average (WMA) smoothing '
                            'over the last 12 readings to reduce transient '
                            'spikes, followed by '
                            '(2) Ordinary Least Squares (OLS) linear '
                            'regression — fitting y = slope·x + intercept '
                            'to minimise the sum of squared residuals — '
                            'extrapolated 60 minutes forward. '
                            'Prediction confidence is assessed using R² '
                            '(coefficient of determination). '
                            'Forecasts are estimates and do not replace '
                            'professional medical or safety judgement.',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Risk banner ───────────────────────────────────────────────────────────
  Widget _buildRiskBanner(
      String risk, Color color, List<_PredictionResult> preds) {
    final reliable = preds.any((p) => p.reliable);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            risk == 'Good'
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Predicted Risk Level — $risk',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  reliable
                      ? 'Forecast based on recent trends using WMA + OLS regression. '
                        'Tap any card below to see the full 1-hour chart.'
                      : 'Not enough history data for a reliable forecast yet. '
                        'Showing current readings only. '
                        'Check back after more readings are collected.',
                  style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── How to use ────────────────────────────────────────────────────────────
  Widget _buildHowToUseCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How to Use This Page',
                    style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                SizedBox(height: 6),
                Text(
                  'Each card shows a different air quality measurement and '
                  'its predicted value in 1 hour based on recent trends. '
                  'Tap a card to see its forecast chart and recommended action. '
                  'Tap "More Information" to learn what the measurement means.',
                  style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Risk level guide ──────────────────────────────────────────────────────
  Widget _buildRiskLevelGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Level Guide',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _guideRow(const Color(0xFF22C55E), 'Good',
              'All pollutant levels are within safe ranges. Normal monitoring is sufficient.'),
          _guideRow(const Color(0xFFEAB308), 'Moderate',
              'Levels are slightly elevated. Sensitive residents should be monitored.'),
          _guideRow(const Color(0xFFF97316), 'Polluted',
              'Air quality is deteriorating. Consider improving ventilation soon.'),
          _guideRow(const Color(0xFFEF4444), 'Very Polluted',
              'Air quality is poor. Move sensitive residents and increase ventilation immediately.'),
          _guideRow(const Color(0xFFA855F7), 'Severely Polluted',
              'Severely degraded. Evacuate sensitive residents. Alert medical staff.'),
          _guideRow(const Color(0xFF991B1B), 'Hazardous',
              'Emergency conditions. Evacuate everyone immediately and contact emergency services.'),
          const SizedBox(height: 8),
          const Text(
            'Source: ATMO (2025); United States Environmental Protection Agency (2024)',
            style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(Color dot, String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                children: [
                  TextSpan(
                      text: '$label — ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pollutant card ─────────────────────────────────────────────────────────
  Widget _buildPollutantCard({
    required int index,
    required _PredictionResult pred,
    required _PollutantMeta meta,
  }) {
    final isExpanded     = _expandedCards.contains(index);
    final isInfoExpanded = _expandedInfoCards.contains(index);

    // FIX: maxChartFor now receives _PredictionResult correctly
    // and is clamped to ≥1 so the painter never divides by zero.
    final maxChart = meta.maxChartFor(pred).clamp(1.0, double.infinity);

    final trendColor = _trendColor(pred.trend);
    final trendIcon  = _trendIcon(pred.trend);

    String fmtVal(double v) =>
        v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

    // Risk badge label
    String badgeLabel;
    Color  badgeColor;
    if (!pred.reliable) {
      badgeLabel = 'Low confidence';
      badgeColor = const Color(0xFF94A3B8);
    } else if (pred.trend == 'rising' && pred.changePercent.abs() > 20) {
      badgeLabel = 'Rising fast';
      badgeColor = const Color(0xFFEF4444);
    } else if (pred.trend == 'rising') {
      badgeLabel = 'Rising';
      badgeColor = const Color(0xFFF97316);
    } else if (pred.trend == 'falling') {
      badgeLabel = 'Improving';
      badgeColor = const Color(0xFF22C55E);
    } else {
      badgeLabel = 'Stable';
      badgeColor = const Color(0xFF22C55E);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          isExpanded
              ? _expandedCards.remove(index)
              : _expandedCards.add(index);
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meta.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                        Text(meta.unit,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badgeLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor)),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Value row ─────────────────────────────────────────────
              Row(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Now',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF64748B))),
                    Text(fmtVal(pred.nowValue),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(width: 14),
                Row(children: [
                  Icon(trendIcon, color: trendColor, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    '${pred.changePercent >= 0 ? '+' : ''}'
                    '${pred.changePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendColor),
                  ),
                ]),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('In 1 hour',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF64748B))),
                    Row(children: [
                      Text(fmtVal(pred.predicted),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: trendColor)),
                      if (!pred.reliable) ...[
                        const SizedBox(width: 4),
                        const Tooltip(
                          message:
                              'Low confidence (R² < 0.4 or insufficient data)',
                          child: Icon(Icons.info_outline,
                              size: 12,
                              color: Color(0xFFEAB308)),
                        ),
                      ],
                    ]),
                  ],
                ),
                // R² badge when expanded
                if (isExpanded && pred.reliable) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'R²: ${pred.rSquared.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ]),

              // ── Expanded section ──────────────────────────────────────
              if (isExpanded) ...[
                const Divider(
                    height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                const Text('1-Hour Forecast Chart',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 12),

                // FIX: Each card has correct nowValue, predicted, maxValue
                // and its own lineColor — no more shared zero values.
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ForecastChartPainter(
                      nowValue:     pred.nowValue,
                      in1HourValue: pred.predicted,
                      maxValue:     maxChart,
                      lineColor:    trendColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('SAFE LEVEL',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(meta.safeLevelText,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 10),

                // What to do box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('What to Do',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8))),
                            const SizedBox(height: 2),
                            Text(meta.buildWhatToDo(pred),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2563EB),
                                    height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // More info accordion
                GestureDetector(
                  onTap: () => setState(() {
                    isInfoExpanded
                        ? _expandedInfoCards.remove(index)
                        : _expandedInfoCards.add(index);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF0284C7), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'More Information about '
                          '${meta.title.split(' ')[0]}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isInfoExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF0284C7),
                        size: 16,
                      ),
                    ]),
                  ),
                ),

                if (isInfoExpanded) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What is ${meta.title.split(' ')[0]}?',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(meta.whatIsText,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                height: 1.4)),
                        const SizedBox(height: 10),
                        const Text('Why does it matter for residents?',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text(meta.whyItMattersText,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORECAST CHART PAINTER
//
// FIX: Added lineColor parameter — each pollutant now uses its own trend colour.
// FIX: safeMax guard — maxValue is clamped to ≥1 before any division so that
//      cards whose predicted value is 0 (or very small) never produce NaN
//      y-coordinates, which was why all charts except PM1.0 rendered blank.
// ═══════════════════════════════════════════════════════════════════════════════

class ForecastChartPainter extends CustomPainter {
  final double nowValue;
  final double in1HourValue;
  final double maxValue;
  final Color  lineColor;

  const ForecastChartPainter({
    required this.nowValue,
    required this.in1HourValue,
    required this.maxValue,
    this.lineColor = const Color(0xFF22C55E),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // FIX: safeMax prevents division by zero when both values are 0
    final double safeMax = maxValue.clamp(1.0, double.infinity);

    const double padLeft   = 36.0;
    const double padBottom = 20.0;
    const double padTop    = 10.0;
    final double chartW = size.width  - padLeft;
    final double chartH = size.height - padBottom - padTop;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Y axis + horizontal grid lines
    final steps = [0.0, safeMax / 4, safeMax / 2, safeMax * 0.75, safeMax];
    for (final step in steps) {
      final y = size.height - padBottom - (step / safeMax) * chartH;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width, y), gridPaint);

      final label = step % 1 == 0
          ? step.toInt().toString()
          : step.toStringAsFixed(1);
      tp.text = TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
      tp.layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    // X axis labels
    tp.text = const TextSpan(
        text: 'Now',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
    tp.layout();
    tp.paint(canvas, Offset(padLeft, size.height - padBottom + 4));

    tp.text = const TextSpan(
        text: '+1h',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9));
    tp.layout();
    tp.paint(
        canvas, Offset(size.width - tp.width, size.height - padBottom + 4));

    // Point coordinates — clamp to [0, safeMax]
    final safeNow  = nowValue.clamp(0.0, safeMax);
    final safePred = in1HourValue.clamp(0.0, safeMax);

    final x1 = padLeft;
    final y1 = size.height - padBottom - (safeNow  / safeMax) * chartH;
    final x2 = size.width;
    final y2 = size.height - padBottom - (safePred / safeMax) * chartH;

    // Gradient fill under the line
    canvas.drawPath(
      Path()
        ..moveTo(x1, size.height - padBottom)
        ..lineTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x2, size.height - padBottom)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.15),
            lineColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Line
    canvas.drawLine(
      Offset(x1, y1),
      Offset(x2, y2),
      Paint()
        ..color      = lineColor
        ..strokeWidth = 2.5
        ..style      = PaintingStyle.stroke
        ..strokeCap  = StrokeCap.round,
    );

    // Dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x1, y1), 4.5, dotPaint);
    canvas.drawCircle(Offset(x2, y2), 4.5, dotPaint);

    // Value labels next to dots
    tp.text = TextSpan(
        text: safeNow % 1 == 0
            ? safeNow.toInt().toString()
            : safeNow.toStringAsFixed(1),
        style: TextStyle(
            color: lineColor, fontSize: 9, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(x1 + 6, y1 - tp.height - 2));

    tp.text = TextSpan(
        text: safePred % 1 == 0
            ? safePred.toInt().toString()
            : safePred.toStringAsFixed(1),
        style: TextStyle(
            color: lineColor, fontSize: 9, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, Offset(x2 - tp.width - 6, y2 - tp.height - 2));
  }

  @override
  bool shouldRepaint(covariant ForecastChartPainter old) =>
      old.nowValue     != nowValue     ||
      old.in1HourValue != in1HourValue ||
      old.maxValue     != maxValue     ||
      old.lineColor    != lineColor;
}