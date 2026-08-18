import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _db              = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery    = '';
  String _roleFilter     = 'All'; // 'All' | 'admin' | 'user'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  // ── Firestore: create a new user document ─────────────────────────────────
Future<void> _addUser({
  required String username,
  required String email,
  required String password,
  required String role,
}) async {
  final cleanUsername = username.trim();
  final cleanEmail = email.trim().toLowerCase();
  final cleanPassword = password;

  if (cleanUsername.isEmpty) {
    throw Exception('Username is required.');
  }

  if (cleanEmail.isEmpty) {
    throw Exception('Email is required.');
  }

  if (cleanPassword.length < 6) {
    throw Exception('Password must be at least 6 characters.');
  }

  FirebaseApp? secondaryApp;
  User? newAuthUser;

  try {
    // ------------------------------------------------------------
    // Create a SECONDARY Firebase App.
    //
    // This is important because createUserWithEmailAndPassword()
    // signs in the newly-created account.
    //
    // Using a secondary app keeps the current admin signed in.
    // ------------------------------------------------------------
    secondaryApp = await Firebase.initializeApp(
      name: 'secondaryUserCreation',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(
      app: secondaryApp,
    );

    // ------------------------------------------------------------
    // 1. CREATE FIREBASE AUTHENTICATION ACCOUNT
    // ------------------------------------------------------------
    final credential =
        await secondaryAuth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    newAuthUser = credential.user;

    if (newAuthUser == null) {
      throw Exception('Failed to create Firebase Authentication user.');
    }

    final authUid = newAuthUser.uid;

    // ------------------------------------------------------------
    // 2. CREATE FIRESTORE USER DOCUMENT
    //
    // IMPORTANT:
    // The Firestore document ID is now the Firebase Auth UID.
    // ------------------------------------------------------------
    await _db.collection('users').doc(authUid).set({
      'uid': authUid,
      'username': cleanUsername,
      'email': cleanEmail,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'email-already-in-use':
        throw Exception(
          'An account already exists for this email address.',
        );

      case 'invalid-email':
        throw Exception(
          'The email address is invalid.',
        );

      case 'weak-password':
        throw Exception(
          'The password is too weak.',
        );

      case 'operation-not-allowed':
        throw Exception(
          'Email/password authentication is not enabled in Firebase.',
        );

      default:
        throw Exception(
          e.message ?? 'Failed to create Firebase Authentication account.',
        );
    }
  } catch (e) {
    // ------------------------------------------------------------
    // If Firestore creation failed AFTER Auth was created,
    // remove the newly-created Auth account so we don't leave
    // an orphaned Authentication account.
    // ------------------------------------------------------------
    if (newAuthUser != null) {
      try {
        await newAuthUser.delete();
      } catch (_) {
        // Ignore cleanup error.
      }
    }

    rethrow;
  } finally {
    // ------------------------------------------------------------
    // Destroy secondary Firebase app.
    // ------------------------------------------------------------
    if (secondaryApp != null) {
      try {
        await secondaryApp.delete();
      } catch (_) {
        // Ignore cleanup error.
      }
    }
  }
}

  // ── Firestore: update user fields ────────────────────────────────────────
  Future<void> _updateUser({
    required String uid,
    required String username,
    required String email,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).update({
      'username': username.trim(),
      'email':    email.trim(),
      'role':     role,
    });
  }

  // ── Firestore: delete user document (Auth deletion requires Cloud Fn) ────
  Future<void> _deleteUser(String uid, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete "$username"?\n\n'
          'This removes the Firestore user document. '
          'The Firebase Authentication account will remain — '
          'delete it separately in the Firebase Console if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      // Unassign any trackers owned by this user first
      final trackerSnap = await _db
          .collection('devices')
          .where('owner_id', isEqualTo: uid)
          .get();
      for (final doc in trackerSnap.docs) {
        await doc.reference.update({'owner_id': ''});
      }
      // Delete user document
      await _db.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')));
      }
    }
  }

  // ── Show edit modal ───────────────────────────────────────────────────────
  void _showEditModal({
    required String uid,
    required String currentUsername,
    required String currentEmail,
    required String currentRole,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditUserModal(
        uid:             uid,
        currentUsername: currentUsername,
        currentEmail:    currentEmail,
        currentRole:     currentRole,
        db:              _db,
        onSave: ({
          required String username,
          required String email,
          required String role,
        }) async {
          try {
            await _updateUser(
              uid:      uid,
              username: username,
              email:    email,
              role:     role,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('User updated successfully')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update user: $e')));
            }
          }
        },
      ),
    );
  }

  // ── Show add user modal ────────────────────────────────────────────────────
  void _showAddUserModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AddUserModal(
        onSave: ({
          required String username,
          required String email,
          required String password,
          required String role,
        }) async {
          try {
            await _addUser(
              username: username,
              email: email,
              password: password,
              role: role,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User added successfully'),
                ),
              );
            }
          } catch (e) {
            rethrow;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search bar ───────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or UID…',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                      ),
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

                  const SizedBox(height: 12),

                  // ── Add New User ─────────────────────────────────────────────────────────
                  _buildAddNewUserButton(),

                  const SizedBox(height: 16),

                  // ── Role filter chips ────────────────────────────────────────────────────
                  Row(
                    children: ['All', 'user', 'admin'].map((filter) {
                      final selected = _roleFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter == 'All'
                                ? 'All Users'
                                : filter == 'admin'
                                    ? 'Admins'
                                    : 'Users',
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _roleFilter = filter),
                          backgroundColor: Colors.white,
                          selectedColor:
                              const Color(0xFF3B62F6).withOpacity(0.1),
                          checkmarkColor: const Color(0xFF3B62F6),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF3B62F6)
                                : const Color(0xFFE2E8F0),
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF3B62F6)
                                : const Color(0xFF475569),
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Live user list ───────────────────────────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('users')
                        .orderBy('username')
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

                      // Apply role filter
                      if (_roleFilter != 'All') {
                        docs = docs.where((d) {
                          final data =
                              d.data() as Map<String, dynamic>;
                          return (data['role'] ?? 'user') ==
                              _roleFilter;
                        }).toList();
                      }

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((d) {
                          final data =
                              d.data() as Map<String, dynamic>;
                          final name = (data['username'] ?? '')
                              .toString()
                              .toLowerCase();
                          final email = (data['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          final uid = d.id.toLowerCase();
                          return name.contains(_searchQuery) ||
                              email.contains(_searchQuery) ||
                              uid.contains(_searchQuery);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No users found.',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8))),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc  = docs[index];
                          final uid  = doc.id;
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final username =
                              (data['username'] ?? 'Unknown')
                                  as String;
                          final email =
                              (data['email'] ?? '') as String;
                          final role =
                              (data['role'] ?? 'user') as String;
                          final createdAt =
                              data['createdAt'] as Timestamp?;

                          // Initials from username
                          final parts = username.trim().split(' ');
                          final initials = parts.length >= 2
                              ? '${parts[0][0]}${parts[1][0]}'
                                  .toUpperCase()
                              : username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?';

                          return _UserCard(
                            uid:       uid,
                            initials:  initials,
                            username:  username,
                            email:     email,
                            role:      role,
                            createdAt: createdAt,
                            db:        _db,
                            onEdit: () => _showEditModal(
                              uid:             uid,
                              currentUsername: username,
                              currentEmail:    email,
                              currentRole:     role,
                            ),
                            onDelete: () =>
                                _deleteUser(uid, username),
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

  Widget _buildAddNewUserButton() {
    return GestureDetector(
      onTap: _showAddUserModal,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3B62F6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.person_add_outlined,
              color: Color(0xFF3B62F6),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Add New User',
              style: TextStyle(
                color: Color(0xFF3B62F6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
          const Text('User Management',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Manage user accounts and roles',
              style: TextStyle(
                  color: Color(0xFFC7D2FE), fontSize: 12)),
        ],
      ),
    );
  }
}

// User Card — fetches tracker count from Firestore directly

class _UserCard extends StatelessWidget {
  final String     uid;
  final String     initials;
  final String     username;
  final String     email;
  final String     role;
  final Timestamp? createdAt;
  final FirebaseFirestore db;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.uid,
    required this.initials,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.db,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _roleColor(String r) =>
      r == 'admin' ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);

  Color _roleBg(String r) =>
      r == 'admin' ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF);

  @override
  Widget build(BuildContext context) {
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
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFF3B62F6).withOpacity(0.12),
                child: Text(initials,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B62F6))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    Text(email,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _roleBg(role),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role == 'admin' ? 'Admin' : 'User',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _roleColor(role)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // ── Info rows ──────────────────────────────────────────────
          _infoRow(Icons.badge_outlined, 'UID: $uid'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined,
              'Joined: ${_formatDate(createdAt)}'),
          const SizedBox(height: 6),

          // Tracker count — live query
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('devices')
                .where('owner_id', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              final trackerNames = snap.data?.docs
                      .map((d) =>
                          (d.data() as Map<String, dynamic>)[
                              'device_name'] ??
                          d.id)
                      .join(', ') ??
                  '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.sensors,
                      '$count tracker${count == 1 ? '' : 's'} assigned'),
                  if (trackerNames.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(trackerNames,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              );
            },
          ),
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
                icon:       Icons.delete_outline,
                label:      'Delete',
                onTap:      onDelete,
                textColor:  const Color(0xFFEF4444),
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
    Color textColor    = Colors.black,
    Color borderColor  = const Color(0xFFE2E8F0),
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

// Edit User Modal
// Editable: username, email, role
// Also shows assigned trackers with option to unassign

class _EditUserModal extends StatefulWidget {
  final String uid;
  final String currentUsername;
  final String currentEmail;
  final String currentRole;
  final FirebaseFirestore db;
  final Future<void> Function({
    required String username,
    required String email,
    required String role,
  }) onSave;

  const _EditUserModal({
    required this.uid,
    required this.currentUsername,
    required this.currentEmail,
    required this.currentRole,
    required this.db,
    required this.onSave,
  });

  @override
  State<_EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<_EditUserModal> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late String _role;
  bool   _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.currentUsername);
    _emailCtrl    = TextEditingController(text: widget.currentEmail);
    _role         = widget.currentRole;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_usernameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Username cannot be empty.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email cannot be empty.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onSave(
        username: _usernameCtrl.text,
        email:    _emailCtrl.text,
        role:     _role,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error  = e.toString();
        });
      }
    }
  }

  Future<void> _unassignTracker(String deviceId) async {
    await widget.db
        .collection('devices')
        .doc(deviceId)
        .update({'owner_id': ''});
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
              const Text('Edit User',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('UID: ${widget.uid}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),

              // ── Username ─────────────────────────────────────────────
              _field('Username', _usernameCtrl, 'Enter username'),
              const SizedBox(height: 14),

              // ── Email ────────────────────────────────────────────────
              _field('Email', _emailCtrl, 'user@example.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),

              // ── Role selector ────────────────────────────────────────
              const Text('Role',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 8),
              Row(children: [
                _roleChip('user',  'User'),
                const SizedBox(width: 10),
                _roleChip('admin', 'Admin'),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Admins have full access to all admin tabs. '
                'Users can only access their own trackers.',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),

              // ── Assigned trackers ────────────────────────────────────
              const Text('Assigned Trackers',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: widget.db
                    .collection('devices')
                    .where('owner_id', isEqualTo: widget.uid)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (snap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.sensors_off,
                            size: 16, color: Color(0xFF94A3B8)),
                        SizedBox(width: 8),
                        Text('No trackers assigned',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8))),
                      ]),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;
                      final name =
                          (data['device_name'] ?? doc.id) as String;
                      final loc =
                          (data['location'] ?? '') as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.sensors,
                              size: 16,
                              color: Color(0xFF3B62F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            Color(0xFF0F172A))),
                                if (loc.isNotEmpty)
                                  Text(loc,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              Color(0xFF94A3B8))),
                                Text('ID: ${doc.id}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color:
                                            Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          // Unassign button
                          GestureDetector(
                            onTap: () =>
                                _unassignTracker(doc.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text('Unassign',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444))),
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                  );
                },
              ),

              // ── Error ────────────────────────────────────────────────
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
                              color: Color(0xFFEF4444),
                              fontSize: 12)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 24),

              // ── Actions ──────────────────────────────────────────────
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

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
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
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            hintText: hint,
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
                  const BorderSide(color: Color(0xFF3B62F6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleChip(String value, String label) {
    final selected = _role == value;
    final color    = value == 'admin'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            value == 'admin'
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            size: 16,
            color: selected ? color : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selected
                      ? color
                      : const Color(0xFF475569))),
        ]),
      ),
    );
  }
}


class _AddUserModal extends StatefulWidget {
  final Future<void> Function({
    required String username,
    required String email,
    required String password,
    required String role,
  }) onSave;

  const _AddUserModal({
    required this.onSave,
  });

  @override
  State<_AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<_AddUserModal> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  String _role = 'user';

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _usernameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

Future<void> _handleSave() async {
  final username = _usernameCtrl.text.trim();
  final email = _emailCtrl.text.trim();
  final password = _passwordCtrl.text;

  if (username.isEmpty) {
    setState(() {
      _error = 'Username cannot be empty.';
    });
    return;
  }

  if (email.isEmpty) {
    setState(() {
      _error = 'Email cannot be empty.';
    });
    return;
  }

  final emailRegex = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  if (!emailRegex.hasMatch(email)) {
    setState(() {
      _error = 'Please enter a valid email address.';
    });
    return;
  }

  if (password.isEmpty) {
    setState(() {
      _error = 'Password cannot be empty.';
    });
    return;
  }

  if (password.length < 6) {
    setState(() {
      _error = 'Password must be at least 6 characters.';
    });
    return;
  }

  setState(() {
    _saving = true;
    _error = null;
  });

    try {
      await widget.onSave(
        username: username,
        email: email,
        password: password,
        role: _role,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),

      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ── Title ────────────────────────────────────────────────

              const Text(
                'Add New User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Create a new user profile',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 20),

              // ── Username ─────────────────────────────────────────────

              _field(
                'Username',
                _usernameCtrl,
                'Enter username',
              ),

              const SizedBox(height: 14),

              // ── Email ────────────────────────────────────────────────

              _field(
                'Email',
                _emailCtrl,
                'user@example.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),
              
              // ── Password
              _field(
                'Password',
                _passwordCtrl,
                'Enter temporary password',
                obscureText: true,
              ),

              // ── Role ─────────────────────────────────────────────────

              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _roleChip('user', 'User'),

                  const SizedBox(width: 10),

                  _roleChip('admin', 'Admin'),
                ],
              ),

              const SizedBox(height: 4),

              const Text(
                'Admins have full access to all admin tabs. '
                'Users can only access their own trackers.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 16),

              // ── Information box ─────────────────────────────────────

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBBF7D0),
                  ),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),

                    SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'The user profile will be saved to Firestore. '
                        'Firebase Authentication must be created separately '
                        'if the user needs to sign in.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Error ────────────────────────────────────────────────

              if (_error != null) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Buttons ──────────────────────────────────────────────

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,

                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),

                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 48,

                      child: ElevatedButton(
                        onPressed:
                            _saving ? null : _handleSave,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF3B62F6),
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),

                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text field ──────────────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            hintText: hint,

            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFCBD5E1),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF3B62F6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Role selector ───────────────────────────────────────────────────────

  Widget _roleChip(
    String value,
    String label,
  ) {
    final selected = _role == value;

    final color = value == 'admin'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);

    return GestureDetector(
      onTap: _saving
          ? null
          : () => setState(() {
                _role = value;
              }),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.1)
              : Colors.white,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(
            color: selected
                ? color
                : const Color(0xFFE2E8F0),

            width: selected ? 1.5 : 1,
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              value == 'admin'
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline,

              size: 16,

              color: selected
                  ? color
                  : const Color(0xFF64748B),
            ),

            const SizedBox(width: 6),

            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,

                color: selected
                    ? color
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notifications end drawer

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

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color    iconBgColor;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final String   time;
  final bool     isUnread;

  const _NotificationTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isUnread ? const Color(0xFFF8FAFC) : Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: const Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.2)),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}