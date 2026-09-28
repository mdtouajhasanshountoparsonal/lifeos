import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final letters = await ArabicSeed.letters();
    if (!mounted) return;
    setState(() => _letters = letters);
  }

  void _showDetail(AppColors c, ArabicLetterItem l) {
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
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text('🔤 আরবি অক্ষর', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Text('২৮টি অক্ষর — ট্যাপ করলে নাম, রূপ ও উদাহরণ দেখাবে', style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: letters.length,
                        itemBuilder: (context, i) {
                          final l = letters[i];
                          return Material(
                            color: c.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _showDetail(c, l),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(l.letter, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.glow)),
                                  const SizedBox(height: 4),
                                  Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
                                ],
                              ),
                            ),
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
                decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                  child: Text(l.letter, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: c.glow)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary)),
                      const SizedBox(height: 2),
                      Text('উচ্চারণ: ${l.reading}', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (l.connectsForward && l.initial.isNotEmpty) ...[
              Text('যোগের রূপ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: c.textSecondary)),
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
              Text('⚠️ এটি এমন অক্ষর যা পরের অক্ষরের সাথে যুক্ত হয় না — শুধু আগেরটির সাথে।', style: TextStyle(fontSize: 12, height: 1.5, color: c.mediumPriority)),
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
                        Text('উদাহরণ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSecondary)),
                        const SizedBox(height: 6),
                        Text(l.example, textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(l.exampleReading, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.glow)),
                        const SizedBox(height: 2),
                        Text('অর্থ: ${l.exampleBangla}', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: c.glow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 13)),
              child: const Text('বন্ধ করুন', style: TextStyle(fontWeight: FontWeight.w800)),
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
          decoration: BoxDecoration(color: c.surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: Text(form, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: c.textPrimary)),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 10, color: c.textSecondary)),
      ],
    );
  }
}