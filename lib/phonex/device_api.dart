import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceApi {
  static const _ch = MethodChannel('lifeos/device');

  static Future<bool> startMonitor() async =>
      (await _ch.invokeMethod<bool>('startMonitor')) ?? false;

  static Future<bool> stopMonitor() async =>
      (await _ch.invokeMethod<bool>('stopMonitor')) ?? false;

  static Future<bool> serviceRunning() async =>
      (await _ch.invokeMethod<bool>('serviceRunning')) ?? false;

  static Future<Map<String, dynamic>> batteryNow() async =>
      Map<String, dynamic>.from((await _ch.invokeMapMethod('batteryNow')) ?? {});

  static Future<Map<String, dynamic>> deviceInfo() async =>
      Map<String, dynamic>.from((await _ch.invokeMapMethod('deviceInfo')) ?? {});

  static Future<List<Map<String, dynamic>>> events(int from, int to) async {
    final r = await _ch.invokeMethod('events', {'from': from, 'to': to});
    return _toMaps(r);
  }

  static Future<List<Map<String, dynamic>>> callLog(int from) async {
    final r = await _ch.invokeMethod('callLog', {'from': from});
    return _toMaps(r);
  }

  static Future<List<Map<String, dynamic>>> usageStats(int from) async {
    final r = await _ch.invokeMethod('usageStats', {'from': from});
    return _toMaps(r);
  }

  static Future<List<Map<String, dynamic>>> installedApps() async {
    final r = await _ch.invokeMethod('installedApps');
    return _toMaps(r);
  }

  static Future<void> clearEvents() => _ch.invokeMethod('clearEvents');

  static Future<Map<String, dynamic>?> lockConfig(String pkg) async {
    final r = await _ch.invokeMethod('lockConfig', {'pkg': pkg});
    return r == null ? null : Map<String, dynamic>.from(r as Map);
  }

  static Future<bool> setLock(String pkg, int pin, int smartMinutes) async =>
      (await _ch.invokeMethod('setLock', {'pkg': pkg, 'pin': pin, 'smartMinutes': smartMinutes})) ?? false;

  static Future<bool> removeLock(String pkg) async =>
      (await _ch.invokeMethod('removeLock', {'pkg': pkg})) ?? false;

  static Future<List<String>> lockedApps() async =>
      List<String>.from((await _ch.invokeMethod('lockedApps')) as List? ?? []);

  static Future<int> failedAttempts(String pkg) async =>
      (await _ch.invokeMethod('failedAttempts', {'pkg': pkg})) as int? ?? 0;

  static Future<bool> usageAccessGranted() async =>
      (await _ch.invokeMethod('usageAccessGranted')) ?? false;

  static Future<bool> notifListenerEnabled() async =>
      (await _ch.invokeMethod('notifListenerEnabled')) ?? false;

  static Future<bool> accessibilityEnabled() async =>
      (await _ch.invokeMethod('accessibilityEnabled')) ?? false;

  static Future<void> unlockNow(String pkg, int minutes) =>
      _ch.invokeMethod('unlockNow', {'pkg': pkg, 'minutes': minutes});

  static Future<void> openUsageSettings() => _ch.invokeMethod('openUsageSettings');
  static Future<void> openNotifSettings() => _ch.invokeMethod('openNotifSettings');
  static Future<void> openAccessibilitySettings() => _ch.invokeMethod('openAccessibilitySettings');
  static Future<void> launchApp(String pkg) => _ch.invokeMethod('launchApp', {'pkg': pkg});

  static Future<bool> requestCallLog() async {
    final s = await Permission.phone.request();
    return s.isGranted;
  }

  static Future<bool> requestNotifications() async {
    if (await Permission.notification.status.isGranted) return true;
    final s = await Permission.notification.request();
    return s.isGranted;
  }

  static List<Map<String, dynamic>> _toMaps(dynamic r) {
    final list = r as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}