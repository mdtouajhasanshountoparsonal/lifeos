import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/arabic_alphabet_screen.dart';
import 'package:lifeos/screens/deen/arabic_harakat_screen.dart';
import 'package:lifeos/screens/deen/arabic_words_screen.dart';
import 'package:lifeos/screens/deen/arabic_teacher_screen.dart';
import 'package:lifeos/screens/deen/content_store_screen.dart';
import 'package:lifeos/screens/deen/grammar_screen.dart';
import 'package:lifeos/screens/deen/hard_words_screen.dart';
import 'package:lifeos/screens/deen/quran_words_screen.dart';
import 'package:lifeos/screens/deen/root_words_screen.dart';
import 'package:lifeos/screens/deen/speak_drill_screen.dart';
import 'package:lifeos/screens/deen/vocabulary_screen.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class ArabicHomeScreen extends StatefulWidget {
  const ArabicHomeScreen({super.key});

  @override
  State<ArabicHomeScreen> createState() => _ArabicHomeScreenState();
}

class _ArabicHomeScreenState extends State<ArabicHomeScreen> {
  int _words = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await ArabicSeed.words();
    if (!mounted) return;
    setState(() => _words = words.length);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Text(
                  '🟢 আরবি পড়া — কুরআন',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'অক্ষর → হরকত → শব্দ → কুরআনের শব্দ পড়া',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _progressCard(c),
                const SizedBox(height: 16),
                _moduleCard(
                  c,
                  emoji: '🔤',
                  title: 'অক্ষর (২৮টি)',
                  subtitle: 'নাম, উচ্চারণ, যোগের রূপ, উদাহরণ',
                  color: c.glow,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const AlphabetScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '🪄',
                  title: 'হরকত (স্বরচিহ্ন)',
                  subtitle: 'ফতহা, কাসরা, দাম্মা, সুকুন, শাদ্দা…',
                  color: c.secondary,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const ArabicHarakatScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '📖',
                  title: 'শব্দ পড়া (${_bn(_words)})',
                  subtitle: 'ছোট শব্দ পড়ে "জানি ✓" চিহ্ন দাও',
                  color: c.primary,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const ArabicWordsScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '🌟',
                  title: 'কুরআনের শব্দ',
                  subtitle: 'সূরা আল-ফাতিহা — শব্দ ধরে ধরে পড়া ও অর্থ',
                  color: c.highPriority,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const QuranWordsScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '📚',
                  title: 'শব্দভাণ্ডার — কুরআন থেকে',
                  subtitle: 'অর্থ, মূলধাতু, আর "কোথায় কোথায় এসেছে"',
                  color: c.mediumPriority,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const VocabularyScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '🌱',
                  title: 'মূলধাতু (Root Words)',
                  subtitle: 'এক শিকড় থেকে কেমন বড় হয় নানা শব্দ',
                  color: c.secondary,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const RootWordsScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '📖',
                  title: 'ব্যাকরণ — ছোট পাঠ',
                  subtitle: 'নাম, আল, নাম-বাক্য, ক্রিয়া — কুরআন দিয়েই',
                  color: c.lowPriority,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const GrammarScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '🧑‍🏫',
                  title: 'আরবি শিক্ষক',
                  subtitle: 'যেকোনো প্রশ্ন — সেভ করা তথ্য থেকে উত্তর, Gemini চালু থাকলে আরও',
                  color: c.glow,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const ArabicTeacherScreen())),
                ),
                ListenableBuilder(
                  listenable: Hive.box('deen_arabic').listenable(),
                  builder: (context, _) {
                    final hard = DeenStore.arabicHard().length;
                    return _moduleCard(
                      c,
                      emoji: '🩹',
                      title: 'কঠিন শব্দ — আরও মুখস্থ',
                      subtitle: hard > 0
                          ? '${_bn(hard)}টি কঠিন চিহ্নিত — এখানে এসে বারবার দেখো'
                          : 'পড়ার সময় কোনো শব্দ আটকালে ⚠️ (কঠিন) চিহ্ন দাও',
                      color: c.highPriority,
                      onTap: () =>
                          Navigator.of(context)
                              .push(FadeRoute(const HardWordsScreen())),
                    );
                  },
                ),
                _moduleCard(
                  c,
                  emoji: '🗣️',
                  title: 'বলে পড়ো — নিজে পড়ো',
                  subtitle: 'আরবি দেখে নিজে পড়ে বলো, তারপর পড়া/অর্থ খুলে দেখো (self-check)',
                  color: c.primary,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const SpeakDrillScreen())),
                ),
                _moduleCard(
                  c,
                  emoji: '🗂️',
                  title: 'কনটেন্ট-স্টোর',
                  subtitle: 'কোন কোন শিখা-সম্পদ আছে, ভার্সন কত — সব বান্ডলে',
                  color: c.textSecondary,
                  onTap: () =>
                      Navigator.of(context)
                          .push(FadeRoute(const ContentStoreScreen())),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(14),
                  child: Text(
                    'আরবি পড়া শিখলে নিজেই কুরআন পড়তে পারবে — কোনো শিক্ষক ছাড়াই। প্রতিদিন সামান্য, ধাপে ধাপে।',
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
    );
  }

  Widget _progressCard(AppColors c) {
    return ListenableBuilder(
      listenable: Hive.box('deen_arabic').listenable(),
      builder: (context, _) {
        final known = DeenStore.arabicKnown().length;
        final hard = DeenStore.arabicHard().length;
        final total = _words > 0 ? _words : 1;
        final pct = (known / total).clamp(0.0, 1.0);
        return GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '📈 আমার রেকর্ড',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.lowPriority.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${_bn(known)} ✓ · ${_bn(hard)} কঠিন',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.lowPriority,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: c.surfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(c.lowPriority),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'নিজের লেখা — বিচার নয়',
                style: TextStyle(fontSize: 10.5, color: c.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moduleCard(
    AppColors c, {
    required String emoji,
    required String title,
    required String subtitle,
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
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
                          color: c.textPrimary,
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
                Icon(Icons.chevron_right_rounded, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _bn(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }
}
