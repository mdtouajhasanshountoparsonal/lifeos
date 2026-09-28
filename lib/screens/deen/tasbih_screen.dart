import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/count_ring.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

class _Preset {
  final String name;
  final String arabic;
  final int target;

  const _Preset(this.name, this.arabic, this.target);
}

const _presets = <_Preset>[
  _Preset('সুবহানাল্লাহ', 'سُبْحَانَ اللَّهِ', 33),
  _Preset('আলহামদুলিল্লাহ', 'الْحَمْدُ لِلَّهِ', 33),
  _Preset('আল্লাহু আকবার', 'اللَّهُ أَكْبَرُ', 33),
  _Preset('ইস্তিগফার', 'أَسْتَغْفِرُ اللَّهَ', 100),
  _Preset('দরূদ শরীফ', 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', 100),
];

/// 📿 Smart Tasbih — পুরো কার্ড ট্যাপে গননা, প্রতি ট্যাপ haptic,
/// session count Hive-এ থাকে + "সংরক্ষিত রান" হিস্ট্রি।
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  late String _name;
  late String _arabic;
  late int _target;
  late int _count;
  String? _customName;

  @override
  void initState() {
    super.initState();
    final cur = DeenStore.tasbihCurrent();
    _name = cur['name'] as String? ?? 'সুবহানাল্লাহ';
    _arabic = cur['arabic'] as String? ?? 'سُبْحَانَ اللَّهِ';
    _target = ((cur['target'] as num?) ?? 33).toInt();
    _count = ((cur['count'] as num?) ?? 0).toInt();
  }

  void _persist() {
    DeenStore.saveTasbihCurrent(
      name: _name,
      arabic: _arabic,
      target: _target,
      count: _count,
    );
  }

  void _selectPreset(_Preset p) {
    HapticFeedback.selectionClick();
    setState(() {
      _name = p.name;
      _arabic = p.arabic;
      _target = p.target;
      _count = 0;
    });
    _persist();
  }

  void _selectCustom(String name, int target) {
    HapticFeedback.selectionClick();
    setState(() {
      _name = name;
      _arabic = 'فَاذْكُرُونِي أَذْكُرْكُمْ';
      _target = target;
      _count = 0;
      _customName = name;
    });
    _persist();
  }

  void _tap() {
    if (_count < _target) {
      HapticFeedback.lightImpact();
      setState(() => _count++);
      _persist();
    }
  }

  bool get _done => _target > 0 && _count >= _target;

  Future<void> _openCustom(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');
    final c = AppTheme.of(context);
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('কাস্টম জিকির', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'নাম (যেমন: সুরা ইখলাস)',
                hintStyle: TextStyle(fontSize: 13, color: c.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: c.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'লক্ষ্য সংখ্যা',
                hintStyle: TextStyle(fontSize: 13, color: c.textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: c.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.glow),
            onPressed: () {
              final t = int.tryParse(targetCtrl.text.trim());
              final n = nameCtrl.text.trim();
              if (t == null || t < 1 || t > 100000) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, (n.isEmpty ? 'কাস্টম' : n, t));
            },
            child: const Text('শুরু'),
          ),
        ],
      ),
    );
    if (result != null) _selectCustom(result.$1, result.$2);
  }

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
                      Text(
                        '📿 স্মার্ট তাসবিহ',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Hive.box('tasbih_session').listenable(),
                    builder: (context, _) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          Text(
                            'প্রিসেট',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final p in _presets)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _chip(c, p.name, _name == p.name, () => _selectPreset(p)),
                                  ),
                                _chip(c, '✦ কাস্টম', _customName != null && _name == _customName, () => _openCustom(context)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _countCard(c),
                          const SizedBox(height: 16),
                          _runsSection(c),
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

  Widget _chip(AppColors c, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? c.glow : c.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _countCard(AppColors c) {
    return Material(
      color: c.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _tap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textSecondary),
                    ),
                  ),
                  Text(
                    'লক্ষ্য ${_bnNum(_target.toString())}',
                    style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 210,
                height: 210,
                child: CountRing(
                  progress: _target > 0 ? _count / _target : 0,
                  color: _done ? c.lowPriority : c.glow,
                  trackColor: c.surfaceColor,
                  strokeWidth: 12,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_arabic, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.4)),
                        const SizedBox(height: 10),
                        Text(
                          _bnNum(_count.toString()),
                          style: TextStyle(
                            fontSize: _count >= 1000 ? 40 : 54,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: _done ? c.lowPriority : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _done ? '✓ লক্ষ্য সম্পন্ন — আমল সংরক্ষণ করুন' : 'কার্ড ট্যাপ করে গননা',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _done ? c.lowPriority : c.textSecondary,
                ),
              ),
              if (_done) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.textSecondary.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          setState(() => _count = 0);
                          _persist();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('আবার শুরু', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.glow,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          DeenStore.addTasbihRun(name: _name, count: _count, target: _target);
                          setState(() => _count = 0);
                          _persist();
                        },
                        icon: const Icon(Icons.bookmark_add_rounded, size: 17),
                        label: const Text('সংরক্ষণ', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _runsSection(AppColors c) {
    final runs = DeenStore.tasbihRuns();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'সংরক্ষিত রান',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.textSecondary),
              ),
            ),
            if (runs.isNotEmpty)
              TextButton(
                onPressed: () {
                  DeenStore.clearTasbihRuns();
                  setState(() {});
                },
                style: TextButton.styleFrom(
                  foregroundColor: c.mediumPriority,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('সব মুছুন', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (runs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'এখনো কোনো রান নেই — লক্ষ্যে পৌঁছে "সংরক্ষণ" চাপলে এখানে জমা হবে।',
              style: TextStyle(fontSize: 11.5, color: c.textSecondary.withValues(alpha: 0.8)),
            ),
          )
        else
          for (final r in runs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.glow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(child: Text('📿', style: TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['name'] as String? ?? 'জিকির',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                          ),
                          Text(
                            _runTime(r['ts'] as String?),
                            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_bnNum(((r['count'] as num?) ?? 0).toInt().toString())} / ${_bnNum(((r['target'] as num?) ?? 0).toInt().toString())}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.lowPriority),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  static String _runTime(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    final p = d.hour < 12 ? 'AM' : 'PM';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_bnNum(h.toString())}:${_bnNum(d.minute.toString().padLeft(2, '0'))} $p';
  }

  static String _bnNum(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }
}