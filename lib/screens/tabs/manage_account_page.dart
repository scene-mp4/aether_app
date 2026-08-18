import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({Key? key}) : super(key: key);

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage>
    with SingleTickerProviderStateMixin {
  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tab Controller
  late TabController _tabController;

  // Controllers for Profile Info
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controllers for Change Password
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password Visibility States
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // State Variables
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Fetch User Data from Firebase
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (mounted) {
          setState(() {
            _emailController.text = user.email ?? "";

            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data() as Map<String, dynamic>;
              _fullNameController.text =
                  data['username'] ?? user.displayName ?? "Katty";
            } else {
              _fullNameController.text = user.displayName ?? "Katty";
            }
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Save Profile Updates to Firestore
  Future<void> _saveProfileChanges() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSavingProfile = true);

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': _fullNameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (_fullNameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_fullNameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  /// Update Password via Firebase Auth
  Future<void> _updatePassword() async {
    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all password fields.', Colors.orange);
      return;
    }

    if (newPassword.length < 8) {
      _showSnackBar('New password must be at least 8 characters long.', Colors.orange);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match.', Colors.red);
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate user before updating sensitive info
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        _showSnackBar('Password updated successfully!', Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Failed to update password.', Colors.red);
    } catch (e) {
      _showSnackBar('An error occurred. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bgColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const lightBg = Color(0xFFF1F5F9);

    final String initial = _fullNameController.text.isNotEmpty
        ? _fullNameController.text[0].toUpperCase()
        : "K";

    return Scaffold(
      backgroundColor: lightBg,
      floatingActionButton: const AiAssistant(),
      body: SafeArea(
        child: Column(
          children: [
            // --- Custom Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 20),
              color: primaryBlue,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Edit your profile and security settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: Column(
                            children: [
                              // --- Profile Avatar Section ---
                              Container(
                                color: Colors.white,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 42,
                                          backgroundColor: primaryBlue,
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            // Action for changing profile picture
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryBlue,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _fullNameController.text.isEmpty
                                          ? "Katty"
                                          : _fullNameController.text,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // --- Navigation Tabs ---
                              Container(
                                color: Colors.white,
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorColor: primaryBlue,
                                  indicatorWeight: 3,
                                  labelColor: primaryBlue,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  tabs: const [
                                    Tab(text: "Profile Info"),
                                    Tab(text: "Change Password"),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // --- Tab Views Content ---
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  height: 480,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildProfileInfoTab(primaryBlue),
                                      _buildChangePasswordTab(primaryBlue),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Profile Info Tab Design ---
  Widget _buildProfileInfoTab(Color primaryBlue) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Name Field
                _buildFieldLabel(Icons.person_outline, "Full Name"),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _fullNameController,
                  hint: "Enter your full name",
                ),

                const SizedBox(height: 16),

                // Email Field (Read Only)
                _buildFieldLabel(Icons.email_outlined, "Email Address"),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: "email@domain.com",
                  readOnly: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSavingProfile ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isSavingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
              label: Text(
                _isSavingProfile ? "Saving..." : "Save Changes",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Change Password Tab Design ---
  Widget _buildChangePasswordTab(Color primaryBlue) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Use a strong password with at least 8 characters',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Current Password
                _buildFieldLabel(Icons.lock_outline, "Current Password"),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _currentPasswordController,
                  hint: "Enter current password",
                  obscureText: _obscureCurrent,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),

                const SizedBox(height: 16),

                // New Password
                _buildFieldLabel(Icons.lock_outline, "New Password"),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _newPasswordController,
                  hint: "Enter new password",
                  obscureText: _obscureNew,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Password
                _buildFieldLabel(Icons.lock_outline, "Confirm New Password"),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: "Re-enter new password",
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Update Password Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isUpdatingPassword ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: _isUpdatingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
              label: Text(
                _isUpdatingPassword ? "Updating..." : "Update Password",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Field Label Row Helper ---
  Widget _buildFieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // --- TextField Helper Widget ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? Colors.grey.shade700 : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}