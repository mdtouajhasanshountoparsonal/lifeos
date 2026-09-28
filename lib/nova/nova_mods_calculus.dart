import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_math.dart';
import 'nova_painters.dart';
import 'nova_mods_graph.dart' show buildFn2, buildFnErr2;
import 'nova_widgets.dart';

class CalculusTab extends StatefulWidget {
  const CalculusTab({super.key});
  @override
  State<CalculusTab> createState() => _CalculusTabState();
}

class _CalculusTabState extends State<CalculusTab> {
  final fn = TextEditingController(text: 'x^3+2x');
  final aT = TextEditingController(text: '0');
  final bT = TextEditingController(text: '2');
  final x0T = TextEditingController(text: '1');
  String? symDeriv;
  String? symErr;
  double? intVal;
  double? diffVal;
  List<double> areaXs = [];
  List<double> areaYs = [];
  String? fnErr;

  void _deriv() {
    final expr = fn.text.trim();
    final e = buildFnErr2(expr);
    final x0 = double.tryParse(x0T.text);
    setState(() {
      symErr = e;
      symDeriv = e == null ? NovaMath.symbolicDerivative(expr) : null;
      diffVal = (e == null && x0 != null) ? NovaMath.centralDiff((x) => buildFn2(expr, x), x0) : null;
      novaSaveHistory(category: 'calculus', expr: 'd/dx ($expr)', result: symDeriv ?? e ?? '');
    });
  }

  void _integrate() {
    final expr = fn.text.trim();
    final e = buildFnErr2(expr);
    setState(() {
      fnErr = e;
      if (e == null) {
        final a = double.tryParse(aT.text) ?? 0;
        final b = double.tryParse(bT.text) ?? 0;
        intVal = NovaMath.simpson((x) => buildFn2(expr, x), a, b);
        final lo = math.min(a, b) - (b - a).abs() * 0.3;
        final hi = math.max(a, b) + (b - a).abs() * 0.3;
        final n = 300;
        areaXs = List.generate(n + 1, (i) => lo + (hi - lo) * i / n);
        areaYs = areaXs.map((x) => buildFn2(expr, x)).toList();
        novaSaveHistory(category: 'integral', expr: '∫[${fmtSmart(a)},${fmtSmart(b)}] ${expr} dx', result: novaFmt(intVal!));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'অন্তরক (Derivative)',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          novaField(context, controller: fn, label: 'f(x) = ', hint: 'x^3+2x', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          novaField(context, controller: x0T, label: 'x₀ বিন্দু', hint: '1'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _deriv,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.glow]), borderRadius: BorderRadius.circular(12)),
              child: Text('d/dx গণনা', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          if (symErr != null)
            NovaOutput(text: symErr!, error: true)
          else if (symDeriv != null) ...[
            NovaOutput(text: "d/dx (${fn.text.trim()})", steps: ['$symDeriv']),
            if (diffVal != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("f'(${x0T.text}) = ${novaFmt(diffVal!)}",
                    style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      novaSection(
        context,
        'নির্দিষ্ট সমাকল (∫)',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: novaField(context, controller: aT, label: 'সীমা a', hint: '0')),
            const SizedBox(width: 10),
            Expanded(child: novaField(context, controller: bT, label: 'সীমা b', hint: '2')),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _integrate,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.glow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.glow.withValues(alpha: 0.4)),
              ),
              child: Text('বক্ররেখার নিচের ক্ষেত্রফল', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 10),
          if (fnErr != null)
            NovaOutput(text: fnErr!, error: true)
          else if (intVal != null) ...[
            NovaOutput(text: '∫ ${fn.text.trim()} dx = ${novaFmt(intVal!)}', steps: ['সিম্পসন নিয়মে সংখ্যাগত সমাকল']),
            const SizedBox(height: 10),
            Container(
              height: 180,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: IntegralAreaPainter(
                    xs: areaXs,
                    ys: areaYs,
                    a: double.tryParse(aT.text) ?? 0,
                    b: double.tryParse(bT.text) ?? 0,
                    curveColor: c.glow),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}