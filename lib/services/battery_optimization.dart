import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimization {
  static const _channel = MethodChannel('heart_link/battery_optimization');


  /// Check if battery optimization is already disabled
  static Future<bool> isIgnoringOptimization() async {
    final res =
    await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return res ?? false;
  }

  /// Opens the system prompt asking to disable optimization
  static Future<void> requestIgnoreOptimization() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  /// Opens app settings page (fallback)
  static Future<void> openAppSettings() async {
    await _channel.invokeMethod('openAppSettings');
  }

  static Future<void> openBatteryOptimizationSettings() async {
    await _channel.invokeMethod('openBatteryOptimizationSettings');
  }
}