import 'package:flutter/material.dart';
import 'package:heart_link_app/screens/heartratedial/hr.state.dart';
import 'package:heart_link_app/radial-gauge.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.config,
  });

  final ActiveWorkoutConfig config;

  @override
  Widget build(BuildContext context) {
    return GaugeChart(
        userDeviceId: config.userDeviceId,
        isOnline: config.isOnline,
        isHost: config.isHost,
        workoutMode: config.workoutMode,
        embeddedInShell: true,
    );
  }
}