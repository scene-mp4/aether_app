import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _db               = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery     = '';
  String _roleFilter      = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Firebase Web API key ──────────────────────────────────────────────────
  // Found in Firebase Console → Project Settings → General → Web API Key.
  // Safe to include in client code — protected by Firebase security rules.
  static const String _firebaseApiKey = 'AIzaSyAKC8511MGgxkEoKVsVPxdK8NUQ8z_iM1Y';

  // ── Create Firebase Auth account via REST API ─────────────────────────────
  // Using the REST API instead of createUserWithEmailAndPassword() means
  // Firebase does NOT sign in as the new user, so the admin stays logged in.
  Future<String> _createAuthUser(String email, String password) async {
    final response = await http.post(
      Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email':             email.trim(),
        'password':          password,
        'returnSecureToken': true,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data['localId'] as String;
    } else {
      final error   = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Unknown error';
      throw Exception(_friendlyAuthError(message));
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'An account with this email already exists.';
      case 'WEAK_PASSWORD':
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Password must be at least 6 characters.';
      case 'INVALID_EMAIL':
        return 'Please enter a valid email address.';
      default:
        return 'Registration failed: $code';
    }
  }

  // ── Add new user ──────────────────────────────────────────────────────────
  Future<void> _addUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    // Step 1: Create Firebase Auth account (admin stays signed in)
    final uid = await _createAuthUser(email, password);

    // Step 2: Write Firestore user document using the returned UID
    await _db.collection('users').doc(uid).set({
      'username':  username.trim(),
      'email':     email.trim(),
      'role':      role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update user fields ────────────────────────────────────────────────────
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

  // ── Delete user document ──────────────────────────────────────────────────
  Future<void> _deleteUser(String uid, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete "$username"?\n\n'
          'This removes the Firestore user document and unassigns their trackers. '
          'The Firebase Authentication account must be deleted separately in '
          'the Firebase Console.',
        ),
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
      // Unassign trackers owned by this user
      final trackerSnap = await _db
          .collection('devices')
          .where('owner_id', isEqualTo: uid)
          .get();
      for (final doc in trackerSnap.docs) {
        await doc.reference.update({'owner_id': ''});
      }
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

  // ── Show add user modal ───────────────────────────────────────────────────
  void _showAddUserModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AddUserModal(
        onAdd: ({
          required String username,
          required String email,
          required String password,
          required String role,
        }) async {
          await _addUser(
            username: username,
            email:    email,
            password: password,
            role:     role,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User "$username" created successfully')),
            );
          }
        },
      ),
    );
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
                uid: uid, username: username, email: email, role: role);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully')));
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
                  // ── Add New User button ────────────────────────────────
                  GestureDetector(
                    onTap: _showAddUserModal,
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
                          Icon(Icons.person_add_outlined,
                              color: Color(0xFF3B62F6), size: 20),
                          SizedBox(width: 8),
                          Text('Add New User',
                              style: TextStyle(
                                  color: Color(0xFF3B62F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Search bar ─────────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, or UID…',
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

                  // ── Role filter chips ──────────────────────────────────
                  Row(
                    children: ['All', 'user', 'admin'].map((filter) {
                      final selected = _roleFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter == 'All'
                              ? 'All Users'
                              : filter == 'admin'
                                  ? 'Admins'
                                  : 'Users'),
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
                                  : const Color(0xFFE2E8F0)),
                          labelStyle: TextStyle(
                              color: selected
                                  ? const Color(0xFF3B62F6)
                                  : const Color(0xFF475569),
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Live user list ─────────────────────────────────────
                  StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('users')
                        .orderBy('username')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                            child: Text('Error: ${snap.error}'));
                      }

                      var docs = snap.data?.docs ?? [];

                      if (_roleFilter != 'All') {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['role'] ?? 'user') == _roleFilter;
                        }).toList();
                      }

                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final name =
                              (data['username'] ?? '').toString().toLowerCase();
                          final email =
                              (data['email'] ?? '').toString().toLowerCase();
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
                        itemBuilder: (context, index) {
                          final doc  = docs[index];
                          final uid  = doc.id;
                          final data = doc.data() as Map<String, dynamic>;
                          final username =
                              (data['username'] ?? 'Unknown') as String;
                          final email   = (data['email']     ?? '') as String;
                          final role    = (data['role']      ?? 'user') as String;
                          final createdAt = data['createdAt'] as Timestamp?;

                          final parts = username.trim().split(' ');
                          final initials = parts.length >= 2
                              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                              : username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?';

                          return _UserCard(
                            uid:        uid,
                            initials:   initials,
                            username:   username,
                            email:      email,
                            role:       role,
                            createdAt:  createdAt,
                            db:         _db,
                            onEdit: () => _showEditModal(
                              uid:             uid,
                              currentUsername: username,
                              currentEmail:    email,
                              currentRole:     role,
                            ),
                            onDelete: () => _deleteUser(uid, username),
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

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B52F3),
      padding: EdgeInsets.only(
          top: topPadding + 16, bottom: 15, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            color: Color(0xFFC7D2FE), fontSize: 11)),
                  ],
                ),
              ]),
              Builder(builder: (innerCtx) {
                return GestureDetector(
                  onTap: () => Scaffold.of(innerCtx).openEndDrawer(),
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
              style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Add User Modal
// ═══════════════════════════════════════════════════════════════════════════════

class _AddUserModal extends StatefulWidget {
  final Future<void> Function({
    required String username,
    required String email,
    required String password,
    required String role,
  }) onAdd;

  const _AddUserModal({required this.onAdd});

  @override
  State<_AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<_AddUserModal> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  String  _role           = 'user';
  bool    _obscurePass    = true;
  bool    _obscureConfirm = true;
  bool    _saving         = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final pass     = _passCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (username.isEmpty) {
      setState(() => _error = 'Username cannot be empty.'); return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Email cannot be empty.'); return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.'); return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.'); return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      await widget.onAdd(
        username: username,
        email:    email,
        password: pass,
        role:     _role,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error  = e.toString().replaceFirst('Exception: ', '');
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New User',
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
              const SizedBox(height: 20),

              _label('Username'),
              _field(controller: _usernameCtrl, hint: 'e.g. John Santos',
                  icon: Icons.person_outline),
              const SizedBox(height: 14),

              _label('Email'),
              _field(controller: _emailCtrl, hint: 'user@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),

              _label('Password'),
              _field(
                controller:  _passCtrl,
                hint:        'At least 6 characters',
                icon:        Icons.lock_outline,
                obscure:     _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF94A3B8), size: 18),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 14),

              _label('Confirm Password'),
              _field(
                controller:  _confirmCtrl,
                hint:        'Repeat the password',
                icon:        Icons.lock_outline,
                obscure:     _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF94A3B8), size: 18),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 16),

              _label('Role'),
              const SizedBox(height: 8),
              Row(children: [
                _roleChip('user',  'User',  Icons.person_outline),
                const SizedBox(width: 10),
                _roleChip('admin', 'Admin', Icons.admin_panel_settings_outlined),
              ]),
              const SizedBox(height: 4),
              Text(
                _role == 'admin'
                    ? 'Admin users have full access to all admin tabs.'
                    : 'Regular users can only access their own linked trackers.',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8)),
              ),

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
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
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
                      onPressed: _saving ? null : _handleAdd,
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
                          : const Text('Create User',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );

  Widget _field({
    required TextEditingController controller,
    required String  hint,
    required IconData icon,
    bool    obscure      = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        suffixIcon: suffixIcon,
        filled:     true,
        fillColor:  Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFCBD5E1), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF3B62F6), width: 1.6),
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final selected = _role == value;
    final color    = value == 'admin'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : const Color(0xFFE2E8F0),
                width: selected ? 1.5 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: selected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? color : const Color(0xFF475569))),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// User Card
// ═══════════════════════════════════════════════════════════════════════════════

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
    required this.uid,      required this.initials,
    required this.username, required this.email,
    required this.role,     required this.createdAt,
    required this.db,       required this.onEdit,
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
          BoxShadow(color: Color(0x0A000000), blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF3B62F6).withOpacity(0.12),
            child: Text(initials,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Color(0xFF3B62F6))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(username,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              Text(email,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _roleBg(role),
                borderRadius: BorderRadius.circular(20)),
            child: Text(role == 'admin' ? 'Admin' : 'User',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: _roleColor(role))),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 10),
        _infoRow(Icons.badge_outlined, 'UID: $uid'),
        const SizedBox(height: 6),
        _infoRow(Icons.calendar_today_outlined,
            'Joined: ${_formatDate(createdAt)}'),
        const SizedBox(height: 6),

        // Tracker count
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('devices')
              .where('owner_id', isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            final count = snap.data?.docs.length ?? 0;
            final names = snap.data?.docs
                .map((d) =>
                    (d.data() as Map<String, dynamic>)['device_name'] ?? d.id)
                .join(', ') ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.sensors,
                    '$count tracker${count == 1 ? '' : 's'} assigned'),
                if (names.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 2),
                    child: Text(names,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: _btn(Icons.edit_outlined, 'Edit',
              Colors.black, const Color(0xFFE2E8F0), onEdit)),
          const SizedBox(width: 10),
          Expanded(child: _btn(Icons.delete_outline, 'Delete',
              const Color(0xFFEF4444), const Color(0xFFFECACA), onDelete)),
        ]),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF475569)),
                overflow: TextOverflow.ellipsis)),
      ]);

  Widget _btn(IconData icon, String label, Color textColor,
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
                    color: textColor, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit User Modal
// ═══════════════════════════════════════════════════════════════════════════════

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
    required this.uid,             required this.currentUsername,
    required this.currentEmail,   required this.currentRole,
    required this.db,             required this.onSave,
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
      setState(() => _error = 'Username cannot be empty.'); return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email cannot be empty.'); return;
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
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
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
              const Text('Edit User',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('UID: ${widget.uid}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),

              _label('Username'),
              _field(_usernameCtrl, 'Enter username'),
              const SizedBox(height: 14),

              _label('Email'),
              _field(_emailCtrl, 'user@example.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),

              _label('Role'),
              const SizedBox(height: 8),
              Row(children: [
                _roleChip('user',  'User',  Icons.person_outline),
                const SizedBox(width: 10),
                _roleChip('admin', 'Admin', Icons.admin_panel_settings_outlined),
              ]),
              const SizedBox(height: 16),

              _label('Assigned Trackers'),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: widget.db
                    .collection('devices')
                    .where('owner_id', isEqualTo: widget.uid)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.sensors_off, size: 16,
                            color: Color(0xFF94A3B8)),
                        SizedBox(width: 8),
                        Text('No trackers assigned',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF94A3B8))),
                      ]),
                    );
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['device_name'] ?? doc.id) as String;
                      final loc  = (data['location']    ?? '') as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.sensors, size: 16,
                              color: Color(0xFF3B62F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                                if (loc.isNotEmpty)
                                  Text(loc,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _unassignTracker(doc.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8)),
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

              if (_error != null) ...[
                const SizedBox(height: 12),
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
                                color: Color(0xFFEF4444), fontSize: 12))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold,
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
                          : const Text('Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller:   ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintText:  hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3B62F6))),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final selected = _role == value;
    final color    = value == 'admin'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : const Color(0xFFE2E8F0),
                width: selected ? 1.5 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: selected ? color : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? color : const Color(0xFF475569))),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Notifications end drawer
// ═══════════════════════════════════════════════════════════════════════════════

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
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