import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<GrammarLessonItem>? _lessons;
  final Set<int> _open = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await ArabicSeed.grammar();
    if (!mounted) return;
    setState(() => _lessons = lessons);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final lessons = _lessons;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: lessons == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: lessons.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📖 ব্যাকরণ — ছোট ছোট পাঠ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                              const SizedBox(height: 4),
                              Text('কীভাবে আরবি বাক্য গড়া হয় — কুরআনের শব্দ দিয়েই উদাহরণ', style: TextStyle(fontSize: 12, height: 1.5, color: c.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return _lessonCard(c, lessons[i - 1], i - 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _lessonCard(AppColors c, GrammarLessonItem l, int idx) {
    final open = _open.contains(idx);
    return GlassCard(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() {
                if (open) {
                  _open.remove(idx);
                } else {
                  _open.add(idx);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text(l.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('${idx + 1}. ${l.title}',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
                    ),
                    Icon(open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  for (final ex in l.explanation)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•', style: TextStyle(color: c.glow, fontSize: 12)),
                          const SizedBox(width: 7),
                          Expanded(child: Text(ex, style: TextStyle(fontSize: 12.5, height: 1.55, color: c.textPrimary))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  for (final e in l.examples)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: c.surfaceColor, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(e.arabic, textAlign: TextAlign.right, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.4)),
                          const SizedBox(height: 3),
                          Text(e.reading, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.glow)),
                          const SizedBox(height: 4),
                          Text('${e.bangla} — ${e.note}', textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, height: 1.5, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.secondary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                    child: Text('💡 ${l.tip}', style: TextStyle(fontSize: 12, height: 1.5, fontWeight: FontWeight.w700, color: c.secondary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}