import 'package:shared_preferences/shared_preferences.dart';

class WorkoutHapticSettings {
  static const String _enabledKey = 'workoutHapticEnabled';
  static const bool _defaultEnabled = true;

  static Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_enabledKey) ?? _defaultEnabled;
  }

  static Future<void> setEnabled(bool enabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_enabledKey, enabled);
  }
}