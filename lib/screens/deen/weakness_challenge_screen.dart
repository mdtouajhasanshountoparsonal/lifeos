import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/arabic_weakness.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🎯 দুর্বলতা-চ্যালেঞ্জ — নিজের কঠিন ⚠️-চিহ্নিত জিনিসগুলো থেকে মিশ্রিত
/// অনুশীলন (সবচেয়ে বেশি ১০টা, এলোমেলো)। "জানি ✓" দিলে কঠিন-লিস্ট থেকে
/// নামিয়ে আবার চেনা-রেকর্ডে ঢোকায়; "এখনো পারিনি" মানে কঠিন-লিস্টেই থাকে।
/// কোনো স্কোর নেই — শুধু নিজের গতি।
class WeaknessChallengeScreen extends StatefulWidget {
  const WeaknessChallengeScreen({super.key});

  @override
  State<WeaknessChallengeScreen> createState() =>
      _WeaknessChallengeScreenState();
}

class _WeaknessChallengeScreenState extends State<WeaknessChallengeScreen> {
  List<WeakItem>? _all;
  List<WeakItem> _queue = [];
  int _i = 0;
  int _knownCount = 0;
  int _stillCount = 0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await WeaknessService.load()
      ..shuffle(Random());
    if (!mounted) return;
    setState(() {
      _all = all;
      _queue = all.take(10).toList();
    });
  }

  void _next() {
    setState(() {
      _revealed = false;
      if (_i + 1 >= _queue.length) {
        _queue = [];
        _i = 0;
      } else {
        _i++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final all = _all;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: all == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListenableBuilder(
                    listenable: Hive.box('deen_arabic').listenable(),
                    builder: (context, _) {
                      if (all.isEmpty) return _emptyState(c);
                      if (_queue.isEmpty) return _summary(c);
                      final w = _queue[_i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: c.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    '🎯 দুর্বলতা-চ্যালেঞ্জ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.glow.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'প্রশ্ন ${_bnNum(_i + 1)}/${_bnNum(_queue.length)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: c.glow,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: (_i + 1) / _queue.length,
                                    minHeight: 7,
                                    backgroundColor: c.surfaceColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      c.glow,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                GlassCard(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    18,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            w.emoji,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              w.label,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: c.textSecondary,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                speakPron(w.reading),
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: Icon(
                                              Icons.volume_up_rounded,
                                              size: 20,
                                              color: c.glow,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        w.ar,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: kArabicFont,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          height: 1.5,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (_revealed &&
                                          w.reading.trim().isNotEmpty)
                                        Text(
                                          w.reading,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: c.glow,
                                            height: 1.4,
                                          ),
                                        )
                                      else
                                        Text(
                                          _revealed
                                              ? '(উচ্চারণ নেই)'
                                              : '👀 উপরে তাকাও — পরে পড়া দেখো',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'এটাকে পড়ো/চেনো — তারপর নিজের বিচারে চিহ্ন দাও। ভুলের ভয় নেই, রেকর্ড ঘরে-বাইরে নয়।',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.5,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () {
                                          DeenStore.resolveHardAndKnown(
                                            w.hardKey,
                                            w.knownKey,
                                          );
                                          _knownCount++;
                                          _next();
                                        },
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'জানি ✓',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: c.lowPriority,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          _stillCount++;
                                          _next();
                                        },
                                        icon: const Icon(
                                          Icons.replay_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'এখনো পারিনি',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: c.mediumPriority,
                                          side: BorderSide(
                                            color: c.mediumPriority.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _revealed = !_revealed),
                                  icon: Icon(
                                    _revealed
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 16,
                                    color: c.secondary,
                                  ),
                                  label: Text(
                                    _revealed
                                        ? 'পড়া/উচ্চারণ লুকাও'
                                        : 'পড়া/উচ্চারণ দেখো',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: c.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColors c) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Text(
            '🌟 এখনো কোনো কঠিন নেই!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'পড়ার সময় কোনো কিছু আটকালে ⚠️ (কঠিন) চিহ্ন দাও — চ্যালেঞ্জ তখনই শুরু হবে।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('ফিরে যাই'),
          ),
        ),
      ],
    );
  }

  Widget _summary(AppColors c) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 50),
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Text(
                '✅ শেষ!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: c.lowPriority,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(c, _bnNum(_knownCount), 'এবার জানি ✓', c.lowPriority),
                  _stat(
                    c,
                    _bnNum(_stillCount),
                    'আবার দেখা হবে',
                    c.mediumPriority,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'যেগুলো "এখনো পারিনি" — সেগুলো কঠিন-লিস্টেই থাকলো, যাত্রা ড্যাশবোর্ডে আবার দেখা যাবে। কোনো স্কোর নয়, লজ্জা নেই।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'বন্ধ করুন',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: c.glow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(AppColors c, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
      ],
    );
  }

  static String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final code = c.codeUnitAt(0);
      return code >= 0x30 && code <= 0x39 ? bn[code - 0x30] : c;
    }).join();
  }
}
