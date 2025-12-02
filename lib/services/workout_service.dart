import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';

class WorkoutService {
  Future<List<HistoryEntry>> loadEntriesForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .get();

    final List<HistoryEntry> out = [];

    for (final doc in snap.docs) {
      final data = doc.data();

      final DateTime start = (data['timestamp'] as Timestamp).toDate();
      final int avgHr = (data['avgHR'] as num?)?.toInt() ?? 0;
      final int durationSec = data['duration'] as int? ?? 0;
      final int calories = data['caloriesBurned'] as int? ?? 0;

      final workout = Workout(
        type: data['type'] ?? "Workout",
        start: start,
        duration: Duration(seconds: durationSec),
        avgHr: avgHr,
        calories: calories,
      );

      print("WORKOUT DURATION: ${workout.duration.inSeconds}");

      out.add(HistoryEntry(
        workout: workout,
        series: const [], // not tracked yet
      ));
    }

    return out;
  }
}
