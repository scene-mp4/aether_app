import 'package:flutter/material.dart';
import '../main.dart';
import 'main_nav.dart';

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
  final TextEditingController usernameField = TextEditingController();
  final TextEditingController passwordField = TextEditingController();

  void checkLogin() {
    String username = usernameField.text;
    String password = passwordField.text;

    // placeholder, wala pa firebase
    if (username == 'admin' && password == 'admin') {
      print("Correct details, login successful.");
    } else {
      print("Incorrect details.");
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
                "wala pa tayo logo",
                style: TextStyle(fontSize: 10)
              ),
              SizedBox(height: 35),
              TextField(
                controller: usernameField,
                decoration: InputDecoration(labelText: 'Username')
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
                      onPressed:() => checkLogin(), 
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
                onPressed:() => print("Register button pressed"), 
                child: Text("Register", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                
            ],
          ),
        ) ,
        )
    );
  }
}