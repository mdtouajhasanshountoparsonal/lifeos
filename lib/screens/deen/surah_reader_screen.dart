import 'package:flutter/material.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🔖 একটি সূরার পূর্ণ পাঠ — আরবি + বাংলা পড়া + অর্থ।
class SurahReaderScreen extends StatelessWidget {
  final SurahItem surah;

  const SurahReaderScreen({super.key, required this.surah});

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
    final s = surah;
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
