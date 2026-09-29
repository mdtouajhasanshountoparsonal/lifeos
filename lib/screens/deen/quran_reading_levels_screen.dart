import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_quran_text.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// ছোট সূরাগুলো শব্দ → বাক্যাংশ → পুরো আয়াত — ধাপে ধাপে পড়া শেখা।
/// "পড়া শেষ ✓"/"মুখস্থ ✓" একই কী (`read:<index>:<n>`) দেয় — সূরা-রিডারের
/// প্রগ্রেসের সাথে তাই মিলে যায়।
class QuranReadingLevelsScreen extends StatefulWidget {
  const QuranReadingLevelsScreen({super.key});

  @override
  State<QuranReadingLevelsScreen> createState() =>
      _QuranReadingLevelsScreenState();
}

class _QuranReadingLevelsScreenState extends State<QuranReadingLevelsScreen> {
  static const _order = [114, 113, 112, 110, 108, 109, 107, 106, 105, 103];
  final Map<int, SurahItem> _short = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DeenSeed.surahs();
    if (!mounted) return;
    setState(() {
      for (final s in all) {
        if (_order.contains(s.index)) _short[s.index] = s;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: _loading
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
                            '📖 কুরআন পড়ার ধাপ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'শব্দ → বাক্যাংশ → পুরো আয়াত → ছোট সূরা। ভয় নেই, ধাপে ধাপে।',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _progressCard(c),
                          const SizedBox(height: 16),
                          for (final idx in _order)
                            if (_short[idx] != null)
                              _surahCard(c, _short[idx]!),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int _ayahTotal() => _order.fold<int>(0, (sum, i) => sum + _ayahCount(i));

  int _ayahCount(int idx) => _short[idx]?.ayahs.length ?? 0;

  int _readCount() {
    var n = 0;
    for (final idx in _order) {
      final s = _short[idx];
      if (s == null) continue;
      for (final a in s.ayahs) {
        if (DeenStore.isQuranRead('read:${s.index}:${a.n}')) n++;
      }
    }
    return n;
  }

  int _memCount() {
    var n = 0;
    for (final idx in _order) {
      final s = _short[idx];
      if (s == null) continue;
      for (final a in s.ayahs) {
        if (DeenStore.isQuranMem('mem:${s.index}:${a.n}')) n++;
      }
    }
    return n;
  }

  Widget _progressCard(AppColors c) {
    final total = _ayahTotal();
    final read = _readCount();
    final mem = _memCount();
    final pct = total > 0 ? read / total : 0.0;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📈 ধাপ-পড়া',
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
                  '${_bn(read)} পড়া · ${_bn(mem)} মুখস্থ',
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
            'সূরা-রিডারেও একই চিহ্ন — দুই জায়গা থেকেই লেখা হয়',
            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _surahCard(AppColors c, SurahItem s) {
    final read = s.ayahs
        .where((a) => DeenStore.isQuranRead('read:${s.index}:${a.n}'))
        .length;
    final mem = s.ayahs
        .where((a) => DeenStore.isQuranMem('mem:${s.index}:${a.n}'))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _SurahLevelsPage(surah: s)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: c.glow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _bn(s.index),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.glow,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.arabicName,
                            style: TextStyle(
                              fontFamily: kQuranFont,
                              fontSize: 16,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_bn(s.ayahCount)} আয়াত · ${mem > 0 ? '${_bn(mem)} মুখস্থ · ' : ''}${_bn(read)} পড়া শেষ ✓',
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

class _SurahLevelsPage extends StatelessWidget {
  final SurahItem surah;

  const _SurahLevelsPage({required this.surah});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: Hive.box('deen_arabic').listenable(),
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Text(
                      '📖 সূরা ${surah.name}',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_bn(surah.ayahCount)} আয়াত — প্রতিটির ডান দিকের স্লাইডার টেনে শব্দ ধরে ধরে পড়ো',
                      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    for (final a in surah.ayahs) _ayahCard(context, c, a),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ayahCard(BuildContext context, AppColors c, SurahAyah a) {
    final surahIdx = surah.index;
    final isFirst = a.n == 1;
    final stripped = stripBasmala(a.ar, a.tl, isFirstAyah: isFirst);
    final ar = stripped.ar;
    final words = ar.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final readKey = 'read:$surahIdx:${a.n}';
    final memKey = 'mem:$surahIdx:${a.n}';
    final isRead = DeenStore.isQuranRead(readKey);
    final isMem = DeenStore.isQuranMem(memKey);
    return _WordRevealCard(
      c: c,
      surahIndex: surahIdx,
      ayah: a,
      stripped: stripped,
      words: words,
      readKey: readKey,
      memKey: memKey,
      isRead: isRead,
      isMem: isMem,
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

class _WordRevealCard extends StatefulWidget {
  final AppColors c;
  final int surahIndex;
  final SurahAyah ayah;
  final ({String ar, String tl, String basmalaAr, String basmalaTl}) stripped;
  final List<String> words;
  final String readKey;
  final String memKey;
  final bool isRead;
  final bool isMem;

  const _WordRevealCard({
    required this.c,
    required this.surahIndex,
    required this.ayah,
    required this.stripped,
    required this.words,
    required this.readKey,
    required this.memKey,
    required this.isRead,
    required this.isMem,
  });

  @override
  State<_WordRevealCard> createState() => _WordRevealCardState();
}

class _WordRevealCardState extends State<_WordRevealCard> {
  int _k = 1;

  @override
  void initState() {
    super.initState();
    _k = 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final total = widget.words.length;
    final revealed = widget.words.take(_k).join(' ');
    final complete = _k >= total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.glow.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'আয়াত ${_bn(widget.ayah.n)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: c.glow,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!complete)
                    Text(
                      '${_bn(_k)}/${_bn(total)} শব্দ',
                      style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                    ),
                  if (widget.isMem)
                    _badge(c, 'মুখস্থ ✓', c.glow)
                  else if (widget.isRead)
                    _badge(c, 'পড়া ✓', c.lowPriority),
                ],
              ),
              if (widget.stripped.basmalaAr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.stripped.basmalaAr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kQuranFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.stripped.basmalaTl,
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Center(
                child: Text(
                  revealed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kQuranFont,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              if (total > 1) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      onPressed: _k > 1 ? () => setState(() => _k--) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      color: c.textSecondary,
                    ),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: total.toDouble(),
                        divisions: total - 1,
                        value: _k.toDouble().clamp(1, total.toDouble()),
                        onChanged: (v) => setState(() => _k = v.round()),
                        activeColor: c.glow,
                        inactiveColor: c.surfaceColor,
                      ),
                    ),
                    IconButton(
                      onPressed: _k < total ? () => setState(() => _k++) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ],
              if (complete) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'বাংলা-পড়া',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.stripped.tl,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: c.glow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => speakPron(widget.stripped.tl),
                      icon: const Icon(Icons.volume_up_rounded),
                      color: c.glow,
                      tooltip: 'পড়া শোনো',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GlassCard(
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অর্থ: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.ayah.bn,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          DeenStore.resolveHardAndKnown(
                            widget.memKey,
                            widget.memKey,
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.bookmark_rounded, size: 17),
                        label: const Text(
                          'মুখস্থ ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.glow,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          DeenStore.arabicMark(widget.readKey);
                          setState(() {});
                        },
                        icon: const Icon(Icons.check_rounded, size: 17),
                        label: const Text(
                          'পড়া শেষ ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.lowPriority,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Center(
                child: Text(
                  complete
                      ? (widget.isRead
                            ? '✅ লেখা হয়েছে'
                            : 'পুরোটা পড়ে "পড়া শেষ ✓" দাও')
                      : '""${_bn(_k)}"" শব্দ দেখছো — স্লাইডার/তীরে বাড়াও',
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(AppColors c, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
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
