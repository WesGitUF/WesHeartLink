import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HrState extends ChangeNotifier {
  // storage key for age and maxhr
  static const _kAgeKey = 'hr.age';
  static const _kCustomMaxKey = 'hr.customMax';

  int? _age;            
  int? _customMaxHr; 

  int? get age => _age;
  int? get customMaxHr => _customMaxHr;

  int get maxHr {
    if (_customMaxHr != null) return _customMaxHr!;
    final a = _age ?? 0;
    return (208 - 0.7 * a).round();
  }

  bool _sessionActive = false;
  bool get sessionActive => _sessionActive;

  void setSessionActive(bool active) {
    if (_sessionActive == active) return;
    _sessionActive = active;
    notifyListeners();
  }

  // load saved hr setting from local storage
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _age = sp.getInt(_kAgeKey);
    _customMaxHr = sp.getInt(_kCustomMaxKey);
    notifyListeners();
  }

  // update age and save to storage
  Future<void> updateAge(int age) async {
    _age = age;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kAgeKey, age);
    notifyListeners();
  }

  // set custom max hr
  Future<void> setCustomMaxHr(int? v) async {
    _customMaxHr = v;
    final sp = await SharedPreferences.getInstance();
    if (v == null) {
      await sp.remove(_kCustomMaxKey);
    } else {
      await sp.setInt(_kCustomMaxKey, v);
    }
    notifyListeners();
  }
}

// global instance for access
final HrState hrState = HrState();
