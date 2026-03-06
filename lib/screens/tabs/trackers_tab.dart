import 'package:flutter/material.dart';
import '../bottom_navbar.dart';

import 'package:flutter/material.dart';
import '../bottom_navbar.dart';

class TrackersTab extends StatefulWidget {
   @override
  _TrackersTabState createState() => _TrackersTabState();
}

class _TrackersTabState extends State<TrackersTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trackers")),
      body: Center(
        child: Column(
          children: [
            Text('Trackers Page WIP')
          ],
        ),)
      );
  }
}