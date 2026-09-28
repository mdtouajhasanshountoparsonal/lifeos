import 'dart:math';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'package:lifeos/phonex/device_api.dart';
import 'package:lifeos/phonex/phonex_engine.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';

class PhonexScreen extends StatefulWidget {
  const PhonexScreen({super.key});

  @override
  State<PhonexScreen> createState() => _PhonexScreenState();
}

class _PhonexScreenState extends State<PhonexScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _serviceOn = false;

  Map<String, dynamic> _device = {};
  Map<String, dynamic> _battery = {};
  bool _usageAccess = false;
  bool _notifAccess = false;
  bool _callAccess = false;

  List<PxEvent> _allEvents = [];
  List<CallEntry> _calls = [];
  List<AppUsage> _usage = [];
  Map<String, String> _labels = {};

  int get _todayStart {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.millisecondsSinceEpoch;
  }

  List<PxEvent> get _today => _allEvents.where((e) => e.ts >= _todayStart).toList();
  List<PxEvent> get _last24 => _allEvents;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final y = _todayStart - 86400000;

    final d = await DeviceApi.deviceInfo();
    final b = await DeviceApi.batteryNow();
    final evs = await DeviceApi.events(y, now);
    final calls = await DeviceApi.callLog(_todayStart);
    final usage = await DeviceApi.usageStats(_todayStart);
    final apps = await DeviceApi.installedApps();
    final service = await DeviceApi.serviceRunning();

    if (!mounted) return;
    setState(() {
      _device = d;
      _battery = b;
      _allEvents = evs.map(PxEvent.fromMap).toList()..sort((a, b) => a.ts.compareTo(b.ts));
      _calls = calls.map(CallEntry.fromMap).toList();
      _usage = usage.map(AppUsage.fromMap).toList()
        ..removeWhere((u) => u.pkg == 'com.lifeos.lifeos')
        ..sort((a, b) => b.totalTimeSec.compareTo(a.totalTimeSec));
      _labels = {
        for (final a in apps.map(InstalledApp.fromMap)) a.pkg: a.label
      };
      _serviceOn = service;
      _loading = false;
    });

    _usageAccess = await DeviceApi.usageAccessGranted();
    _notifAccess = await DeviceApi.notifListenerEnabled();
    _callAccess = await _requestedCallLog();
  }

  Future<bool> _requestedCallLog() async {
    final l = await DeviceApi.callLog(_todayStart);
    return l.isNotEmpty;
  }

  void _goTo(int t) => setState(() => _tab = t);

  void _setService(bool on) => setState(() => _serviceOn = on);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final pages = [
      _OverviewTab(key: ValueKey('ov'), data: this, c: c),
      _TimelineTab(key: ValueKey('tl'), data: this, c: c),
      _BatteryTab(key: ValueKey('bt'), data: this, c: c),
      _AppsTab(key: ValueKey('ap'), data: this, c: c),
      _InsightsTab(key: ValueKey('in'), data: this, c: c),
    ];
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('PHONEX',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: c.textPrimary)),
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
            ),
          ],
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(color: c.primary),
              )
            : RefreshIndicator(
                color: c.primary,
                onRefresh: _refresh,
                child: IndexedStack(index: _tab, children: pages),
              ),
        bottomNavigationBar: _navBar(context, c),
        floatingActionButton: _commandFab(context, c),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _navBar(BuildContext context, AppColors c) {
    // 4 tabs + center Command button; battery lives under tab index 2
    // and opens via the Overview device card or the "বattery history" command.
    final items = [
      (0, Icons.monitor_heart_rounded, 'ওভারভিউ'),
      (1, Icons.history_rounded, 'টাইমলাইন'),
      (3, Icons.apps_rounded, 'অ্যাপ'),
      (4, Icons.insights_rounded, 'বিশ্লেষণ'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceColor.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: c.textSecondary.withValues(alpha: 0.12))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                if (i != 2)
                  Expanded(
                    child: _navItem(context, c, items[i].$1, items[i].$2, items[i].$3),
                  )
                else
                  const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, AppColors c, int i, IconData icon, String label) {
    final sel = _tab == i;
    return InkWell(
      onTap: () => setState(() => _tab = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: sel ? c.glow : c.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? c.glow : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandFab(BuildContext context, AppColors c) {
    return FloatingActionButton(
      onPressed: () => _openCommand(context, c),
      backgroundColor: c.primary,
      child: Icon(Icons.terminal_rounded, color: Colors.white, size: 26),
    );
  }

  void _openCommand(BuildContext context, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceColor.withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⌁ COMMAND',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: c.glow),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(c, 'কী ঘটেছে আজ?', Icons.calendar_today_rounded, () {
                    Navigator.pop(context);
                    _goTo(1);
                  }),
                  _chip(c, 'বattery history', Icons.battery_charging_full_rounded, () {
                    Navigator.pop(context);
                    _goTo(2);
                  }),
                  _chip(c, 'অস্বাভাবিক কার্যকলাপ', Icons.warning_amber_rounded, () {
                    Navigator.pop(context);
                    _goTo(4);
                  }),
                  _chip(c, 'Notification peak', Icons.notifications_active_rounded, () {
                    Navigator.pop(context);
                    _goTo(4);
                  }),
                  _chip(c, 'App usage', Icons.apps_rounded, () {
                    Navigator.pop(context);
                    _goTo(3);
                  }),
                  _chip(c, 'While you were away', Icons.airline_seat_individual_suite_rounded, () {
                    Navigator.pop(context);
                    _showAwayReport(context, c);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(AppColors c, String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: c.cardColor,
      avatar: Icon(icon, size: 16, color: c.glow),
      label: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  void _showAwayReport(BuildContext context, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceColor.withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => AnywhereReport(c: c, events: _allEvents, calls: _calls),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final _PhonexScreenState data;
  final AppColors c;
  const _OverviewTab({super.key, required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    final today = data._today;
    final series = batterySeries(data._last24);
    final charges = chargeSessions(data._last24, series);
    final sessions = screenSessions(today);
    final t = today;
    final screenSec = sessions.fold<int>(0, (a, s) => a + s.durationSec);
    final unlockCount = t.where((e) => e.type == 'unlock').length;
    final isCharging = data._battery['charging'] == true;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _deviceCard(context, c, isCharging),
        const SizedBox(height: 14),
        _monitorCard(context, c),
        const SizedBox(height: 14),
        _todayGrid(c, today, calls: data._calls, charges: charges.length,
            screenSec: screenSec, unlockCount: unlockCount, networkEvents: networkTimeline(today).length),
        const SizedBox(height: 14),
        _awayCard(context, c),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _deviceCard(BuildContext context, AppColors c, bool isCharging) {
    final level = (data._battery['percent'] as int?) ?? 0;
    final temp = (data._battery['tempC'] as num?)?.toDouble() ?? 0;
    final model = '${data._device['brand']} ${data._device['model']}';
    return GestureDetector(
      onTap: () => data._goTo(2),
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.gradientTop,
            c.gradientBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.glow.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: c.glow.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: _RingPainter(
                percent: level / 100,
                color: c.glow,
                track: c.cardColor.withValues(alpha: 0.6),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$level%',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary)),
                    if (isCharging)
                      Icon(Icons.bolt_rounded, size: 12, color: c.secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY DEVICE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: c.textSecondary)),
                const SizedBox(height: 4),
                Text(model,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.thermostat_rounded, size: 15, color: c.textSecondary),
                    const SizedBox(width: 4),
                    Text('${temp.toStringAsFixed(1)}°C',
                        style: TextStyle(fontSize: 13, color: c.textSecondary)),
                    const SizedBox(width: 14),
                    Icon(Icons.bolt_rounded,
                        size: 15,
                        color: isCharging ? c.secondary : c.textSecondary),
                    const SizedBox(width: 4),
                    Text(isCharging ? 'Charging' : 'On battery',
                        style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, size: 9, color: const Color(0xFF3DDC97)),
                    const SizedBox(width: 5),
                    Text('Device Healthy',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3DDC97))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _monitorCard(BuildContext context, AppColors c) {
    return _pxCard(c, children: [
      Row(
        children: [
          Expanded(
            child: _permRow(context, c, 'Usage access', data._usageAccess, Icons.query_stats_rounded, () => DeviceApi.openUsageSettings()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _permRow(context, c, 'Notification lsnr', data._notifAccess, Icons.notifications_rounded, () => DeviceApi.openNotifSettings()),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _permRow(context, c, 'Call log', data._callAccess, Icons.phone_in_talk_rounded, () => DeviceApi.requestCallLog()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _serviceRow(c),
          ),
        ],
      ),
    ]);
  }

  Widget _permRow(BuildContext context, AppColors c, String label, bool ok,
      IconData icon, VoidCallback? onTap) {
    final col = ok ? const Color(0xFF3DDC97) : const Color(0xFFFFB454);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: col),
                const Spacer(),
                Icon(Icons.circle, size: 8, color: col),
              ],
            ),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _serviceRow(AppColors c) {
    final on = data._serviceOn;
    final col = on ? const Color(0xFF3DDC97) : const Color(0xFFFFB454);
    return InkWell(
      onTap: () async {
        if (on) {
          await DeviceApi.stopMonitor();
        } else {
          await DeviceApi.requestNotifications();
          await DeviceApi.startMonitor();
        }
        if (data.mounted) {
          data._setService(!on);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radar_rounded, size: 16, color: col),
                const Spacer(),
                Icon(Icons.circle, size: 8, color: col),
              ],
            ),
            const SizedBox(height: 6),
            Text(on ? 'Monitor ON' : 'Monitor OFF',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _todayGrid(AppColors c, List<PxEvent> today,
      {required List<CallEntry> calls,
      required int charges,
      required int screenSec,
      required int unlockCount,
      required int networkEvents}) {
    final incoming = calls.where((c2) => c2.type == 1).length;
    final outgoing = calls.where((c2) => c2.type == 2).length;
    final missed = calls.where((c2) => c2.type == 3).length;
    final talkSec =
        calls.where((c2) => c2.type == 1 || c2.type == 2).fold<int>(0, (a, c2) => a + c2.durationSec);

    final items = [
      (Icons.notifications_rounded, today.where((e) => e.type == 'notif').length, 'নোটিফিকেশন', c.primary),
      (Icons.phone_callback_rounded, missed, 'মিসড কল', c.mediumPriority),
      if (charges > 0)
        (Icons.bolt_rounded, charges, 'চার্জিং', c.secondary)
      else
        (Icons.bolt_rounded, 0, 'চার্জিং', c.secondary),
      (Icons.timer_rounded, fmtDur(screenSec), 'স্ক্রিন টাইম', c.glow),
      (Icons.lock_open_rounded, unlockCount, 'আনলক', c.lowPriority),
      (Icons.forum_rounded, calls.length, 'কল', c.highPriority),
    ];

    return _pxCard(
      c,
      title: 'TODAY',
      children: [
        Row(
          children: [
            Expanded(
              child: _statItem(c, Icons.north_east_rounded, '$incoming/$outgoing', 'in/out কল'),
            ),
            Expanded(
              child: _statItem(c, Icons.timer_outlined, fmtDurShort(talkSec), 'কথা বলেছো'),
            ),
            Expanded(
              child: _statItem(c, Icons.wifi_rounded, '$networkEvents', 'নেটওয়ার্ক পরিবর্তন'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            for (final it in items) _statItemColor(c, it.$1, it.$2, it.$3, it.$4),
          ],
        ),
      ],
    );
  }

  Widget _statItem(AppColors c, IconData icon, dynamic value, String label) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ],
    );
  }

  Widget _statItemColor(AppColors c, IconData icon, dynamic value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text('$value',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _awayCard(BuildContext context, AppColors c) {
    return InkWell(
      onTap: () => data._showAwayReport(context, c),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.primary.withValues(alpha: 0.22), c.surfaceColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.airline_seat_individual_suite_rounded, color: c.primary, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('While You Were Away',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 3),
                  Text('তুমি ফোন থেকে দূরে থাকার সময়ের পুরো রিপোর্ট',
                      style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _pxCard(AppColors c, {String? title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: c.textSecondary)),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final _PhonexScreenState data;
  final AppColors c;
  const _TimelineTab({super.key, required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    final today = data._today;
    if (today.isEmpty) {
      return _empty(c, 'এখনো কোনো ইভেন্ট নেই।\nMonitor চালু রাখো — কিছুক্ষণের মধ্যে টাইমলাইন জমবে।');
    }
    final byHour = <int, List<PxEvent>>{};
    for (final e in today) {
      final h = DateTime.fromMillisecondsSinceEpoch(e.ts).hour;
      byHour.putIfAbsent(h, () => []).add(e);
    }
    final hours = byHour.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final h in hours) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Row(
              children: [
                Container(width: 18, height: 3,
                    decoration: BoxDecoration(color: c.glow, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(_hourLabel(h),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textSecondary)),
                const Spacer(),
                Text('${byHour[h]!.length}টি ঘটনা',
                    style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.8))),
              ],
            ),
          ),
          for (final e in byHour[h]!)
            _eventRow(context, c, e),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  String _hourLabel(int h) {
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:00 $period';
  }

  Widget _eventRow(BuildContext context, AppColors c, PxEvent e) {
    final icon = _icon(e);
    final label = _label(c, e);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, height: 34, child: Center(child: Text(icon.$1, style: const TextStyle(fontSize: 17)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                if (e.extra != null && e.type == 'notif')
                  Text(e.extra!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textSecondary)),
              ],
            ),
          ),
          Text(fmtShortTime(e.ts),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: icon.$2)),
        ],
      ),
    );
  }

  (String, Color) _icon(PxEvent e) {
    switch (e.type) {
      case 'notif': return ('🔔', c.primary);
      case 'unlock': return ('🔓', c.lowPriority);
      case 'screen_on': return ('💡', Color(0xFFFFE082));
      case 'screen_off': return ('🌙', c.textSecondary);
      case 'charge_on': return ('🔌', c.secondary);
      case 'charge_off': return ('🔋', c.secondary);
      case 'boot': return ('🚀', c.glow);
      case 'network': return ('🌐', Color(0xFF81D4FA));
      case 'notif_removed': return ('🕳️', c.textSecondary);
      default: return ('・', c.textSecondary);
    }
  }

  String _label(AppColors c, PxEvent e) {
    switch (e.type) {
      case 'notif': return data._labels[e.pkg] ?? e.pkg ?? 'নোটিফিকেশন';
      case 'unlock': return 'ফোন আনলক';
      case 'screen_on': return 'স্ক্রিন অন';
      case 'screen_off': return 'স্ক্রিন অফ';
      case 'charge_on': return 'চার্জার লাগানো হয়েছে';
      case 'charge_off': return 'চার্জার খোলা হয়েছে';
      case 'boot': return 'ডিভাইস চালু';
      case 'network': return e.extra == 'wifi' ? 'Wi-Fi সংযুক্ত' : e.extra == 'mobile' ? 'মোবাইল ডেটা' : 'নেটওয়ার্ক';
      case 'notif_connected': return 'নোটিফিকেশন লিসেনার চালু';
      default: return e.type;
    }
  }

  Widget _empty(AppColors c, String msg) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(msg, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textSecondary)),
      ),
    );
}

class _BatteryTab extends StatelessWidget {
  final _PhonexScreenState data;
  final AppColors c;
  const _BatteryTab({super.key, required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    final series = batterySeries(data._last24);
    final charges = chargeSessions(data._last24, series);
    final pct = (data._battery['percent'] as int?) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _currentBattery(c, data._battery),
        const SizedBox(height: 16),
        _gaugeCard(c, pct, series, charges),
        const SizedBox(height: 16),
        _insightCard(c, series, charges),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _currentBattery(AppColors c, Map<String, dynamic> b) {
    final pct = (b['percent'] as int?) ?? 0;
    final temp = (b['tempC'] as num?)?.toDouble() ?? 0;
    final charging = b['charging'] == true;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary.withValues(alpha: 0.35), c.surfaceColor],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _RingPainter(
                        percent: pct / 100,
                        color: pct <= 20 ? c.highPriority : c.secondary,
                        track: c.cardColor),
                    child: Center(
                      child: Text('$pct%',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(charging ? 'চার্জ হচ্ছে ⚡' : 'ব্যাটারি',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${temp.toStringAsFixed(1)}°C তাপমাত্রা',
                          style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      const SizedBox(height: 2),
                      Text(charging
                          ? 'স্বাস্থ্যকর হার'
                          : pct <= 20 ? 'দয়া করে চার্জ দাও' : 'স্বাভাবিক',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: pct <= 20 ? c.highPriority : c.lowPriority)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gaugeCard(AppColors c, int pct, List<BatteryPoint> series, List<ChargeSession> charges) {
    final samples = series.isNotEmpty ? series : [BatteryPoint(ts: DateTime.now().millisecondsSinceEpoch, percent: pct, tempC: 0, charging: false)];
    final first = samples.first.percent;
    final last = samples.last.percent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('BATTERY CURVE — ২৪ ঘণ্টা',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.textSecondary)),
              const Spacer(),
              if (charges.isNotEmpty)
                Text('${charges.length}টি চার্জ',
                    style: TextStyle(fontSize: 12, color: c.secondary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _LinePainter(samples: samples, color: c.secondary, track: c.surfaceColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(c, 'প্রথম ${fmtShortTime(samples.first.ts)}', '$first%'),
              const Spacer(),
              _legend(c, 'এখন', '$last%'),
            ],
          ),
          const SizedBox(height: 14),
          for (final ch in charges.reversed.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: c.secondary),
                  const SizedBox(width: 8),
                  Text('${fmtShortTime(ch.startTs)} → ${fmtShortTime(ch.endTs)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(width: 8),
                  if (ch.startPercent != null && ch.endPercent != null)
                    Text('${ch.startPercent}% → ${ch.endPercent}%',
                        style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  const Spacer(),
                  Text(fmtDur(ch.durationSec),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.glow)),
                ],
              ),
            ),
          if (charges.isEmpty)
            Text('আজ কোনো চার্জ সেশন হয়নি এখনো',
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _legend(AppColors c, String label, String val) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        const SizedBox(width: 6),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textPrimary)),
      ],
    );
  }

  Widget _insightCard(AppColors c, List<BatteryPoint> series, List<ChargeSession> charges) {
    if (charges.isEmpty) {
      return SizedBox.shrink();
    }
    final totalChargeSec = charges.fold<int>(0, (a, ch) => a + ch.durationSec);
    final avgMin = totalChargeSec ~/ charges.length ~/ 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.glow.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: c.glow, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              charges.length == 1
                  ? 'আজ ১ বার চার্জ দিয়েছো, ${fmtDur(totalChargeSec)} লেগেছে।'
                  : 'আজ ${charges.length} বার চার্জ দিয়েছো — গড়ে প্রতি সেশনে ~$avgMin মিনিট।',
              style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppsTab extends StatelessWidget {
  final _PhonexScreenState data;
  final AppColors c;
  const _AppsTab({super.key, required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    if (!data._usageAccess) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_rounded, color: c.textSecondary, size: 40),
              const SizedBox(height: 14),
              Text('App usage দেখতে Usage Access দরকার',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.textSecondary)),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => DeviceApi.openUsageSettings(),
                icon: Icon(Icons.settings_rounded, size: 18),
                label: const Text('Usage Access দিন'),
              ),
            ],
          ),
        ),
      );
    }
    final usage = data._usage;
    if (usage.isEmpty) {
      return Center(
          child: Text('কোনো usage তথ্য নেই', style: TextStyle(color: c.textSecondary)),
      );
    }
    final notifs = notifCounts(data._today);
    final maxTime = usage.fold<int>(0, (a, u) => max(a, u.totalTimeSec));
    final totalSec = usage.fold<int>(0, (a, u) => a + u.totalTimeSec);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.primary.withValues(alpha: 0.22), c.surfaceColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.apps_rounded, color: c.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'আজ ${usage.length} অ্যাপ • মোট ${fmtDur(totalSec)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Icon(Icons.south_rounded, color: c.textSecondary, size: 16),
            ],
          ),
        ),
        for (final u in usage)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.cardColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _avatar(c, u.pkg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data._labels[u.pkg] ?? limitName(medianLabel(u.pkg)),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: c.textSecondary),
                              const SizedBox(width: 3),
                              Text(fmtDur(u.totalTimeSec),
                                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
                              if (notifs[u.pkg] != null) ...[
                                const SizedBox(width: 10),
                                Icon(Icons.notifications_rounded, size: 12, color: c.primary),
                                const SizedBox(width: 3),
                                Text('${notifs[u.pkg]} নোটিফিকেশন',
                                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maxTime > 0 ? u.totalTimeSec / maxTime : 0,
                    minHeight: 5,
                    backgroundColor: c.surfaceColor,
                    valueColor: AlwaysStoppedAnimation<Color>(c.glow),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _avatar(AppColors c, String pkg) {
    final letter = (data._labels[pkg] ?? medianLabel(pkg)).substring(0, 1).toUpperCase();
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c.primary, c.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _InsightsTab extends StatelessWidget {
  final _PhonexScreenState data;
  final AppColors c;
  const _InsightsTab({super.key, required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    final today = data._today;
    final series = batterySeries(data._last24);
    final sessions = screenSessions(today);
    final notifs = notifCounts(today);
    final hours = notifByHour(today);
    final insightLines = _generate(c, today, series, sessions, notifs, hours);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard(c, today, sessions, hills: hours),
        const SizedBox(height: 14),
        Text('AI INSIGHTS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: c.textSecondary)),
        const SizedBox(height: 10),
        for (final (sev, txt) in insightLines)
          _insightRow(c, sev, txt),
        const SizedBox(height: 20),
      ],
    );
  }

  List<(int, String)> _generate(AppColors c, List<PxEvent> today, List<BatteryPoint> series,
      List<ScreenSession> sessions, Map<String, int> notifs, List<int> hours) {
    final out = <(int, String)>[];

    if (notifs.isNotEmpty) {
      final top = notifs.entries.reduce((a, b) => a.value >= b.value ? a : b);
      out.add((0, 'সবচেয়ে বেশি নোটিফিকেশন দিয়েছে ${data._labels[top.key] ?? limitName(medianLabel(top.key))} — ${top.value}টি'));
    }
    if (sessions.isNotEmpty) {
      final longest = sessions.reduce((a, b) => a.durationSec >= b.durationSec ? a : b);
      out.add((0, 'সবচেয়ে দীর্ঘ স্ক্রিন সেশন ${fmtShortTime(longest.startTs)} এ ${fmtDur(longest.durationSec)} ধরে'));
    }
    final peak = _argmax(hours);
    if (peak != -1 && hours[peak] > 0) {
      final n = hours[peak];
      out.add((0, 'নোটিফিকেশনের পিক ${_hourName(peak)} — এই সময়ে ${n}টি নোটিফিকেশন এসেছে'));
      if (peak >= 23 || peak <= 5) {
        out.add((2, 'রাতের বেলা ${n}টি নোটিফিকেশন — সম্ভবত অ্যালার্ম/জরুরি অ্যাপ দায়ী'));
      }
    }
    if (series.length >= 2 && !series.last.charging && series.first.percent - series.last.percent > 15) {
      out.add((1, '২৪ ঘণ্টায় ${series.first.percent}% → ${series.last.percent}% — দ্রুত ব্যাটারি খরচ হয়েছে'));
    }
    final unlockCount = today.where((e) => e.type == 'unlock').length;
    if (unlockCount > 60) {
      out.add((1, 'আজ ${unlockCount} বার ফোন খোলা হয়েছে — স্ক্রিন টাইম কমানোর কথা ভাবো'));
    } else if (unlockCount > 0) {
      out.add((0, 'আজ ${unlockCount} বার আনলক করেছো'));
    }
    if (today.isEmpty) {
      out.add((1, 'আজ এখনো পর্যাপ্ত ডেটা জমেনি — টাইমলাইন আসবে Monitor চলতে থাকলে'));
    }
    return out;
  }

  int _argmax(List<int> a) {
    if (a.isEmpty) return -1;
    var mi = 0;
    for (var i = 1; i < a.length; i++) {
      if (a[i] > a[mi]) mi = i;
    }
    return a[mi] > 0 ? mi : -1;
  }

  String _hourName(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final p = h >= 12 ? 'PM' : 'AM';
    return '$h12$p';
  }

  Widget _summaryCard(AppColors c, List<PxEvent> today, List<ScreenSession> sessions, {required List<int> hills}) {
    final screenSec = sessions.fold<int>(0, (a, s) => a + s.durationSec);
    final notifCount = today.where((e) => e.type == 'notif').length;
    final unlock = today.where((e) => e.type == 'unlock').length;
    final charges = today.where((e) => e.type == 'charge_on').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.gradientTop, c.gradientBottom],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
              const SizedBox(width: 8),
              Text('DAILY DEVICE REPORT',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(c, fmtDur(screenSec), 'স্ক্রিন'),
              _miniStat(c, '$unlock', 'আনলক'),
              _miniStat(c, '$notifCount', 'নোটিফিকেশন'),
              _miniStat(c, '$charges', 'চার্জ'),
            ],
          ),
          const SizedBox(height: 14),
          _heatmap(c, hills),
        ],
      ),
    );
  }

  Widget _miniStat(AppColors c, String v, String l) {
    return Expanded(
      child: Column(
        children: [
          Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
          Text(l, style: TextStyle(fontSize: 10, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _heatmap(AppColors c, List<int> hours) {
    if (hours.every((h) => h == 0)) {
      return Text('আজ এখনো নোটিফিকেশন হয়নি',
          style: TextStyle(fontSize: 12, color: c.textSecondary));
    }
    final maxV = hours.reduce(max);
    return Column(
      children: [
        for (var h = 0; h < 24; h += 3) ...[
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('${h.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 9, color: c.textSecondary)),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (var k = 0; k < 3; k++)
                      Expanded(
                        child: Container(
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
                          decoration: BoxDecoration(
                            color: (h + k < 24 && hours[h + k] > 0)
                                ? c.primary.withValues(alpha: 0.25 + 0.75 * (hours[h + k] / maxV))
                                : c.cardColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Text('নোটিফিকেশন হিটম্যাপ (৩ ঘণ্টা ব্লক)', style: TextStyle(fontSize: 10, color: c.textSecondary)),
      ],
    );
  }

  Widget _insightRow(AppColors c, int severity, String text) {
    final Color col;
    final IconData ic;
    switch (severity) {
      case 1: col = c.mediumPriority; ic = Icons.info_outline_rounded;
      case 2: col = c.highPriority; ic = Icons.warning_amber_rounded;
      default: col = c.glow; ic = Icons.lightbulb_outline_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ic, size: 18, color: col),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

// ─── Anywhere (while-away) report ────────────────────────────────────────────

class AnywhereReport extends StatelessWidget {
  final AppColors c;
  final List<PxEvent> events;
  final List<CallEntry> calls;

  const AnywhereReport({super.key, required this.c, required this.events, required this.calls});

  @override
  Widget build(BuildContext context) {
    final away = _lastGap();
    if (away == null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: c.lowPriority, size: 40),
            const SizedBox(height: 12),
            Text('দীর্ঘ বিরতি পাওয়া যায়নি', style: TextStyle(fontSize: 15, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text('২০ মিনিটের বেশি ফোন ব্যবহার না হলে এখানে রিপোর্ট দেখাবে',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        ),
      );
    }
    final start = away.$1, end = away.$2;
    final durMin = ((end - start) / 60000).round();
    final inEvents = events.where((e) => e.ts >= start && e.ts <= end).toList();
    final notifCount = inEvents.where((e) => e.type == 'notif').length;
    final missed = calls.where((c2) => c2.type == 3 && c2.date >= start && c2.date <= end).length;
    final msgNotifs = notifCounts(inEvents).entries
        .where((c2) => c2.key.contains(RegExp(r'whatsapp|messenger|telegram|message')))
        .fold<int>(0, (a, e) => a + e.value);
    final series = batterySeries(inEvents);
    var batteryDelta = 0;
    if (series.isNotEmpty) {
      batteryDelta = series.first.percent - series.last.percent;
      if (series.last.charging) batteryDelta = series.last.percent - series.first.percent;
    }
    final netStay = networkTimeline(inEvents).isNotEmpty ? 'বদলেছে' : 'স্থির ছিল';
    final sessions = screenSessions(inEvents);
    final screenGap = sessions.where((s) => s.durationSec > 60).length;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('While You Were Away',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: c.glow)),
          const SizedBox(height: 6),
          Text('তুমি ${fmtShortTime(start)} — ${fmtShortTime(end)} (${durMin} মিনিট) দূরে ছিলে',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 16),
          _line(c, '🔔', notifCount, 'নোটিফিকেশন'),
          _line(c, '📵', missed, 'মিসড কল'),
          _line(c, '💬', msgNotifs, 'মেসেজ নোটিফিকেশন'),
          _line(c, '🔋', batteryDelta < 0 ? -batteryDelta : batteryDelta, 'ব্যাটারি পরিবর্তন (%)'),
          _line(c, '🌐', 0, 'নেটওয়ার্ক $netStay'),
          _line(c, '📱', screenGap, 'স্ক্রিন সেশন'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  (int, int)? _lastGap() {
    final list = events.where((e) => e.type == 'screen_on' || e.type == 'screen_off').toList();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    (int, int)? last;
    int? prevOn;
    for (final e in list) {
      if (e.type == 'screen_off') continue;
      if (prevOn != null) {
        final gap = e.ts - prevOn;
        if (gap >= 20 * 60000 && e.ts <= nowMs) {
          last = (prevOn, e.ts);
        }
      }
      prevOn = e.ts;
    }
    return last;
  }

  Widget _line(AppColors c, String emoji, dynamic value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: c.textPrimary))),
          Text('$value',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color track;
  _RingPainter({required this.percent, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    paint.color = track;
    canvas.drawCircle(center, r, paint);
    paint.color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -pi / 2,
        pi * 2 * percent.clamp(0.0, 1.0), false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent || old.color != color;
}

class _LinePainter extends CustomPainter {
  final List<BatteryPoint> samples;
  final Color color;
  final Color track;
  _LinePainter({required this.samples, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, Paint()..color = color);
      return;
    }
    final minTs = samples.first.ts.toDouble();
    final maxTs = samples.last.ts.toDouble();
    final range = maxTs - minTs > 0 ? maxTs - minTs : 1;
    final pts = <Offset>[];
    for (final s in samples) {
      final x = ((s.ts - minTs) / range) * size.width;
      final y = (1 - s.percent / 100) * size.height;
      pts.add(Offset(x, y));
    }
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final closed = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(closed, fill);
    canvas.drawPoints(PointMode.points, pts, Paint()
      ..color = color
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, line);
    final grid = Paint()
      ..color = track
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.samples != samples;
}