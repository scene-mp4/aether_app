import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/stores/app_data_store.dart';

class AdminTrackersTab extends StatefulWidget {
  const AdminTrackersTab({super.key});

  @override
  State<AdminTrackersTab> createState() => _AdminTrackersTabState();
}

class _AdminTrackersTabState extends State<AdminTrackersTab> {
  final _db              = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery    = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Firestore operations ──────────────────────────────────────────────────

  Future<void> _addTracker({
    required String trackerId,
    required String deviceName,
    required String location,
    required String ownerId,
  }) async {
    if (trackerId.trim().isEmpty || deviceName.trim().isEmpty) return;
    try {
      await _db.collection('devices').doc(trackerId.trim()).set({
        'device_name': deviceName.trim(),
        'location':    location.trim(),
        'owner_id':    ownerId,
        'active':      true,
        'created_at':  FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracker added successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add tracker: $e')));
      }
    }
  }

  Future<void> _editTracker({
    required String docId,
    required String deviceName,
    required String location,
    required String ownerId,
  }) async {
    try {
      await _db.collection('devices').doc(docId).update({
        'device_name': deviceName.trim(),
        'location':    location.trim(),
        'owner_id':    ownerId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracker updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update tracker: $e')));
      }
    }
  }

  Future<void> _deleteTracker(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tracker'),
        content: Text(
            'Are you sure you want to delete "$docId"?\n\n'
            'This will permanently remove the tracker document. '
            'Historical readings will remain in the subcollections.'),
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
    try {
      await _db.collection('devices').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracker deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tracker: $e')));
      }
    }
  }

  // ── Fetch users for the owner dropdown ────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'uid':         d.id,
        'email':       data['email']        ?? d.id,
        'displayName': data['display_name'] ?? data['email'] ?? d.id,
        'role':        data['role']         ?? 'user',
      };
    }).toList();
  }

  // ── Add / Edit tracker modal ───────────────────────────────────────────────
  void _showTrackerModal({
    String? existingDocId,
    String? currentName,
    String? currentLocation,
    String? currentOwnerId,
  }) {
    final isEditing       = existingDocId != null;
    final idController    = TextEditingController(
        text: isEditing ? existingDocId : '');
    final nameController  = TextEditingController(
        text: currentName     ?? '');
    final locController   = TextEditingController(
        text: currentLocation ?? '');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _TrackerModal(
        isEditing:        isEditing,
        existingDocId:    existingDocId,
        idController:     idController,
        nameController:   nameController,
        locController:    locController,
        initialOwnerId:   currentOwnerId ?? '',
        fetchUsers:       _fetchUsers,
        onSave: (ownerId) async {
          Navigator.pop(ctx);
          if (isEditing) {
            await _editTracker(
              docId:      existingDocId!,
              deviceName: nameController.text,
              location:   locController.text,
              ownerId:    ownerId,
            );
          } else {
            await _addTracker(
              trackerId:  idController.text,
              deviceName: nameController.text,
              location:   locController.text,
              ownerId:    ownerId,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const _NotificationsEndDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ── Search bar ─────────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search trackers…',
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Add button ─────────────────────────────────────────
                  _buildAddNewButton(),
                  const SizedBox(height: 20),

                  // ── Live tracker list from Firestore ───────────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('devices')
                        .orderBy('device_name')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                              child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                            child: Text('Error: ${snap.error}'));
                      }

                      var docs = snap.data?.docs ?? [];

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((d) {
                          final data =
                              d.data() as Map<String, dynamic>;
                          final name = (data['device_name'] ?? '')
                              .toString()
                              .toLowerCase();
                          final loc = (data['location'] ?? '')
                              .toString()
                              .toLowerCase();
                          final id  = d.id.toLowerCase();
                          return name.contains(_searchQuery) ||
                              loc.contains(_searchQuery) ||
                              id.contains(_searchQuery);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No trackers found.',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8))),
                          ),
                        );
                      }

                      return Consumer<AppDataStore>(
                        builder: (context, store, _) {
                          return ListView.separated(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc  = docs[index];
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              final docId   = doc.id;
                              final name    =
                                  data['device_name'] ?? 'Unnamed';
                              final loc     =
                                  data['location']    ?? 'No location';
                              final ownerId =
                                  data['owner_id']    ?? '';

                              // Last update from AppDataStore latest reading
                              final reading =
                                  store.allReadingFor(docId);
                              final lastUpdate = reading != null
                                  ? _timeAgo(reading.timestamp)
                                  : 'No readings yet';
                              final status = ownerId.isEmpty
                                  ? 'Unassigned'
                                  : 'Active';

                              return _buildTrackerCard(
                                docId:      docId,
                                title:      name,
                                status:     status,
                                location:   loc,
                                ownerId:    ownerId,
                                lastUpdate: lastUpdate,
                                onEdit: () => _showTrackerModal(
                                  existingDocId:   docId,
                                  currentName:     name,
                                  currentLocation: loc,
                                  currentOwnerId:  ownerId,
                                ),
                                onDelete: () => _deleteTracker(docId),
                              );
                            },
                          );
                        },
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3),
      padding: EdgeInsets.only(
        top: topPadding + 16,
        bottom: 15,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/Aether_logo_v1.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AETHER',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1)),
                      Text('Admin Portal',
                          style: TextStyle(
                              color: Color(0xFFC7D2FE),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Builder(builder: (innerCtx) {
                return GestureDetector(
                  onTap: () =>
                      Scaffold.of(innerCtx).openEndDrawer(),
                  child: const Icon(Icons.notifications,
                      color: Colors.white, size: 26),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Tracker Management',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Add, edit, or remove trackers from the system',
              style: TextStyle(
                  color: Color(0xFFC7D2FE), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAddNewButton() {
    return GestureDetector(
      onTap: () => _showTrackerModal(),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B62F6), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Color(0xFF3B62F6), size: 20),
            SizedBox(width: 8),
            Text('Add New Tracker',
                style: TextStyle(
                    color: Color(0xFF3B62F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerCard({
    required String docId,
    required String title,
    required String status,
    required String location,
    required String ownerId,
    required String lastUpdate,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isActive = status == 'Active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('ID: $docId',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // ── Info rows ──────────────────────────────────────────────
          _infoRow(Icons.location_on_outlined,
              location.isNotEmpty ? location : 'No location set'),
          const SizedBox(height: 6),
          _infoRow(Icons.person_outline,
              ownerId.isNotEmpty ? ownerId : 'Unassigned'),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time, 'Last reading: $lastUpdate'),
          const SizedBox(height: 14),

          // ── Action buttons ─────────────────────────────────────────
          Row(children: [
            Expanded(
              child: _actionButton(
                icon:  Icons.edit_outlined,
                label: 'Edit',
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionButton(
                icon:      Icons.delete_outline,
                label:     'Delete',
                onTap:     onDelete,
                textColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFFECACA),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF64748B)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _actionButton({
    required IconData  icon,
    required String    label,
    required VoidCallback onTap,
    Color textColor   = Colors.black,
    Color borderColor = const Color(0xFFE2E8F0),
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tracker modal — handles both Add and Edit in a StatefulWidget so the
// owner dropdown can hold its own async state cleanly.
// ═══════════════════════════════════════════════════════════════════════════════

class _TrackerModal extends StatefulWidget {
  final bool                         isEditing;
  final String?                      existingDocId;
  final TextEditingController        idController;
  final TextEditingController        nameController;
  final TextEditingController        locController;
  final String                       initialOwnerId;
  final Future<List<Map<String, dynamic>>> Function() fetchUsers;
  final Future<void> Function(String ownerId) onSave;

  const _TrackerModal({
    required this.isEditing,
    required this.existingDocId,
    required this.idController,
    required this.nameController,
    required this.locController,
    required this.initialOwnerId,
    required this.fetchUsers,
    required this.onSave,
  });

  @override
  State<_TrackerModal> createState() => _TrackerModalState();
}

class _TrackerModalState extends State<_TrackerModal> {
  List<Map<String, dynamic>> _users    = [];
  bool                       _loading  = true;
  String                     _ownerId  = '';
  bool                       _saving   = false;
  String?                    _error;

  @override
  void initState() {
    super.initState();
    _ownerId = widget.initialOwnerId;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await widget.fetchUsers();
      if (mounted) {
        setState(() {
          _users   = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSave() async {
    final name = widget.nameController.text.trim();
    final id   = widget.idController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Tracker name is required.');
      return;
    }
    if (!widget.isEditing && id.isEmpty) {
      setState(() => _error = 'Tracker ID is required.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    await widget.onSave(_ownerId);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Edit Tracker' : 'Add New Tracker',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),

              // ── Tracker ID (read-only when editing) ─────────────────
              if (!widget.isEditing) ...[
                _inputField(
                  label:      'Tracker ID',
                  controller: widget.idController,
                  hint:       'e.g. tracker_003',
                  helper:     'This will be the Firestore document ID.',
                ),
                const SizedBox(height: 14),
              ] else ...[
                _readOnlyField('Tracker ID', widget.existingDocId ?? ''),
                const SizedBox(height: 14),
              ],

              // ── Device name ─────────────────────────────────────────
              _inputField(
                label:      'Device Name',
                controller: widget.nameController,
                hint:       'e.g. Nursing Station A',
              ),
              const SizedBox(height: 14),

              // ── Location ────────────────────────────────────────────
              _inputField(
                label:      'Location',
                controller: widget.locController,
                hint:       'e.g. Main Building, Floor 2',
              ),
              const SizedBox(height: 14),

              // ── Owner ID dropdown ────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign Owner',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  if (_loading)
                    const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _ownerId.isEmpty ? null : _ownerId,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        hint: const Text('Unassigned',
                            style: TextStyle(
                                color: Color(0xFF94A3B8))),
                        items: [
                          // "Unassigned" option
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Unassigned',
                                style: TextStyle(
                                    color: Color(0xFF64748B))),
                          ),
                          // One item per user
                          ..._users.map((u) => DropdownMenuItem<String>(
                            value: u['uid'] as String,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  u['displayName'] as String,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${u['role']} · ${u['uid']}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )),
                        ],
                        onChanged: (v) =>
                            setState(() => _ownerId = v ?? ''),
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a user account to assign this tracker to. '
                    'Leave as Unassigned to make it available to link.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),

              // ── Error message ────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 10),
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
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12)),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────────────────
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
                            borderRadius:
                                BorderRadius.circular(12)),
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
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : Text(
                              widget.isEditing
                                  ? 'Save Changes'
                                  : 'Add Tracker',
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

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8)),
            helperText: helper,
            helperStyle:
                const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF3B62F6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}


// Notifications end drawer (placeholder — will be connected to live alerts)

class _NotificationsEndDrawer extends StatelessWidget {
  const _NotificationsEndDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const Expanded(
            child: Center(
              child: Text('No notifications',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ),
        ]),
      ),
    );
  }
}