import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class QuranWordsScreen extends StatefulWidget {
  const QuranWordsScreen({super.key});

  @override
  State<QuranWordsScreen> createState() => _QuranWordsScreenState();
}

class _QuranWordsScreenState extends State<QuranWordsScreen> {
  List<QuranSurahItem>? _quran;
  bool _testMode = false;
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quran = await ArabicSeed.quran();
    if (!mounted) return;
    setState(() => _quran = quran);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final quran = _quran;
    final surah = quran == null || quran.isEmpty ? null : quran.first;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: surah == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text('🌟 কুরআনের শব্দ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Text('সূরা ${surah.name} — প্রতিটি শব্দ ধরে পড়া ও অর্থ', style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() {
                                _testMode = !_testMode;
                                _revealed.clear();
                              }),
                              icon: Icon(_testMode ? Icons.visibility_rounded : Icons.lock_outline_rounded, size: 17),
                              label: Text(_testMode ? '👀 পড়া মোডে ফিরো' : '🎯 নিজে বলো (test)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: c.glow,
                                side: BorderSide(color: c.glow.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final a in surah.ayahs) _ayahCard(c, surah, a),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ayahCard(AppColors c, QuranSurahItem surah, QuranAyahItem a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(_bn(a.ayah), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c.glow)),
                ),
                const SizedBox(width: 8),
                Text('আয়াত', style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(a.arabic, textAlign: TextAlign.right,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.8)),
            const SizedBox(height: 6),
            Text('অর্থ: ${a.bangla}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textSecondary)),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in a.words) _wordTile(c, surah.id, a.ayah, w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordTile(AppColors c, String surahId, int ayah, QuranWordItem w) {
    final key = '$surahId-$ayah-${w.id}';
    final revealed = _revealed.contains(key);
    final show = !_testMode || revealed;
    return Material(
      color: c.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _revealed.add(key)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(w.arabic, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.4)),
              if (show) ...[
                const SizedBox(height: 3),
                Text(w.reading, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.glow)),
                const SizedBox(height: 1),
                Text(w.bangla, style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('🔒', style: TextStyle(fontSize: 13)),
                ),
            ],
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