import 'package:flutter/material.dart';
import '../bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  
  // Custom color from your image
  final Color customBgColor = const Color(0xFFF8FAF5);

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the name from Firebase
    _nameController.text = user?.displayName ?? "";
  }

  Future<void> _updateDisplayName() async {
    try {
      await user?.updateDisplayName(_nameController.text);
      await user?.reload(); // Refresh the user object
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Manage Account", style: TextStyle(color: Color(0xFF545E56))),
        iconTheme: const IconThemeData(color: Color(0xFF545E56)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("Profile Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF545E56))),
          const SizedBox(height: 20),
          
          // Name Field
          _buildTextField("Full Name", _nameController, Icons.person_outline),
          
          const SizedBox(height: 20),
          
          // Email Field (Read Only usually, as changing email requires re-auth)
          _buildReadOnlyField("Email Address", user?.email ?? "No email found", Icons.email_outlined),
          
          const SizedBox(height: 30),
          
          ElevatedButton(
            onPressed: _updateDisplayName,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 82, 163, 255), // Matching your switch color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
          ),
          
          const SizedBox(height: 40),
          const Divider(),
          
          // Account Actions
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.blueGrey),
            title: const Text("Reset Password"),
            subtitle: const Text("Send a reset link to your email"),
            onTap: () async {
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset email sent!")));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // Add a confirmation dialog here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5C6BC0))),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: Colors.black26),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
        const Divider(color: Colors.black12),
      ],
    );
  }
}