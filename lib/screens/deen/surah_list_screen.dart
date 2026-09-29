import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/surah_reader_screen.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 📖 কুরআনের সব সূরা — তালিকা (১১৪টি)। যার পাঠ আছে তাপ দিলে পড়া যায়।
class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<SurahItem>? _surahs;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await DeenSeed.surahs();
    if (!mounted) return;
    setState(() => _surahs = list);
  }

  List<SurahItem> get _filtered {
    final all = _surahs ?? const <SurahItem>[];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final s in all)
        if (s.name.toLowerCase().contains(q) ||
            s.nameMeaning.toLowerCase().contains(q) ||
            s.arabicName.toLowerCase().contains(q) ||
            s.revelation.toLowerCase().contains(q) ||
            s.index.toString() == q)
          s,
    ];
  }

  String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final surahs = _surahs;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: surahs == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text(
                        '📖 কুরআন — সূরা তালিকা',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_bnNum(surahs.length)}টি সূরা · সব কটির আয়াত ধরে ধরে পাঠ — কুরআনের লিপিতে, বাংলা অনুবাদসহ',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: c.cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: c.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '🔍 নাম বা নাম্বার দিয়ে খুঁজো…',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: c.textSecondary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: c.textSecondary,
                            ),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: c.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${_bnNum(_filtered.length)}টি দেখানো হচ্ছে',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ListenableBuilder(
                        listenable: Hive.box('deen_arabic').listenable(),
                        builder: (context, _) {
                          return _progressCard(c, surahs);
                        },
                      ),
                      const SizedBox(height: 6),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Center(
                            child: Text(
                              'কিছু পাওয়া যায়নি — অন্য নাম্বার/নাম দিয়ে দেখো',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final s in _filtered) _tile(c, s),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(AppColors c, List<SurahItem> surahs) {
    final total = surahs.fold<int>(0, (t, s) => t + s.ayahs.length);
    final reads = DeenStore.quranReads().length;
    final mems = DeenStore.quranMems().length;
    final readPct = total == 0 ? 0 : (reads * 100 / total).round();
    final memPct = total == 0 ? 0 : (mems * 100 / total).round();
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
          Text(
            '📖 কুরআন পড়ার প্রগ্রেস',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: bar(reads)),
              const SizedBox(width: 10),
              Text(
                'পড়া শেষ ${_bnNum(readPct)}% (${_bnNum(reads)}/${_bnNum(total)})',
                style: TextStyle(fontSize: 11, color: c.glow),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: bar(mems)),
              const SizedBox(width: 10),
              Text(
                'মুখস্থ ${_bnNum(memPct)}% (${_bnNum(mems)}/${_bnNum(total)})',
                style: TextStyle(fontSize: 11, color: c.lowPriority),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'প্রতিটি আয়াত-কার্ডে "মুখস্থ" আর "পড়া শেষ" চিহ্নিত করলে এই % আপডেট হবে।',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: c.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AppColors c, SurahItem s) {
    final hasText = s.arabic.trim().isNotEmpty || s.ayahs.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!hasText) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'সূরা ${s.name} — আরবি পাঠ এখনো যোগ হয়নি (প্রস্তুত হচ্ছে)',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SurahReaderScreen(surah: s)),
            );
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (hasText ? c.lowPriority : c.textSecondary).withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    _bnNum(s.index),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: hasText ? c.lowPriority : c.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.arabicName} · ${s.revelation} · ${_bnNum(s.ayahCount)} আয়াত',
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.nameMeaning,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (hasText ? c.glow : c.textSecondary).withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasText ? '✓ পাঠ আছে' : 'পাঠ আসবে',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: hasText ? c.glow : c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
