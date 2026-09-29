import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// বিসমিল্লাহ — কুরআনের লিপিতে (৯ নং সূরা তওবা বাদে প্রতিটি সূরার ১ নং
/// আয়াতের শুরুতে থাকে); নিজের লাইনে আলাদা করে দেখানো হয়।
const _basmalaAr =
    '\u0628\u0650\u0633\u06e1\u0645\u0650\u0020\u0671\u0644\u0644\u0651\u064e\u0647\u0650\u0020\u0671\u0644\u0631\u0651\u064e\u062d\u06e1\u0645\u064e\u0640\u0670\u0646\u0650\u0020\u0671\u0644\u0631\u0651\u064e\u062d\u0650\u06cc\u0645\u0650';

/// বিসমিল্লাহ-এর বাংলা-বানানে পড়া (ট্রান্সলিটারেটর নির্ধারিত রূপ)।
const _basmalaTl = 'বিস-মি আল-লা-হি আর-রাহ-মা-নি আর-রা-হি-মি';

/// আরবি (আয়াত) টেক্সটে ব্যবহৃত ফন্ট — কুরআনী লিপি + তাশকিল সঠিকভাবে দেখায়।
const _quranFont = 'Amiri';

/// আরবি তাশকিল/কুরআন-চিহ্ন (নরমালাইজ করে বাদ দেওয়া হয়)।
final _arMarks = RegExp(
  r'[\u0610-\u061a\u0640\u064b-\u0652\u0656-\u065f\u0670\u06d6-\u06ed\u08d3-\u08ff]',
);

/// আলিফের রূপ (ا أ إ آ ٱ) — সবকে এক বলে ধরি।
final _alefForms = RegExp(r'[\u0622\u0623\u0625\u0671]');

/// `ar`-এর শুরু থেকে পুরো বিসমিল্লাহ (যেকোনো লিপি-ভ্যারিয়েন্টসহ) কত অক্ষর
/// দখল করে তা-বেরে — ম্যাচ না পেলে 0। তাওবাহ (৯)-তে নেই → 0।
int _basmalaLen(String ar) {
  final target = _basmalaAr
      .replaceAll(_arMarks, '')
      .replaceAll(_alefForms, '\u0627')
      .replaceAll(' ', '');
  final buf = StringBuffer();
  var len = 0;
  for (var i = 0; i < ar.length; i++) {
    buf.write(ar[i]);
    final n = buf
        .toString()
        .replaceAll(_arMarks, '')
        .replaceAll(_alefForms, '\u0627')
        .replaceAll(' ', '');
    if (n == target) {
      len = i + 1;
      break;
    }
  }
  if (len == 0) return 0;
  while (len < ar.length && _arMarks.hasMatch(ar[len])) {
    len++;
  }
  return len;
}

/// 🔖 একটি সূরার পূর্ণ পাঠ — আয়াত ধরে ধরে (কুরআনের লিপি: رسم عثمانی) +
/// বাংলা-বানানে পড়া + বাংলা অনুবাদ + 'মুখস্থ ✓' / 'পড়া শেষ ✓' / 'কঠিন ⚠️'।
class SurahReaderScreen extends StatefulWidget {
  final SurahItem surah;

  const SurahReaderScreen({super.key, required this.surah});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final _scroll = ScrollController();
  List<SurahItem>? _all;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = (widget.surah.index - 1).clamp(0, 113);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await DeenSeed.surahs();
    if (!mounted) return;
    setState(() {
      _all = all;
      final i = all.indexWhere((s) => s.index == widget.surah.index);
      _index = i < 0 ? 0 : i;
    });
  }

  bool _hasText(SurahItem t) =>
      t.arabic.trim().isNotEmpty || t.ayahs.isNotEmpty;

  void _jump(int i) {
    final all = _all;
    if (all == null) return;
    if (i < 0 || i >= all.length) return;
    final target = all[i];
    if (!_hasText(target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'সূরা ${target.name} — পাঠ এখনো আসেনি',
            style: const TextStyle(fontSize: 12.5),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _index = i);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  String _ayahKey(int surahIdx, int n) => 'read:$surahIdx:$n';
  String _memKey(int surahIdx, int n) => 'mem:$surahIdx:$n';
  String _hardKey(int surahIdx, int n) => 'hard:${_ayahKey(surahIdx, n)}';

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = _all?[_index] ?? widget.surah;
    final ayahs = s.ayahs;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.arabicName} · ${s.name}',
                              style: const TextStyle(
                                fontFamily: _quranFont,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_bnNum(s.index)} নং সূরা · ${_bnNum(s.ayahCount)} আয়াত · ${s.revelation} · ${s.nameMeaning}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (ayahs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      'কুরআনের লিপি (রাসম-ই-উসমানি) — আয়াত ধরে ধরে · আরবি → বাংলা-বানানে পড়া → অর্থ',
                      style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: ayahs.isNotEmpty ? _ayahList(c, s) : _blobList(c, s),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _jump(_index - 1),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'আগের',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textSecondary,
                            side: BorderSide(
                              color: c.textSecondary.withValues(alpha: 0.4),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${_bnNum(s.index)} / ${_bnNum(_all?.length ?? 114)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _jump(_index + 1),
                          icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          label: Text(
                            'পরের',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.glow,
                            side: BorderSide(
                              color: c.glow.withValues(alpha: 0.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ayahList(AppColors c, SurahItem s) {
    return ListenableBuilder(
      listenable: Hive.box('deen_arabic').listenable(),
      builder: (context, _) {
        final reads = DeenStore.quranReads();
        final mems = DeenStore.quranMems();
        return ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: s.ayahs.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i == 0) return _progressCard(c, s, reads, mems);
            if (i == s.ayahs.length + 1) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.source,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.glow,
                  ),
                ),
              );
            }
            final a = s.ayahs[i - 1];
            final aKey = _ayahKey(s.index, a.n);
            final mKey = _memKey(s.index, a.n);
            final hKey = _hardKey(s.index, a.n);
            final read = reads.contains(aKey);
            final mem = mems.contains(mKey);
            final hard = DeenStore.isHard(hKey);
            final bmLen = a.n == 1 ? _basmalaLen(a.ar) : 0;
            final hasBm = bmLen > 0;
            final ayahAr = hasBm
                ? (a.ar.length > bmLen ? a.ar.substring(bmLen).trim() : '')
                : a.ar;
            final ayahTl = hasBm
                ? (a.tl.startsWith(_basmalaTl)
                      ? a.tl.substring(_basmalaTl.length).trim()
                      : a.tl.trim())
                : a.tl.trim();
            return GlassCard(
              padding: const EdgeInsets.all(13),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: hard
                      ? Border.all(
                          color: c.highPriority.withValues(alpha: 0.45),
                        )
                      : null,
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color:
                                ((mem || read)
                                        ? c.lowPriority
                                        : c.textSecondary)
                                    .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _bnNum(a.n),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: (mem || read)
                                    ? c.lowPriority
                                    : c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: hard
                              ? 'কঠিন থেকে বাদ দাও'
                              : 'কঠিন — আরও মুখস্থ',
                          child: IconButton(
                            onPressed: () => hard
                                ? DeenStore.hardUnmark(hKey)
                                : DeenStore.hardMark(hKey),
                            icon: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: hard
                                  ? c.highPriority
                                  : c.textSecondary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasBm) ...[
                      const SizedBox(height: 2),
                      Text(
                        _basmalaAr,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _quranFont,
                          fontSize: 23,
                          height: 2.0,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _basmalaTl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: c.glow,
                        ),
                      ),
                    ],
                    if (hasBm && ayahAr.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: c.textSecondary.withValues(alpha: 0.18),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (ayahAr.isNotEmpty)
                      Text(
                        ayahAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: _quranFont,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.9,
                          color: c.textPrimary,
                        ),
                      ),
                    if (ayahTl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '🔤 $ayahTl',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: c.glow,
                        ),
                      ),
                    ],
                    if (a.bn.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '💬 ${a.bn}',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => mem
                                ? DeenStore.quranMemUnmark(mKey)
                                : DeenStore.quranMemMark(mKey),
                            icon: Icon(
                              mem
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                            ),
                            label: Text(
                              mem ? 'মুখস্থ ✓' : 'মুখস্থ',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mem
                                  ? c.lowPriority
                                  : c.textSecondary,
                              side: BorderSide(
                                color: (mem ? c.lowPriority : c.textSecondary)
                                    .withValues(alpha: 0.5),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => read
                                ? DeenStore.arabicUnmark(aKey)
                                : DeenStore.arabicMark(aKey),
                            icon: Icon(
                              read
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                            ),
                            label: Text(
                              read ? 'পড়া শেষ ✓' : 'পড়া শেষ',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: read
                                  ? c.lowPriority
                                  : c.textSecondary,
                              side: BorderSide(
                                color: (read ? c.lowPriority : c.textSecondary)
                                    .withValues(alpha: 0.5),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _progressCard(
    AppColors c,
    SurahItem s,
    Set<String> reads,
    Set<String> mems,
  ) {
    final total = s.ayahs.length;
    var readCount = 0, memCount = 0;
    for (final a in s.ayahs) {
      if (reads.contains(_ayahKey(s.index, a.n))) readCount++;
      if (mems.contains(_memKey(s.index, a.n))) memCount++;
    }
    Widget bar(int done) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: total == 0 ? 0 : done / total,
        minHeight: 6,
        backgroundColor: c.textSecondary.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(
          done > 0 ? c.glow : c.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'এই সূরার প্রগ্রেস',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'পড়া ${_bnNum(readCount)}/${_bnNum(total)} · মুখস্থ ${_bnNum(memCount)}/${_bnNum(total)}',
                style: TextStyle(fontSize: 10.5, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('📖 পড়া শেষ', style: TextStyle(fontSize: 11, color: c.glow)),
          const SizedBox(height: 3),
          bar(readCount),
          const SizedBox(height: 8),
          Text(
            '🧠 মুখস্থ',
            style: TextStyle(fontSize: 11, color: c.lowPriority),
          ),
          const SizedBox(height: 3),
          bar(memCount),
        ],
      ),
    );
  }

  Widget _blobList(AppColors c, SurahItem s) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (s.arabic.trim().isNotEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আরবি',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.glow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.arabic,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.9,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (s.transliteration.trim().isNotEmpty) ...[
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'বাংলা পড়া',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.transliteration,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (s.bangla.trim().isNotEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'অর্থ',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.lowPriority,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.bangla,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          s.source,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.glow,
          ),
        ),
      ],
    );
  }
}
