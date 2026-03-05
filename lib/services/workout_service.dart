import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:heart_link_app/screens/history/history_screen.dart';
import 'package:heart_link_app/screens/history/history_repo.dart';

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

    final calories = _calculateCalories(
      avgHr: avgHr.toInt(),
      age: userAge,
      weight: weight,
      gender: gender,
      duration: elapsed,
    );
    final endTime = DateTime.now();
    final startTime = endTime.subtract(elapsed);
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
      'start': Timestamp.fromDate(startTime),
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

  static int _calculateCalories({
    required int avgHr,
    required int age,
    required double weight,
    required String gender,
    required Duration duration,
  }) {
    final minutes = duration.inSeconds / 60.0;

    double perMin;
    if (gender == 'female') {
      perMin = ((0.4472 * avgHr) - (0.1263 * (weight * 0.45359237)) + (0.074 * age) - 20.4022) / 4.184;
    } else {
      perMin = ((0.6309 * avgHr) + (0.1988 * (weight * 0.45359237)) + (0.2017 * age) - 55.0969) / 4.184;
    }

    if (perMin < 0) perMin = 0;
    return (perMin * minutes).round();
  }
}
