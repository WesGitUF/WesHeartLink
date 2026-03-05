import 'dart:async';
import 'package:flutter/services.dart';

class WorkoutNotificationService {
  static const _method = MethodChannel('heart_link/workout_notification');
  static const _events = EventChannel('heart_link/workout_notification_events');

  static StreamSubscription? _sub;

  static void listenForActions(void Function() onEndWorkout) {
    _sub?.cancel();
    _sub = _events.receiveBroadcastStream().listen((event) {
      if (event is Map && event['action'] == 'END_WORKOUT') {
        onEndWorkout();
      }
    });
  }

  static Future<void> start({String? title, String? text}) async {
    await _method.invokeMethod('startWorkoutNotification', {
      'title': title ?? 'Heart Link',
      'text': text ?? 'Workout in progress',
    });
  }

  static Future<void> stop() async {
    await _method.invokeMethod('stopWorkoutNotification');
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}