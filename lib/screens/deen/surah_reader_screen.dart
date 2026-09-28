import 'package:flutter/material.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🔖 একটি সূরার পূর্ণ পাঠ — আরবি + বাংলা পড়া + অর্থ + আগের/পরের সূরা।
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

  void _jump(int i) {
    final all = _all;
    if (all == null) return;
    if (i < 0 || i >= all.length) return;
    final target = all[i];
    if (target.arabic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'সূরা ${target.name} — আরবি পাঠ এখনো যোগ হয়নি (প্রস্তুত হচ্ছে)',
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

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final s = _all?[_index] ?? widget.surah;
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
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
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
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
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
                  ),
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
}
