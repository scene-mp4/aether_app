import 'package:flutter/material.dart';
import '../bottom_navbar.dart';

class SettingsTab extends StatefulWidget {
   @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Center(
        child: Column(
          children: [
            Text('Settings Page WIP')
          ],
        ),)
      );
  }
}