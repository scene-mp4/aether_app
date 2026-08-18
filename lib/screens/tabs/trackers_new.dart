import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';
import '/models/tracker_reading.dart';
import '/models/tracker_info.dart';
import 'tracker_details_page.dart';

class TrackersNewPage extends StatelessWidget {
  const TrackersNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataStore>(
      builder: (context, store, _) {
        final trackers = store.trackers;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: Column(
            children: [
              // ── Blue header ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 24, bottom: 20),
                decoration: const BoxDecoration(color: Color(0xFF0052FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Trackers",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${trackers.length} active device${trackers.length == 1 ? '' : 's'}",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: store.loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            children: [
                              // Add new tracker button
                              GestureDetector(
                                onTap: () =>
                                    _showAddTrackerDialog(context, store),
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF0052FF),
                                        width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add,
                                          color: Color(0xFF0052FF),
                                          size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        "Add New Tracker",
                                        style: TextStyle(
                                          color: Color(0xFF0052FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tracker cards
                              if (trackers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      "No trackers linked yet.\nTap \"Add New Tracker\" to get started.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 14),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: trackers.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final info    = trackers[index];
                                    final reading =
                                        store.readingFor(info.id);
                                    return TrackerCard(
                                      key: ValueKey(info.id),
                                      info:    info,
                                      reading: reading,
                                      onUnlink: () =>
                                          _confirmUnlink(context, store, info),
                                      onEdit: () =>
                                          _showEditModal(context, info),
                                    );
                                  },
                                ),

                              const SizedBox(height: 16),
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

  // ── Add tracker dialog ───────────────────────────────────────────────────

  void _showAddTrackerDialog(BuildContext context, AppDataStore store) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _AddTrackerDialog(store: store);
      },
    );
  }

  // ── Edit modal ───────────────────────────────────────────────────────────

  void _showEditModal(BuildContext context, TrackerInfo info) {
    showDialog(
      context: context,
      builder: (_) => _EditTrackerModal(
        deviceId:        info.id,
        currentName:     info.deviceName,
        currentLocation: info.location,
      ),
    );
  }

  // ── Unlink confirmation ──────────────────────────────────────────────────

  void _confirmUnlink(
      BuildContext context, AppDataStore store, TrackerInfo info) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink Tracker'),
        content: Text(
            'Remove "${info.deviceName}" from your account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              store.unlinkTracker(info.id);
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Add Tracker Dialog
// Shows devices from Firestore where owner_id is empty.
// ═══════════════════════════════════════════════════════════════════════════════

class _AddTrackerDialog extends StatelessWidget {
  final AppDataStore store;
  const _AddTrackerDialog({required this.store});

  @override
  Widget build(BuildContext context) {
    // Available trackers come from the store's unowned device list
    final available = store.availableTrackers;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Available Trackers",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            available.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        "No nearby trackers found.",
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                : Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (ctx, index) {
                        final tracker = available[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            tracker.deviceName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF334155)),
                          ),
                          subtitle: Text(
                            tracker.id,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              store.linkTracker(tracker.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text("Add"),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tracker Card
// Displays live data from AppDataStore for one tracker.
// Shows placeholder dashes when the reading hasn't arrived yet.
// ═══════════════════════════════════════════════════════════════════════════════

class TrackerCard extends StatefulWidget {
  final TrackerInfo     info;
  final TrackerReading? reading;
  final VoidCallback    onUnlink;
  final VoidCallback    onEdit;

  const TrackerCard({
    super.key,
    required this.info,
    required this.reading,
    required this.onUnlink,
    required this.onEdit,
  });

  @override
  State<TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<TrackerCard> {
  bool _showAqiInfo = false;

  // ── AQI color ──────────────────────────────────────────────────────────────
  Color _aqiColor(int aqi) {
    if (aqi <= 50)  return const Color(0xFF16A34A); // green
    if (aqi <= 100) return const Color(0xFFCA8A04); // yellow
    if (aqi <= 150) return const Color(0xFFEA580C); // orange
    if (aqi <= 200) return const Color(0xFFDC2626); // red
    if (aqi <= 300) return const Color(0xFF7C3AED); // purple
    return const Color(0xFF7F1D1D);                 // maroon
  }

  // ── Last updated string ────────────────────────────────────────────────────
  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'No readings yet';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final r       = widget.reading;
    final hasData = r != null;

    // IAQI display values
    final iaqi      = hasData ? r.iaqi      : 0;
    final iaqiLabel = hasData ? r.iaqiLabel : '--';
    final aqiColor  = hasData ? _aqiColor(iaqi) : const Color(0xFF94A3B8);
    final aqiProgress = hasData ? (iaqi / 500).clamp(0.0, 1.0) : 0.0;

    // Sensor grid rows — label, value, unit
    final readings = [
      {
        'label': 'PM1.0',
        'value': hasData ? r.pm1Ugm3.toStringAsFixed(1)   : '--',
        'unit':  'µg/m³',
      },
      {
        'label': 'PM2.5',
        'value': hasData ? r.pm25Ugm3.toStringAsFixed(1)  : '--',
        'unit':  'µg/m³',
      },
      {
        'label': 'PM10',
        'value': hasData ? r.pm10Ugm3.toStringAsFixed(1)  : '--',
        'unit':  'µg/m³',
      },
      {
        'label': 'CO',
        'value': hasData ? r.coPpm.toStringAsFixed(1)     : '--',
        'unit':  'ppm',
      },
      {
        'label': 'CO₂',
        'value': hasData ? r.co2Ppm.toStringAsFixed(0)    : '--',
        'unit':  'ppm',
      },
      {
        'label': 'O₃',
        'value': hasData ? r.o3Ppm.toStringAsFixed(2)     : '--',
        'unit':  'ppm',
      },
      {
        'label': 'Temp',
        'value': hasData ? r.temperatureC.toStringAsFixed(1) : '--',
        'unit':  '°C',
      },
      {
        'label': 'Humid',
        'value': hasData ? r.humidityPct.toStringAsFixed(0) : '--',
        'unit':  '%',
      },
    ];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackerDetailsPage(
            deviceId:    widget.info.id,
            trackerName: widget.info.deviceName,
            location:    widget.info.location,
          ),
        ),
      ),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.info.deviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 17, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit tracker',
                    onPressed: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  // Unlink button
                  IconButton(
                    icon: const Icon(Icons.link_off,
                        size: 18, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove tracker',
                    onPressed: widget.onUnlink,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Color(0xFF64748B)),
                ],
              ),
              const SizedBox(height: 4),

              // ── Location ─────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFF475569)),
                  const SizedBox(width: 4),
                  Text(
                    widget.info.location.isNotEmpty
                        ? widget.info.location
                        : 'No location set',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── IAQI row ─────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    hasData ? '$iaqi' : '--',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: aqiColor,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: aqiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      iaqiLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: aqiColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // CO alert badge — only shown when alert is active
                  if (hasData && r.coAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: Colors.red),
                          SizedBox(width: 4),
                          Text('CO Alert',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // "What is AQI?" toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showAqiInfo = !_showAqiInfo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFBFDBFE)),
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 12, color: Color(0xFF0052FF)),
                          SizedBox(width: 4),
                          Text(
                            "What is AQI?",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── AQI info box ─────────────────────────────────────────────
              if (_showAqiInfo) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "AQI (Air Quality Index) measures how clean or "
                          "polluted the air is. Lower numbers are better. "
                          "0–50 is Good, 51–100 is Moderate, 101–150 is "
                          "Unhealthy for Sensitive Groups, 151–200 is "
                          "Unhealthy, 201–300 is Very Unhealthy, and "
                          "301–500 is Hazardous.",
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Color(0xFF1E40AF)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAqiInfo = false),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFF2563EB), size: 18),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // ── Last updated ─────────────────────────────────────────────
              Text(
                _timeAgo(r?.timestamp),
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),

              // ── AQI progress bar ─────────────────────────────────────────
              Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("0 — Good",
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B))),
                      Text("500 — Hazardous",
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: aqiProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(aqiColor),
                    ),
                  ),
                ],
              ),

              const Divider(
                  height: 24,
                  thickness: 1,
                  color: Color(0xFFE2E8F0)),

              // ── Sensor readings grid ─────────────────────────────────────
              const Text(
                "Current Readings",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: readings.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:  4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing:  6,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final item = readings[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['label']!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item['value']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: hasData
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          item['unit']!,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Tracker Modal
// Allows the user to update device_name and location for their own tracker.
// Writes directly to Firestore — AppDataStore's live stream picks up the change.
// ═══════════════════════════════════════════════════════════════════════════════

// Predefined location suggestions (same list as admin page)
const List<String> _locationSuggestions = [
  'Bedroom',
  'Kitchen',
  'Living Room',
  'Bathroom',
  'Dining Room',
  'Office',
  'Hallway',
  'Nursery',
  'Ward',
  'Nursing Station',
  'Reception',
  'Corridor',
  'Common Area',
  'Utility Room',
  'Storage Room',
  'Custom…',
];

class _EditTrackerModal extends StatefulWidget {
  final String deviceId;
  final String currentName;
  final String currentLocation;

  const _EditTrackerModal({
    required this.deviceId,
    required this.currentName,
    required this.currentLocation,
  });

  @override
  State<_EditTrackerModal> createState() => _EditTrackerModalState();
}

class _EditTrackerModalState extends State<_EditTrackerModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locCtrl;

  String? _selectedLocation;
  bool    _showCustomLocation = false;
  bool    _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _locCtrl  = TextEditingController(text: widget.currentLocation);

    // Pre-select existing location in dropdown if it matches a suggestion
    final existing = widget.currentLocation.trim();
    if (existing.isNotEmpty) {
      if (_locationSuggestions.contains(existing)) {
        _selectedLocation   = existing;
        _showCustomLocation = false;
      } else {
        _selectedLocation   = 'Custom…';
        _showCustomLocation = true;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tracker name cannot be empty.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({
        'device_name': name,
        'location':    _locCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error  = 'Failed to save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Tracker',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Color(0xFF64748B), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('ID: ${widget.deviceId}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),

              // Tracker name
              const Text('Tracker Name',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  hintText: 'e.g. Bedroom Sensor',
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF0052FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location picker
              const Text('Location',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('Select a location',
                      style: TextStyle(color: Color(0xFF94A3B8))),
                  items: _locationSuggestions.map((loc) {
                    final isCustom = loc == 'Custom…';
                    return DropdownMenuItem<String>(
                      value: loc,
                      child: Row(children: [
                        Icon(
                          isCustom
                              ? Icons.edit_outlined
                              : Icons.location_on_outlined,
                          size: 14,
                          color: isCustom
                              ? const Color(0xFF0052FF)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(loc,
                            style: TextStyle(
                                fontSize: 13,
                                color: isCustom
                                    ? const Color(0xFF0052FF)
                                    : const Color(0xFF0F172A),
                                fontWeight: isCustom
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ]),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedLocation   = v;
                      _showCustomLocation = v == 'Custom…';
                      if (v != null && v != 'Custom…') {
                        _locCtrl.text = v;
                      } else if (v == 'Custom…') {
                        _locCtrl.clear();
                      }
                    });
                  },
                ),
              ),
              if (_showCustomLocation) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _locCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    hintText: 'Type a custom location…',
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Color(0xFF64748B)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF0052FF)),
                    ),
                  ),
                ),
              ],

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}