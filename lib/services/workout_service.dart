import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:heart_link_app/models/heart_rate_zone.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';
import 'package:heart_link_app/services/active_workout_store.dart';
import 'package:heart_link_app/services/bpm_log_file.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<String?> saveEntry({
    required double avgHr,
    required List<int> bpmSeries,
    required Duration elapsed,
    required String workoutMode,
    required int maxSessionHr,
    required String topZone,
    required int theoreticalMaxHr,
    DateTime? startTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    int userAge = 0;
    double weight = 70.0;
    String gender = '';

    try {
      final userDoc =
          await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          userAge = data['age'] ?? 0;
          weight = (data['weight'] != null)
              ? double.tryParse(data['weight'].toString()) ?? 70.0
              : 70.0;
          gender = data['gender'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('WorkoutService.saveEntry – failed to load profile: $e');
    }

    final calories = calculateCalories(
      avgHr: avgHr.toInt(),
      age: userAge,
      weight: weight,
      gender: gender,
      duration: elapsed,
    );
    final endTime = startTime != null
        ? startTime.add(elapsed)
        : DateTime.now();
    final resolvedStartTime = startTime ?? endTime.subtract(elapsed);
    final ref = await _db
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .add({
      'avgHr': avgHr,
      'bpmSeries': bpmSeries,
      'calories': calories,
      'createdAt': Timestamp.fromDate(endTime),
      'durationSeconds': elapsed.inSeconds,
      'maxSessionHr': maxSessionHr,
      'topZone': topZone,
      'start': Timestamp.fromDate(resolvedStartTime),
      'type': workoutMode,
      'theoreticalMaxHr': theoreticalMaxHr,
    });

    return ref.id;
  }

  Future<List<HistoryEntry>> loadEntriesForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .get();

    final List<HistoryEntry> out = [];

    for (final doc in snap.docs) {
      final data = doc.data();

      final startTs = data['start'];
      if (startTs == null) continue;
      final DateTime start = (startTs as Timestamp).toDate().toLocal();
      final int avgHr = _asInt(data['avgHr']);
      final int durationSec = _asInt(data['durationSeconds']);
      final int calories = _asInt(data['calories']);
      final int? theoreticalMaxHr =
          data['theoreticalMaxHr'] == null ? null : _asInt(data['theoreticalMaxHr']);
      final int? maxSessionHr =
          data['maxSessionHr'] == null ? null : _asInt(data['maxSessionHr']);
      final String? topZone =
          data['topZone'] == null ? null : data['topZone'].toString();
      final List<int> series = (data['bpmSeries'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [];

      final workout = Workout(
        type: (data['type'] ?? 'Workout').toString(),
        start: start,
        duration: Duration(seconds: durationSec),
        avgHr: avgHr,
        calories: calories,
        theoreticalMaxHr: theoreticalMaxHr,
        maxSessionHr: maxSessionHr,
        topZone: topZone,
      );

      out.add(HistoryEntry(
        id: doc.id,
        workout: workout,
        series: series,
      ));
    }

    return out;
  }

  /// Checks for a workout that was interrupted by a crash and saves it to
  /// Firestore. Returns true if a workout was recovered, false otherwise.
  static Future<bool> recoverCrashedWorkout() async {
    final saved = await ActiveWorkoutStore.load();
    if (saved == null) return false;

    final elapsed = saved['elapsed'] as Duration;
    final timesHr = saved['timesHr'] as int;

    // Discard trivially short sessions (< 10 s) or sessions with no HR data
    if (elapsed.inSeconds < 10 || timesHr == 0) {
      await ActiveWorkoutStore.clear();
      return false;
    }

    final bpmLog          = await BpmLogFile.readAll();
    final sumHr           = saved['sumHr'] as int;
    final maxHr           = saved['maxHr'] as int;
    final workoutMode     = saved['workoutMode'] as String;
    final theoreticalMaxHr = saved['theoreticalMaxHr'] as int;
    final start           = saved['start'] as DateTime;
    final avgHr           = sumHr / timesHr;

    // Compute the zone the user spent most time in
    String topZone = 'Zone 1';
    if (bpmLog.isNotEmpty && theoreticalMaxHr > 0) {
      final zoneCounts = <String, int>{};
      for (final bpm in bpmLog) {
        final zone = getZoneForHR(bpm, theoreticalMaxHr);
        zoneCounts[zone.name] = (zoneCounts[zone.name] ?? 0) + 1;
      }
      topZone = zoneCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    try {
      await WorkoutService().saveEntry(
        avgHr: avgHr,
        bpmSeries: bpmLog,
        elapsed: elapsed,
        workoutMode: workoutMode,
        maxSessionHr: maxHr,
        topZone: topZone,
        theoreticalMaxHr: theoreticalMaxHr,
        startTime: start,
      );
    } catch (e) {
      debugPrint('WorkoutService.recoverCrashedWorkout – save failed: $e');
      return false;
    }

    await ActiveWorkoutStore.clear();
    await BpmLogFile.clear();
    return true;
  }

  Future<void> deleteEntry(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .doc(id)
        .delete();
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int calculateCalories({
    required int avgHr,
    required int age,
    required double weight,
    required String gender,
    required Duration duration,
  }) {
    final minutes = duration.inSeconds / 60.0;
    final normalizedGender = gender.toLowerCase();

    double perMin;
    if (normalizedGender == 'female') {
      perMin = ((0.4472 * avgHr) - (0.05741 * (weight * 0.45359237)) + (0.074 * age) - 20.4022) / 4.184;
    } else {
      perMin = ((0.6309 * avgHr) + (0.09036 * (weight * 0.45359237)) - 55.0969 + (0.2017 * age)) / 4.184;
    }

    if (perMin < 0) perMin = 0;
    return (perMin * minutes).round();
  }
}
