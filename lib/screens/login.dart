import 'package:flutter/material.dart';
import '../main.dart';
import 'bottom_navbar.dart'; 
import 'tabs/Register.dart'; //diko alam kng tama to ayaw kasi gumana nung button para sa register. Tinanong ko yng AI, ito daw kulang sabi


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Contains the main login screen and is the first screen that shows up on app startup.
// TODO (for Login):
// - add show/hide button for password
// - implement login functionality with firebase
// - pollutracker logo (?)
// - polish UI
// - add user registration screen

class LoginScreen extends StatefulWidget {
   @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailField = TextEditingController();
  final TextEditingController passwordField = TextEditingController();
   bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailField.text.trim(), 
        password: passwordField.text.trim(),
      );
      
      Navigator.pushReplacementNamed(context, '/bottom_navbar');
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Login failed: ${e.message}';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Pollutracker",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)
              ),
              Text(
                "lalagyan pa to logo tinatamad pa lang ako",
                style: TextStyle(fontSize: 10)
              ),
              SizedBox(height: 35),
              TextField(
                controller: emailField,
                decoration: InputDecoration(labelText: 'Email Address')
              ),
              SizedBox(height: 20),
                TextField(
                controller: passwordField,
                decoration: InputDecoration(labelText: 'Password')
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed:() => _signIn(), 
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Log In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      ),
                  ],
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ),
              ),
                SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Register()),
                  );
                },
                child: Text("Register"),
              )
            ],
          ),
        ) ,
        )
    );
  }
}