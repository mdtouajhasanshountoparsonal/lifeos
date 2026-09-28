import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lifeos/screens/deen/salah_screen.dart';
import 'package:lifeos/services/app_nav.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/pray_times.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// নামাজের সময় স্মরণ — offline engine থেকে শিডিউল, ট্যাপে deep link।
/// Guilt-message নেই, কোনোরকম assumption নেই।
class DeenNotifications {
  DeenNotifications._();

  static final FlutterLocalNotificationsPlugin _p =
      FlutterLocalNotificationsPlugin();

  /// Payload থেকে ধরা নামাজ — SalahScreen হাইলাইট করে দেখাবে।
  static String? pendingPrayer;

  static const _scheduleDays = 21;
  static const _idBase = 200000;
  static bool _initialized = false;

  static const _names = <String, String>{
    'fajr': 'ফজর',
    'dhuhr': 'যোহর',
    'asr': 'আসর',
    'maghrib': 'মাগরিব',
    'isha': 'ইশা',
  };

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _p.initialize(
      settings: init,
      onDidReceiveNotificationResponse: _onResponse,
    );

    final launch = await _p.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _applyPayload(launch?.notificationResponse);
    }

    await _requestPermission();
  }

  static Future<void> _requestPermission() async {
    final android =
        _p.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<bool> notificationsEnabled() async {
    final android =
        _p.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  static Future<bool> exactAllowed() async {
    final android =
        _p.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  /// setting বদলালে / অ্যাপ খুললে আবার চালাও — timings হালনাগাদ হয়।
  static Future<void> rescheduleAll() async {
    final android =
        _p.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final useExact = await android?.canScheduleExactNotifications() ?? false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var day = 0; day < _scheduleDays; day++) {
      final date = today.add(Duration(days: day));
      final times = PrayTimesEngine.compute(
        date: date,
        lat: DeenStore.lat,
        lng: DeenStore.lng,
        tzMinutes: DeenStore.tzMinutes,
        method: PrayMethod.fromKey(DeenStore.methodKey),
        asr: AsrJuristic.fromKey(DeenStore.asrKey),
        highLat: HighLatRule.fromKey(DeenStore.highLatKey),
        offsets: DeenStore.offsets,
      );

      for (var i = 0; i < DeenStore.prayers.length; i++) {
        final prayer = DeenStore.prayers[i];
        final id = _idBase + day * 10 + i;
        // আগের শিডিউল মুছে দাও (disabled হলে যেন থেকে না যায়)
        await _p.cancel(id: id);

        if (!DeenStore.notifEnabled || !DeenStore.waqtEnabled(prayer)) {
          continue;
        }

        final kind = PrayerKind.values[i];
        final wall = times.of(kind);
        if (wall == null) continue;
        final inst = DateTime.utc(
          wall.year,
          wall.month,
          wall.day,
          wall.hour,
          wall.minute,
        ).subtract(Duration(minutes: DeenStore.tzMinutes.round()));
        final when = tz.TZDateTime.from(inst, tz.UTC);
        if (when.isBefore(tz.TZDateTime.now(tz.UTC))) continue;

        await _p.zonedSchedule(
          id: id,
          title: '🕌 ${_names[prayer]} এর সময় হয়েছে',
          body: 'এখন নামাজ আদায়ের সময়।',
          scheduledDate: when,
          notificationDetails: _details(prayer),
          androidScheduleMode: useExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: _payload(prayer, date),
        );
      }
    }
  }

  static NotificationDetails _details(String prayer) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'deen_salah',
        'নামাজের সময়',
        channelDescription: 'প্রতি ওয়াক্তে সময় স্মরণ করাবে',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  static String _payload(String prayer, DateTime date) =>
      'salah|$prayer|${DeenStore.dayKey(date)}';

  static void _onResponse(NotificationResponse? r) {
    _applyPayload(r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = AppNav.key.currentState;
      if (nav == null) return;
      nav.push(MaterialPageRoute(builder: (_) => const SalahScreen()));
    });
  }

  static void _applyPayload(NotificationResponse? r) {
    final p = r?.payload ?? '';
    if (!p.startsWith('salah|')) return;
    final parts = p.split('|');
    if (parts.length < 2) return;
    pendingPrayer = parts[1];
    if (r?.actionId == 'done' && parts.length >= 3) {
      DeenStore.setSalah(parts[2], parts[1], SalahMode.jamaat);
    }
  }
}