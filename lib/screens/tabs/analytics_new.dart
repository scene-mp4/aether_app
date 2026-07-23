import 'package:flutter/material.dart';

// Data Model for Pollutants
class PollutantData {
  final String title;
  final String unit;
  final double nowValue;
  final double in1HourValue;
  final String trend;
  final String safeLevelText;
  final String whatToDoText;
  final String whatIsText;
  final String whyItMattersText;
  final double maxChartValue;

  PollutantData({
    required this.title,
    required this.unit,
    required this.nowValue,
    required this.in1HourValue,
    required this.trend,
    required this.safeLevelText,
    required this.whatToDoText,
    required this.whatIsText,
    required this.whyItMattersText,
    required this.maxChartValue,
  });
}

class AnalyticsNewPage extends StatefulWidget {
  const AnalyticsNewPage({super.key});

  @override
  State<AnalyticsNewPage> createState() => _AnalyticsNewPageState();
}

class _AnalyticsNewPageState extends State<AnalyticsNewPage> {
  // Track expanded state for main pollutant cards & "More Info" sub-cards
  final Set<int> _expandedCards = {};
  final Set<int> _expandedInfoCards = {};

  final List<PollutantData> _pollutants = [
    PollutantData(
      title: "PM1.0 (Ultra-fine Particulate Matter)",
      unit: "µg/m³",
      nowValue: 4,
      in1HourValue: 9,
      trend: "Rising",
      safeLevelText: "Safe below 10 µg/m³",
      whatToDoText:
          "Levels will remain within safe range. Continue normal monitoring.",
      whatIsText:
          "PM1.0 are extremely tiny particles — smaller than 1/70th of a human hair. They float in the air and can be inhaled.",
      whyItMattersText:
          "Because they are so small, they can go deep into the lungs. High levels over time may affect breathing, especially for elderly residents.",
      maxChartValue: 20,
    ),
    PollutantData(
      title: "PM2.5 (Fine Particulate Matter)",
      unit: "µg/m³",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Safe below 12 µg/m³ (WHO guideline)",
      whatToDoText:
          "Levels are rising slowly. Keep ventilation going to prevent PM2.5 from climbing further.",
      whatIsText:
          "PM2.5 are fine dust particles — about 30 times smaller than a grain of sand. They come from smoke, cooking, or outdoor pollution entering the building.",
      whyItMattersText:
          "They can pass through the nose and mouth and reach deep into the lungs. Regular exposure can worsen conditions like asthma or heart disease.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "PM10 (Coarse Particulate Matter)",
      unit: "µg/m³",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Safe below 54 µg/m³",
      whatToDoText:
          "Dust levels are rising slowly. Regular cleaning and keeping windows closed can help.",
      whatIsText:
          "PM10 are larger dust particles you can sometimes see floating in a beam of light. They come from dust, pollen, and dirt tracked indoors.",
      whyItMattersText:
          "They can irritate the nose, throat, and airways. Residents with allergies or lung conditions are most sensitive to PM10 levels.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "CO (Carbon Monoxide)",
      unit: "ppm",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Safe below 9 ppm (danger above 35 ppm)",
      whatToDoText:
          "Carbon Monoxide remains within a safe range. Continue regular HVAC checks.",
      whatIsText:
          "CO stands for Carbon Monoxide. It is a colorless, odorless gas produced when fuel is burned incompletely — from gas stoves, heaters, or car exhaust nearby.",
      whyItMattersText:
          "CO is very dangerous at high levels because it prevents your blood from carrying oxygen. Even small amounts over time can cause headaches and dizziness.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "CO₂ (Carbon Dioxide)",
      unit: "ppm",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Good below 800 ppm · Stuffy above 1000 ppm",
      whatToDoText:
          "CO₂ is gradually rising as staff and residents are active. Keep ventilation going to prevent buildup.",
      whatIsText:
          "CO₂ (Carbon Dioxide) is the gas that people exhale when breathing. It naturally builds up in rooms with many people and poor air circulation.",
      whyItMattersText:
          "At high levels, CO₂ makes the air feel stuffy and can cause tiredness, headaches, and difficulty concentrating — important for both residents and caregiving staff.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "O₃ (Ozone)",
      unit: "ppb",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Safe below 70 ppb",
      whatToDoText:
          "Ozone remains at a safe level. Avoid using ozone-generating air purifiers in resident rooms.",
      whatIsText:
          "O₃ is ozone — a gas that forms when sunlight reacts with other pollutants. Outdoors it protects us, but at ground level indoors it is an irritant.",
      whyItMattersText:
          "Breathing ozone can irritate the throat and lungs. It is especially concerning for residents with asthma, COPD, or other breathing conditions.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "Temperature",
      unit: "°C",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Comfortable range: 20–26°C",
      whatToDoText:
          "Temperature is rising gradually. Consider adjusting the AC slightly to keep residents comfortable — ideal is 22–26°C.",
      whatIsText:
          "This is the air temperature inside the room being monitored. It rises when many people are present, when sunlight enters, or when ventilation is poor.",
      whyItMattersText:
          "Elderly and ill residents are more sensitive to heat. A too-warm room can cause dehydration, fatigue, and increase risk of heat-related illness.",
      maxChartValue: 0,
    ),
    PollutantData(
      title: "Humidity",
      unit: "%",
      nowValue: 0,
      in1HourValue: 0,
      trend: "Rising",
      safeLevelText: "Comfortable range: 40–60%",
      whatToDoText:
          "Humidity is rising slowly and still within comfortable range. Monitor and run a dehumidifier if it climbs above 60%.",
      whatIsText:
          "Humidity measures how much moisture is in the air. It rises in rooms with many people, after bathing activities, or during rainy weather.",
      whyItMattersText:
          "Too much humidity makes the air feel hot and sticky, promotes mold growth, and can worsen breathing problems. Too little causes dry skin and irritated airways.",
      maxChartValue: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Blue Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 24, bottom: 20),
              color: const Color(0xFF0052FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Predictive Analytics",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "1-hour forecast · Tracker Name · Location",
                    style: TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Alert Banner Box
                  _buildLowRiskBanner(),
                  const SizedBox(height: 12),

                  // "How to Use This Page" Info Box
                  _buildHowToUseCard(),
                  const SizedBox(height: 12),

                  // Risk Level Guide Card
                  _buildRiskLevelGuide(),
                  const SizedBox(height: 20),

                  // Pollutant Forecasts Header Section
                  const Text(
                    "All Pollutant Forecasts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Tap any card to expand and see the forecast chart.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List of Pollutants
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pollutants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _pollutants[index];
                      final isExpanded = _expandedCards.contains(index);
                      final isInfoExpanded =
                          _expandedInfoCards.contains(index);

                      return _buildPollutantCard(
                        index: index,
                        item: item,
                        isExpanded: isExpanded,
                        isInfoExpanded: isInfoExpanded,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Green Low Risk Alert Banner
  Widget _buildLowRiskBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF94A3B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF94A3B8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Risk Level — Risk information",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "All 6 pollutants are (information). Tap any card below to see the full 1-hour chart and details.",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // How To Use Guide Box
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "How to Use This Page",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Each card below shows a different air quality measurement. Tap a card to see its 1-hour prediction chart and what action you should take. Tap \"More Information\" inside a card to learn what the measurement means in plain language.",
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Risk Level Guide List
  Widget _buildRiskLevelGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Risk Level Guide",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideRow(
              const Color(0xFF22C55E),
              "Good",
              "All pollutant levels are within safe ranges. Normal monitoring is sufficient."),
          _buildGuideRow(
              const Color(0xFFEAB308),
              "Moderate",
              "Levels are slightly elevated. Sensitive residents should be monitored."),
          _buildGuideRow(
              const Color(0xFFF97316),
              "Polluted",
              "Air quality is deteriorating. Consider improving ventilation soon."),
          _buildGuideRow(
              const Color(0xFFEF4444),
              "Very Polluted",
              "Air quality is poor. Move sensitive residents and increase ventilation immediately."),
          _buildGuideRow(
              const Color(0xFFA855F7),
              "Severely Polluted",
              "Air quality is severely degraded. Evacuate sensitive residents. Alert medical staff."),
          _buildGuideRow(
              const Color(0xFF991B1B),
              "Hazardous",
              "Emergency conditions. Evacuate everyone immediately and contact emergency services."),
          const SizedBox(height: 8),
          const Text(
            "Source: ATMO (2025); United States Environmental Protection Agency (2024)",
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(Color dotColor, String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                children: [
                  TextSpan(
                    text: "$label — ",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pollutant Expandable Item Card
  Widget _buildPollutantCard({
    required int index,
    required PollutantData item,
    required bool isExpanded,
    required bool isInfoExpanded,
  }) {
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
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCards.remove(index);
            } else {
              _expandedCards.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          item.unit,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 233, 233, 233),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Risk Level",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
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

              // Value & Trend Row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Now",
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      Text(
                        item.nowValue % 1 == 0
                            ? item.nowValue.toInt().toString()
                            : item.nowValue.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          color: Color(0xFF94A3B8), size: 16),
                      const SizedBox(width: 2),
                      Text(
                        item.trend,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "In 1 hour",
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      Text(
                        item.in1HourValue % 1 == 0
                            ? item.in1HourValue.toInt().toString()
                            : item.in1HourValue.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Details Body (Chart, Actions, Info Accordion)
              if (isExpanded) ...[
                const Divider(
                    height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                // Chart Label
                const Text(
                  "1-Hour Forecast Chart",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // Canvas Chart
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: ForecastChartPainter(
                      nowValue: item.nowValue,
                      in1HourValue: item.in1HourValue,
                      maxValue: item.maxChartValue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Safe Level Description
                const Text(
                  "SAFE LEVEL",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.safeLevelText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 10),

                // "What to Do" Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
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
                            const Text(
                              "What to Do",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.whatToDoText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2563EB),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // "More Information about [Pollutant]" Accordion Trigger Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isInfoExpanded) {
                        _expandedInfoCards.remove(index);
                      } else {
                        _expandedInfoCards.add(index);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF0284C7), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "More Information about ${item.title}",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
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
                      ],
                    ),
                  ),
                ),

                // Expanded "More Info" Card Body
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
                          "What is ${item.title.split(' ')[0]}?",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.whatIsText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Why does it matter for residents?",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.whyItMattersText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
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

// Custom Painter to replicate the 1-hour trend graph
class ForecastChartPainter extends CustomPainter {
  final double nowValue;
  final double in1HourValue;
  final double maxValue;

  ForecastChartPainter({
    required this.nowValue,
    required this.in1HourValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = 32.0;
    final double paddingBottom = 20.0;
    final double paddingTop = 10.0;
    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom - paddingTop;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw Y-Axis labels and dotted horizontal grid lines
    final List<double> steps = [
      0,
      maxValue / 4,
      maxValue / 2,
      maxValue * 0.75,
      maxValue
    ];
    for (double step in steps) {
      double y = size.height - paddingBottom - (step / maxValue) * chartHeight;

      // Draw grid line
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);

      // Format label text
      String label =
          step % 1 == 0 ? step.toInt().toString() : step.toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    // Draw X-Axis labels
    textPainter.text = const TextSpan(
      text: "Now",
      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(paddingLeft, size.height - paddingBottom + 4));

    textPainter.text = const TextSpan(
      text: "+1h",
      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset(size.width - textPainter.width, size.height - paddingBottom + 4));

    // Calculate Point Coordinates
    double x1 = paddingLeft;
    double y1 =
        size.height - paddingBottom - (nowValue / maxValue) * chartHeight;

    double x2 = size.width;
    double y2 =
        size.height - paddingBottom - (in1HourValue / maxValue) * chartHeight;

    // Draw Line
    final Paint linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);

    // Draw Dots
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x1, y1), 4.5, dotPaint);
    canvas.drawCircle(Offset(x2, y2), 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}