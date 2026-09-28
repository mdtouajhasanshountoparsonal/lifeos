import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_math.dart';
import 'nova_science.dart';
import 'nova_units.dart';
import 'nova_widgets.dart';

// ---------------- Matrix ----------------

class MatrixTab extends StatefulWidget {
  const MatrixTab({super.key});
  @override
  State<MatrixTab> createState() => _MatrixTabState();
}

class _MatrixTabState extends State<MatrixTab> {
  int n = 2;
  late List<List<TextEditingController>> grid;
  String? result;
  List<List<String>> resultGrid = [];

  @override
  void initState() {
    super.initState();
    grid = List.generate(n, (_) => List.generate(n, (_) => TextEditingController(text: '1')));
  }

  void _setN(int v) {
    setState(() {
      for (final row in grid) {
        for (final c in row) {
          c.dispose();
        }
      }
      n = v;
      grid = List.generate(n, (_) => List.generate(n, (i) => TextEditingController(text: i == 0 ? '1' : '0')));
      result = null;
      resultGrid = [];
    });
  }

  List<List<double>> readMatrix() {
    return List.generate(n, (i) => List.generate(n, (j) => double.tryParse(grid[i][j].text.trim()) ?? 0));
  }

  void _showGrid(List<List<double>> m) {
    setState(() {
      resultGrid = m.map((r) => r.map((e) => novaFmt(e)).toList()).toList();
      result = null;
    });
  }

  void _run(String op) {
    final m = readMatrix();
    switch (op) {
      case 'det':
        setState(() {
          result = 'det = ${novaFmt(NovaMath.det(m))}';
          resultGrid = [];
        });
        novaSaveHistory(category: 'matrix', expr: 'det($n×$n)', result: '${novaFmt(NovaMath.det(m))}');
        break;
      case 'trans':
        _showGrid(NovaMath.transpose(m));
        break;
      case 'inv':
        final inv = NovaMath.inverse(m);
        setState(() {
          if (inv == null) {
            result = 'অসিঙ্গুলার — inverse নেই';
            resultGrid = [];
          } else {
            resultGrid = inv.map((r) => r.map((e) => novaFmt(e)).toList()).toList();
            result = null;
          }
        });
        break;
      case 'rank':
        setState(() {
          result = 'rank = ${NovaMath.rank(m)}';
          resultGrid = [];
        });
        break;
      case 'mul':
        _showGrid(NovaMath.multiply(m, m));
        break;
      case 'eigen':
        final eigs = NovaMath.eigen2x2(m);
        setState(() {
          if (eigs.isEmpty) {
            result = 'জটিল eigenvalues';
            resultGrid = [];
          } else {
            result = eigs.map((e) => 'λ = ${novaFmt((e['lam'] as double))}').join('   ');
            resultGrid = [];
          }
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'ম্যাট্রিক্স ল্যাব',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('মাত্রা: '),
            for (final sz in [2, 3])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _setN(sz),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: n == sz ? c.primary : c.cardColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('$sz×$sz', style: TextStyle(color: n == sz ? Colors.black : c.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          for (int i = 0; i < n; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (int j = 0; j < n; j++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: c.cardColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                        ),
                        child: TextField(
                          controller: grid[i][j],
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _op(context, 'Determinant', () => _run('det')),
            _op(context, 'Transpose', () => _run('trans')),
            _op(context, 'Inverse', () => _run('inv')),
            _op(context, 'Rank', () => _run('rank')),
            _op(context, 'A×A', () => _run('mul')),
            if (n == 2) _op(context, 'Eigen', () => _run('eigen')),
          ]),
          const SizedBox(height: 10),
          if (result != null) NovaOutput(text: result!, error: result!.contains('নেই')),
          if (resultGrid.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  for (final row in resultGrid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final e in row)
                            Expanded(child: Text(e, textAlign: TextAlign.center, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          const Text('ভেক্টর', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          novaField(context, controller: _va, label: 'ভেক্টর A (কমা দিয়ে) e.g. 1,2,3'),
          const SizedBox(height: 6),
          novaField(context, controller: _vb, label: 'ভেক্টর B (কমা দিয়ে) e.g. 4,5,6'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _op(context, 'Dot', () => _vec('dot')),
            _op(context, 'Cross (3D)', () => _vec('cross')),
          ]),
          if (_vecOut != null) ...[
            const SizedBox(height: 8),
            NovaOutput(text: _vecOut!),
          ],
        ]),
      ),
    ]);
  }

  final _va = TextEditingController(text: '1,2,3');
  final _vb = TextEditingController(text: '4,5,6');
  String? _vecOut;

  void _vec(String op) {
    final a = NovaMath.parseData(_va.text) ?? [];
    final b = NovaMath.parseData(_vb.text) ?? [];
    if (a.isEmpty || b.isEmpty) return;
    if (op == 'dot') {
      final d = NovaMath.dot(a, b);
      setState(() {
        _vecOut = 'A·B = ${novaFmt(d)}';
      });
    } else {
      if (a.length != 3 || b.length != 3) {
        setState(() => _vecOut = '২টি ভেক্টরকেই ৩টি মান দিন');
        return;
      }
      final cr = NovaMath.cross3(a, b);
      setState(() {
        _vecOut = 'A×B = ${cr.map((x) => novaFmt(x)).join(', ')}';
      });
    }
  }

  Widget _op(BuildContext context, String t, VoidCallback onTap) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.glow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.glow.withValues(alpha: 0.35)),
        ),
        child: Text(t, style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ---------------- Physics ----------------

class PhysicsTab extends StatefulWidget {
  const PhysicsTab({super.key});
  @override
  State<PhysicsTab> createState() => _PhysicsTabState();
}

class _PhysicsTabState extends State<PhysicsTab> {
  int idx = 0;
  String target = 'F';
  List<TextEditingController> vals = [];
  String? out;

  NovaPhysFormula get f => NovaFormulas[idx];

  void _select(int i) {
    setState(() {
      idx = i;
      target = f.vars.first.key;
      out = null;
      for (final c in vals) {
        c.dispose();
      }
      vals = List.generate(f.vars.length, (_) => TextEditingController());
    });
  }

  @override
  void initState() {
    super.initState();
    vals = List.generate(f.vars.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in vals) {
      c.dispose();
    }
    super.dispose();
  }

  void _solve() {
    final m = <String, double>{};
    bool bad = false;
    for (int i = 0; i < f.vars.length; i++) {
      final txt = vals[i].text.trim();
      if (txt.isEmpty || txt == '.') {
        bad = true;
        break;
      }
      final v = double.tryParse(txt);
      if (v == null) {
        bad = true;
        break;
      }
      m[f.vars[i].key] = v;
    }
    if (bad) {
      setState(() => out = 'সব মান পূরণ করুন');
      return;
    }
    final r = f.compute(target, m);
    final tv = f.vars.firstWhere((v) => v.key == target);
    setState(() {
      out = r == null
          ? 'বের করা যাচ্ছে না'
          : '${tv.symbol} = ${novaFmt(r)} ${tv.unit}';
    });
    novaSaveHistory(category: 'physics', expr: '${f.expression} → ${tv.symbol}', result: r == null ? '' : '${novaFmt(r)} ${tv.unit}');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'ফিজিক্স ফর্মুলা',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: idx,
                isExpanded: true,
                dropdownColor: c.cardColor,
                style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                items: [for (int i = 0; i < NovaFormulas.length; i++) DropdownMenuItem(value: i, child: Text('${NovaFormulas[i].name}  (${NovaFormulas[i].expression})'))],
                onChanged: (v) {
                  if (v != null) _select(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('কী বের করবেন?', style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final v in f.vars)
              GestureDetector(
                onTap: () => setState(() => target = v.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: target == v.key ? c.primary : c.cardColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('${v.symbol} (${v.unit})', style: TextStyle(color: target == v.key ? Colors.black : c.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          for (int i = 0; i < f.vars.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: novaField(context,
                  controller: vals[i],
                  label: '${f.vars[i].name} (${f.vars[i].symbol}) — ${f.vars[i].unit}',
                  hint: 'মান লিখুন',
                  keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true)),
            ),
          GestureDetector(
            onTap: _solve,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.glow]), borderRadius: BorderRadius.circular(12)),
              child: Text('সমাধান', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          if (out != null) NovaOutput(text: out!),
        ]),
      ),
    ]);
  }
}

// ---------------- Chemistry ----------------

class ChemTab extends StatefulWidget {
  const ChemTab({super.key});
  @override
  State<ChemTab> createState() => _ChemTabState();
}

class _ChemTabState extends State<ChemTab> {
  final fT = TextEditingController();
  NovaChemResult? chem;
  String? chemErr;

  final massT = TextEditingController(text: '10');
  final volT = TextEditingController(text: '1');
  final mT = TextEditingController();
  String? solOut;

  void _analyze() {
    final r = NovaChem.molarMass(fT.text.trim());
    setState(() {
      chem = r;
      chemErr = r == null ? 'ফর্মুলা পার্স করা যায়নি (যেমন H2SO4, Ca(OH)2)' : null;
      if (r != null) mT.text = novaFmt(r.molarMass);
      novaSaveHistory(category: 'chem', expr: 'molar mass ${fT.text.trim()}', result: r == null ? '' : '${novaFmt(r.molarMass)} g/mol');
    });
  }

  void _solution() {
    final mG = double.tryParse(massT.text.trim());
    final volL = double.tryParse(volT.text.trim());
    final mm = double.tryParse(mT.text.trim());
    setState(() {
      if (mG == null || volL == null || mm == null || mm == 0) {
        solOut = 'ভর, আয়তন (L) ও মোলার ভর দিন';
      } else {
        final n = mG / mm;
        final M = n / volL;
        solOut = 'মোল n = ${novaFmt(n)} mol\nমোলারিটি M = ${novaFmt(M)} mol/L';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'রসায়ন — মোলার ভর',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          novaField(context, controller: fT, label: 'রাসায়নিক ফর্মুলা', hint: 'H2SO4, Ca(OH)2', style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _analyze,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.glow.withValues(alpha: 0.4))),
              child: Text('বিশ্লেষণ', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          if (chemErr != null)
            NovaOutput(text: chemErr!, error: true)
          else if (chem != null) ...[
            NovaOutput(text: 'মোলার ভর = ${novaFmt(chem!.molarMass)} g/mol'),
            const SizedBox(height: 10),
            for (final comp in chem!.comps)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text('${comp.symbol}${comp.count > 1 ? comp.count : ''}', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${novaFmt(comp.mass)} g', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600))),
                  Text('${novaFmt(comp.mass / chem!.molarMass * 100)}%', style: TextStyle(color: c.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(height: 4),
            Text('উপাদানের শতকরা রচনা এখানে', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      novaSection(
        context,
        'দ্রবণ / মোল',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          novaField(context, controller: massT, label: 'দ্রবের ভর (g)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 6),
          novaField(context, controller: volT, label: 'দ্রবণ আয়তন (L)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 6),
          novaField(context, controller: mT, label: 'মোলার ভর (g/mol)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _solution,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.glow.withValues(alpha: 0.4))),
              child: Text('মোল ও মোলারিটি', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          if (solOut != null) NovaOutput(text: solOut!),
        ]),
      ),
    ]);
  }
}

// ---------------- Units ----------------

class UnitsTab extends StatefulWidget {
  const UnitsTab({super.key});
  @override
  State<UnitsTab> createState() => _UnitsTabState();
}

class _UnitsTabState extends State<UnitsTab> {
  String dim = 'length';
  String from = 'm';
  String to = 'km';
  final valT = TextEditingController(text: '1');
  String? out;

  void _setDim(String d) {
    final us = NovaUnits.unitsForDimension(d);
    setState(() {
      dim = d;
      from = us.isNotEmpty ? us[0] : '';
      to = us.length > 1 ? us[1] : from;
    });
  }

  void _convert() {
    final v = double.tryParse(valT.text.trim());
    if (v == null || from.isEmpty || to.isEmpty) {
      setState(() => out = 'মান দিন');
      return;
    }
    final base = NovaUnits.toBase(from, v);
    final r = NovaUnits.fromBase(to, base);
    setState(() {
      out = '${novaFmt(v)} ${from} = ${novaFmt(r)} ${to}';
    });
    novaSaveHistory(category: 'unit', expr: '$v $from → $to', result: '${novaFmt(r)} $to');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final us = NovaUnits.unitsForDimension(dim);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      novaSection(
        context,
        'স্মার্ট ইউনিট সিস্টেম',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final d in NovaUnits.dimNames)
              GestureDetector(
                onTap: () => _setDim(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: dim == d ? c.primary : c.cardColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(d, style: TextStyle(color: dim == d ? Colors.black : c.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: novaField(context, controller: valT, label: 'মান', keyboard: const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height: 10),
          _unitDrop(c, 'থেকে', from, us, (v) => setState(() => from = v)),
          const SizedBox(height: 8),
          _unitDrop(c, 'তে', to, us, (v) => setState(() => to = v)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _convert,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.glow]), borderRadius: BorderRadius.circular(12)),
              child: Text('রূপান্তর', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          if (out != null) NovaOutput(text: out!),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.glow.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: Text('টিপ: মূল ক্যালকুলেটরেও চলে — যেমন “5 km + 300 m” বা “20 m_s -> km_h”।',
                style: TextStyle(color: c.textSecondary, fontSize: 11.5)),
          ),
        ]),
      ),
    ]);
  }

  Widget _unitDrop(AppColors c, String label, String val, List<String> options, ValueChanged<String> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            isExpanded: true,
            dropdownColor: c.cardColor,
            style: TextStyle(color: c.textPrimary, fontSize: 14),
            items: [for (final o in options) DropdownMenuItem(value: o, child: Text('$o (${NovaUnits.units[o]?.label ?? o})'))],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    ]);
  }
}