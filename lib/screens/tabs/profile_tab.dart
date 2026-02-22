import 'package:flutter/material.dart';
import '../bottom_navbar.dart';

import 'package:flutter/material.dart';
import '../bottom_navbar.dart';

class ProfileTab extends StatefulWidget {
   @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(
        child: Column(
          children: [
            Text('Profile Page WIP')
          ],
        ),)
      );
  }
}