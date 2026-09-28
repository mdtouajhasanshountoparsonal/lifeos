import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_painters.dart';
import 'nova_widgets.dart';

double buildFn2(String expr, double x) {
  final r = NovaEngine.evaluate(expr, x: x);
  return r.ok ? (r.value ?? double.nan) : double.nan;
}

String? buildFnErr2(String expr) {
  final r = NovaEngine.evaluate(expr);
  return r.ok ? null : r.error;
}

class GraphTab extends StatefulWidget {
  const GraphTab({super.key});
  @override
  State<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<GraphTab> {
  final List<TextEditingController> funcs = List.generate(3, (_) => TextEditingController());
  double xmin = -10, xmax = 10;
  double ymin = -6, ymax = 6;
  static const int samples = 420;
  List<List<double>> series = [];
  List<double> xs = [];
  List<String?> errors = [null, null, null];
  Size _panSize = const Size(300, 280);

  @override
  void initState() {
    super.initState();
    funcs[0].text = 'sin(x)';
    funcs[1].text = 'cos(x)';
    funcs[2].text = 'x/2';
    _compute();
  }

  void _compute() {
    final all = <List<double>>[];
    final errs = <String?>[null, null, null];
    double mny = double.infinity, mxy = double.negativeInfinity;
    const double okBound = 1e7;
    xs = List.generate(samples + 1, (i) => xmin + (xmax - xmin) * i / samples);
    for (int f = 0; f < 3; f++) {
      final expr = funcs[f].text.trim();
      if (expr.isEmpty) {
        all.add(const []);
        continue;
      }
      errs[f] = buildFnErr2(expr);
      final ys = <double>[];
      if (errs[f] == null) {
        for (final x in xs) {
          double v = buildFn2(expr, x);
          if (!v.isFinite || v.abs() > okBound) v = double.nan;
          ys.add(v);
          if (v.isFinite) {
            if (v < mny) mny = v;
            if (v > mxy) mxy = v;
          }
        }
      }
      all.add(ys);
    }
    if (mny.isFinite && mxy.isFinite) {
      final pad = (mxy - mny) * 0.12;
      ymin = mny - pad;
      ymax = mxy + pad;
    }
    setState(() {
      series = all;
      errors = errs;
    });
  }

  void _zoom(double f) {
    final cx = (xmin + xmax) / 2, r = (xmax - xmin) / 2;
    final cy = (ymin + ymax) / 2, ry = (ymax - ymin) / 2;
    xmin = cx - r * f;
    xmax = cx + r * f;
    ymin = cy - ry * f;
    ymax = cy + ry * f;
    _compute();
  }

  void _pan(Offset d) {
    final dx = d.dx * (xmax - xmin) / _panSize.width;
    final dy = d.dy * (ymax - ymin) / _panSize.height;
    xmin -= dx;
    xmax -= dx;
    ymin += dy;
    ymax += dy;
    _compute();
  }

  List<double> _roots() {
    final out = <double>[];
    if (series.isEmpty || series[0].length < 2) return out;
    final ys = series[0];
    for (int i = 1; i < ys.length; i++) {
      final a = ys[i - 1], b = ys[i];
      if (!a.isFinite || !b.isFinite) continue;
      if (a == 0) {
        out.add(xs[i - 1]);
      } else if (a * b < 0) {
        out.add(xs[i - 1] - a * (xs[i] - xs[i - 1]) / (b - a));
      }
    }
    return out.take(6).toList();
  }

  List<double> _extremes() {
    if (series.isEmpty || series[0].length < 3) return [];
    final ys = series[0];
    int imin = 0, imax = 0;
    for (int i = 1; i < ys.length; i++) {
      if (ys[i].isFinite) {
        if (ys[i] < ys[imin] || !ys[imin].isFinite) imin = i;
        if (ys[i] > ys[imax] || !ys[imax].isFinite) imax = i;
      }
    }
    return [xs[imin], xs[imax]];
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final colors = [c.primary, c.glow, Colors.orangeAccent];
    final roots = _roots();
    final exts = _extremes();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'লাইভ গ্রাফ (y = f(x))',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: novaField(context,
                      controller: funcs[i],
                      label: i == 0 ? 'প্রথম ফাংশন' : (i == 1 ? 'দ্বিতীয়' : 'তৃতীয়'),
                      hint: ['sin(x)', 'cos(x)', 'x/2'][i]),
                ),
              ]),
            ),
          const SizedBox(height: 6),
          Row(children: [
            _gbtn(context, Icons.zoom_in, () => _zoom(0.6)),
            const SizedBox(width: 8),
            _gbtn(context, Icons.zoom_out, () => _zoom(1.8)),
            const SizedBox(width: 8),
            _gbtn(context, Icons.replay_rounded, () {
              xmin = -10;
              xmax = 10;
              _compute();
            }),
            const Spacer(),
            Text('ড্র্যাগ = প্যান', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          for (int i = 0; i < 3; i++)
            if (errors[i] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${['১ম', '২য়', '৩য়'][i]} ফাংশন: ${errors[i]}', style: TextStyle(color: c.expense, fontSize: 12)),
              ),
          GestureDetector(
            onPanUpdate: (d) => _pan(d.delta),
            child: LayoutBuilder(builder: (context, constraints) {
              _panSize = Size(constraints.maxWidth, 280);
              return Container(
                height: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14)),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 280),
                  painter: GraphPainter(
                    series: series,
                    xs: xs,
                    colors: colors,
                    xmin: xmin,
                    xmax: xmax,
                    ymin: ymin,
                    ymax: ymax,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          if (series.isNotEmpty && series[0].isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in roots) _tag(context, 'মূল x ≈ ${novaFmt(r)}'),
              if (exts.length >= 2) _tag(context, 'নিম্ন ≈ ${novaFmt(exts[0])}'),
              if (exts.length >= 2) _tag(context, 'উর্ধ্ব ≈ ${novaFmt(exts[1])}'),
            ]),
        ]),
      ),
    ]);
  }

  Widget _gbtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.primary.withValues(alpha: 0.3))),
        child: Icon(icon, size: 20, color: c.primary),
      ),
    );
  }

  Widget _tag(BuildContext context, String t) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.glow.withValues(alpha: 0.3))),
      child: Text(t, style: TextStyle(color: c.primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}