import 'package:flutter/material.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

class ArabicHarakatScreen extends StatefulWidget {
  const ArabicHarakatScreen({super.key});

  @override
  State<ArabicHarakatScreen> createState() => _ArabicHarakatScreenState();
}

class _ArabicHarakatScreenState extends State<ArabicHarakatScreen> {
  List<HarakaItem>? _harakat;
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final harakat = await ArabicSeed.harakat();
    if (!mounted) return;
    setState(() => _harakat = harakat);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final harakat = _harakat;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: harakat == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    itemCount: harakat.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🪄 হরকত (স্বরচিহ্ন)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                              const SizedBox(height: 4),
                              Text('চিহ্ন দেখে পড়া শিখো — ট্যাপ করলে পড়া ও মানে খুলবে', style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
                            ],
                          ),
                        );
                      }
                      final h = harakat[i - 1];
                      return _tile(c, h);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AppColors c, HarakaItem h) {
    final revealed = _revealed.contains(h.id);
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          if (revealed) {
            _revealed.remove(h.id);
          } else {
            _revealed.add(h.id);
          }
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (h.id.contains('madd') ? c.secondary : c.glow).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(h.mark, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
                    const SizedBox(height: 3),
                    Text(revealed ? h.reading : '🔒 ট্যাপ করে পড়া দেখুন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: revealed ? c.glow : c.textSecondary)),
                    const SizedBox(height: 3),
                    Text(h.bangla, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}