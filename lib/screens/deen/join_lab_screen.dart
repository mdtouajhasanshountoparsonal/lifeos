import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// অক্ষর জোড়া/যুক্ত রূপ নিয়ে অনুশীলন — পড়া শেখার ভিত্তি (Phase A)।
class JoinLabScreen extends StatefulWidget {
  const JoinLabScreen({super.key});

  @override
  State<JoinLabScreen> createState() => _JoinLabScreenState();
}

class _JoinItem {
  final List<ArabicLetterItem> letters;
  final bool nonJoinerStart;

  const _JoinItem(this.letters, {this.nonJoinerStart = false});

  String get key => letters.map((l) => l.id).join(':');

  String get markKey => 'join2:$key';

  String get word => letters.map((l) => l.letter).join();
}

class _JoinLabScreenState extends State<JoinLabScreen> {
  List<ArabicLetterItem>? _letters;
  List<ArabicLetterItem> _nonJoiner = [];
  List<_JoinItem> _pairs = [];
  List<_JoinItem> _triples = [];
  int _extraPairs = 30;
  int _extraTriples = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final letters = await ArabicSeed.letters();
    if (!mounted) return;
    setState(() {
      _letters = letters;
      _nonJoiner = letters.where((l) => !l.connectsForward).toList();
      _pairs = _genPairs(letters);
      _triples = _genTriples(letters);
    });
  }

  /// পরের অক্ষরের সাথে যুক্ত হয় না এমন অক্ষর: ا د ذ ر ز و
  bool _joinsNext(ArabicLetterItem l) => l.connectsForward;

  List<_JoinItem> _genPairs(List<ArabicLetterItem> letters) {
    final conn = letters.where((l) => _joinsNext(l)).toList();
    final result = <_JoinItem>[];
    final seen = <String>{};
    var i = 0;
    // ২০টি যুক্ত-অক্ষরতলা জোড়া (ছক্কা রোটেশন — সব জোড়াই শুদ্ধ রূপ)।
    while (result.length < 30 && i < 6000) {
      final a = conn[i % conn.length];
      final b = letters[(i * 7 + 3) % letters.length];
      final key = '${a.id}:${b.id}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(_JoinItem([a, b]));
      }
      i++;
    }
    // অ-যুক্ত-শুরু জোড়া: যেমন د + ب = دب (আগেরটা আলাদা, পরে নতুন শুরু)।
    for (final n in _nonJoiner) {
      final bIdx =
          (letters.indexWhere((l) => l.id == n.id) * 5 + 11) % letters.length;
      final key = '${n.id}:${letters[bIdx].id}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(_JoinItem([n, letters[bIdx]], nonJoinerStart: true));
      }
    }
    return result;
  }

  List<_JoinItem> _genTriples(List<ArabicLetterItem> letters) {
    final conn = letters.where((l) => _joinsNext(l)).toList();
    final result = <_JoinItem>[];
    final seen = <String>{};
    var i = 0;
    while (result.length < 26 && i < 8000) {
      final a = conn[i % conn.length];
      final b = letters[(i * 5 + 11) % letters.length];
      final c = letters[(i * 13 + 7) % letters.length];
      final key = '${a.id}:${b.id}:${c.id}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(_JoinItem([a, b, c]));
      }
      i++;
    }
    return result;
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
                : ListenableBuilder(
                    listenable: Hive.box('deen_arabic').listenable(),
                    builder: (context, _) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          _header(c),
                          const SizedBox(height: 14),
                          _progressCard(c),
                          const SizedBox(height: 16),
                          _sectionTitle(
                            c,
                            '🚫 অ-যুক্ত অক্ষর',
                            'পরের অক্ষরের সাথে এরা যুক্ত হয় না — এদের পরে অক্ষর নতুন করে শুরু হয়',
                          ),
                          const SizedBox(height: 8),
                          _nonJoinerGrid(c),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            c,
                            '🔗 ২ অক্ষরের জোড়া',
                            '"জানি ✓" দাও যা পড়তে পারো, "কঠিন ⚠️" যেটা আটকে',
                          ),
                          const SizedBox(height: 8),
                          _pairGrid(c, _pairs.take(_extraPairs).toList(), 3),
                          if (_pairs.length > _extraPairs) _moreButton(c, 3),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            c,
                            '📖 ৩ অক্ষরের শব্দ-জোড়া',
                            'মাঝের অক্ষর দুদিকেই যুক্ত হয় — ধীরে পড়ো, ভেবেভেবে',
                          ),
                          const SizedBox(height: 8),
                          _pairGrid(
                            c,
                            _triples.take(_extraTriples).toList(),
                            2,
                          ),
                          if (_triples.length > _extraTriples)
                            _moreButton(c, 2),
                          const SizedBox(height: 18),
                          _quizCard(c),
                          const SizedBox(height: 14),
                          GlassCard(
                            padding: const EdgeInsets.all(12),
                            borderRadius: BorderRadius.circular(14),
                            child: Text(
                              'যুক্ত রূপ স্ক্রিনে আরবি ফন্টে সঠিক আকৃতি পায় — যেমন ব+ত = بت। শুধু অক্ষর জোড়া দেওয়াতেই অ্যাপ নিজে শুদ্ধ বাঁশি-আকৃতির জোড়া দেখায়।',
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

  Widget _header(AppColors c) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔗 Joining Lab',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'অক্ষর → যুক্ত রূপ → শব্দ পড়া (ধাপে ধাপে)',
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _progressCard(AppColors c) {
    final total = _nonJoiner.length + _pairs.length + _triples.length;
    final known = <String>[
      for (final n in _nonJoiner) 'join0:${n.id}',
      for (final p in _pairs) p.markKey,
      for (final t in _triples) t.markKey,
    ].where(DeenStore.isArabicKnown).length;
    final hard = <String>[
      for (final n in _nonJoiner) 'join0:${n.id}',
      for (final p in _pairs) p.markKey,
      for (final t in _triples) t.markKey,
    ].where(DeenStore.isHard).length;
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
                '📈 জোড়া পড়া',
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
          const SizedBox(height: 6),
          Text(
            'নিজের লেখা — বিচার নয় · ট্যাপ করে যোগের রূপ দেখো',
            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
      ],
    );
  }

  Widget _nonJoinerGrid(AppColors c) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: _nonJoiner.length,
      itemBuilder: (context, i) {
        final l = _nonJoiner[i];
        final k = 'join0:${l.id}';
        final known = DeenStore.isArabicKnown(k);
        final hard = DeenStore.isHard(k);
        return Material(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showNonJoiner(c, l),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.letter,
                    style: TextStyle(
                      fontFamily: kArabicFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: known ? c.glow : c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
          ),
        );
      },
    );
  }

  Widget _pairGrid(AppColors c, List<_JoinItem> items, int cross) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _joinTile(c, item);
      },
    );
  }

  Widget _joinTile(AppColors c, _JoinItem item) {
    final known = DeenStore.isArabicKnown(item.markKey);
    final hard = DeenStore.isHard(item.markKey);
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showJoinDetail(c, item),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.word,
                style: TextStyle(
                  fontFamily: kArabicFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: known ? c.glow : c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.letters.map((l) => l.letter).join(' + '),
                style: TextStyle(fontSize: 10.5, color: c.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                known ? '✓ জানি' : (hard ? '⚠️ কঠিন' : ''),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: known ? c.glow : c.mediumPriority,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreButton(AppColors c, int step) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              if (step == 3) {
                _extraPairs += 30;
              } else {
                _extraTriples += 20;
              }
            });
          },
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          label: const Text('আরও দেখাও'),
          style: TextButton.styleFrom(
            foregroundColor: c.glow,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void _showNonJoiner(AppColors c, ArabicLetterItem l) {
    speakPron(l.reading);
    final k = 'join0:${l.id}';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _nonJoinerSheet(c, l, k),
    );
  }

  Widget _nonJoinerSheet(AppColors c, ArabicLetterItem l, String k) {
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
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.glow.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    l.letter,
                    style: TextStyle(
                      fontFamily: kArabicFont,
                      fontSize: 42,
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
                          fontSize: 19,
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.mediumPriority.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⚠️ এই অক্ষরটি পরের অক্ষরের সাথে যুক্ত হয় না।\nএটির **পরে** আসা অক্ষর সদা নতুন করে (প্রথম রূপে) শুরু হয়।',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: c.mediumPriority,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'উদাহরণ — এ অক্ষর দিয়ে:',
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 6),
            _sampleNonJoiner(c, l),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      DeenStore.resolveHardAndKnown('join0:${l.id}', k);
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
                      DeenStore.hardMark(k);
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
    );
  }

  Widget _sampleNonJoiner(AppColors c, ArabicLetterItem l) {
    final others = _letters ?? const <ArabicLetterItem>[];
    final partner = others.where((x) => x.id != l.id).toList();
    ArabicLetterItem? b;
    for (var i = 0; i < partner.length; i++) {
      final cand = partner[(partner.length ~/ 2 + i) % partner.length];
      if (cand.connectsForward) {
        b = cand;
        break;
      }
    }
    if (b == null) return const SizedBox.shrink();
    final it = _JoinItem([l, b], nonJoinerStart: true);
    return Material(
      color: c.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.word,
                    style: TextStyle(
                      fontFamily: kArabicFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l.letter} + ${b.letter}',
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: c.textSecondary),
            Text(
              '${l.reading} + ${b.reading}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.glow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDetail(AppColors c, _JoinItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _joinDetailSheet(c, item),
    );
  }

  Widget _joinDetailSheet(AppColors c, _JoinItem item) {
    final isSingle = item.letters.length == 1;
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
            Text(
              item.letters.map((l) => l.name).join(' + '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: c.glow.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.word,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kArabicFont,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: c.glow,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isSingle ? 'এই অক্ষরটি এভাবে থাকে' : 'কীভাবে যুক্ত হল',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < item.letters.length; i++)
                  _formChip(c, i, item.letters[i], item),
              ],
            ),
            if (!isSingle) ...[
              const SizedBox(height: 12),
              Text(
                'পড়ো: ${_banglaReading(item)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      DeenStore.resolveHardAndKnown(item.markKey, item.markKey);
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
                      DeenStore.hardMark(item.markKey);
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
    );
  }

  String _banglaReading(_JoinItem item) {
    return item.letters.map((l) => l.reading).join('-');
  }

  Widget _formChip(AppColors c, int i, ArabicLetterItem l, _JoinItem item) {
    final form = _formFor(item.letters, i);
    final label = switch (i) {
      0 => 'শুরু',
      _ => i == item.letters.length - 1 ? 'শেষ' : 'মাঝ',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
          const SizedBox(width: 8),
          Text(
            form,
            style: TextStyle(
              fontFamily: kArabicFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          if (i < item.letters.length - 1) ...[
            const SizedBox(width: 4),
            Text('→', style: TextStyle(color: c.textSecondary)),
          ],
        ],
      ),
    );
  }

  /// কোনো অক্ষর কোনো অবস্থানে কোন রূপে বসে (যুক্ত নিয়ম অনুযায়ী)।
  String _formFor(List<ArabicLetterItem> letters, int i) {
    final l = letters[i];
    final prev = i > 0 ? letters[i - 1] : null;
    final prevJoins = prev != null && prev.connectsForward;
    final isLast = i == letters.length - 1;
    if (!prevJoins) return l.connectsForward ? l.initial : l.isolated;
    return isLast ? l.finalJ : l.medial;
  }

  // ─── অনুশীলন (কুইজ) ──────────────────────────────────────────────────
  Widget _quizCard(AppColors c) {
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startQuiz(c),
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
                      'জোড়া চিনে নাও, অ-যুক্ত ঠিক করো — বারবার খেলো',
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

  void _startQuiz(AppColors c) {
    final quiz = _buildQuiz();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _JoinQuizSheet(c: c, quiz: quiz),
    );
  }

  List<_QuizQuestion> _buildQuiz() {
    final pool = <_QuizQuestion>[];
    // যুক্ত-জোড়া প্রশ্ন (সঠিকটা = জোড়া হওয়া শব্দ)।
    for (var i = 0; i < _pairs.length && pool.length < 7; i++) {
      pool.add(_readJoinQuestion(_pairs[i]));
    }
    // অ-যুক্ত প্রশ্ন।
    for (final n in _nonJoiner) {
      pool.add(
        _QuizQuestion(
          prompt: '${n.letter}  —  এটি কি পরের অক্ষরের সাথে যুক্ত হয়?',
          options: ['হ্যাঁ, যুক্ত হয়', 'না, যুক্ত হয় না'],
          correct: 'না, যুক্ত হয় না',
          word: n.letter,
        ),
      );
    }
    pool.shuffle();
    return pool.take(10).toList();
  }

  _QuizQuestion _readJoinQuestion(_JoinItem item) {
    final options = <String>{item.word};
    for (final other in _pairs) {
      if (options.length >= 4) break;
      if (other.word != item.word) options.add(other.word);
    }
    for (final other in _triples) {
      if (options.length >= 4) break;
      if (other.word != item.word) options.add(other.word);
    }
    final list = options.toList()..shuffle();
    return _QuizQuestion(
      prompt: item.letters.map((l) => l.letter).join(' + '),
      options: list,
      correct: item.word,
      word: item.word,
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

class _QuizQuestion {
  final String prompt;
  final List<String> options;
  final String correct;
  final String word;

  const _QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correct,
    required this.word,
  });
}

class _JoinQuizSheet extends StatefulWidget {
  final AppColors c;
  final List<_QuizQuestion> quiz;

  const _JoinQuizSheet({required this.c, required this.quiz});

  @override
  State<_JoinQuizSheet> createState() => _JoinQuizSheetState();
}

class _JoinQuizSheetState extends State<_JoinQuizSheet> {
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

  Widget _question(AppColors c, _QuizQuestion q) {
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
          'কোনটি সঠিক জোড়া?',
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
              fontSize: 32,
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
                        fontFamily: kArabicFont,
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
          '🏁 অনুশীলন শেষ!',
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
              ? 'দারুণ! যেখানে আটকেছ, ⚠️ চিহ্ন দাও — পরে "কঠিন"-এ দেখবে।'
              : 'ভুল থেকে শেখা — বেশি practice করতে থাকো।',
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
