import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController usernameField = TextEditingController();
  final TextEditingController emailField = TextEditingController();
  final TextEditingController passwordField = TextEditingController();
  final TextEditingController confirmPasswordField = TextEditingController();

  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _register() async {
    if (passwordField.text.trim() != confirmPasswordField.text.trim()) {
      _showSnackBar('Passwords do not match.');
      return;
    }

    if (usernameField.text.trim().isEmpty) {
      _showSnackBar('Username cannot be empty.');
      return;
    }

    if (emailField.text.trim().isEmpty) {
      _showSnackBar('Email cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailField.text.trim(),
        password: passwordField.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': usernameField.text.trim(),
        'email': emailField.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Account created successfully!');
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message;

      if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already exists.';
      } else {
        message = 'Registration failed: ${e.message}';
      }

      _showSnackBar(message);

    } catch (e) {
      _showSnackBar('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                "PolluTracker",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 35),

              TextField(
                controller: usernameField,
                decoration: InputDecoration(labelText: 'Username'),
              ),

              SizedBox(height: 20),

              TextField(
                controller: emailField,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 20),

              TextField(
                controller: passwordField,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),

              SizedBox(height: 20),

              TextField(
                controller: confirmPasswordField,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
              ),

              SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                        "Register", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}