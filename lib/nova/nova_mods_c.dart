import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_math.dart';
import 'nova_painters.dart';
import 'nova_science.dart';
import 'nova_widgets.dart';

// ---------------- Statistics ----------------

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final dataT = TextEditingController(text: '12, 18, 25, 25, 31, 42, 51');
  Map<String, dynamic>? st;
  String? err;

  double get _maxBin {
    final bins = (st?['bins'] as List? ?? []);
    double mx = 0;
    for (final b in bins) {
      if (b is num && b > mx) mx = b.toDouble();
    }
    return mx == 0 ? 1 : mx;
  }

  void _run() {
    final data = NovaMath.parseData(dataT.text);
    setState(() {
      if (data == null || data.isEmpty) {
        err = 'ডেটা পাওয়া যায়নি';
        st = null;
        return;
      }
      err = null;
      st = NovaMath.stats(data);
      novaSaveHistory(category: 'stats', expr: dataT.text.trim(), result: '${novaFmt(data.length.toDouble())} টি মান, গড় ${novaFmt(st!['mean'] as double)}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'পরিসংখ্যান ও ডেটা ল্যাব',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          novaField(context, controller: dataT, label: 'ডেটা (কমা/স্পেস দিয়ে)', hint: '12, 18, 25, 25, 31, 42, 51', maxLines: 2),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _run,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.glow]), borderRadius: BorderRadius.circular(12)),
              child: Text('বিশ্লেষণ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          if (err != null)
            NovaOutput(text: err!, error: true)
          else if (st != null) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              _stat(context, 'n', st!['n']),
              _stat(context, 'গড়', st!['mean']),
              _stat(context, 'মধ্যমা', st!['median']),
              _stat(context, 'প্রচুরক', st!['mode']),
              _stat(context, 'প্রমাণ বিচ্যুতি', st!['std']),
              _stat(context, 'বৈচিত্র্য', st!['var']),
              _stat(context, 'রেঞ্জ', st!['range']),
              _stat(context, 'Q1', st!['q1']),
              _stat(context, 'Q3', st!['q3']),
              _stat(context, 'IQR', st!['iqr']),
            ]),
            const SizedBox(height: 12),
            Text('হিস্টোগ্রাম', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in (st!['bins'] as List? ?? []))
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: (b as num).toDouble() / _maxBin * 94,
                        decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('বিন: ${(st!['bins'] as List? ?? []).length}টি  •  সর্বোচ্চ ${fmtSmart(_maxBin)}', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ],
        ]),
      ),
    ]);
  }

  Widget _stat(BuildContext context, String label, dynamic v) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(v is num ? novaFmt(v.toDouble()) : (v == null ? '—' : '$v'),
            style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ---------------- Constants ----------------

class ConstantsTab extends StatelessWidget {
  const ConstantsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'বৈজ্ঞানিক ধ্রুবকসমূহ',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final k in NovaConstants)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: k.expr));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${k.glyph} (${k.expr}) কপি হয়েছে')));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: c.cardColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(k.glyph, style: TextStyle(color: c.primary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(k.name, style: TextStyle(color: c.textPrimary, fontSize: 12.5))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(novaFmt(k.value), style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    if (k.unit.isNotEmpty) Text(k.unit, style: TextStyle(color: c.textSecondary, fontSize: 10)),
                  ]),
                ]),
              ),
            ),
          const SizedBox(height: 6),
          Text('টিপ: মানে ট্যাপ করলে সিম্বল কপি হয়ে ক্যালকুলেটরে পেস্ট করতে পারবেন।',
              style: TextStyle(color: c.textSecondary, fontSize: 11.5)),
        ]),
      ),
    ]);
  }
}

// ---------------- Simulation ----------------

class SimTab extends StatefulWidget {
  const SimTab({super.key});
  @override
  State<SimTab> createState() => _SimTabState();
}

class _SimTabState extends State<SimTab> with SingleTickerProviderStateMixin {
  final vT = TextEditingController(text: '20');
  final aT = TextEditingController(text: '45');
  final gT = TextEditingController(text: '9.8');
  late AnimationController ctrl;
  NovaProjectile? p;
  List<Offset> trajectory = [];
  bool running = true;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..addListener(() => setState(() {}));
    _build();
    ctrl.repeat();
  }

  void _build() {
    final v = double.tryParse(vT.text);
    final a = double.tryParse(aT.text);
    final g = double.tryParse(gT.text);
    if (v == null || a == null || g == null || v <= 0 || g <= 0) return;
    p = NovaProjectile(v, a, g);
    final T = p!.timeOfFlight;
    final n = 60;
    trajectory = List.generate(n + 1, (i) => Offset(p!.x(T * i / n), p!.y(T * i / n)));
    if (T.isFinite && T > 0.1) {
      ctrl.duration = Duration(milliseconds: (T * 1000).round().clamp(800, 6000));
    }
  }

  void _toggle() {
    setState(() {
      running = !running;
      if (running) {
        ctrl.repeat();
      } else {
        ctrl.stop();
      }
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    vT.dispose();
    aT.dispose();
    gT.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final T = p?.timeOfFlight ?? 1;
    final t = (ctrl.value * T).clamp(0.0, T) as double;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'প্রজেক্টাইল সিমুলেশন',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: novaField(context, controller: vT, label: 'বেগ v₀ (m/s)', keyboard: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 8),
            Expanded(child: novaField(context, controller: aT, label: 'কোণ (°)', keyboard: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 8),
            Expanded(child: novaField(context, controller: gT, label: 'g (m/s²)', keyboard: const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              onTap: () {
                _build();
                ctrl.value = 0;
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.glow.withValues(alpha: 0.4))),
                child: Row(children: [
                  Icon(Icons.refresh, size: 16, color: c.primary),
                  const SizedBox(width: 6),
                  Text('রিসেট', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: running ? c.primary : c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(running ? Icons.pause : Icons.play_arrow, size: 16, color: running ? Colors.black : c.textPrimary),
                  const SizedBox(width: 6),
                  Text(running ? 'থাম' : 'চালু', style: TextStyle(color: running ? Colors.black : c.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (p != null) ...[
            Container(
              height: 230,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(
                size: const Size(double.infinity, 230),
                painter: ProjectilePainter(
                  trajectory: trajectory,
                  ball: Offset(p!.x(t), p!.y(t)),
                  range: p!.range,
                  maxH: p!.maxHeight,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _v(context, 'সময়', '${novaFmt(t)} s'),
              _v(context, 'উচ্চতা', '${novaFmt(math.max(0, p!.y(t)))} m'),
              _v(context, 'দূরত্ব', '${novaFmt(p!.x(t))} m'),
              _v(context, 'গতি', '${novaFmt(p!.speed(t))} m/s'),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _v(context, 'মোট সময়', '${novaFmt(p!.timeOfFlight)} s'),
              _v(context, 'মোট রেঞ্জ', '${novaFmt(p!.range)} m'),
              _v(context, 'সর্বোচ্চ উচ্চতা', '${novaFmt(p!.maxHeight)} m'),
            ]),
            const SizedBox(height: 8),
            novaSaveAfter(context, 'সিমুলেশন হিসাব নোটে রাখুন', () {
              novaSaveToNotes(
                  title: 'NOVA • প্রজেক্টাইল',
                  content: '# প্রজেক্টাইল\nv₀ = ${vT.text} m/s, কোণ = ${aT.text}°, g = ${gT.text}\n- মোট সময় = ${novaFmt(p!.timeOfFlight)} s\n- রেঞ্জ = ${novaFmt(p!.range)} m\n- সর্বোচ্চ উচ্চতা = ${novaFmt(p!.maxHeight)} m');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নোটে যোগ হয়েছে')));
            }),
          ],
        ]),
      ),
    ]);
  }

  Widget _v(BuildContext context, String label, String v) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
        Text(v, style: TextStyle(color: c.glow, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

Widget novaSaveAfter(BuildContext context, String label, VoidCallback onTap) {
  final c = AppTheme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.glow.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
    ),
  );
}

// ---------------- History ----------------

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final items = novaHistory();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'ইতিহাস → জ্ঞান',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text('এখনো কোনো হিসাব নেই\nআগের ট্যাবে হিসাব করলে এখানে জমা হবে।', textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary))),
            ),
          for (final it in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                    child: Text(it['category'] ?? '', style: TextStyle(color: c.primary, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                  const Spacer(),
                  Text(novaFmtTime((it['at'] as String?) ?? ''), style: TextStyle(color: c.textSecondary, fontSize: 10.5)),
                ]),
                const SizedBox(height: 8),
                Text(it['expr'] as String? ?? '', style: TextStyle(color: c.textSecondary, fontSize: 12.5, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text(it['result'] as String? ?? '', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 8),
                Row(children: [
                  _historyChip(context, Icons.note_add_outlined, 'নোটে', () {
                    final b = StringBuffer();
                    b.writeln('# ${it['category'] ?? 'NOVA'}');
                    b.writeln('**${it['expr'] as String? ?? ''}**');
                    b.writeln((it['result'] as String? ?? ''));
                    if (it['unit'] != null && (it['unit'] as String).isNotEmpty) {
                      b.writeln('একক: ${it['unit']}');
                    }
                    if ((it['steps'] as List? ?? []).isNotEmpty) {
                      b.writeln('');
                      b.writeln('**Steps:**');
                      for (final s in it['steps'] as List) {
                        b.writeln('- $s');
                      }
                    }
                    novaSaveToNotes(title: 'NOVA • ${it['category'] ?? ''}', content: b.toString());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নোটে যোগ হয়েছে')));
                  }),
                  const SizedBox(width: 6),
                  _historyChip(context, Icons.delete_outline, 'মুছুন', () {
                    HiveDelete.delete(it['id']);
                    setState(() => _tick++);
                  }),
                ]),
              ]),
            ),
          if (items.isNotEmpty)
            GestureDetector(
              onTap: () {
                HiveDelete.clearAll();
                setState(() => _tick++);
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.expense.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.expense.withValues(alpha: 0.4))),
                child: Text('সব মুছুন', style: TextStyle(color: c.expense, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _historyChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.glow.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: c.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class HiveDelete {
  static void delete(String? id) {
    final box = novaHistoryBox();
    if (id == null) return;
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is Map && v['id'] == id) {
        box.delete(k);
        return;
      }
    }
  }

  static void clearAll() {
    novaHistoryBox().clear();
  }
}