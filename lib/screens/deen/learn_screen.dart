import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/memorize_screen.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 📚 "আজকের শিক্ষা" — প্রতিদিন ঘুরেফিরে একটি দুয়া (offline deterministic)।
/// ⏰ "Quick Recall" — যে দুয়াগুলোর পর্যালোচনার সময় হয়েছে।
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<DuaItem> _pool = const [];
  List<MemItem> _mems = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DeenSeed.duas();
    final mems = await DeenSeed.memPool();
    if (!mounted) return;
    setState(() {
      _pool = items.where((d) => d.arabic.trim().isNotEmpty).toList();
      _mems = mems.where((m) => m.arabic.trim().isNotEmpty).toList();
      _loaded = true;
    });
  }

  MemItem? _byKey(String key) =>
      _mems.where((m) => m.key == key).firstOrNull;

  /// প্রতিদিনের স্থির ও আজ পঠিত আইটেম — সার্চ/এলগোরিদম নেই।
  DuaItem? get _daily {
    if (_pool.isEmpty) return null;
    final start = DateTime(2024, 1, 1);
    final days = DateTime.now().difference(start).inDays;
    return _pool[days % _pool.length];
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                Hive.box('deen_meta').listenable(),
                Hive.box('memorization').listenable(),
              ]),
              builder: (context, _) {
                final daily = _daily;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📚 আজকের শিক্ষা', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.textPrimary)),
                                Text('প্রতিদিন একটি দুয়া + পর্যালোচনা', style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: !_loaded
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              children: [
                                _recallSection(c),
                                const SizedBox(height: 14),
                                Text('আজকের শিক্ষা', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary)),
                                const SizedBox(height: 8),
                                if (daily != null) _dailyCard(c, daily) else const SizedBox.shrink(),
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

  Widget _recallSection(AppColors c) {
    final due = DeenStore.dueMemorizationIds(DateTime.now());
    if (due.isEmpty) return const SizedBox.shrink();
    final map = DeenStore.memorizationAll();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⏰ পর্যালোচনার সময় (Quick Recall)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.glow)),
        const SizedBox(height: 8),
        for (final id in due)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _byKey(id)?.label ?? id,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ধাপ ${_fromEn((map[id]?.level ?? 1).toString())}/৫',
                          style: TextStyle(fontSize: 11, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MemorizePracticeScreen(itemKey: id)),
                    ),
                    style: FilledButton.styleFrom(backgroundColor: c.glow, foregroundColor: Colors.black),
                    child: const Text('এখনি যাই', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _dailyCard(AppColors c, DuaItem d) {
    final key = 'dua:${d.id}';
    final doneToday = DeenStore.dailyLearnDate == DeenStore.dayKey(DateTime.now());
    final inProgress = DeenStore.memorizationGet(key) != null;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (doneToday)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.lowPriority.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(9)),
                child: Text('✓ আজকের শিক্ষা পড়া হয়েছে', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.lowPriority)),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.glow.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(d.section, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.glow)),
          ),
          const SizedBox(height: 10),
          Text(d.arabic, textAlign: TextAlign.right, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.7)),
          const SizedBox(height: 8),
          Text(d.bangla, style: TextStyle(fontSize: 13.5, height: 1.6, color: c.textSecondary)),
          const SizedBox(height: 10),
          Text(
            '📚 ${d.hasSource ? d.source : 'source নেই'}',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: d.hasSource ? c.glow : c.mediumPriority),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: doneToday
                ? null
                : () {
                    DeenStore.setDailyLearnDone();
                    setState(() {});
                  },
            icon: const Icon(Icons.check_rounded, size: 17),
            label: Text(doneToday ? 'আজকের শিক্ষা পড়া হয়েছে ✓' : 'পড়া হয়েছে ✓'),
            style: FilledButton.styleFrom(
              backgroundColor: doneToday ? c.textSecondary.withValues(alpha: 0.35) : c.lowPriority,
              foregroundColor: doneToday ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: inProgress
                      ? null
                      : () {
                          DeenStore.memorizationStart(key);
                          setState(() {});
                        },
                  icon: const Icon(Icons.psychology_rounded, size: 17),
                  label: Text(inProgress ? 'মুখস্থ চলছে…' : 'মুখস্থ শুরু'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.glow,
                    side: BorderSide(color: c.glow.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fromEn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }
}