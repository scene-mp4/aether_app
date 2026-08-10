import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAdviceTab extends StatefulWidget {
  const AdminAdviceTab({super.key});
  @override
  State<AdminAdviceTab> createState() => _AdminAdviceTabState();
}

class _AdminAdviceTabState extends State<AdminAdviceTab> {
  final _db = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _filterSeverity = 'All';

  // Trigger options — maps display label to Firestore field name
  static const List<Map<String, String>> _triggerOptions = [
    {'label': 'IAQI (Overall AQI)',           'value': 'iaqi'},
    {'label': 'PM2.5 AQI',                    'value': 'pm25_aqi'},
    {'label': 'PM1.0 (µg/m³)',                'value': 'pm1_ugm3'},
    {'label': 'PM2.5 (µg/m³)',               'value': 'pm25_ugm3'},
    {'label': 'PM10 (µg/m³)',                'value': 'pm10_ugm3'},
    {'label': 'CO (ppm)',                     'value': 'co_ppm'},
    {'label': 'CO₂ (ppm)',                   'value': 'co2_ppm'},
    {'label': 'LPG/Smoke (ppm)',             'value': 'lpg_ppm'},
    {'label': 'O₃ (ppm)',                    'value': 'o3_ppm'},
    {'label': 'NH₃ (ppm)',                   'value': 'nh3_ppm'},
    {'label': 'Temperature (°C)',            'value': 'temperature_c'},
    {'label': 'Humidity (%)',                'value': 'humidity_pct'},
    {'label': 'Heat Index (°C)',             'value': 'heat_index_c'},
    // {'label': 'CO Alert (flag)',             'value': 'co_alert'},
    // {'label': 'LPG Alert (flag)',            'value': 'lpg_alert'},
    // {'label': 'PM2.5 Alert (flag)',          'value': 'pm25_alert'},
    // {'label': 'CO₂ Alert (flag)',            'value': 'co2_alert'},
  ];

  static const List<Map<String, String>> _comparatorOptions = [
    {'label': 'Greater than (>)',          'value': 'gt'},
    {'label': 'Greater than or equal (≥)', 'value': 'gte'},
    {'label': 'Less than (<)',             'value': 'lt'},
    {'label': 'Less than or equal (≤)',   'value': 'lte'},
    {'label': 'Equal to (=)',              'value': 'eq'},
  ];

  static const List<String> _severityOptions = ['info', 'warning', 'critical'];

  // ── Firestore operations ──────────────────────────────────────────────────

  Future<void> _saveAdvice({
    String?        docId,
    required String title,
    required String category,
    required String trigger,
    required String comparator,
    required double threshold,
    required String severity,
    required String message,
    required List<String> actions,
    required bool   active,
  }) async {
    final data = {
      'title':      title.trim(),
      'category':   category.trim(),
      'trigger':    trigger,
      'comparator': comparator,
      'threshold':  threshold,
      'severity':   severity,
      'message':    message.trim(),
      'actions':    actions.where((a) => a.trim().isNotEmpty).toList(),
      'active':     active,
    };

    if (docId == null) {
      data['created_at'] = FieldValue.serverTimestamp();
      data['created_by'] = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _db.collection('advice').add(data);
    } else {
      await _db.collection('advice').doc(docId).update(data);
    }
  }

  Future<void> _toggleActive(String docId, bool current) async {
    await _db.collection('advice').doc(docId).update({'active': !current});
  }

  Future<void> _deleteAdvice(String docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Advice'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _db.collection('advice').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advice entry deleted')));
    }
  }

  // ── Modal ─────────────────────────────────────────────────────────────────

  void _showModal({
    String?        docId,
    Map<String, dynamic>? existing,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AdviceModal(
        docId:           docId,
        existing:        existing,
        triggerOptions:  _triggerOptions,
        comparatorOptions: _comparatorOptions,
        severityOptions: _severityOptions,
        onSave: ({
          required String title,
          required String category,
          required String trigger,
          required String comparator,
          required double threshold,
          required String severity,
          required String message,
          required List<String> actions,
          required bool   active,
        }) async {
          await _saveAdvice(
            docId:      docId,
            title:      title,
            category:   category,
            trigger:    trigger,
            comparator: comparator,
            threshold:  threshold,
            severity:   severity,
            message:    message,
            actions:    actions,
            active:     active,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(docId == null
                    ? 'Advice entry added'
                    : 'Advice entry updated')));
          }
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return const Color(0xFFEF4444);
      case 'warning':  return const Color(0xFFD97706);
      default:         return const Color(0xFF2563EB);
    }
  }

  Color _severityBg(String s) {
    switch (s) {
      case 'critical': return const Color(0xFFFEE2E2);
      case 'warning':  return const Color(0xFFFEF3C7);
      default:         return const Color(0xFFDBEAFE);
    }
  }

  String _triggerLabel(String value) =>
      _triggerOptions.firstWhere(
        (t) => t['value'] == value,
        orElse: () => {'label': value},
      )['label'] ?? value;

  String _comparatorLabel(String value) =>
      _comparatorOptions.firstWhere(
        (c) => c['value'] == value,
        orElse: () => {'label': value},
      )['label'] ?? value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Search
              TextField(
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search advice entries…',
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),

              // Severity filter chips
              Row(children: [
                ...['All', 'info', 'warning', 'critical'].map((f) {
                  final sel = _filterSeverity == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f == 'All'
                          ? 'All'
                          : f[0].toUpperCase() + f.substring(1)),
                      selected: sel,
                      onSelected: (_) =>
                          setState(() => _filterSeverity = f),
                      backgroundColor: Colors.white,
                      selectedColor: _filterSeverity == 'All'
                          ? const Color(0xFF3B62F6).withOpacity(0.1)
                          : _severityBg(f),
                      checkmarkColor: sel
                          ? (f == 'All'
                              ? const Color(0xFF3B62F6)
                              : _severityColor(f))
                          : null,
                      side: BorderSide(
                          color: sel
                              ? (f == 'All'
                                  ? const Color(0xFF3B62F6)
                                  : _severityColor(f))
                              : const Color(0xFFE2E8F0)),
                      labelStyle: TextStyle(
                          fontSize: 12,
                          color: sel
                              ? (f == 'All'
                                  ? const Color(0xFF3B62F6)
                                  : _severityColor(f))
                              : const Color(0xFF475569),
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 16),

              // Add button
              GestureDetector(
                onTap: () => _showModal(),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF3B62F6), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add,
                          color: Color(0xFF3B62F6), size: 20),
                      SizedBox(width: 8),
                      Text('Add New Advice Entry',
                          style: TextStyle(
                              color: Color(0xFF3B62F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Live list
              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('advice')
                    .orderBy('severity')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  var docs = snap.data?.docs ?? [];

                  if (_filterSeverity != 'All') {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return data['severity'] == _filterSeverity;
                    }).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final title    = (data['title']   ?? '').toString().toLowerCase();
                      final category = (data['category']?? '').toString().toLowerCase();
                      final trigger  = (data['trigger'] ?? '').toString().toLowerCase();
                      return title.contains(_searchQuery) ||
                          category.contains(_searchQuery) ||
                          trigger.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No advice entries found.',
                            style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc  = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _AdviceCard(
                        docId:            doc.id,
                        data:             data,
                        severityColor:    _severityColor(
                            data['severity'] ?? 'info'),
                        severityBg:       _severityBg(
                            data['severity'] ?? 'info'),
                        triggerLabel:     _triggerLabel(
                            data['trigger'] ?? ''),
                        comparatorLabel:  _comparatorLabel(
                            data['comparator'] ?? ''),
                        onEdit: () => _showModal(
                            docId: doc.id, existing: data),
                        onDelete: () => _deleteAdvice(
                            doc.id, data['title'] ?? ''),
                        onToggle: () => _toggleActive(
                            doc.id, data['active'] == true),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3),
      padding: EdgeInsets.only(
          top: topPadding + 16, bottom: 15, left: 16, right: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/Aether_logo_v1.png',
                    width: 52, height: 52, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('AETHER',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1)),
                Text('Admin Portal',
                    style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11)),
              ]),
            ]),
            const Icon(Icons.notifications, color: Colors.white, size: 26),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Advice Management',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        const Text('Create and manage air quality advice shown to users',
            style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Advice card widget — list item shown for each Firestore document
// ═══════════════════════════════════════════════════════════════════════════════

class _AdviceCard extends StatelessWidget {
  final String               docId;
  final Map<String, dynamic> data;
  final Color                severityColor;
  final Color                severityBg;
  final String               triggerLabel;
  final String               comparatorLabel;
  final VoidCallback         onEdit;
  final VoidCallback         onDelete;
  final VoidCallback         onToggle;

  const _AdviceCard({
    required this.docId,
    required this.data,
    required this.severityColor,
    required this.severityBg,
    required this.triggerLabel,
    required this.comparatorLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final title    = (data['title']     ?? 'Untitled') as String;
    final category = (data['category']  ?? '')         as String;
    final severity = (data['severity']  ?? 'info')     as String;
    final threshold= data['threshold'];
    final active   = data['active'] == true;
    final actions  = data['actions'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              if (category.isNotEmpty)
                Text(category,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: severityBg, borderRadius: BorderRadius.circular(20)),
            child: Text(severity[0].toUpperCase() + severity.substring(1),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: severityColor)),
          ),
          const SizedBox(width: 8),
          // Active toggle
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(active ? 'Active' : 'Disabled',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: active
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B))),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 10),

        // Condition row
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.rule, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'When $triggerLabel $comparatorLabel $threshold',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF334155)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),

        // Message preview
        Text(
          (data['message'] as String? ?? '').length > 80
              ? '${(data['message'] as String).substring(0, 80)}…'
              : (data['message'] as String? ?? ''),
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('${actions.length} action${actions.length == 1 ? '' : 's'} defined',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF94A3B8))),
        ],
        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          Expanded(child: _actionBtn(
              Icons.edit_outlined, 'Edit', Colors.black,
              const Color(0xFFE2E8F0), onEdit)),
          const SizedBox(width: 10),
          Expanded(child: _actionBtn(
              Icons.delete_outline, 'Delete', const Color(0xFFEF4444),
              const Color(0xFFFECACA), onDelete)),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color textColor,
      Color borderColor, VoidCallback onTap) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Add / Edit modal
// ═══════════════════════════════════════════════════════════════════════════════

class _AdviceModal extends StatefulWidget {
  final String?                  docId;
  final Map<String, dynamic>?    existing;
  final List<Map<String, String>> triggerOptions;
  final List<Map<String, String>> comparatorOptions;
  final List<String>             severityOptions;
  final Future<void> Function({
    required String title,
    required String category,
    required String trigger,
    required String comparator,
    required double threshold,
    required String severity,
    required String message,
    required List<String> actions,
    required bool   active,
  }) onSave;

  const _AdviceModal({
    required this.docId,
    required this.existing,
    required this.triggerOptions,
    required this.comparatorOptions,
    required this.severityOptions,
    required this.onSave,
  });

  @override
  State<_AdviceModal> createState() => _AdviceModalState();
}

class _AdviceModalState extends State<_AdviceModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _messageCtrl;
  late List<TextEditingController> _actionCtrls;

  late String _trigger;
  late String _comparator;
  late String _severity;
  late bool   _active;

  bool   _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl     = TextEditingController(text: e?['title']    ?? '');
    _categoryCtrl  = TextEditingController(text: e?['category'] ?? '');
    _thresholdCtrl = TextEditingController(
        text: e?['threshold']?.toString() ?? '0');
    _messageCtrl   = TextEditingController(text: e?['message']  ?? '');

    final existingActions = (e?['actions'] as List? ?? [])
        .map((a) => TextEditingController(text: a.toString()))
        .toList();
    _actionCtrls = existingActions.isEmpty
        ? [TextEditingController()]
        : existingActions;

    _trigger    = e?['trigger']    ?? widget.triggerOptions.first['value']!;
    _comparator = e?['comparator'] ?? 'gt';
    _severity   = e?['severity']   ?? 'info';
    _active     = e?['active']     ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _thresholdCtrl.dispose();
    _messageCtrl.dispose();
    for (final c in _actionCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final threshold = double.tryParse(_thresholdCtrl.text.trim());
    if (threshold == null) {
      setState(() => _error = 'Threshold must be a number.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave(
        title:      _titleCtrl.text,
        category:   _categoryCtrl.text,
        trigger:    _trigger,
        comparator: _comparator,
        threshold:  threshold,
        severity:   _severity,
        message:    _messageCtrl.text,
        actions:    _actionCtrls.map((c) => c.text.trim()).toList(),
        active:     _active,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.docId == null ? 'Add Advice Entry' : 'Edit Advice Entry',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 20),

              _field('Title', _titleCtrl, 'e.g. Elevated CO Detected'),
              const SizedBox(height: 14),
              _field('Category', _categoryCtrl,
                  'e.g. Carbon Monoxide (CO)'),
              const SizedBox(height: 14),

              // Trigger dropdown
              _dropdownSection<String>(
                label: 'Trigger Field',
                value: _trigger,
                items: widget.triggerOptions
                    .map((t) => DropdownMenuItem<String>(
                          value: t['value'],
                          child: Text(t['label']!,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _trigger = v!),
              ),
              const SizedBox(height: 14),

              // Comparator dropdown
              _dropdownSection<String>(
                label: 'Comparator',
                value: _comparator,
                items: widget.comparatorOptions
                    .map((c) => DropdownMenuItem<String>(
                          value: c['value'],
                          child: Text(c['label']!,
                              style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _comparator = v!),
              ),
              const SizedBox(height: 14),

              _field('Threshold Value', _thresholdCtrl, 'e.g. 35',
                  keyboardType: TextInputType.number,
                  helper: ''),
              const SizedBox(height: 14),

              // Severity chips
              const Text('Severity',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Row(children: widget.severityOptions.map((s) {
                final sel = _severity == s;
                final color = s == 'critical'
                    ? const Color(0xFFEF4444)
                    : s == 'warning'
                        ? const Color(0xFFD97706)
                        : const Color(0xFF2563EB);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _severity = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? color : const Color(0xFFE2E8F0),
                            width: sel ? 1.5 : 1),
                      ),
                      child: Text(s[0].toUpperCase() + s.substring(1),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: sel
                                  ? color
                                  : const Color(0xFF475569))),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 14),

              _field('Message', _messageCtrl,
                  'Explain what this condition means and why it matters.\n'
                  'Use {value} to insert the current sensor reading.',
                  maxLines: 4),
              const SizedBox(height: 14),

              // Actions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recommended Actions',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                  GestureDetector(
                    onTap: () => setState(
                        () => _actionCtrls.add(TextEditingController())),
                    child: const Text('+ Add',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3B62F6),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._actionCtrls.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: c,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintText: 'Action step ${i + 1}',
                          hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF3B62F6))),
                        ),
                      ),
                    ),
                    if (_actionCtrls.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          c.dispose();
                          _actionCtrls.removeAt(i);
                        }),
                        child: const Icon(Icons.remove_circle_outline,
                            color: Color(0xFFEF4444), size: 22),
                      ),
                    ],
                  ]),
                );
              }),
              const SizedBox(height: 14),

              // Active toggle
              Row(children: [
                Switch(
                  value: _active,
                  activeColor: const Color(0xFF3B62F6),
                  onChanged: (v) => setState(() => _active = v),
                ),
                const SizedBox(width: 8),
                Text(_active ? 'Active — shown to users' : 'Disabled — hidden from users',
                    style: TextStyle(
                        fontSize: 13,
                        color: _active
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B))),
              ]),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                        backgroundColor: const Color(0xFF3B62F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              widget.docId == null
                                  ? 'Add Advice'
                                  : 'Save Changes',
                              style: const TextStyle(
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

  Widget _field(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text,
      String? helper}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText:   hint,
          helperText: helper,
          helperMaxLines: 2,
          hintStyle:  const TextStyle(color: Color(0xFF94A3B8)),
          helperStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3B62F6))),
        ),
      ),
    ]);
  }

  Widget _dropdownSection<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155))),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(10)),
        child: DropdownButton<T>(
          value:      value,
          isExpanded: true,
          underline:  const SizedBox.shrink(),
          items:      items,
          onChanged:  onChanged,
        ),
      ),
    ]);
  }
}