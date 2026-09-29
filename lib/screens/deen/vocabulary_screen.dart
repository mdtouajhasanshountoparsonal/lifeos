import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabItem>? _vocab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vocab = await ArabicSeed.vocab();
    if (!mounted) return;
    setState(() => _vocab = vocab);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final vocab = _vocab;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: vocab == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: vocab.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📚 শব্দভাণ্ডার — কুরআন থেকে',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'প্রতিটি শব্দের অর্থ, মূলধাতু (root), আর কোথায় কোথায় এসেছে',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _vocabCard(c, vocab[i - 1]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _vocabCard(AppColors c, VocabItem v) {
    return ListenableBuilder(
      listenable: Hive.box('deen_arabic').listenable(),
      builder: (context, _) {
        final known = DeenStore.isArabicKnown('vocab:${v.id}');
        final hard = DeenStore.isHard('hard:vocab:${v.id}');
        return GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.arabic,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: hard ? 'কঠিন থেকে বাদ দাও' : 'কঠিন — আরও মুখস্থ',
                    child: IconButton(
                      onPressed: () => hard
                          ? DeenStore.hardUnmark('hard:vocab:${v.id}')
                          : DeenStore.hardMark('hard:vocab:${v.id}'),
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: hard
                            ? c.highPriority
                            : c.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  if (v.root.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'মূল ${v.root}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                v.reading,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.glow,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                v.bangla,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Divider(height: 22),
              Text(
                '📍 যেখানে এসেছে',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final o in v.occurrences) _occurrence(c, o),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () => known
                    ? DeenStore.arabicUnmark('vocab:${v.id}')
                    : DeenStore.arabicMark('vocab:${v.id}'),
                icon: Icon(
                  known
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                label: Text(
                  known ? 'জানি ✓ — রাখা আছে' : 'জানি ✓',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: known ? c.lowPriority : c.surfaceColor,
                  foregroundColor: known ? Colors.black : c.textSecondary,
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

  Widget _occurrence(AppColors c, QuranOccurrenceItem o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.glow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${o.surahName} ${_bn(o.surah)}:${_bn(o.ayah)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: c.glow,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    o.arabic,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    o.bangla,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: c.textSecondary,
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

  static String _bn(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }
}
