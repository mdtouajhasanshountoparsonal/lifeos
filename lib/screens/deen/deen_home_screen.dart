import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/adhkar_screen.dart';
import 'package:lifeos/screens/deen/arabic_home_screen.dart';
import 'package:lifeos/screens/deen/dua_screen.dart';
import 'package:lifeos/screens/deen/hadith_screen.dart';
import 'package:lifeos/screens/deen/learn_screen.dart';
import 'package:lifeos/screens/deen/memorize_screen.dart';
import 'package:lifeos/screens/deen/post_prayer_screen.dart';
import 'package:lifeos/screens/deen/salah_screen.dart';
import 'package:lifeos/screens/deen/surah_list_screen.dart';
import 'package:lifeos/screens/deen/tasbih_screen.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/pray_times.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/content_gate.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class DeenHomeScreen extends StatelessWidget {
  const DeenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ContentGate(
      child: AppBackground(
        child: Stack(
          children: [
            const MoonBackground(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Text(
                    '🌙 DEEN',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _bnDate(DateTime.now()),
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  const _NextPrayerCard(),
                  const SizedBox(height: 18),
                  const _TodaySummary(),
                  const SizedBox(height: 18),
                  const _PostPrayerResumeCard(),
                  const SizedBox(height: 18),
                  Text(
                    'ইবাদাত',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _moduleCard(
                    c,
                    emoji: '🕌',
                    title: 'নামাজ ট্র্যাকার',
                    subtitle: 'আজকের ৫ ওয়াক্ত, ইতিহাস, সেটিংস',
                    ready: true,
                    color: c.glow,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const SalahScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '📿',
                    title: 'স্মার্ট তাসবিহ',
                    subtitle: 'টোকা টোকা গননা, হিসাব',
                    ready: true,
                    color: c.secondary,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const TasbihScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '🤲',
                    title: 'দুআ লাইব্রেরি',
                    subtitle: 'সোর্সসহ, সেকশন অনুযায়ী',
                    ready: true,
                    color: c.primary,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const DuaScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '📜',
                    title: 'হাদিস লাইব্রেরি',
                    subtitle: 'কিতাব-নম্বর + শ্রেণি ফিল্টার',
                    ready: true,
                    color: c.mediumPriority,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const HadithScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '🌅',
                    title: 'সকাল-সন্ধ্যার আজকার ও আজকের আমল',
                    subtitle: 'যিকির ট্র্যাক + নামাজ/কুরআন/মুখস্থ রেকর্ড',
                    ready: true,
                    color: c.highPriority,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const AdhkarScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '🧠',
                    title: 'মুখস্থ বিদ্যা',
                    subtitle: 'ধাপ ১→৫, পরের দিন আবার recall',
                    ready: true,
                    color: c.secondary,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const MemorizeScreen())),
                  ),
                  _moduleCard(
                    c,
                    emoji: '📚',
                    title: 'আজকের শিক্ষা',
                    subtitle: 'প্রতিদিন একটি দুয়া + Quick Recall',
                    ready: true,
                    color: c.primary,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const LearnScreen())),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'শিখা — আরবি পড়া (কুরআন)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _moduleCard(
                    c,
                    emoji: '🟢',
                    title: 'আরবি পড়া — কুরআন',
                    subtitle: 'অক্ষর → হরকত → শব্দ → ফাতিহার শব্দ পড়া',
                    ready: true,
                    color: c.lowPriority,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const ArabicHomeScreen())),
                  ),
                  const SizedBox(height: 14),
                  _moduleCard(
                    c,
                    emoji: '📖',
                    title: 'কুরআনের সূরা — তালিকা ও পড়া',
                    subtitle:
                        '১১৪ সূরা · যার পাঠ আছে তা থেকে পড়ুন (আরবি + অর্থ)',
                    ready: true,
                    color: c.mediumPriority,
                    onTap: () =>
                        Navigator.of(context)
                            .push(FadeRoute(const SurahListScreen())),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(14),
                    child: Text(
                      'নামাজের সময় আনুমানিক গাণিতিক হিসাব — জামাতের নির্ভুল সময় আপনার মসজিদের রুটিন অনুযায়ী মিলিয়ে নিন।',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(
    AppColors c, {
    required String emoji,
    required String title,
    required String subtitle,
    required bool ready,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: ready ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: ready ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: ready
                              ? c.textPrimary
                              : c.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ready)
                  Icon(Icons.chevron_right_rounded, color: c.textSecondary)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'M2+',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Next prayer card ──────────────────────────────────────────────────
class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Hive.box('deen_settings').listenable(),
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
        final next = today.nextFrom(now);
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nights_stay_rounded, color: c.glow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'পরবর্তী ওয়াক্ত',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (next != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _prayerNames[next.name]!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _tfmt(today.of(next)!),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: c.glow,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'আজকের সব ওয়াক্তের সময় অতিক্রম করেছে — আগামীকাল ফজর থেকে',
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final p in DeenStore.prayers)
                    Column(
                      children: [
                        Text(
                          _prayerNames[p]!,
                          style: TextStyle(
                            fontSize: 10,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tfmt(
                            today.of(
                              PrayerKind.values.firstWhere((k) => k.name == p),
                            )!,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: next?.name == p ? c.glow : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Post-prayer resume banner ─────────────────────────────────────────
class _PostPrayerResumeCard extends StatelessWidget {
  const _PostPrayerResumeCard();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Hive.box('amal_log').listenable(),
      builder: (context, _) {
        final pending = DeenStore.todayPendingPostPrayer();
        final done = DeenStore.todayCompletedPostPrayers();
        if (pending == null && done.isEmpty) return const SizedBox.shrink();
        return GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pending != null
                          ? '${_prayerNames[pending]} এর পরের জিকির চলছে'
                          : 'এখনো কিছু আমল নোট আছে',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (pending != null) ...[
                const SizedBox(height: 4),
                Text(
                  'যেখান থেকে ছিল সেখান থেকে — ধাপ সংরক্ষিত আছে',
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.glow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context)
                            .push(FadeRoute(PostPrayerScreen(prayer: pending))),
                    child: const Text(
                      'চালিয়ে যান',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else if (done.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'আজ ${done.map((p) => _prayerNames[p]).join(' · ')} এর জিকির সম্পন্ন — আলহামদুলিল্লাহ',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: c.lowPriority,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Today summary ─────────────────────────────────────────────────────
class _TodaySummary extends StatelessWidget {
  const _TodaySummary();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Hive.box('salah_log').listenable(),
      builder: (context, _) {
        final key = DeenStore.dayKey(DateTime.now());
        final log = DeenStore.dayLog(key);
        final done = DeenStore.prayers
            .where((p) => log[p]?.done ?? false)
            .length;
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.lowPriority.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🕌', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আজ আদায়ের হিসাব',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'নিজের লেখা — বিচার নয়',
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${_bnNum(done.toString())} / ${_bnNum(DeenStore.prayers.length.toString())}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.lowPriority,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────
const _prayerNames = <String, String>{
  'fajr': 'ফজর',
  'dhuhr': 'যোহর',
  'asr': 'আসর',
  'maghrib': 'মাগরিব',
  'isha': 'ইশা',
};

String _bnNum(String s) {
  const bn = '০১২৩৪৫৬৭৮৯';
  return s.split('').map((c) {
    final i = c.codeUnitAt(0);
    return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
  }).join();
}

String _tfmt(DateTime t) {
  final p = t.hour < 12 ? 'AM' : 'PM';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${_bnNum(h.toString())}:${_bnNum(t.minute.toString().padLeft(2, '0'))} $p';
}

const _bnMonths = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

String _bnDate(DateTime d) =>
    '${_bnNum(d.day.toString())} ${_bnMonths[d.month - 1]}';
