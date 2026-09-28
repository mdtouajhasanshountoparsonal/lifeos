import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/post_prayer_screen.dart';
import 'package:lifeos/services/deen_notifications.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/pray_times.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

const _prayerIcons = <String, String>{
  'fajr': '🌅',
  'dhuhr': '☀️',
  'asr': '🌇',
  'maghrib': '🌆',
  'isha': '🌙',
};

const _prayerNames = <String, String>{
  'fajr': 'ফজর',
  'dhuhr': 'যোহর',
  'asr': 'আসর',
  'maghrib': 'মাগরিব',
  'isha': 'ইশা',
};

class SalahScreen extends StatefulWidget {
  const SalahScreen({super.key});

  @override
  State<SalahScreen> createState() => _SalahScreenState();
}

class _SalahScreenState extends State<SalahScreen> {
  int _tab = 0;
  String? _pending;

  @override
  void initState() {
    super.initState();
    _pending = DeenNotifications.pendingPrayer;
    DeenNotifications.pendingPrayer = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🕌 নামাজ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              _bnDate(DateTime.now()),
                              style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openSettings(context),
                        tooltip: 'নামাজ সেটিংস',
                        icon: Icon(Icons.settings_rounded, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, icon: Icon(Icons.today_rounded, size: 16), label: Text('আজ')),
                      ButtonSegment(value: 1, icon: Icon(Icons.calendar_view_week_rounded, size: 16), label: Text('ইতিহাস')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      Hive.box('salah_log').listenable(),
                      Hive.box('deen_settings').listenable(),
                      Hive.box('amal_log').listenable(),
                    ]),
                    builder: (context, _) {
                      final now = DateTime.now();
                      final today = PrayTimesEngine.compute(
                        date: now,
                        lat: DeenStore.lat,
                        lng: DeenStore.lng,
                        tzMinutes: DeenStore.tzMinutes,
                        method: PrayMethod.fromKey(DeenStore.methodKey),
                        asr: AsrJuristic.fromKey(DeenStore.asrKey),
                        highLat: HighLatRule.fromKey(DeenStore.highLatKey),
                        offsets: DeenStore.offsets,
                      );
                      return _tab == 0
                            ? _todayView(context, c, now, today)
                            : _historyView(context, c, now);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Today ────────────────────────────────────────────────────────────
  Widget _todayView(BuildContext context, AppColors c, DateTime now, PrayerTimeResult today) {
    final next = today.nextFrom(now);
    final pending = DeenStore.todayPendingPostPrayer();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        if (pending != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Text('📿', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_prayerNames[pending]} এর পরের জিকির শুরু হয়েছে — যেখান থেকে ছিল সেখান থেকে চালিয়ে যান',
                      style: TextStyle(fontSize: 12, height: 1.4, color: c.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.glow,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      FadeRoute(PostPrayerScreen(prayer: pending)),
                    ),
                    child: const Text('চালিয়ে যান', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        if (next != null)
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: c.glow.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(_prayerIcons[next.name]!, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পরবর্তী ওয়াক্ত',
                        style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                      ),
                      Text(
                        _prayerNames[next.name]!,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary),
                      ),
                    ],
                  ),
                ),
                Text(
                  _tfmt(today.of(next)!),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.glow),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        ...DeenStore.prayers.map((p) => _todayRow(context, c, p, today, now, highlight: _pending == p)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(14),
          child: Text(
            'সময় আনুমানিক — জামাতের নির্ভুল সময় আপনার মসজিদের রুটিন অনুযায়ী মিলিয়ে নিন। '
            'ওয়াক্ত ট্যাপ করে "আদায় করেছি" চিহ্ন দিলে হিসাব রাখা হবে।',
            style: TextStyle(fontSize: 11.5, height: 1.5, color: c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _todayRow(BuildContext context, AppColors c, String p, PrayerTimeResult today, DateTime now,
      {bool highlight = false}) {
    final t = today.of(PrayerKind.values.firstWhere((k) => k.name == p))!;
    final entry = DeenStore.dayLog(DeenStore.dayKey(now))[p];
    final done = entry?.mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: highlight ? c.glow.withValues(alpha: 0.10) : c.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markSheet(context, p, today, entry),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: highlight
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.glow.withValues(alpha: 0.7), width: 1.4),
                  )
                : null,
            child: Row(
              children: [
                Text(_prayerIcons[p]!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _prayerNames[p]!,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ),
                Text(
                  _tfmt(t),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textSecondary),
                ),
                const SizedBox(width: 12),
                if (done != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.lowPriority.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '✓ ${done.label}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.lowPriority),
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.textSecondary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const SizedBox.expand(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── History ──────────────────────────────────────────────────────────
  Widget _historyView(BuildContext context, AppColors c, DateTime now) {
    final days = DeenStore.lastNDays(7, now);
    const bnDays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি', 'রবি'];
    var doneCount = 0;
    var total = 0;
    for (final d in days) {
      for (final p in DeenStore.prayers) {
        total++;
        if (d.log[p]?.done ?? false) doneCount++;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'গত ৭ দিন',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${_bnNum(doneCount.toString())} / ${_bnNum(total.toString())}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.glow),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'নিজের হিসাব — কোনো বিচার নয়, শুধু দেখা',
                style: TextStyle(fontSize: 11.5, color: c.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(width: 34),
                  for (final d in days)
                    Expanded(
                      child: Text(
                        bnDays[d.date.weekday - 1],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (final p in DeenStore.prayers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(_prayerIcons[p]!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      ),
                      for (final d in days)
                        Expanded(
                          child: Center(
                            child: _dot(context, c, d.log[p]),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context, AppColors c, SalahEntry? entry) {
    final done = entry?.mode;
    final color = done == SalahMode.jamaat
        ? c.lowPriority
        : done == SalahMode.alone
            ? c.primary
            : done == SalahMode.qada
                ? c.mediumPriority
                : c.textSecondary.withValues(alpha: 0.18);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done != null ? color.withValues(alpha: 0.25) : Colors.transparent,
        border: Border.all(color: color, width: 1.6),
      ),
      alignment: Alignment.center,
      child: done != null
          ? Icon(Icons.check_rounded, size: 14, color: color)
          : null,
    );
  }

  // ─── Mark sheet ───────────────────────────────────────────────────────
  void _markSheet(BuildContext context, String p, PrayerTimeResult today, SalahEntry? entry) {
    final c = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_prayerIcons[p]!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_prayerNames[p]} ${_tfmt(today.of(PrayerKind.values.firstWhere((k) => k.name == p))!)}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.textPrimary),
                        ),
                        Text(
                          'কীভাবে আদায় করেছেন?',
                          style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final mode in SalahMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.lowPriority,
                        side: BorderSide(color: c.lowPriority.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        DeenStore.setSalah(DeenStore.dayKey(DateTime.now()), p, mode);
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(FadeRoute(PostPrayerScreen(prayer: p)));
                      },
                      child: Text('আদায় করেছি — ${mode.label}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ),
              if (entry?.done ?? false)
                TextButton(
                  onPressed: () {
                    DeenStore.clearSalah(DeenStore.dayKey(DateTime.now()), p);
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: c.mediumPriority,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('এখনো করিনি — চিহ্ন মুছুন'),
                ),
              const SizedBox(height: 4),
              Text(
                'কোনো assumption নেই — চিহ্ন না দিলে কিছুই বদলায় না।',
                style: TextStyle(fontSize: 10.5, color: c.textSecondary.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Settings ─────────────────────────────────────────────────────────
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }

  // ─── Format helpers ───────────────────────────────────────────────────
  static String _tfmt(DateTime t) {
    final p = t.hour < 12 ? 'AM' : 'PM';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${_bnNum(h.toString())}:${_bnNum(t.minute.toString().padLeft(2, '0'))} $p';
  }

  static String _bnNum(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  static const _bnMonths = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  static String _bnDate(DateTime d) =>
      'আজ, ${_bnNum(d.day.toString())} ${_bnMonths[d.month - 1]}';
}

// ─── Settings sheet ─────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late String _method = DeenStore.methodKey;
  late String _asr = DeenStore.asrKey;
  late String _highLat = DeenStore.highLatKey;
  late bool _notifEnabled = DeenStore.notifEnabled;
  final Map<String, bool> _notifToggles = {
    for (final p in DeenStore.prayers) p: DeenStore.waqtEnabled(p),
  };
  final _latCtrl = TextEditingController(text: DeenStore.lat.toString());
  final _lngCtrl = TextEditingController(text: DeenStore.lng.toString());
  final _tzCtrl = TextEditingController(text: (DeenStore.tzMinutes / 60).toStringAsFixed(0));

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final c = AppTheme.of(context);
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    final tz = double.tryParse(_tzCtrl.text.trim());
    if (lat == null || lng == null || tz == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('অক্ষাংশ, দ্রাঘিমা, টাইমজোন সংখ্যায় দিন'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surfaceColor,
        ));
      return;
    }
    DeenStore.saveSettings(
      method: _method,
      asr: _asr,
      highLat: _highLat,
      lat: lat,
      lng: lng,
      tzMinutes: tz * 60,
    );
    DeenStore.saveNotifSettings(
      enabled: _notifEnabled,
      toggles: _notifToggles,
    );
    await DeenNotifications.rescheduleAll();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'নামাজ সেটিংস',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'সময় গাণিতিক প্রথা অনুযায়ী — ধর্মীয় রায় নয়',
                style: TextStyle(fontSize: 11.5, color: c.textSecondary),
              ),
              const SizedBox(height: 14),
              _label(c, 'গণনা পদ্ধতি (Method)'),
              DropdownButtonFormField<String>(
                initialValue: _method,
                items: [
                  for (final m in PrayMethod.values)
                    DropdownMenuItem(value: m.key, child: Text(m.label, style: TextStyle(fontSize: 13, color: c.textPrimary))),
                ],
                onChanged: (v) => setState(() => _method = v!),
                isExpanded: true,
                dropdownColor: c.surfaceColor,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _label(c, 'আসর মাযহাব'),
              DropdownButtonFormField<String>(
                initialValue: _asr,
                items: [
                  for (final a in AsrJuristic.values)
                    DropdownMenuItem(value: a.key, child: Text(a.label, style: TextStyle(fontSize: 13, color: c.textPrimary))),
                ],
                onChanged: (v) => setState(() => _asr = v!),
                isExpanded: true,
                dropdownColor: c.surfaceColor,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _label(c, 'উচ্চ অক্ষাংশের নিয়ম (৪৮°+)'),
              DropdownButtonFormField<String>(
                initialValue: _highLat,
                items: [
                  for (final h in HighLatRule.values)
                    DropdownMenuItem(value: h.key, child: Text(h.label, style: TextStyle(fontSize: 13, color: c.textPrimary))),
                ],
                onChanged: (v) => setState(() => _highLat = v!),
                isExpanded: true,
                dropdownColor: c.surfaceColor,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              _label(c, 'অবস্থান (ঢাকা: 23.8103, 90.4125)'),
              Row(
                children: [
                  Expanded(
                    child: _numField(c, _latCtrl, 'অক্ষাংশ'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numField(c, _lngCtrl, 'দ্রাঘিমা'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label(c, 'টাইমজোন (UTC+৬ = 6)'),
              _numField(c, _tzCtrl, 'ঘণ্টা'),
              const SizedBox(height: 18),
              _divider(c),
              const SizedBox(height: 16),
              _label(c, 'সময় স্মরণ (নোটিফিকেশন)'),
              _switchTile(
                c,
                icon: '🔔',
                title: 'নামাজের সময় নোটিফিকেশন',
                subtitle: 'প্রতি ওয়াক্তে "সময় হয়েছে" — কোনো দোষ/গিল্টি বার্তা নয়',
                value: _notifEnabled,
                onChanged: (v) => setState(() {
                  _notifEnabled = v;
                  if (v) {
                    for (final p in _notifToggles.keys) {
                      _notifToggles[p] = true;
                    }
                  }
                }),
              ),
              if (_notifEnabled) ...[
                const SizedBox(height: 8),
                for (final p in DeenStore.prayers)
                  _switchTile(
                    c,
                    icon: _prayerIcons[p]!,
                    title: '${_prayerNames[p]} ওয়াক্ত',
                    value: _notifToggles[p] ?? true,
                    onChanged: (v) => setState(() => _notifToggles[p] = v),
                    dense: true,
                  ),
              ],
              if (_notifEnabled)
                Text(
                  'সময় বদলে যায় বলে ২১ দিনের শিডিউল অ্যাপ খুললেই আপডেট হয়। '
                  'নোটিফিকেশন অনুমতি না দিলে নিঃশব্দে বাদ পড়ে — অ্যাপ ভাঙে না।',
                  style: TextStyle(fontSize: 10.5, height: 1.4, color: c.textSecondary.withValues(alpha: 0.8)),
                ),
              const SizedBox(height: 4),
              Text(
                'লোকেশন ও হিসাব ডিভাইসেই থাকে — কোথাও আপলোড হয় না।',
                style: TextStyle(fontSize: 10.5, color: c.textSecondary.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.glow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _save(context),
                  child: const Text('সংরক্ষণ', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(AppColors c, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary)),
      );

  Widget _divider(AppColors c) =>
      Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.12));

  Widget _switchTile(
    AppColors c, {
    required String icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 2 : 0),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: dense ? 13.5 : 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: c.textSecondary)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: c.glow,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _numField(AppColors c, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: TextStyle(fontSize: 14, color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: c.textSecondary.withValues(alpha: 0.7)),
        filled: true,
        fillColor: c.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}