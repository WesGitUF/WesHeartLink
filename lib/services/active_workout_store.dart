import 'package:shared_preferences/shared_preferences.dart';

class ActiveWorkoutStore {
  static const _kActive            = 'session.active';
  static const _kStart             = 'session.start';
  static const _kElapsed           = 'session.elapsed';
  static const _kPaused            = 'session.paused';
  static const _kMaxHr             = 'session.maxHr';
  static const _kSumHr             = 'session.sumHr';
  static const _kTimesHr           = 'session.timesHr';
  static const _kWorkoutMode       = 'session.workoutMode';
  static const _kTheoreticalMaxHr  = 'session.theoreticalMaxHr';

  // BPM series is stored separately in BpmLogFile (append-only binary file)
  // so that SharedPreferences stays small regardless of workout duration.

  static Future<void> save({
    required bool active,
    required DateTime start,
    required Duration elapsed,
    required bool paused,
    required int maxHr,
    required int sumHr,
    required int timesHr,
    required String workoutMode,
    required int theoreticalMaxHr,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kActive, active);
    await sp.setInt(_kStart, start.millisecondsSinceEpoch);
    await sp.setInt(_kElapsed, elapsed.inMilliseconds);
    await sp.setBool(_kPaused, paused);
    await sp.setInt(_kMaxHr, maxHr);
    await sp.setInt(_kSumHr, sumHr);
    await sp.setInt(_kTimesHr, timesHr);
    await sp.setString(_kWorkoutMode, workoutMode);
    await sp.setInt(_kTheoreticalMaxHr, theoreticalMaxHr);
  }

  static Future<Map<String, dynamic>?> load() async {
    final sp = await SharedPreferences.getInstance();
    final active = sp.getBool(_kActive) ?? false;
    if (!active) return null;

    final startMs          = sp.getInt(_kStart);
    final elapsedMs        = sp.getInt(_kElapsed);
    final paused           = sp.getBool(_kPaused);
    final maxHr            = sp.getInt(_kMaxHr);
    final sumHr            = sp.getInt(_kSumHr);
    final timesHr          = sp.getInt(_kTimesHr);
    final workoutMode      = sp.getString(_kWorkoutMode);
    final theoreticalMaxHr = sp.getInt(_kTheoreticalMaxHr);

    if (startMs == null ||
        elapsedMs == null ||
        paused == null ||
        maxHr == null ||
        sumHr == null ||
        timesHr == null) {
      return null;
    }

    return {
      'start':            DateTime.fromMillisecondsSinceEpoch(startMs),
      'elapsed':          Duration(milliseconds: elapsedMs),
      'paused':           paused,
      'maxHr':            maxHr,
      'sumHr':            sumHr,
      'timesHr':          timesHr,
      'workoutMode':      workoutMode ?? 'Workout',
      'theoreticalMaxHr': theoreticalMaxHr ?? 0,
    };
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kActive);
    await sp.remove(_kStart);
    await sp.remove(_kElapsed);
    await sp.remove(_kPaused);
    await sp.remove(_kMaxHr);
    await sp.remove(_kSumHr);
    await sp.remove(_kTimesHr);
    await sp.remove(_kWorkoutMode);
    await sp.remove(_kTheoreticalMaxHr);
  }
}
