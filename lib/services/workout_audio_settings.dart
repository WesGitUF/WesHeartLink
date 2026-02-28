import 'package:shared_preferences/shared_preferences.dart';

class WorkoutAudioSettings {
  static const _audioEnabledKey = 'zoneAudioEnabled';
  static const _audioAssetKey = 'zoneAudioAsset';

  static const String defaultAsset = 'audio/zone_up.m4a';

  // ---- ENABLED ----
  static Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_audioEnabledKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_audioEnabledKey, value);
  }

  // ---- SOUND FILE ----
  static Future<String> getAsset() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_audioAssetKey) ?? defaultAsset;
  }

  static Future<void> setAsset(String asset) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_audioAssetKey, asset);
  }
}