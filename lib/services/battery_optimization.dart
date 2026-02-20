import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimization {
  static const _channel = MethodChannel('heart_link/battery_optimization');
  static const _askedKey = 'askedBatteryOpt_v1';

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

  /// Show prompt once when user starts a session
  static Future<void> maybePromptOnce(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    final alreadyAsked = sp.getBool(_askedKey) ?? false;
    if (alreadyAsked) return;

    bool ignoring;
    try {
      ignoring = await isIgnoringOptimization();
    } catch (_) {
      return; // platform call failed, don't block user
    }

    if (ignoring) return;

    // Mark as asked BEFORE showing
    await sp.setBool(_askedKey, true);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Allow background workout tracking'),
        content: const Text(
          'To keep your session running while using other apps, '
              'set Battery usage to Unrestricted for HeartLink.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await requestIgnoreOptimization();
              } catch (_) {
                await openAppSettings();
              }
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }
}