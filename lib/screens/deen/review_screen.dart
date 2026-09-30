import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/dua_word_sheet.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/review_content.dart';
import 'package:lifeos/services/review_scheduler.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class _RevUnit {
  final String key;
  final String kind;
  final String arabic;
  final String reading;
  final String bangla;

  const _RevUnit({
    required this.key,
    required this.kind,
    required this.arabic,
    required this.reading,
    required this.bangla,
  });

  factory _RevUnit.of(ReviewUnit u) => _RevUnit(
    key: u.key,
    kind: u.kind,
    arabic: u.arabic,
    reading: u.reading,
    bangla: u.bangla,
  );
}

/// 🔁 পুনরাল্লাপ — আজকের ধার্য, নিজের লজিকে সাজানো।
/// "জানি ✓" দেওয়া যে শব্দগুলো এখানে ফিরে আসে; কঠিন বললে আবার আজকের তালিকায়।
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Map<String, _RevUnit> _byKey = {};
  List<String> _queue = const [];
  int _i = 0;

  /// শুরুর সংখ্যা — রেট করা একক তালিকা থেকে বেরিয়ে যায়, তাই অগ্রগতি এখানো থেকে হিসাব হয়।
  int _total = 0;
  bool _revealed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // আগের সংস্করণে "জানি ✓" দেওয়া এককগুলো এখনো না থাকলে ঢুকিয়ে দেওয়া হয়,
    // যাতে হালনাগাদের পরেও কারো তালিকা খালি না দেখায়।
    await ReviewContent.backfill();
    final units = <String, _RevUnit>{
      for (final u in await ReviewContent.units()) u.key: _RevUnit.of(u),
    };
    final due = ReviewScheduler.dueToday()
        .where((k) => units.containsKey(k))
        .toList();
    if (!mounted) return;
    setState(() {
      _byKey
        ..clear()
        ..addAll(units);
      _queue = due;
      _total = due.length;
      _loading = false;
    });
  }

  void _rate(bool easy) {
    final key = _queue[_i.clamp(0, _queue.length - 1)];
    ReviewScheduler.rate(key, easy: easy);
    final left = [..._queue]..removeAt(_i);
    setState(() {
      _revealed = false;
      _queue = left;
      if (_i >= _queue.length) _i = 0;
    });
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
                Hive.box('deen_review').listenable(),
                Hive.box('deen_arabic').listenable(),
              ]),
              builder: (context, _) {
                if (_loading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: c.glow,
                      strokeWidth: 2.5,
                    ),
                  );
                }
                if (_queue.isEmpty) return _empty(c);
                final u = _byKey[_queue[_i.clamp(0, _queue.length - 1)]]!;
                return Column(
                  children: [
                    _header(c),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _progress(c),
                          const SizedBox(height: 12),
                          _card(c, u),
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

  Widget _header(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔁 পুনরাল্লাপ',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'ভুলে যাওয়ার আগে আবার দেখা — রেকর্ড, স্কোর নয়',
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 42, color: c.glow)),
            const SizedBox(height: 10),
            Text(
              'আজ কোনো পুনরাল্লাপ বাকি নেই',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'যেসব শব্দ "জানি ✓" দিয়েছ, তারা সময়মতো ফিরে আসবে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(AppColors c) {
    final total = _total;
    final done = total - _queue.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আজ ${_bn(done.toString())}/${_bn(total.toString())} হয়েছে',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c.glow,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 5,
            backgroundColor: c.surfaceColor,
            valueColor: AlwaysStoppedAnimation<Color>(c.glow),
          ),
        ),
      ],
    );
  }

  Widget _card(AppColors c, _RevUnit u) {
    final key = _queue[_i.clamp(0, _queue.length - 1)];
    final item = ReviewScheduler.get(key);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  u.kind,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              if (item != null && !item.isNew)
                Text(
                  'বাক্স ${_bn(item.box.toString())}',
                  style: TextStyle(fontSize: 10.5, color: c.mediumPriority),
                ),
            ],
          ),
          const SizedBox(height: 18),
          DuaTappableArabic(text: u.arabic, fontSize: 30),
          const SizedBox(height: 12),
          if (_revealed) ...[
            Text(
              u.reading,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              u.bangla,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: c.textSecondary,
              ),
            ),
          ] else
            Text(
              'মনে করে বলো — না পারলে "উত্তর দেখো" চাপো',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _btn(
                c,
                label: '🔊 শুনুন',
                bg: c.cardColor,
                fg: c.glow,
                onTap: () => speakPron(u.arabic),
              ),
              const SizedBox(width: 8),
              if (!_revealed)
                _btn(
                  c,
                  label: 'উত্তর দেখো',
                  bg: c.glow,
                  fg: Colors.black,
                  onTap: () => setState(() => _revealed = true),
                )
              else ...[
                _btn(
                  c,
                  label: '😅 আবার দেখা দরকার',
                  bg: c.cardColor,
                  fg: c.mediumPriority,
                  onTap: () => _rate(false),
                ),
                const SizedBox(width: 8),
                _btn(
                  c,
                  label: '😊 মনে আছে',
                  bg: c.glow,
                  fg: Colors.black,
                  onTap: () => _rate(true),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'তুমি নিজেই ঠিক বলেছ কি না সেটা তুমিই জানো — অ্যাপ কোনো স্কোর দেয় না।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: c.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(
    AppColors c, {
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _bn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }
}
