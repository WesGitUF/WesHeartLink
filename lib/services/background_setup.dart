import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:heart_link_app/services/battery_optimization.dart';

class BackgroundSetupStatus {
  final bool batteryOk;
  final bool notifOk;

  const BackgroundSetupStatus({
    required this.batteryOk,
    required this.notifOk,
  });

  bool get allOk => batteryOk && notifOk;
}

class BackgroundSetup {
  static Future<BackgroundSetupStatus> check() async {
    if (kIsWeb) {
      return const BackgroundSetupStatus(batteryOk: true, notifOk: true);
    }

    // batteryOk means: app is allowed to ignore Doze (best signal we can check)
    bool batteryOk = true;
    try {
      batteryOk = await BatteryOptimization.isIgnoringOptimization();
    } catch (_) {
      // if the channel fails, don't block UI; just treat as "unknown/ok"
      batteryOk = true;
    }

    // notifOk: Android 13+ needs POST_NOTIFICATIONS
    final notifStatus = await Permission.notification.status;
    final notifOk = notifStatus.isGranted;

    return BackgroundSetupStatus(batteryOk: batteryOk, notifOk: notifOk);
  }

  /// Most reliable: open the app's details page so user can set Unrestricted / permissions.
  static Future<void> fixBattery() async {
    try {
      await BatteryOptimization.requestIgnoreOptimization();
    } catch (_) {
      await BatteryOptimization.openAppSettings();
    }
  }

  static Future<void> fixNotifications() async {
    await Permission.notification.request();
  }
}