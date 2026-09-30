import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/adhkar_screen.dart';
import 'package:lifeos/screens/deen/arabic_alphabet_screen.dart';
import 'package:lifeos/screens/deen/arabic_harakat_screen.dart';
import 'package:lifeos/screens/deen/arabic_words_screen.dart';
import 'package:lifeos/screens/deen/dua_screen.dart';
import 'package:lifeos/screens/deen/night_routine_screen.dart';
import 'package:lifeos/screens/deen/quran_words_screen.dart';
import 'package:lifeos/screens/deen/review_screen.dart';
import 'package:lifeos/screens/deen/weakness_challenge_screen.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/arabic_weakness.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/night_routine.dart';
import 'package:lifeos/services/review_scheduler.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 📊 আমার আরবি যাত্রা — কোন দিকে কতটা জানা, কতটা কঠিন।
/// শুধু রেকর্ড (স্কোর নয়): জানা/কঠিন চিহ্নগুলোই এক জায়গায় হিসাব।
/// "কঠিন" থেকে "জানি ✓" দিলে নিচে থাকা দুর্বলতা-তালিকা থেকেও সরে যায়।
class ArabicJourneyScreen extends StatefulWidget {
  const ArabicJourneyScreen({super.key});

  @override
  State<ArabicJourneyScreen> createState() => _ArabicJourneyScreenState();
}

class _CatItem {
  final String emoji;
  final String label;
  final int known;
  final int total;
  final int hard;

  const _CatItem(this.emoji, this.label, this.known, this.total, this.hard);
}

class _ArabicJourneyScreenState extends State<ArabicJourneyScreen> {
  List<_CatItem>? _cats;
  List<WeakItem> _weak = [];

  /// আজকের আমাল-কার্ডের জন্য — যিকির প্রতিদিন রিসেট হয়, তাই সেটি
  /// "জানা" হিসাবে নয়, আলাদা দৈনিক রেকর্ড হিসেবে দেখানো হয়।
  List<AdhkarItem> _adhkar = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lettersF = ArabicSeed.letters();
    final wordsF = ArabicSeed.words();
    final vocabF = ArabicSeed.vocab();
    final harakatF = ArabicSeed.harakat();
    final surahsF = DeenSeed.surahs();
    final duasF = DeenSeed.duas();
    final letters = await lettersF; // ignore: omit_local_variable_types
    final words = await wordsF;
    final vocab = await vocabF;
    final harakat = await harakatF;
    final surahs = await surahsF;
    final duas = await duasF;
    final joinKeys = _joinKeys(letters);

    int lettersK = 0, lettersH = 0;
    int joinK = 0, joinH = 0;
    int harakK = 0, harakH = 0;
    int wordK = 0, wordH = 0;
    int vocabK = 0, vocabH = 0;
    int quranK = 0, quranH = 0;
    int duaK = 0, duaH = 0;

    for (final k in DeenStore.arabicKnown()) {
      if (k.startsWith('a:')) {
        lettersK++;
      } else if (k.startsWith('join')) {
        joinK++;
      } else if (k.startsWith('harak:')) {
        harakK++;
      } else if (k.startsWith('vocab:')) {
        vocabK++;
      } else if (k.startsWith('read:') || k.startsWith('mem:')) {
        quranK++;
      } else if (k.startsWith('dua-learn:')) {
        // পুরো দোয়া পড়া — শব্দ-চর্চার গোনায় ঢুকবে না
        duaK++;
      } else {
        wordK++;
      }
    }
    for (final k in DeenStore.arabicHard()) {
      if (k.startsWith('hard:read:')) {
        quranH++;
      } else if (k.startsWith('hard:vocab:')) {
        vocabH++;
      } else if (k.startsWith('hard:dua')) {
        duaH++;
      } else if (k.startsWith('hard:')) {
        wordH++;
      } else if (k.startsWith('join')) {
        joinH++;
      } else if (k.startsWith('harak:')) {
        harakH++;
      } else if (k.startsWith('a:')) {
        lettersH++;
      }
    }

    final totalAyah = surahs.fold<int>(0, (sum, s) => sum + s.ayahs.length);

    final cats = <_CatItem>[
      _CatItem('🔤', 'অক্ষর চেনা', lettersK, letters.length, lettersH),
      _CatItem('🔗', 'জোড়া-যোগ', joinK, joinKeys.length, joinH),
      _CatItem('➰', 'হরকত', harakK, harakat.length, harakH),
      _CatItem('📖', 'শব্দ চর্চা', wordK, words.length, wordH),
      _CatItem('🗝️', 'কুরআন শব্দ', vocabK, vocab.length, vocabH),
      _CatItem('🕌', 'কুরআন পড়া', quranK, totalAyah, quranH),
      _CatItem('🤲', 'দুআ', duaK, duas.length, duaH),
    ];

    final weak = await WeaknessService.load();
    final adhkar = await DeenSeed.adhkar();

    if (!mounted) return;
    setState(() {
      _cats = cats;
      _weak = weak;
      _adhkar = adhkar;
    });
  }

  /// জোড়া-ল্যাবের মতোই ডিটারমিনিস্টিক জেনারেশন — মোট সংখ্যা মেলাতে।
  static List<String> _joinKeys(List<ArabicLetterItem> letters) {
    final nonJoiner = letters.where((l) => !l.connectsForward).toList();
    final conn = letters.where((l) => l.connectsForward).toList();
    final keys = <String>[];
    final seen = <String>{};
    for (final n in nonJoiner) {
      keys.add('join0:${n.id}');
    }
    var i = 0;
    var join2 = 0;
    while (join2 < 30 && i < 6000) {
      final a = conn[i % conn.length];
      final b = letters[(i * 7 + 3) % letters.length];
      final key = '${a.id}:${b.id}';
      if (seen.add(key)) {
        keys.add('join2:$key');
        join2++;
      }
      i++;
    }
    for (final n in nonJoiner) {
      final bIdx =
          (letters.indexWhere((l) => l.id == n.id) * 5 + 11) % letters.length;
      final key = '${n.id}:${letters[bIdx].id}';
      if (seen.add(key)) {
        keys.add('join2:$key');
        join2++;
      }
    }
    i = 0;
    while (join2 < 56 && i < 8000) {
      final a = conn[i % conn.length];
      final b = letters[(i * 5 + 11) % letters.length];
      final c = letters[(i * 13 + 7) % letters.length];
      final key = '${a.id}:${b.id}:${c.id}';
      if (seen.add(key)) {
        keys.add('join2:$key');
        join2++;
      }
      i++;
    }
    return keys;
  }

  static String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final cats = _cats;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: cats == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListenableBuilder(
                    listenable: Listenable.merge([
                      Hive.box('deen_arabic').listenable(),
                      Hive.box('amal_log').listenable(),
                      Hive.box('salah_log').listenable(),
                      Hive.box('memorization').listenable(),
                      Hive.box('deen_review').listenable(),
                    ]),
                    builder: (context, _) {
                      final knownSum = cats.fold<int>(0, (s, x) => s + x.known);
                      final totalSum = cats.fold<int>(0, (s, x) => s + x.total);
                      final pct = totalSum == 0 ? 0.0 : knownSum / totalSum;
                      final hardSum = cats.fold<int>(0, (s, x) => s + x.hard);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '📊 আমার আরবি যাত্রা',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _overallCard(c, pct, knownSum, totalSum, hardSum),
                          const SizedBox(height: 16),
                          Text(
                            'কোন দিকে কত এগিয়েছ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final cat in cats)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _catRow(c, cat),
                            ),
                          const SizedBox(height: 12),
                          _todayAmalCard(c),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 0,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '🩹 কঠিন ⚠️ — বেশি দরকার এগুলো',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: c.textSecondary,
                                ),
                              ),
                              if (_weak.isNotEmpty) ...[
                                FilledButton.tonalIcon(
                                  onPressed: () => Navigator.of(context).push(
                                    FadeRoute(const WeaknessChallengeScreen()),
                                  ),
                                  icon: const Icon(
                                    Icons.bolt_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    '🎯 চ্যালেঞ্জ শুরু',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    for (final w in List.of(_weak)) {
                                      DeenStore.hardUnmark(w.hardKey);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_sweep_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'সব সেরে ফেলি',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_weak.isEmpty)
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              borderRadius: BorderRadius.circular(16),
                              child: Text(
                                '🎉 কোনো কঠিন নেই! পড়ার সময় কোনো কিছু আটকালে ⚠️ দাও — এখানে এসে বারবার দেখবে।',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: c.textSecondary,
                                ),
                              ),
                            )
                          else
                            for (final w in _weak)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _weakCard(c, w),
                              ),
                          const SizedBox(height: 6),
                          Text(
                            'রেকর্ড শুধু — স্কোর/গিল্টি নয়। নিজের গতিতে এগোও।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _overallCard(
    AppColors c,
    double pct,
    int knownSum,
    int totalSum,
    int hardSum,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _bnPct(pct),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: c.glow,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_bnNum(knownSum)}/${_bnNum(totalSum)} একক চেনা',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_bnNum(hardSum)} টা ⚠️ কঠিন বাকি',
                    style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 9,
              backgroundColor: c.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(c.glow),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'পড়ার জন্য ২৮ অক্ষর, হরকত, জোড়া, শব্দ আর কুরআনের মোট এককের হিসাব — প্রতিটা "জানি ✓" হিসেবে গোনা হয়।',
            style: TextStyle(fontSize: 11, height: 1.4, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  static String _bnPct(double p) {
    return '${_bnNum((p * 100).round())}%';
  }

  /// আজকের আমাল — নামাজ, যিকির, ঘুম রুটিন ও কুরআন, এক জায়গায়।
  Widget _todayAmalCard(AppColors c) {
    final key = DeenStore.dayKey(DateTime.now());
    final log = DeenStore.dayLog(key);
    final salahDone =
        DeenStore.prayers.where((p) => log[p]?.done ?? false).length;
    final dhikr = DeenStore.adhkarDoneToday();
    final morning = _adhkar.where((a) => a.isMorning);
    final evening = _adhkar.where((a) => a.isEvening);
    final morningDone = morning.any((a) => dhikr.contains(a.id));
    final eveningDone = evening.any((a) => dhikr.contains(a.id));
    final nightDone = DeenStore.nightStepsDoneToday().length;
    final nightTotal = NightRoutine.order.length;
    final quranMin = DeenStore.quranMinutesToday();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আজকের আমাল',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'প্রতিদিনের আমল — রেকর্ড, স্কোর নয়',
          style: TextStyle(fontSize: 10.5, color: c.textSecondary),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _amalRow(
                c,
                icon: Icons.mosque_rounded,
                label: 'নামাজ',
                value: '${_bnNum(salahDone)}/${_bnNum(DeenStore.prayers.length)}',
                done: salahDone >= DeenStore.prayers.length,
              ),
              const SizedBox(height: 10),
              _amalRow(
                c,
                icon: Icons.auto_awesome_rounded,
                label: 'যিকির',
                value: morningDone && eveningDone
                    ? 'সকাল ✓ সন্ধ্যা ✓'
                    : morningDone
                    ? 'সন্ধ্যা ○'
                    : 'সকাল ○',
                done: morningDone && eveningDone,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdhkarScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _amalRow(
                c,
                icon: Icons.bedtime_rounded,
                label: 'ঘুম রুটিন',
                value: '${_bnNum(nightDone)}/${_bnNum(nightTotal)} ধাপ',
                done: nightDone >= nightTotal && nightTotal > 0,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NightRoutineScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _amalRow(
                c,
                icon: Icons.menu_book_rounded,
                label: 'কুরআন পড়া',
                value: '${_bnNum(quranMin)} মিনিট',
                done: quranMin > 0,
              ),
              const SizedBox(height: 10),
              _amalRow(
                c,
                icon: Icons.psychology_rounded,
                label: 'মুখস্থ',
                value: '${_bnNum(DeenStore.memorizedTodayIds().length)} টি',
                done: DeenStore.memorizedTodayIds().isNotEmpty,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.12)),
              const SizedBox(height: 4),
              _reviewRow(c),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔁 পুনরাল্লাপ — "জানি ✓" দেওয়া শব্দ ভুলে যাওয়ার আগে আবার আসে।
  Widget _reviewRow(AppColors c) {
    final due = ReviewScheduler.dueCount;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: due == 0
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReviewScreen()),
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                Icons.autorenew_rounded,
                size: 17,
                color: due > 0 ? c.glow : c.lowPriority,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'পুনরাল্লাপ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                due == 0 ? 'আজ শেষ ✓' : '${_bnNum(due)} টি বাকি',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: due > 0 ? c.glow : c.lowPriority,
                ),
              ),
              if (due > 0) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amalRow(
    AppColors c, {
    required IconData icon,
    required String label,
    required String value,
    required bool done,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: done ? c.lowPriority : c.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: done ? c.lowPriority : c.textSecondary,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _catRow(AppColors c, _CatItem cat) {
    final pct = cat.total == 0 ? 0.0 : cat.known / cat.total;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _catTarget(cat.label),
          child: Row(
        children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: c.surfaceColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 0.8 ? c.lowPriority : c.glow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_bnNum(cat.known)}/${_bnNum(cat.total)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c.textSecondary,
            ),
          ),
          if (cat.hard > 0) ...[
            const SizedBox(width: 6),
            Text(
              '⚠️${_bnNum(cat.hard)}',
              style: TextStyle(fontSize: 11, color: c.mediumPriority),
            ),
          ],
              if (_catTarget(cat.label) != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: c.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// যে ক্যাটাগরিগুলোর নিজস্ব স্ক্রিন আছে, সেগুলোতে চাপ দিলে সেখানে যাওয়া যায়।
  VoidCallback? _catTarget(String label) {
    switch (label) {
      case 'দুআ':
        return () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DuaScreen()),
        );
      case 'অক্ষর চেনা':
        return () => Navigator.of(context).push(
          FadeRoute(const AlphabetScreen()),
        );
      case 'হরকত':
        return () => Navigator.of(context).push(
          FadeRoute(const ArabicHarakatScreen()),
        );
      case 'শব্দ চর্চা':
        return () => Navigator.of(context).push(
          FadeRoute(const ArabicWordsScreen()),
        );
      case 'কুরআন শব্দ':
        return () => Navigator.of(context).push(
          FadeRoute(const QuranWordsScreen()),
        );
      default:
        return null;
    }
  }

  Widget _weakCard(AppColors c, WeakItem w) {
    return GlassCard(
      padding: const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  w.label,
                  style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                ),
              ),
              IconButton(
                onPressed: () => speakPron(w.reading),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.volume_up_rounded, size: 18, color: c.glow),
              ),
            ],
          ),
          Text(
            w.ar,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: kArabicFont,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: c.textPrimary,
            ),
          ),
          if (w.reading.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                w.reading,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.glow,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    DeenStore.resolveHardAndKnown(w.hardKey, w.knownKey);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text(
                    'এখন জানি ✓',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.lowPriority,
                    side: BorderSide(
                      color: c.lowPriority.withValues(alpha: 0.6),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    DeenStore.hardUnmark(w.hardKey);
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                  label: const Text(
                    'তাড়াহুড়া? বাদ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.mediumPriority,
                    side: BorderSide(
                      color: c.mediumPriority.withValues(alpha: 0.4),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
