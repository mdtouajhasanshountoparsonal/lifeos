import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

const _levelNames = {
  1: 'ধাপ ১ · পুরোটা দেখে পড়া',
  2: 'ধাপ ২ · অর্থ লুকানো',
  3: 'ধাপ ৩ · শব্দ লুকানো',
  4: 'ধাপ ৪ · সব লুকানো',
  5: 'ধাপ ৫ · দ্রুত recall',
};

/// 🧠 মুখস্থ বিদ্যা — SM-2-স্টাইল spaced repetition, বিচার নয়।
class MemorizeScreen extends StatefulWidget {
  const MemorizeScreen({super.key});

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  List<MemItem> _pool = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DeenSeed.memPool();
    if (!mounted) return;
    setState(() {
      _pool = items.where((m) => m.arabic.trim().isNotEmpty).toList();
      _loaded = true;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🧠 মুখস্থ বিদ্যা', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.textPrimary)),
                            Text('ধাপ ১→৫, পরের দিন আবার', style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Hive.box('memorization').listenable(),
                    builder: (context, _) {
                      final all = DeenStore.memorizationAll();
                      final rows = [...all.entries]..sort((a, b) => a.value.nextReview.compareTo(b.value.nextReview));
                      if (!_loaded) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                      }
                      return _list(c, rows);
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

  Widget _list(AppColors c, List<MapEntry<String, MemorizationEntry>> rows) {
    final started = rows.map((e) => e.key).toSet();
    final catalog = _pool.where((m) => !started.contains(m.key)).toList()
      ..sort((a, b) => a.isSurah == b.isSurah ? a.label.compareTo(b.label) : (a.isSurah ? 0 : 1));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (rows.isNotEmpty) ...[
          Text('মুখস্থ চলছে', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary)),
          const SizedBox(height: 8),
          for (final e in rows) _itemCard(c, e.key, e.value, _pool.where((m) => m.key == e.key).firstOrNull),
          const SizedBox(height: 16),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: BorderRadius.circular(16),
              child: Text(
                'এখনো মুখস্থ শুরু হয়নি। নিচের ক্যাটালগ থেকে যেকোনো দুয়া/সুরা "► শুরু" করুন — ধাপ ১→৫, প্রতিটি ধাপের পরের দিন আবার recall।',
                style: TextStyle(fontSize: 12, height: 1.5, color: c.textSecondary),
              ),
            ),
          ),
        if (catalog.isNotEmpty) ...[
          Text('ক্যাটালগ — মুখস্থ শুরু করুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary)),
          const SizedBox(height: 8),
          for (final m in catalog) _catalogTile(c, m),
        ],
      ],
    );
  }

  /// প্রিভিউ: উচ্চারণ (বাংলা পড়া) থাকলে সেটা, না-থাকলে অর্থ।
  static String _preview(MemItem m) {
    final t = m.transliteration.trim();
    final s = t.isNotEmpty ? t : m.bangla;
    return s.length > 60 ? '${s.substring(0, 60)}…' : s;
  }

  Widget _catalogTile(AppColors c, MemItem m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MemorizePracticeScreen(itemKey: m.key)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (m.isSurah ? c.secondary : c.primary).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(m.isSurah ? '📖' : '🤲', style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        _preview(m),
                        style: TextStyle(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => setState(() => DeenStore.memorizationStart(m.key)),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.glow,
                    foregroundColor: Colors.black,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  child: const Text('► শুরু'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemCard(AppColors c, String key, MemorizationEntry e, MemItem? item) {
    final due = e.isDueNow;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item?.label ?? key,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.glow),
                  ),
                ),
                if (e.streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: c.mediumPriority.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                    child: Text('🔥 ${_fromEn(e.streak.toString())}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.mediumPriority)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item?.bangla ?? '', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(item?.arabic ?? '', textAlign: TextAlign.right,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.5)),
            if (item != null && item.transliteration.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(item.transliteration,
                    style: TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: c.textSecondary)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(c, e.level),
                      const SizedBox(height: 4),
                      Text(_levelNames[e.level] ?? '', style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: due ? c.lowPriority.withValues(alpha: 0.22) : c.glow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    due ? '⏰ এখনি recall' : 'পরের: ${_date(e.nextReview)}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: due ? c.lowPriority : c.glow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MemorizePracticeScreen(itemKey: key)),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.glow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    child: Text(due ? '⏰ অনুশীলন করুন' : 'অনুশীলন'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => DeenStore.memorizationRemove(key),
                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(AppColors c, int level) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: (level - 1) / 4,
        minHeight: 6,
        color: c.glow,
        backgroundColor: c.textSecondary.withValues(alpha: 0.18),
      ),
    );
  }

  static String _date(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = that.difference(day).inDays;
    if (diff <= 0) return 'আজ';
    if (diff == 1) return 'আগামীকাল';
    return '${_fromEn((diff).toString())} দিন';
  }

  static String _fromEn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }
}

/// একটি আইটেমের ধাপ-ভিত্তিক অনুশীলন।
class MemorizePracticeScreen extends StatefulWidget {
  final String itemKey;
  const MemorizePracticeScreen({super.key, required this.itemKey});

  @override
  State<MemorizePracticeScreen> createState() => _MemorizePracticeScreenState();
}

class _MemorizePracticeScreenState extends State<MemorizePracticeScreen> {
  MemItem? _item;
  List<MemItem> _pool = const [];
  bool _loaded = false;
  bool _reveal = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DeenSeed.memPool();
    if (!mounted) return;
    setState(() {
      _pool = all.where((m) => m.arabic.trim().isNotEmpty).toList();
      _item = _pool.where((m) => m.key == widget.itemKey).firstOrNull;
      _loaded = true;
    });
  }

  MemorizationEntry? get _entry => DeenStore.memorizationGet(widget.itemKey);

  /// cloze: মাঝখানের একটি শব্দ লুকাই।
  static String _cloze(String arabic) {
    final words = arabic.split(' ');
    if (words.length < 4) return arabic;
    final idx = (words.length ~/ 2).clamp(1, words.length - 2);
    final hidden = List<String>.from(words);
    hidden[idx] = '__________';
    return hidden.join(' ');
  }

  /// ধাপ ৫-এর বিকল্প: সঠিক + ৩টি ভিন্ন প্রথম-শব্দ।
  List<MemItem> _options() {
    final d = _item;
    if (d == null) return const [];
    final others = _pool.where((o) => o.key != d.key).toList()..shuffle();
    return ([d, ...others.take(3)]..shuffle()).toList();
  }

  void _success() {
    if (_finished) return;
    final e = _entry;
    if (e == null) return;
    DeenStore.memorizationSuccess(widget.itemKey, e);
    setState(() {
      _reveal = true;
      _finished = true;
    });
  }

  void _mistake() {
    if (_finished) return;
    final e = _entry;
    if (e == null) return;
    DeenStore.memorizationMistake(widget.itemKey, e);
    setState(() {
      _reveal = true;
      _finished = true;
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
            child: ListenableBuilder(
              listenable: Hive.box('memorization').listenable(),
              builder: (context, _) {
                if (!_loaded) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                }
                final item = _item;
                if (item == null) {
                  return const Center(child: Text('আইটেম পাওয়া যায়নি'));
                }
                final e = _entry;
                if (e == null) {
                  return _notStarted(c, item);
                }
                final level = e.level;
                return _content(c, item, level);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _notStarted(AppColors c, MemItem item) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.isSurah ? '📖' : '🗂️', style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text('${item.label} — মুখস্থ শুরু করা হয়নি', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => setState(() => DeenStore.memorizationStart(widget.itemKey)),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('মুখস্থ শুরু করি', style: TextStyle(fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(backgroundColor: c.glow, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(AppColors c, MemItem item, int level) {
    final reveal = _reveal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
              ),
              Expanded(
                child: Text(_levelNames[level] ?? '',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.glow)),
              ),
              Text('${_fromEn(level.toString())}/৫', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (level == 1 || level == 2)
                  Text(item.arabic, textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.7)),
                if (level == 3)
                  Text(reveal ? item.arabic : _cloze(item.arabic), textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: c.textPrimary, height: 1.7)),
                if (level == 4)
                  Text(reveal ? item.arabic : _maskAll(item.arabic), textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: c.textPrimary, height: 1.7)),
                const SizedBox(height: 12),
                if (item.transliteration.trim().isNotEmpty && (level == 1 || level == 2 || reveal))
                  Text(item.transliteration, textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w600, color: c.textSecondary)),
                if (level == 4 && !reveal)
                  Text('🔒 সংখ্যা অনুযায়ী নিজে বলুন…', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: c.textSecondary)),
                if (level == 2 || level == 3)
                  Text(reveal ? item.bangla : '🔒 অর্থ — উত্তর দেখুন চাপুন',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textSecondary)),
                if (level == 1 || level == 4 || level == 5)
                  Text(item.bangla, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 14),
                if (item.hasSource)
                  Text('📚 ${item.source}', style: TextStyle(fontSize: 11.5, color: c.glow.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (level >= 2 && level <= 4 && !reveal)
            OutlinedButton.icon(
              onPressed: () => setState(() => _reveal = true),
              icon: Icon(Icons.visibility_rounded, size: 17),
              label: Text(level == 4 ? 'আরবি দেখুন' : 'উত্তর দেখুন'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.glow,
                side: BorderSide(color: c.glow.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          if (level >= 2 && level <= 4 && reveal) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _success,
                    style: FilledButton.styleFrom(backgroundColor: c.lowPriority, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('✓ মনে ছিল', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _mistake,
                    style: FilledButton.styleFrom(backgroundColor: c.mediumPriority, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('✗ ভুল ছিল', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
          if (level == 1) ...[
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _success,
              style: FilledButton.styleFrom(backgroundColor: c.glow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 13)),
              child: const Text('✓ পুরোটা পড়েছি, পরের ধাপে যাই', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
          if (level == 5) ...[
            const SizedBox(height: 6),
            for (final d in _options())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    if (d.key == item.key) {
                      _success();
                    } else {
                      _mistake();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.textSecondary.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: Text('${d.arabic.split(' ').take(4).join(' ')}…', textAlign: TextAlign.center),
                ),
              ),
          ],
          if (level == 5 && reveal)
            Text(
              _finished ? '✓ মনে ছিল — ভালো হয়েছে 🌿' : 'এবার ভুল — লজ্জা নয়, ধাপ ১ থেকে আবার।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: _finished ? c.lowPriority : c.mediumPriority,
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'পরের: ${_inDays(_entry?.nextReview ?? DateTime.now().add(const Duration(days: 1)))} দিন পরে recall।\nভুলে গেলে লজ্জা নয় — এটাই স্বাভাবিক পদ্ধতি।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, height: 1.5, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static String _maskAll(String arabic) =>
      arabic.split(' ').map((w) => '·' * w.length).join(' ');

  static String _inDays(DateTime d) {
    final day = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = that.difference(day).inDays;
    return _fromEn(diff.clamp(0, 999).toString());
  }

  static String _fromEn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }
}
