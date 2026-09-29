import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class ArabicWordsScreen extends StatefulWidget {
  const ArabicWordsScreen({super.key});

  @override
  State<ArabicWordsScreen> createState() => _ArabicWordsScreenState();
}

class _ArabicWordsScreenState extends State<ArabicWordsScreen> {
  List<ArabicWordItem>? _words;
  final Set<String> _showReading = {};
  final Set<String> _showMeaning = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await ArabicSeed.words();
    if (!mounted) return;
    setState(() => _words = words);
  }

  static String _bn(int n) {
    if (n == 1) return '১';
    if (n == 2) return '২';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final words = _words;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: words == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: words.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📖 শব্দ পড়া',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'প্রতিটি শব্দ পড়ো — পড়া ও অর্থ নিয়ন্ত্রণে, "জানি ✓" দিয়ে চিহ্নিত রাখো',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListenableBuilder(
                                listenable: Hive.box('deen_arabic')
                                    .listenable(),
                                builder: (context, _) {
                                  final count = words
                                      .where(
                                        (w) => DeenStore.isArabicKnown(w.id),
                                      )
                                      .length;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.lowPriority.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count > 0
                                          ? '${_bn(count)}টি শব্দ চিহ্নিত হয়েছে ✓ — "জানি ✓" টিক রাখো'
                                          : 'কোনো শব্দ চিহ্নিত হয়নি — "জানি ✓" চাপো',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: c.lowPriority,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return _wordCard(c, words[i - 1]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _wordCard(AppColors c, ArabicWordItem w) {
    final reading = _showReading.contains(w.id);
    final meaning = _showMeaning.contains(w.id);
    return ListenableBuilder(
      listenable: Hive.box('deen_arabic').listenable(),
      builder: (context, _) {
        final known = DeenStore.isArabicKnown(w.id);
        final hard = DeenStore.isHard('hard:${w.id}');
        return GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      w.arabic,
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
                          ? DeenStore.hardUnmark('hard:${w.id}')
                          : DeenStore.hardMark('hard:${w.id}'),
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: hard
                            ? c.highPriority
                            : c.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              if (reading) ...[
                const SizedBox(height: 4),
                Text(
                  w.reading,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.glow,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        if (reading) {
                          _showReading.remove(w.id);
                        } else {
                          _showReading.add(w.id);
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
                          _showMeaning.remove(w.id);
                        } else {
                          _showMeaning.add(w.id);
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
              if (meaning) ...[
                const SizedBox(height: 10),
                Text(
                  w.bangla,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (w.hasSource)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '📚 ${w.source}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        color: c.glow.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => known
                    ? DeenStore.arabicUnmark(w.id)
                    : DeenStore.arabicMark(w.id),
                icon: Icon(
                  known
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                label: Text(
                  known ? 'জানি ✓ — গেছি এগিয়ে' : 'জানি ✓',
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
}
