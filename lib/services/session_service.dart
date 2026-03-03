import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('sessions');

  // Session ID generation
  String generateSessionId() {
    final rand = Random();
    final letters = _randomLetters(3);
    final digits = rand.nextInt(1000);
    return '$letters$digits';
  }

  static String _randomLetters(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
  }

  // Create / Join
  Future<void> createSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _sessions.doc(sessionId).set({
      'user1Id': user.uid,
      'user2Id': null,
      'user1HR': 0,
      'user2HR': 0,
      'startTime': FieldValue.serverTimestamp(),
      'sessionActive': true,
    });
  }

  Future<Object> joinSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Please log in first.';

    try {
      final doc = await _sessions.doc(sessionId).get();

      if (!doc.exists) return 'Session not found.';

      final data = doc.data()!;
      if (data['user2Id'] != null) return 'Session is already full!';

      await doc.reference.update({'user2Id': user.uid});
      return true;
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Real-time updates
  void updateHeartRate(String sessionId, {required bool isHost, required int hr}) {
    final field = isHost ? 'user1HR' : 'user2HR';
    _sessions.doc(sessionId).update({field: hr}).catchError(
        (e) => debugPrint('SessionService.updateHeartRate error: $e'));
  }

  Stream<Map<String, dynamic>?> sessionStream(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) => snap.data());
  }

  // End session
  Future<void> endSession(String sessionId) async {
    await _sessions.doc(sessionId).update({'sessionActive': false});
  }

  // User profile helpers
  Future<int> fetchUserAge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['age'] ?? 0;
    } catch (e) {
      debugPrint('SessionService.fetchUserAge error: $e');
      return 0;
    }
  }

  static int computeMaxHr(int age) => (208 - (age * 0.7)).toInt();
}
