import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:heart_link_app/screens/history/history_screen.dart' show Workout;
import 'package:heart_link_app/screens/history/history_repo.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> saveEntry(HistoryEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final workout = entry.workout;
    final data = {
      'type': workout.type,
      'start': Timestamp.fromDate(workout.start),
      'durationSeconds': workout.duration.inSeconds,
      'avgHr': workout.avgHr,
      'calories': workout.calories,
      'bpmSeries': entry.series,               
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = await _db
        .collection('users')
        .doc(user.uid)
        .collection('workout')  
        .add(data);
    return ref.id;
  }

  Future<List<HistoryEntry>> loadEntriesForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('workout')  
        .orderBy('start', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();

      final workout = Workout(
        type: data['type'] as String? ?? 'Unknown',
        start: (data['start'] as Timestamp).toDate(),
        duration: Duration(
          seconds: (data['durationSeconds'] as int?) ?? 0,
        ),
        avgHr: data['avgHr'] as int? ?? 0,
        calories: data['calories'] as int? ?? 0,
      );

      final List<dynamic> rawSeries =
          (data['bpmSeries'] as List<dynamic>? ?? []);
      final series =
          rawSeries.map((e) => (e as num).toInt()).toList();

      return HistoryEntry(id: doc.id, workout: workout, series: series);
    }).toList();
  }

  // delete a workout entry base on docid
  Future<void> deleteEntry(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('workout')  
        .doc(id)
        .delete();
  }
}