import 'package:flutter/material.dart';
import 'package:lifeos/screens/deen/surah_reader_screen.dart';
import 'package:lifeos/services/deen_seed.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await DeenSeed.surahs();
    if (!mounted) return;
    setState(() => _surahs = list);
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
                        '${_bnNum(surahs.length)}টি সূরা · যার পাঠ (আরবি + অর্থ) আছে তা থেকে পড়ুন — বাকিগুলো ধাপে ধাপে যোগ হচ্ছে',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final s in surahs) _tile(c, s),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(AppColors c, SurahItem s) {
    final hasText = s.arabic.trim().isNotEmpty;
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
