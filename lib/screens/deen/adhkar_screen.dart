import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🌅 সকাল-সন্ধ্যার যিকির + "আজকের আমল" — ব্যক্তিগত রেকর্ড, স্কোর নয়।
class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  List<AdhkarItem> _items = const [];
  bool _loaded = false;
  late bool _morning = DateTime.now().hour < 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DeenSeed.adhkar();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loaded = true;
    });
  }

  List<AdhkarItem> get _shown =>
      _items.where((a) => _morning ? a.isMorning : a.isEvening).toList();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
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
                        icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🌅 সকাল-সন্ধ্যার যিকির',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.textPrimary),
                            ),
                            Text(
                              '"আজকের আমল" — হিসাব, বিচার নয়',
                              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, icon: Icon(Icons.wb_sunny_rounded, size: 16), label: Text('সকাল')),
                      ButtonSegment(value: false, icon: Icon(Icons.nights_stay_rounded, size: 16), label: Text('সন্ধ্যা')),
                    ],
                    selected: {_morning},
                    onSelectionChanged: (s) => setState(() => _morning = s.first),
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      Hive.box('amal_log').listenable(),
                      Hive.box('salah_log').listenable(),
                      Hive.box('deen_meta').listenable(),
                      Hive.box('memorization').listenable(),
                    ]),
                    builder: (context, _) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _todayAmalCard(c),
                          const SizedBox(height: 14),
                          Text(
                            _morning ? 'সকালের যিকির' : 'সন্ধ্যার যিকির',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          if (!_loaded)
                            Center(child: CircularProgressIndicator(color: c.glow, strokeWidth: 2.5))
                          else if (_shown.isEmpty)
                            Text('এখনো কোনো যিকির সংযোজন হয়নি', style: TextStyle(fontSize: 12.5, color: c.textSecondary))
                          else
                            for (final a in _shown) _adhkarRow(c, a),
                          const SizedBox(height: 10),
                          Text(
                            'সংখ্যা ও সূত্র হাদিস/কুরআন থেকে — "source নেই" হলে সেটা স্পষ্ট দেখানো হয়।',
                            style: TextStyle(fontSize: 10.5, height: 1.4, color: c.textSecondary.withValues(alpha: 0.8)),
                          ),
                        ],
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

  Widget _todayAmalCard(AppColors c) {
    final key = DeenStore.dayKey(DateTime.now());
    final salahDone = DeenStore.prayers
        .where((p) => DeenStore.dayLog(key)[p]?.done ?? false)
        .length;
    final dhikr = DeenStore.adhkarDoneToday();
    final morningDone = _items.any((a) => a.isMorning && dhikr.contains(a.id));
    final eveningDone = _items.any((a) => a.isEvening && dhikr.contains(a.id));
    final memorized = DeenStore.memorizedTodayIds().length;
    final quran = DeenStore.quranMinutesToday();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('আজকের আমল', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              Text('রেকর্ড — স্কোর নয়', style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(c, '🕌 নামাজ', '${_bnNum(salahDone.toString())}/৫'),
              _stat(c, 'যিকির', morningDone && eveningDone ? 'সকাল ✓ সন্ধ্যা ✓' : morningDone ? 'সন্ধ্যা ○' : 'সকাল ○'),
              _stat(c, '🧠 মুখস্থ', _bnNum(memorized.toString())),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('📖 কুরআন পড়া', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => DeenStore.addQuranMinutes(-5),
                icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: c.textSecondary),
              ),
              Text('${_bnNum(quran.toString())} মিনিট', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.glow)),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => DeenStore.addQuranMinutes(5),
                icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: c.glow),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary)),
        ],
      ),
    );
  }

  Widget _adhkarRow(AppColors c, AdhkarItem a) {
    final done = DeenStore.isAdhkarDone(a.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: done ? c.lowPriority.withValues(alpha: 0.08) : c.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => DeenStore.toggleAdhkar(a.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.lowPriority : Colors.transparent,
                    border: Border.all(
                      color: done ? c.lowPriority : c.textSecondary.withValues(alpha: 0.4),
                      width: 1.6,
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, size: 15, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.arabic,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(a.bangla, style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (a.repeat > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.glow.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_bnNum(a.repeat.toString())} বার',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.glow),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '📚 ${a.hasSource ? a.source : 'source নেই'}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: a.hasSource ? c.textSecondary : c.mediumPriority,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _bnNum(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }
}