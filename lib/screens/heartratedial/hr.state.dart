import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveWorkoutConfig {
  final String userDeviceId;
  final bool isHost;
  final bool isOnline;
  final String workoutMode;

  const ActiveWorkoutConfig({
    required this.userDeviceId,
    required this.isHost,
    required this.isOnline,
    required this.workoutMode,
  });
}

class HrState extends ChangeNotifier {
  static const _kAgeKey = 'hr.age';
  static const _kCustomMaxKey = 'hr.customMax';

  int? _age;
  int? _customMaxHr;
  bool _sessionActive = false;
  ActiveWorkoutConfig? _activeWorkout;

  int? get age => _age;
  int? get customMaxHr => _customMaxHr;
  bool get sessionActive => _sessionActive;
  ActiveWorkoutConfig? get activeWorkout => _activeWorkout;

  int get maxHr {
    if (_customMaxHr != null) return _customMaxHr!;
    final a = _age ?? 0;
    return (208 - 0.7 * a).round();
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _age = sp.getInt(_kAgeKey);
    _customMaxHr = sp.getInt(_kCustomMaxKey);
    notifyListeners();
  }

  Future<void> updateAge(int age) async {
    _age = age;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kAgeKey, age);
    notifyListeners();
  }

  Future<void> setCustomMaxHr(int? value) async {
    _customMaxHr = value;
    final sp = await SharedPreferences.getInstance();

    if (value == null) {
      await sp.remove(_kCustomMaxKey);
    } else {
      await sp.setInt(_kCustomMaxKey, value);
    }

    notifyListeners();
  }

  void setWorkoutConfig(ActiveWorkoutConfig config) {
    _activeWorkout = config;
    notifyListeners();
  }

  void startWorkout(ActiveWorkoutConfig config) {
    _sessionActive = true;
    _activeWorkout = config;
    notifyListeners();
  }

  void endWorkout() {
    _sessionActive = false;
    _activeWorkout = null;
    notifyListeners();
  }

  void clearWorkout() {
    _sessionActive = false;
    _activeWorkout = null;
    notifyListeners();
  }
}

final HrState hrState = HrState();