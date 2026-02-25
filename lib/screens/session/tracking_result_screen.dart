import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:heart_link_app/screens/home/home_screen.dart';
import 'package:heart_link_app/shell/app_shell.dart';

class TrackingResultScreen extends StatelessWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final String workoutMode;
  final IconData workoutModeIcon;
  final int maxHeartRate;
  final double avgHeartRate;
  final List<int> series;
  final String topZone;
  final bool isSolo;

  const TrackingResultScreen({
    super.key, 
    required this.elapsedTime, 
    required this.sameZoneTime, 
    required this.workoutMode, 
    required this.workoutModeIcon,
    required this.maxHeartRate,
    required this.avgHeartRate,
    required this.series,
    required this.topZone,
    required this.isSolo
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // height of your appbar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: AppBar(
            backgroundColor: Colors.redAccent,
            centerTitle: true,
            title: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
             Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text('Great Job!', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  Text('Workout Statistics:', style: TextStyle(fontSize: 36), textAlign: TextAlign.center),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 80),
                child: _StatsBox(
                  elapsedTime: elapsedTime, 
                  sameZoneTime: sameZoneTime, 
                  workoutMode: workoutMode, 
                  workoutModeIcon: workoutModeIcon,
                  maxHeartRate: maxHeartRate,
                  avgHeartRate: avgHeartRate,
                  series: series,
                  topZone: topZone,
                  isSolo: isSolo,
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}

class _StatsBox extends StatelessWidget {
  final Duration elapsedTime;
  final Duration sameZoneTime;
  final String workoutMode;
  final IconData workoutModeIcon;
  final int maxHeartRate;
  final double avgHeartRate;
  final List<int> series;
  final String topZone;
  final bool isSolo;
  const _StatsBox({required this.elapsedTime, 
    required this.sameZoneTime, 
    required this.workoutMode, 
    required this.workoutModeIcon,
    required this.maxHeartRate,
    required this.avgHeartRate,
    required this.series,
    required this.topZone,
    required this.isSolo
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  int _caloriesCal({
    required int avgHr,
    required int age,
    required double weight,
    required String gender,
    required Duration duration,
  }) {
    final minutes = duration.inSeconds / 60.0;

    double perMin;

    if (gender == 'female') {
      perMin = ((0.4472 * avgHr - 0.1263 * weight + 0.074 * age - 20.4022) / 4.184);
    } else {
      perMin = ((0.6309 * avgHr - 0.1988 * weight + 0.2017 * age - 55.0969) / 4.184);
    }

    // prevent negative calories
    if (perMin < 0) perMin = 0;

    return (perMin * minutes).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            workoutModeIcon,
            size: 50
          ),
          Text('Workout Type: $workoutMode', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Elapsed Time: ${_formatDuration(elapsedTime)}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (!isSolo) ...[
            Text('Time in Same Zone: ${_formatDuration(sameZoneTime)}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
            const SizedBox(height: 24)],
          Text('Max Heart Rate: $maxHeartRate', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Average Heart Rate: ${avgHeartRate.round()}', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Peak Heart Rate Zone: $topZone', style: const TextStyle(fontSize: 24), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                print("USER NAME: $user");
                int userAge = 0;
                double weight = 70.0;
                String gender = "";
                // Fetch additional user data from Firestore
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                if (userDoc.exists) {
                  final userData = userDoc.data();
                  if (userData != null) {
                    userAge = userData['age'] ?? 0;
                    weight = (userData['weight'] != null) ? double.tryParse(userData['weight'].toString()) ?? 70.0 : 70.0;
                    gender = userData['gender'] ?? "";
                  }
                }

                FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('workouts')
                  .add({
                    'avgHr': avgHeartRate,
                    'bpmSeries': series,
                    'calories': _caloriesCal(avgHr: avgHeartRate.toInt(), age: userAge, weight: weight, gender: gender, duration: elapsedTime),
                    'createdAt': FieldValue.serverTimestamp(),
                    'durationSeconds': elapsedTime.inSeconds,
                    //'maxHr': maxHeartRate,
                    //'topZone': topZone,
                    'start': FieldValue.serverTimestamp(),
                    'type': workoutMode,
                  });
              }
              else {
                print("USER IS NULL");
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AppShell()),
                (_) => false, // This predicate ensures all previous routes are removed
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text('Return Home', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
