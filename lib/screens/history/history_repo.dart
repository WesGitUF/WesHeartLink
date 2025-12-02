import 'package:flutter/foundation.dart';
import 'history_screen.dart' show Workout;
import 'package:heart_link_app/services/workout_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A single workout record entry
class HistoryEntry {
  final Workout workout;
  final List<int> series;

  HistoryEntry({
    required this.workout,
    required this.series,
  });
}

class HistoryRepo extends ChangeNotifier {
  HistoryRepo._();
  static final HistoryRepo instance = HistoryRepo._();

  List<HistoryEntry> _entries = [];
  final WorkoutService _service = WorkoutService();

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // Load cloud workouts for logged-in user
  Future<void> loadFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;

    // If not logged in, clear data
    if (user == null) {
      _entries = [];
      notifyListeners();
      return;
    }

    try {
      // Load workouts for this user
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .orderBy('timestamp', descending: true)
          .get();

      final List<HistoryEntry> newEntries = [];

      for (final doc in snap.docs) {
        final data = doc.data();

        // Required fields with safe defaults
        final DateTime start =
            (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate().toLocal()
                : DateTime.now();

        final int durationSec = _asInt(data['duration'] ?? 0);
        final Duration duration = Duration(seconds: durationSec);

        final int avgHr = _asInt(data['avgHR'] ?? 0);

        final String type =
            (data['type'] ?? 'Workout').toString();

        final int calories = _asInt(data['caloriesBurned'] ?? 0);

        // Build Workout object for UI
        final workout = Workout(
          type: type,
          start: start,
          duration: duration,
          avgHr: avgHr,
          calories: calories,
        );

        final List<int> series = data['series'] is List
            ? (data['series'] as List)
                .map((e) => _asInt(e))
                .toList()
            : [];

        newEntries.add(HistoryEntry(
          workout: workout,
          series: series,
        ));
      }

      _entries = newEntries;
      notifyListeners();
    } catch (e) {
      debugPrint("HistoryRepo.loadFromCloud ERROR → $e");
    }
  }
}
