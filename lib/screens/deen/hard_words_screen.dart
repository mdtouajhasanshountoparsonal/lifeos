import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🩹 কঠিন শব্দ — সমস্যা যেখানে চিহ্নিত, সেখানে বেশি মুখস্থ।
/// users.Fill '.কঠিন ⚠️' দিলে এখানে আসে; "জানি ✓" মানে কঠিন-লিস্ট থেকে সরে
/// গিয়ে শিখা-রেকর্ডে ঢোকে (স্কোর নয় — নিজের গতিতে)।
class HardWordsScreen extends StatefulWidget {
  const HardWordsScreen({super.key});

  @override
  State<HardWordsScreen> createState() => _HardWordsScreenState();
}

class _HardItem {
  final String hardKey;
  final String knownKey;
  final String ar;
  final String reading;
  final String bangla;
  final String label;

  const _HardItem({
    required this.hardKey,
    required this.knownKey,
    required this.ar,
    required this.reading,
    required this.bangla,
    required this.label,
  });
}

class _HardWordsScreenState extends State<HardWordsScreen> {
  List<_HardItem>? _items;
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wordsFuture = ArabicSeed.words();
    final vocabFuture = ArabicSeed.vocab();
    final surahsFuture = DeenSeed.surahs();
    final words = await wordsFuture;
    final vocab = await vocabFuture;
    final surahs = await surahsFuture;
    if (!mounted) return;

    final wordsByHard = {for (final w in words) 'hard:${w.id}': w};
    final vocabByHard = {for (final v in vocab) 'hard:vocab:${v.id}': v};
    final surahByIndex = {for (final s in surahs) s.index: s};

    final items = <_HardItem>[];
    for (final hk in DeenStore.arabicHard()) {
      final w = wordsByHard[hk];
      if (w != null) {
        items.add(
          _HardItem(
            hardKey: hk,
            knownKey: w.id,
            ar: w.arabic,
            reading: w.reading,
            bangla: w.bangla,
            label: 'শব্দ চর্চা',
          ),
        );
        continue;
      }
      final v = vocabByHard[hk];
      if (v != null) {
        items.add(
          _HardItem(
            hardKey: hk,
            knownKey: 'vocab:${v.id}',
            ar: v.arabic,
            reading: v.reading,
            bangla: v.bangla,
            label: 'কুরআন শব্দভাণ্ডার',
          ),
        );
        continue;
      }
      // hard:read:<i>:<n>
      final m = RegExp(r'^hard:read:(\d+):(\d+)$').firstMatch(hk);
      if (m != null) {
        final i = int.parse(m.group(1)!);
        final n = int.parse(m.group(2)!);
        final s = surahByIndex[i];
        if (s != null) {
          for (final a in s.ayahs) {
            if (a.n == n) {
              items.add(
                _HardItem(
                  hardKey: hk,
                  knownKey: 'read:$i:$n',
                  ar: a.ar,
                  reading: '',
                  bangla: a.bn,
                  label: 'সূরা ${s.name} · আয়াত ${_bnNum(n)}',
                ),
              );
              break;
            }
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _items = items);
  }

  static String _bnNum(int n) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final items = _items;
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
                              '🩹 কঠিন শব্দ — আরও মুখস্থ',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              'যেসব কঠিন বলে ⚠️ দিয়েছ — সেগুলোই এখানে। বারবার দেখা = মনে থাকা।',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
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
                  child: items == null
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : ListenableBuilder(
                          listenable: Hive.box('deen_arabic').listenable(),
                          builder: (context, _) {
                            final live = items
                                .where((it) => DeenStore.isHard(it.hardKey))
                                .toList();
                            if (live.isEmpty) {
                              return ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 30),
                                  Center(
                                    child: Text(
                                      '🎉 কোনো কঠিন শব্দ নেই!',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      'পড়ার সময় কোনো শব্দ আটকালে ⚠️ চিহ্ন দাও — এখানে এসে বারবার মুখস্থ করবে।',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: live.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                if (i == live.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'রেকর্ড শুধু — স্কোর/গিল্টি নয়। নিজের গতিতে।',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                                return _hardCard(c, live[i]);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hardCard(AppColors c, _HardItem it) {
    final hidden = _hidden.contains(it.hardKey);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            it.label,
            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            it.ar,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: c.textPrimary,
            ),
          ),
          if (!hidden && it.reading.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                it.reading,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.glow,
                ),
              ),
            ),
          if (!hidden && it.bangla.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                it.bangla,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          if (hidden)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '(পড়া/অর্থ লুকানো — নিজে পড়ে বলার চেষ্টা করো)',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    if (hidden) {
                      _hidden.remove(it.hardKey);
                    } else {
                      _hidden.add(it.hardKey);
                    }
                  }),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 16,
                    color: c.secondary,
                  ),
                  label: Text(
                    hidden ? 'পড়া/অর্থ দেখাও' : 'লুকিয়ে নিজে পড়ো',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.secondary,
                    side: BorderSide(color: c.secondary.withValues(alpha: 0.5)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    DeenStore.resolveHardAndKnown(it.hardKey, it.knownKey);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text(
                    'জানি ✓ — নেমে গেল',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.lowPriority,
                    foregroundColor: Colors.black,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
