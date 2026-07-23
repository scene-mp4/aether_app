import 'package:flutter/material.dart';

class TrackerHistoryTab extends StatefulWidget {
  const TrackerHistoryTab({super.key});

  @override
  State<TrackerHistoryTab> createState() => _TrackerHistoryTabState();
}

class _TrackerHistoryTabState extends State<TrackerHistoryTab> {
  // Independent State Variables for Each Card
  String _selectedPmTimeFrame = 'Today';
  String _selectedCoO3TimeFrame = 'Today';
  String _selectedCo2TimeFrame = 'Today';

  // --- HELPER METHODS FOR PM CHART ---
  List<String> get _pmXLabels {
    switch (_selectedPmTimeFrame) {
      case '7 Days':
        return const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      case '30 Days':
        return const ["Week 1", "Week 2", "Week 3", "Week 4"];
      case 'Today':
      default:
        return const ["12am", "4am", "8am", "12pm", "4pm", "8pm"];
    }
  }

  List<double> get _pmPoints {
    switch (_selectedPmTimeFrame) {
      case '7 Days':
        return const [0.20, 0.35, 0.28, 0.40, 0.22, 0.18, 0.25];
      case '30 Days':
        return const [0.30, 0.45, 0.25, 0.20];
      case 'Today':
      default:
        return const [0.15, 0.12, 0.22, 0.32, 0.20, 0.16];
    }
  }

  // --- HELPER METHODS FOR CO & O3 CHART ---
  List<String> get _coO3XLabels {
    switch (_selectedCoO3TimeFrame) {
      case '7 Days':
        return const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      case '30 Days':
        return const ["Week 1", "Week 2", "Week 3", "Week 4"];
      case 'Today':
      default:
        return const ["12am", "4am", "8am", "12pm", "4pm", "8pm"];
    }
  }

  List<double> get _coO3Points {
    switch (_selectedCoO3TimeFrame) {
      case '7 Days':
        return const [0.08, 0.12, 0.10, 0.15, 0.09, 0.07, 0.06];
      case '30 Days':
        return const [0.10, 0.14, 0.08, 0.06];
      case 'Today':
      default:
        return const [0.06, 0.05, 0.07, 0.07, 0.06, 0.05];
    }
  }

  // --- HELPER METHODS FOR CO2 CHART ---
  List<String> get _co2XLabels {
    switch (_selectedCo2TimeFrame) {
      case '7 Days':
        return const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      case '30 Days':
        return const ["Week 1", "Week 2", "Week 3", "Week 4"];
      case 'Today':
      default:
        return const ["12am", "4am", "8am", "12pm", "4pm", "8pm"];
    }
  }

  List<double> get _co2Points {
    switch (_selectedCo2TimeFrame) {
      case '7 Days':
        return const [0.70, 0.85, 0.78, 0.90, 0.82, 0.65, 0.60];
      case '30 Days':
        return const [0.75, 0.88, 0.70, 0.65];
      case 'Today':
      default:
        return const [0.65, 0.62, 0.82, 0.96, 0.82, 0.72];
    }
  }

  // --- DOWNLOAD MODAL DIALOG DISPLAY ---
  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DownloadHistoryModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. History Summary Card
        _buildHistorySummaryCard(),
        const SizedBox(height: 16),

        // 2. Particulate Matter History Chart Card
        _buildParticulateMatterHistoryCard(),
        const SizedBox(height: 16),

        // 3. CO & O3 History Chart Card
        _buildCoO3HistoryCard(),
        const SizedBox(height: 16),

        // 4. CO2 History Chart Card
        _buildCo2HistoryCard(),
        const SizedBox(height: 16),

        // 5. Recommendations Card
        _buildRecommendationsCard(),
        const SizedBox(height: 20),

        // 6. Download Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showDownloadDialog(context),
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            label: const Text(
              "Download History Data",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- REUSABLE HEADER WITH INDEPENDENT CALLBACK ---

  Widget _buildCardHeader({
    required String title,
    String? subtitle,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: ['Today', '7 Days', '30 Days'].map((tf) {
            final isSelected = selectedValue == tf;
            return GestureDetector(
              onTap: () => onSelected(tf),
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tf.replaceAll(' ', '\n'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    height: 1.1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHistorySummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                "History Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Air quality in this room has remained consistently Good throughout the day. Both PM2.5 and CO₂ showed mild increases during daytime activity hours but stayed well within safe limits and recovered by evening.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryBlock(
            title: "Overnight Baseline (12am–4am)",
            description:
                "PM2.5 was at its lowest point of 6 µg/m³ at 4am — classified as Good. CO₂ also dropped to 380 ppm, indicating good overnight ventilation with minimal occupant activity.",
            dotColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
          ),
          const SizedBox(height: 12),
          _buildSummaryBlock(
            title: "Midday Rise (8am–12pm)",
            description:
                "PM2.5 climbed from 12 to 15 µg/m³ as morning activity began. CO₂ rose from 520 to 580 ppm during peak activity hours. Both values remained in the Good range despite the increase.",
            dotColor: const Color(0xFFF97316),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFFEDD5),
          ),
          const SizedBox(height: 12),
          _buildSummaryBlock(
            title: "Evening Recovery (4pm–8pm)",
            description:
                "PM2.5 dropped back to 9 µg/m³ and CO₂ fell to 420 ppm after 4pm as activity reduced. This shows current ventilation practices are effectively managing air quality.",
            dotColor: const Color(0xFF22C55E),
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFDCFCE7),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBlock({
    required String title,
    required String description,
    required Color dotColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: dotColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticulateMatterHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Particulate Matter\nHistory",
            selectedValue: _selectedPmTimeFrame,
            onSelected: (newValue) {
              setState(() {
                _selectedPmTimeFrame = newValue;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _DotLegend(color: Color(0xFF8B4513), label: "PM1.0 (µg/m³)"),
              SizedBox(width: 8),
              _DotLegend(color: Color(0xFFEAB308), label: "PM2.5 (µg/m³)"),
              SizedBox(width: 8),
              _DotLegend(color: Color(0xFFEA580C), label: "PM10 (µg/m³)"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: ChartPainter(
                lineColor: const Color(0xFFEA580C),
                yLabels: const ["24", "18", "12", "6", "0"],
                xLabels: _pmXLabels,
                normalizedPoints: _pmPoints,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoO3HistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "CO & O₃ History",
            subtitle: "CO in ppm · O₃ in ppb — different units, similar numeric scale",
            selectedValue: _selectedCoO3TimeFrame,
            onSelected: (newValue) {
              setState(() {
                _selectedCoO3TimeFrame = newValue;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _DotLegend(color: Color(0xFFEF4444), label: "CO (ppm)"),
              SizedBox(width: 12),
              _DotLegend(color: Color(0xFF0D9488), label: "O₃ (ppb)"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: ChartPainter(
                lineColor: const Color(0xFF0D9488),
                yLabels: const ["24", "18", "12", "6", "0"],
                xLabels: _coO3XLabels,
                normalizedPoints: _coO3Points,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCo2HistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "CO₂ History",
            subtitle: "Carbon Dioxide in ppm — shown separately due to different scale",
            selectedValue: _selectedCo2TimeFrame,
            onSelected: (newValue) {
              setState(() {
                _selectedCo2TimeFrame = newValue;
              });
            },
          ),
          const SizedBox(height: 12),
          const _DotLegend(color: Color(0xFF3B82F6), label: "CO₂ (ppm)"),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: ChartPainter(
                lineColor: const Color(0xFF3B82F6),
                yLabels: const ["600", "300", "150", "0"],
                xLabels: _co2XLabels,
                normalizedPoints: _co2Points,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommendations Based on History",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            icon: Icons.thermostat_outlined,
            iconColor: const Color(0xFFD97706),
            title: "PM2.5 Peaks at Midday",
            description:
                "PM2.5 levels tend to rise between 8am and 12pm. Consider improving ventilation during morning shift activities.",
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
          ),
          const SizedBox(height: 10),
          _buildRecommendationItem(
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF2563EB),
            title: "CO₂ Builds Up During the Day",
            description:
                "CO₂ rises significantly from 8am to 12pm as staff and residents are most active. Open windows or run ventilation during this period.",
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
          ),
          const SizedBox(height: 10),
          _buildRecommendationItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            title: "Levels Improve in the Evening",
            description:
                "Both PM2.5 and CO₂ drop after 4pm. Monitor whether ventilation changes are helping.",
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.3,
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

// --- DOWNLOAD HISTORY POPUP DIALOG COMPONENT ---

class DownloadHistoryModal extends StatefulWidget {
  const DownloadHistoryModal({super.key});

  @override
  State<DownloadHistoryModal> createState() => _DownloadHistoryModalState();
}

class _DownloadHistoryModalState extends State<DownloadHistoryModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  // Pollutants state map
  final Map<String, bool> _pollutants = {
    "PM1.0": true,
    "PM2.5": true,
    "PM10": true,
    "CO": true,
    "CO₂": true,
    "O₃": true,
    "Temperature": true,
    "Humidity": true,
  };

  bool get _allSelected => _pollutants.values.every((v) => v);
  bool get _canDownload => _startDate != null && _endDate != null;

  void _toggleAllPollutants() {
    setState(() {
      final newValue = !_allSelected;
      _pollutants.updateAll((key, value) => newValue);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "dd/mm/yyyy";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? "am" : "pm";
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Download History Data",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description Text
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                children: [
                  TextSpan(
                      text:
                          "Select the date range, time range, and pollutants you want to include in the downloaded report for "),
                  TextSpan(
                    text: "Tracker 1 — Main Building, Floor 1.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Range Section
            const Text(
              "Date Range",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: "Start Date",
                    value: _formatDate(_startDate),
                    icon: Icons.calendar_today_outlined,
                    isPlaceholder: _startDate == null,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerField(
                    label: "End Date",
                    value: _formatDate(_endDate),
                    icon: Icons.calendar_today_outlined,
                    isPlaceholder: _endDate == null,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Range Section
            const Text(
              "Time Range",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: "Start Time",
                    value: _formatTime(_startTime),
                    icon: Icons.access_time_rounded,
                    isPlaceholder: false,
                    onTap: () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerField(
                    label: "End Time",
                    value: _formatTime(_endTime),
                    icon: Icons.access_time_rounded,
                    isPlaceholder: false,
                    onTap: () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pollutants to Include Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pollutants to Include",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleAllPollutants,
                  child: Text(
                    _allSelected ? "Deselect All" : "Select All",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pollutant Checkbox Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _pollutants.keys.map((pollutant) {
                final isSelected = _pollutants[pollutant]!;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _pollutants[pollutant] = !isSelected;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pollutant,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Warning Notice Block (if dates not picked)
            if (!_canDownload) ...[
              Row(
                children: const [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Please select both a start and end date to download.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canDownload
                        ? () {
                            Navigator.pop(context);
                          }
                        : null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text(
                      "Download",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFFBFDBFE),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required bool isPlaceholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: isPlaceholder
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                  ),
                ),
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// --- HELPER CLASSES FOR CHART & LEGEND ---

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _DotLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class ChartPainter extends CustomPainter {
  final Color lineColor;
  final List<String> yLabels;
  final List<String> xLabels;
  final List<double> normalizedPoints;

  ChartPainter({
    required this.lineColor,
    required this.yLabels,
    required this.xLabels,
    required this.normalizedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 28.0;
    const double bottomPadding = 20.0;
    final double chartWidth = size.width - leftPadding;
    final double chartHeight = size.height - bottomPadding;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw Y-Axis Grid Lines & Labels
    final int yCount = yLabels.length;
    for (int i = 0; i < yCount; i++) {
      final double y = chartHeight * (i / (yCount - 1));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 4, y - (textPainter.height / 2)),
      );
    }

    // 2. Draw X-Axis Ticks & Labels
    final int xCount = xLabels.length;
    for (int i = 0; i < xCount; i++) {
      final double x = leftPadding + (chartWidth * (i / (xCount - 1)));

      canvas.drawLine(
        Offset(x, chartHeight),
        Offset(x, chartHeight + 4),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), chartHeight + 4),
      );
    }

    // 3. Draw Chart Line Curve
    if (normalizedPoints.isEmpty) return;

    final Path path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < normalizedPoints.length; i++) {
      final double x = leftPadding + (chartWidth * (i / (normalizedPoints.length - 1)));
      final double y = chartHeight * (1.0 - normalizedPoints[i]);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
      final Offset controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final Offset controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}