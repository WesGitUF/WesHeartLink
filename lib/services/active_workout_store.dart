import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveWorkoutStore {
  static const _kActive   = 'session.active';
  static const _kStart    = 'session.start';
  static const _kElapsed  = 'session.elapsed';
  static const _kPaused   = 'session.paused';
  static const _kBpmLog   = 'session.bpmLog';
  static const _kMaxHr    = 'session.maxHr';
  static const _kSumHr    = 'session.sumHr';
  static const _kTimesHr  = 'session.timesHr';

  // save the current workout data
  static Future<void> save({
    required bool active,
    required DateTime start,
    required Duration elapsed,
    required bool paused,
    required List<int> bpmLog,
    required int maxHr,
    required int sumHr,
    required int timesHr,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kActive, active);
    await sp.setInt(_kStart, start.millisecondsSinceEpoch);
    await sp.setInt(_kElapsed, elapsed.inMilliseconds);
    await sp.setBool(_kPaused, paused);
    await sp.setString(_kBpmLog, jsonEncode(bpmLog));
    await sp.setInt(_kMaxHr, maxHr);
    await sp.setInt(_kSumHr, sumHr);
    await sp.setInt(_kTimesHr, timesHr);
  }

  // read the exercise statues from last time if have
  static Future<Map<String, dynamic>?> load() async {
    final sp = await SharedPreferences.getInstance();
    final active = sp.getBool(_kActive) ?? false;
    if (!active) return null;

    final startMs  = sp.getInt(_kStart);
    final elapsedMs = sp.getInt(_kElapsed);
    final paused   = sp.getBool(_kPaused);
    final bpmLogJson = sp.getString(_kBpmLog);
    final maxHr    = sp.getInt(_kMaxHr);
    final sumHr    = sp.getInt(_kSumHr);
    final timesHr  = sp.getInt(_kTimesHr);

    if (startMs == null ||
        elapsedMs == null ||
        paused == null ||
        bpmLogJson == null ||
        maxHr == null ||
        sumHr == null ||
        timesHr == null) {
      return null;
    }

    return {
      'start':   DateTime.fromMillisecondsSinceEpoch(startMs),
      'elapsed': Duration(milliseconds: elapsedMs),
      'paused':  paused,
      'bpmLog':  List<int>.from(jsonDecode(bpmLogJson) as List),
      'maxHr':   maxHr,
      'sumHr':   sumHr,
      'timesHr': timesHr,
    };
  }

  // clean all the workout data
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kActive);
    await sp.remove(_kStart);
    await sp.remove(_kElapsed);
    await sp.remove(_kPaused);
    await sp.remove(_kBpmLog);
    await sp.remove(_kMaxHr);
    await sp.remove(_kSumHr);
    await sp.remove(_kTimesHr);
  }
}