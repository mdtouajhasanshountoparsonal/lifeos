import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// হরকত চেনার ড্রিল — চিহ্ন → নাম, নাম → চিহ্ন। প্রশ্ন প্রতিবার বদলায়,
/// উত্তর চিহ্নিত হয় "জানি ✓"/"কঠিন ⚠️" → নিজের রেকর্ড।
class HarakatDrillScreen extends StatefulWidget {
  const HarakatDrillScreen({super.key});

  @override
  State<HarakatDrillScreen> createState() => _HarakatDrillScreenState();
}

class _HarakatDrillScreenState extends State<HarakatDrillScreen> {
  List<HarakaItem>? _harakat;
  List<ArabicLetterItem>? _letters;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final harakat = await ArabicSeed.harakat();
    final letters = await ArabicSeed.letters();
    if (!mounted) return;
    setState(() {
      _harakat = harakat;
      _letters = letters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final harakat = _harakat;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: harakat == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListenableBuilder(
                    listenable: Hive.box('deen_arabic').listenable(),
                    builder: (context, _) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          Text(
                            '🪄 হরকত ড্রিল',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'চিহ্ন দেখে নাম, নাম দেখে চিহ্ন — বারবার খেলে কাটবে',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _progressCard(c),
                          const SizedBox(height: 16),
                          Text(
                            'চিহ্নগুলো',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: harakat.length,
                            itemBuilder: (context, i) =>
                                _markTile(c, harakat[i]),
                          ),
                          const SizedBox(height: 18),
                          _drillCard(c),
                          const SizedBox(height: 14),
                          GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(14),
                            child: Text(
                              'প্রশ্নের চিহ্নগুলো ড্রিল নিজেই রান্ডম অক্ষরে বসায় — হরকতই আসল প্রশ্ন, অক্ষরটা নয়।',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.5,
                                color: c.textSecondary,
                              ),
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

  Widget _progressCard(AppColors c) {
    final total = _harakat!.length;
    final known = _harakat!
        .where((h) => DeenStore.isArabicKnown('harak:${h.id}'))
        .length;
    final hard = _harakat!
        .where((h) => DeenStore.isHard('harak:${h.id}'))
        .length;
    final pct = total > 0 ? known / total : 0.0;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📈 হরকত লেখা',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        ],
      ),
    );
  }

  Widget _markTile(AppColors c, HarakaItem h) {
    final key = 'harak:${h.id}';
    final known = DeenStore.isArabicKnown(key);
    final hard = DeenStore.isHard(key);
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showMark(c, h),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                h.mark,
                style: TextStyle(
                  fontFamily: kArabicFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: known ? c.glow : c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                h.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: c.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                known ? '✓' : (hard ? '⚠️' : ''),
                style: TextStyle(fontSize: 12, color: c.glow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMark(AppColors c, HarakaItem h) {
    speakPron(h.reading);
    final key = 'harak:${h.id}';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.glow.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      h.mark,
                      style: TextStyle(
                        fontFamily: kArabicFont,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: c.glow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.name,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'পড়া: ${h.reading}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.glow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  h.bangla,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        DeenStore.resolveHardAndKnown(key, key);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'জানি ✓',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.glow,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        DeenStore.hardMark(key);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: const Text(
                        'কঠিন ⚠️',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.mediumPriority,
                        side: BorderSide(
                          color: c.mediumPriority.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('বন্ধ করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drillCard(AppColors c) {
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startDrill(c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🧪', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'অনুশীলন — ১০ প্রশ্ন',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'চিহ্ন → নাম ও নাম → চিহ্ন — প্রতিবার নতুন অক্ষরে',
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _startDrill(AppColors c) {
    final quiz = _buildQuiz();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _HarakatDrillSheet(c: c, quiz: quiz),
    );
  }

  List<_Hq> _buildQuiz() {
    final harakat = _harakat!;
    final letters = _letters ?? const <ArabicLetterItem>[];
    final list = <_Hq>[];
    for (var i = 0; i < 10; i++) {
      final h = harakat[i % harakat.length];
      final base = letters.isNotEmpty
          ? letters[(i * 7 + 5) % letters.length].letter
          : 'ب';
      String gly(HarakaItem x) => x.mark.replaceAll('ب', base);
      if (i.isEven) {
        list.add(
          _Hq(
            prompt: gly(h),
            options: [for (final x in _pick(h, harakat)) x.name],
            correct: h.name,
            isNameQuestion: false,
          ),
        );
      } else {
        final opts = _pick(h, harakat);
        final labels = <String>[];
        for (final x in opts) {
          final g = gly(x);
          if (!labels.contains(g)) labels.add(g);
        }
        if (labels.length < 2) continue;
        list.add(
          _Hq(
            prompt: h.name,
            options: labels,
            correct: gly(h),
            isNameQuestion: true,
          ),
        );
      }
    }
    list.shuffle();
    return list;
  }

  List<HarakaItem> _pick(HarakaItem q, List<HarakaItem> all) {
    final set = <HarakaItem>{q};
    var i = all.indexOf(q);
    while (set.length < 4) {
      i = (i + 5) % all.length;
      set.add(all[i]);
    }
    final list = set.toList()..shuffle();
    return list;
  }

  static String _bn(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }
}

class _Hq {
  final String prompt;
  final List<String> options;
  final String correct;
  final bool isNameQuestion;

  const _Hq({
    required this.prompt,
    required this.options,
    required this.correct,
    required this.isNameQuestion,
  });
}

class _HarakatDrillSheet extends StatefulWidget {
  final AppColors c;
  final List<_Hq> quiz;

  const _HarakatDrillSheet({required this.c, required this.quiz});

  @override
  State<_HarakatDrillSheet> createState() => _HarakatDrillSheetState();
}

class _HarakatDrillSheetState extends State<_HarakatDrillSheet> {
  int _i = 0;
  int _score = 0;
  String? _selected;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final q = widget.quiz[_i];
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: _done ? _summary(c) : _question(c, q),
      ),
    );
  }

  Widget _question(AppColors c, _Hq q) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.glow.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'প্রশ্ন ${_bnNum(_i + 1)} / ${_bnNum(widget.quiz.length)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.glow,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'সঠিক: ${_bnNum(_score)}',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          q.isNameQuestion ? 'কোন চিহ্নটা এটা?' : 'এটা কোন হরকত?',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.glow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            q.prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kArabicFont,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final op in q.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _selected != null && op == q.correct
                  ? c.lowPriority.withValues(alpha: 0.30)
                  : (_selected == op
                        ? c.highPriority.withValues(alpha: 0.25)
                        : c.surfaceColor),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selected == null
                    ? () {
                        final ok = op == q.correct;
                        setState(() {
                          _selected = op;
                          if (ok) _score++;
                        });
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      op,
                      style: TextStyle(
                        fontFamily: q.isNameQuestion ? kArabicFont : null,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _selected != null && op == q.correct
                            ? c.lowPriority
                            : c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        if (_selected != null)
          FilledButton(
            onPressed: () {
              setState(() {
                if (_i + 1 >= widget.quiz.length) {
                  _done = true;
                } else {
                  _i++;
                  _selected = null;
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: c.glow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              _i + 1 >= widget.quiz.length ? 'ফল দেখো' : 'পরবর্তী →',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }

  Widget _summary(AppColors c) {
    final total = widget.quiz.length;
    final pct = total > 0 ? _score / total : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🏁 ড্রিল শেষ!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_bnNum(_score)} / ${_bnNum(total)} সঠিক',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.glow,
          ),
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
        const SizedBox(height: 10),
        Text(
          pct >= 0.8
              ? 'দারুণ! যেটা আটকাচ্ছে, ⚠️ দাও — টাইল ট্যাপ করে আবার দেখো।'
              : 'বারবার খেলো — চিহ্ন-চেনাই পড়ার ভিত্তি।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: c.glow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: const Text(
            'বন্ধ করুন',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  static String _bnNum(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }
}
