import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  List<ArabicLetterItem>? _letters;
  Map<String, Map<String, String>> _quran = {};
  bool _quranLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final letters = await ArabicSeed.letters();
    final quran = await ArabicSeed.lettersQuran();
    if (!mounted) return;
    setState(() {
      _letters = letters;
      _quran = quran;
      _quranLoaded = true;
    });
  }

  void _showDetail(AppColors c, ArabicLetterItem l) {
    speakPron(l.reading);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _letterDetail(c, l),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final letters = _letters;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: letters == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text(
                        '🔤 আরবি অক্ষর',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '২৮টি অক্ষর — ট্যাপ করলে নাম, রূপ ও উদাহরণ দেখাবে',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'কুরআনে (এক-এক সূরায়) প্রতিটি অক্ষর কোন রূপে আসে — ডিটেইলে দেখো',
                        style: TextStyle(fontSize: 11, color: c.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.95,
                            ),
                        itemCount: letters.length,
                        itemBuilder: (context, i) {
                          final l = letters[i];
                          return ListenableBuilder(
                            listenable: Hive.box('deen_arabic').listenable(),
                            builder: (context, _) {
                              final mk = 'a:${l.id}';
                              final known = DeenStore.isArabicKnown(mk);
                              final hard = DeenStore.isHard(mk);
                              return _letterTile(c, l, known, hard);
                            },
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _letterDetail(AppColors c, ArabicLetterItem l) {
    return SafeArea(
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
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.glow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.letter,
                    style: TextStyle(
                      fontFamily: kArabicFont,
                      fontSize: 48,
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
                        l.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'উচ্চারণ: ${l.reading}',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (l.connectsForward && l.initial.isNotEmpty) ...[
              Text(
                'যোগের রূপ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _formTile(c, 'পৃথক', l.isolated),
                  _formTile(c, 'শুরুতে', l.initial),
                  _formTile(c, 'মাঝে', l.medial),
                  _formTile(c, 'শেষে', l.finalJ),
                ],
              ),
            ] else ...[
              Text(
                '⚠️ এটি এমন অক্ষর যা পরের অক্ষরের সাথে যুক্ত হয় না — শুধু আগেরটির সাথে।',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: c.mediumPriority,
                ),
              ),
            ],
            const SizedBox(height: 18),
            GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'উদাহরণ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.example,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: kArabicFont,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.exampleReading,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: c.glow,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'অর্থ: ${l.exampleBangla}',
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_quranLoaded && _quran[l.id] != null) ..._quranExamples(c, l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      DeenStore.resolveHardAndKnown('a:${l.id}', 'a:${l.id}');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'জানি ✓',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.lowPriority,
                      side: BorderSide(
                        color: c.lowPriority.withValues(alpha: 0.6),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      DeenStore.hardMark('a:${l.id}');
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text(
                      'কঠিন ⚠️',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.mediumPriority,
                      side: BorderSide(
                        color: c.mediumPriority.withValues(alpha: 0.6),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
        ),
      ),
    );
  }

  Widget _letterTile(AppColors c, ArabicLetterItem l, bool known, bool hard) {
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(c, l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.letter,
              style: TextStyle(
                fontFamily: kArabicFont,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: known ? c.glow : c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.name,
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
    );
  }

  Widget _formTile(AppColors c, String label, String form) {
    return Column(
      children: [
        Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            form,
            style: TextStyle(
              fontFamily: kArabicFont,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
      ],
    );
  }

  String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  List<Widget> _quranExamples(AppColors c, ArabicLetterItem l) {
    final m = _quran[l.id]!;
    const positions = [
      ('isolated', 'পৃথক'),
      ('initial', 'শুরুতে'),
      ('medial', 'মাঝে'),
      ('final', 'শেষে'),
    ];
    return [
      Text(
        'কুরআন থেকে — এ অক্ষর কোন রূপে আসে',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: c.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (final (key, label) in positions)
              if (m[key] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.glow.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: c.glow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          m[key]!,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: kArabicFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (m['${key}Src'] != null &&
                          m['${key}Src']!.contains(':'))
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            _fmtSrc(m['${key}Src']!),
                            style: TextStyle(
                              fontSize: 10,
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
      const SizedBox(height: 16),
    ];
  }

  String _fmtSrc(String src) {
    final parts = src.split(':');
    if (parts.length == 2) {
      return 'সূরা ${_bnNum(int.tryParse(parts[0]) ?? 0)}:${_bnNum(int.tryParse(parts[1]) ?? 0)}';
    }
    return src;
  }
}
