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
        .orderBy('createdAt', descending: true)
        .get();

    final List<HistoryEntry> out = [];

    for (final doc in snap.docs) {
      final data = doc.data();

      final DateTime start = (data['createdAt'] as Timestamp).toDate();
      final int avgHr = (data['avgHr'] as num?)?.toInt() ?? 0;
      final int durationSec = data['durationSeconds'] as int? ?? 0;
      final int calories = data['calories'] as int? ?? 0;
      final List<int> series = (data['bpmSeries'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [];

      final workout = Workout(
        type: data['type'] ?? "Workout",
        start: start,
        duration: Duration(seconds: durationSec),
        avgHr: avgHr,
        calories: calories,
      );

      out.add(HistoryEntry(
        workout: workout,
        series: series,
      ));
    }

    return out;
  }
}
