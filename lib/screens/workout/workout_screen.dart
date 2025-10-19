import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Workout')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.directions_run), title: Text('Running')),
          Divider(height: 0),
          ListTile(leading: Icon(Icons.directions_walk), title: Text('Walking')),
          Divider(height: 0),
          ListTile(leading: Icon(Icons.pool), title: Text('Swimming')),
        ],
      ),
    );
  }
}