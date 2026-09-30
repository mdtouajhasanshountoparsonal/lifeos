import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_quran_text.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';
import 'package:lifeos/theme/app_theme.dart';

/// দোয়ার যেকোনো শব্দে চাপ দিলে এই শিট খোলে: অক্ষর-হরকত ভাঙা, পড়ার অনুশীলন,
/// আর অ্যাপের যাচাইকৃত ভাণ্ডারে শব্দটি থাকলে তার অর্থ + জানি/কঠিন চিহ্ন।
Future<void> showDuaWordSheet(BuildContext context, String word) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DuaWordSheet(word: word),
  );
}

class DuaWordSheet extends StatefulWidget {
  final String word;

  const DuaWordSheet({super.key, required this.word});

  @override
  State<DuaWordSheet> createState() => _DuaWordSheetState();
}

class _DuaWordSheetState extends State<DuaWordSheet> {
  late final DuaWordInfo _info;
  ArabicWordItem? _bankWord;
  VocabItem? _bankVocab;
  Map<String, ArabicLetterItem> _letters = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _info = DuaWordAnalyzer.analyze(widget.word);
    _lookup();
  }

  Future<void> _lookup() async {
    final base = _info.base;
    final w = await DuaWordLookup.word(base);
    final v = w == null ? await DuaWordLookup.vocab(base) : null;
    final letters = <String, ArabicLetterItem>{};
    for (final s in _info.segments) {
      final l = await DuaWordLookup.letter(s.letter);
      if (l != null) letters[s.letter] = l;
    }
    if (!mounted) return;
    setState(() {
      _bankWord = w;
      _bankVocab = v;
      _letters = letters;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '🔤 শব্দটা ভেঙে পড়ি',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'শব্দটি শুনুন',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => speakPron(_info.raw),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 20,
                      color: c.glow,
                    ),
                  ),
                ],
              ),
              Center(
                child: Text(
                  _info.raw,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kQuranFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    height: 1.7,
                  ),
                ),
              ),
              if (_info.base.isNotEmpty)
                Center(
                  child: Text(
                    'মূল স্পেলিং: ${_info.base}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              _label(c, 'অক্ষর ও হরকত'),
              ..._info.segments.map((s) => _segTile(c, s)),
              const SizedBox(height: 10),
              if (_loaded && _bankWord == null && _bankVocab == null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'এই শব্দটি অ্যাপের যাচাইকৃত শব্দ-ভাণ্ডারে নেই — তাই অর্থ দেখানো হচ্ছে না। উপরে অক্ষর-হরকত ভাঙা ও শোনার অনুশীলন করা যাচ্ছে।',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_bankWord != null) _wordCard(c, _bankWord!),
              if (_bankVocab != null) _vocabCard(c, _bankVocab!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(AppColors c, String s) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      s,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: c.textSecondary,
      ),
    ),
  );

  Widget _segTile(AppColors c, DuaLetterSeg s) {
    final l = _letters[s.letter];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            s.glyph,
            style: TextStyle(
              fontFamily: kQuranFont,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l == null
                      ? 'বর্ণমালার ২৮ অক্ষরের বাইরে — যোগাফ বর্ণ'
                      : '${l.name} · পড়া: ${l.reading}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: l == null ? c.mediumPriority : c.textPrimary,
                  ),
                ),
                if (s.marks.isNotEmpty)
                  Text(
                    'হরকত: ${s.markNames}',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                    ),
                  ),
                if (l != null && l.example.isNotEmpty)
                  Text(
                    'উদাহরণ: ${l.example} (${l.exampleReading})',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordCard(AppColors c, ArabicWordItem w) => _dataCard(
    c,
    badge: '📖 শব্দ চর্চা',
    arabic: w.arabic,
    reading: w.reading,
    meaning: w.bangla,
    footer: w.hasSource ? w.source : null,
    hardKey: 'hard:${w.id}',
    knownKey: w.id,
  );

  Widget _vocabCard(AppColors c, VocabItem v) => _dataCard(
    c,
    badge: '🗝️ কুরআন শব্দভাণ্ডার',
    arabic: v.arabic,
    reading: v.reading,
    meaning: v.bangla,
    footer: v.root.isEmpty ? null : 'মূল: ${v.root} · কুরআনে ${v.occurrences.length} বার',
    hardKey: 'hard:vocab:${v.id}',
    knownKey: 'vocab:${v.id}',
  );

  Widget _dataCard(
    AppColors c, {
    required String badge,
    required String arabic,
    required String reading,
    required String meaning,
    String? footer,
    required String hardKey,
    required String knownKey,
  }) {
    return ListenableBuilder(
      listenable: Hive.box('deen_meta').listenable(),
      builder: (context, _) {
        final known = DeenStore.isArabicKnown(knownKey);
        final hard = DeenStore.isHard(hardKey);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: c.glow,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    arabic,
                    style: TextStyle(
                      fontFamily: kQuranFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => speakPron(arabic),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: c.glow,
                    ),
                  ),
                ],
              ),
              if (reading.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    reading,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  meaning,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    footer,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _markButton(
                      c,
                      label: 'জানি ✓',
                      icon: Icons.check_circle_rounded,
                      active: known && !hard,
                      onTap: () {
                        DeenStore.hardUnmark(hardKey);
                        DeenStore.arabicMark(knownKey);
                      },
                    ),
                    const SizedBox(width: 8),
                    _markButton(
                      c,
                      label: 'কঠিন ⚠️',
                      icon: Icons.error_rounded,
                      active: hard,
                      onTap: () => hard
                          ? DeenStore.hardUnmark(hardKey)
                          : DeenStore.hardMark(hardKey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _markButton(
    AppColors c, {
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? c.glow : c.surfaceColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.black : c.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.black : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
