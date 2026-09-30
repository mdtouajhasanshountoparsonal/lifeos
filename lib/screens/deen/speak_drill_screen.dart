import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// M12 — "বলে পড়ো" (self-check read-aloud)।
/// পর্দায় আরবি দেখে নিজে পড়ে বলো; পড়া/অর্থ লুকানো থাকে বলার আগে পর্যন্ত।
/// `said:<kind>:<id>` লোকাল রেকর্ড শুধু — বিচার/স্কোর নেই, স্পিচ-জাজমেন্ট নেই।
class _DrillUnit {
  final String key;
  final String kind;
  final String arabic;
  final String reading;
  final String bangla;

  const _DrillUnit({
    required this.key,
    required this.kind,
    required this.arabic,
    required this.reading,
    required this.bangla,
  });
}

class SpeakDrillScreen extends StatefulWidget {
  const SpeakDrillScreen({super.key});

  @override
  State<SpeakDrillScreen> createState() => _SpeakDrillScreenState();
}

class _SpeakDrillScreenState extends State<SpeakDrillScreen> {
  List<_DrillUnit> _units = [];
  final _showReading = <String>{};
  final _showMeaning = <String>{};
  final _showGuide = <String>{};
  final _guideFutures = <String, Future<List<DuaPronunciation>>>{};
  String _filter = 'সব';
  bool _loading = true;

  static const _filters = <String>['সব', 'শব্দ', 'শব্দভাণ্ডার', 'দোয়া', 'ফাতিহা'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final words = await ArabicSeed.words();
    final vocab = await ArabicSeed.vocab();
    final quran = await ArabicSeed.quran();
    final duas = await DeenSeed.duas();
    final units = <_DrillUnit>[
      for (final w in words)
        if (w.arabic.trim().isNotEmpty && w.reading.trim().isNotEmpty)
          _DrillUnit(
            key: 'said:word:${w.id}',
            kind: 'শব্দ',
            arabic: w.arabic,
            reading: w.reading,
            bangla: w.bangla,
          ),
      for (final v in vocab)
        if (v.arabic.trim().isNotEmpty && v.reading.trim().isNotEmpty)
          _DrillUnit(
            key: 'said:vocab:${v.id}',
            kind: 'শব্দভাণ্ডার',
            arabic: v.arabic,
            reading: v.reading,
            bangla: v.bangla,
          ),
      for (final d in duas)
        if (d.arabic.trim().isNotEmpty && d.transliteration.trim().isNotEmpty)
          _DrillUnit(
            key: 'said:dua:${d.id}',
            kind: 'দোয়া',
            arabic: d.arabic,
            reading: d.transliteration,
            bangla: d.bangla,
          ),
      for (final s in quran)
        for (final a in s.ayahs)
          if (a.arabic.trim().isNotEmpty)
            _DrillUnit(
              key: 'said:ayah:${s.id}:${a.ayah}',
              kind: 'ফাতিহা',
              arabic: a.arabic,
              reading: a.words.map((w) => w.reading).join(' '),
              bangla: a.bangla,
            ),
    ];
    if (!mounted) return;
    setState(() {
      _units = units;
      _loading = false;
    });
  }

  List<_DrillUnit> get _view => _filter == 'সব'
      ? _units
      : _units.where((u) => u.kind == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            const MoonBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '🗣️ বলে পড়ো — নিজে পড়ো',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'আরবি দেখ → নিজে বলে পাস করো → তারপর দেখো। 🔊 চাপলে ডিভাইসের TTS থেকে শোনাবে — এটি রেকর্ড করা কারীর নুরানি নয়, তাই কার্ও কণ্ঠস্বর আলাদা। কোনো মাইক, স্কোর বা স্পিচ-জাজমেন্ট নেই।',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ChoiceChip(
                        label: Text(
                          _filters[i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: _filter == _filters[i],
                        onSelected: (_) =>
                            setState(() => _filter = _filters[i]),
                        selectedColor: c.lowPriority,
                        backgroundColor: c.cardColor,
                        labelStyle: TextStyle(
                          color: _filter == _filters[i]
                              ? Colors.black
                              : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  _loading
                      ? const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Expanded(
                          child: ValueListenableBuilder(
                            valueListenable: Hive.box('deen_arabic')
                                .listenable(),
                            builder: (context, _, _) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      6,
                                      16,
                                      4,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '✅ বলেছি',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: c.lowPriority,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_bn(_saidCount())} / ${_bn(_view.length)}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: c.lowPriority,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'রেকর্ড — বিচার নয়',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        24,
                                      ),
                                      itemCount: _view.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, i) =>
                                          _drillCard(c, _view[i]),
                                    ),
                                  ),
                                ],
                              );
                            },
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

  int _saidCount() =>
      DeenStore.arabicKnown().where((k) => k.startsWith('said:')).length;

  Widget _drillCard(AppColors c, _DrillUnit u) {
    final reading = _showReading.contains(u.key);
    final meaning = _showMeaning.contains(u.key);
    return ListenableBuilder(
      listenable: Hive.box('deen_arabic').listenable(),
      builder: (context, _) {
        final said = DeenStore.isArabicKnown(u.key);
        return GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.glow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      u.kind,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: c.glow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                u.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => speakPron(u.arabic),
                  icon: Icon(Icons.volume_up_rounded, size: 16, color: c.glow),
                  label: Text(
                    '🔊 পুরোটা শোনাও',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: c.glow,
                    ),
                  ),
                ),
              ),
              if (u.kind == 'দোয়া') ...[
                const SizedBox(height: 4),
                _guideToggle(c, u),
                if (_showGuide.contains(u.key)) _guide(c, u),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        if (reading) {
                          _showReading.remove(u.key);
                        } else {
                          _showReading.add(u.key);
                        }
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.glow,
                        side: BorderSide(color: c.glow.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        reading ? '🙈 পড়া লুকাও' : '🔤 পড়া দেখ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        if (meaning) {
                          _showMeaning.remove(u.key);
                        } else {
                          _showMeaning.add(u.key);
                        }
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primary,
                        side: BorderSide(
                          color: c.primary.withValues(alpha: 0.5),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        meaning ? '🙈 অর্থ লুকাও' : '📖 অর্থ দেখ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (reading) ...[
                const SizedBox(height: 10),
                Text(
                  u.reading,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.glow,
                    height: 1.5,
                  ),
                ),
              ],
              if (meaning) ...[
                const SizedBox(height: 8),
                Text(
                  u.bangla,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => said
                    ? DeenStore.arabicUnmark(u.key)
                    : DeenStore.arabicMark(u.key),
                icon: Icon(
                  said
                      ? Icons.check_circle_rounded
                      : Icons.record_voice_over_rounded,
                  size: 18,
                ),
                label: Text(
                  said ? 'বলেছি ✓ — ফেরত' : '✅ বলেছি ✓',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: said ? c.lowPriority : c.surfaceColor,
                  foregroundColor: said ? Colors.black : c.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// দোয়ার শব্দগুলোর গাইড — পড়ার মতো শব্দ ধরে ধরে।
  Future<List<DuaPronunciation>> _guideFor(_DrillUnit u) =>
      _guideFutures.putIfAbsent(u.key, () => DuaPronouncer.words(u.arabic));

  /// বর্ণ-ভিত্তিক গাইড — যাচাইকৃত অক্ষর-পড়া, কোনো অনুমান নেই।
  Widget _guideToggle(AppColors c, _DrillUnit u) {
    final open = _showGuide.contains(u.key);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => setState(() {
          if (open) {
            _showGuide.remove(u.key);
          } else {
            _showGuide.add(u.key);
          }
        }),
        icon: Icon(
          open ? Icons.expand_less_rounded : Icons.spellcheck_rounded,
          size: 16,
          color: c.mediumPriority,
        ),
        label: Text(
          open ? 'অক্ষর-ভাঙা লুকাও' : '🔤 অক্ষরে অক্ষরে শোনাও',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: c.mediumPriority,
          ),
        ),
      ),
    );
  }

  Widget _guide(AppColors c, _DrillUnit u) {
    return FutureBuilder<List<DuaPronunciation>>(
      future: _guideFor(u),
      builder: (context, snap) {
        final words = snap.data;
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'অক্ষর ভাঙা হচ্ছে…',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
          );
        }
        if (words == null || words.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            for (final w in words) ...[
              Text(
                w.base,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: kArabicFont,
                  fontSize: 16,
                  height: 1.7,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in w.syllables)
                    _chip(c, s),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'প্রতিটি অক্ষরে চাপলে ডিভাইসের TTS থেকে শোনাবে। যেসব অক্ষরের পড়া অ্যাপে নেই, সেখানে কিছু দেখানো হয়নি — ভুল পড়া দেখাবো না।',
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(AppColors c, DuaSyllable s) {
    return Tooltip(
      message: s.reading.isEmpty ? s.letter : '${s.reading}${s.markNames.isEmpty ? '' : ' • ${s.markNames}'}',
      child: Material(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => speakPron(s.letter),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              s.glyph,
              style: TextStyle(
                fontFamily: kArabicFont,
                fontSize: 18,
                height: 1.5,
                color: s.reading.isEmpty
                    ? c.textSecondary
                    : c.textPrimary,
              ),
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
