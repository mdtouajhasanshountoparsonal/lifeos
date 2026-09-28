import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_math.dart';
import 'nova_widgets.dart';

class CalcTab extends StatefulWidget {
  const CalcTab({super.key});
  @override
  State<CalcTab> createState() => _CalcTabState();
}

class _CalcTabState extends State<CalcTab> {
  final expr = TextEditingController();
  final solver = TextEditingController();
  NovaCalcResult? res;
  NovaSolveResult? sol;
  bool deg = NovaEngine.degMode;

  static const _funcs = ['sin', 'cos', 'tan', 'log', 'ln', '√', '^', '!', '(', ')'];
  static const _consts = [('π', 'pi'), ('e', 'e'), ('c', 'c'), ('g', 'g'), ('h', 'h'), ('Nₐ', 'na'), ('qₑ', 'qe'), ('R', 'r')];

  void _insert(String s) {
    expr.text = expr.text + s;
    expr.selection = TextSelection.collapsed(offset: expr.text.length);
    res = null;
    setState(() {});
  }

  void _eval() {
    setState(() {
      res = NovaEngine.evaluate(expr.text, record: true);
      if (res!.ok) {
        novaSaveHistory(
            category: 'calc',
            expr: expr.text.trim(),
            result: novaFmt(res!.value!),
            unit: res!.unit,
            steps: res!.steps);
      }
    });
  }

  void _solve() {
    setState(() {
      sol = NovaMath.solveEquation(solver.text);
      if (sol!.ok) {
        final rootsTxt = sol!.roots.map((r) => 'x = ${novaFmt(r.$1)}${r.$2 != '0' ? r.$2 : ''}').join(', ');
        novaSaveHistory(category: sol!.category, expr: solver.text.trim(), result: rootsTxt, steps: sol!.steps);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        novaSection(
          context,
          'মূল ক্যালকুলেটর',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            novaField(context,
                controller: expr,
                label: 'এক্সপ্রেশন',
                hint: 'sin(45°) + log(100) × √25',
                style: const TextStyle(fontSize: 19)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _chip(c, 'DEG', () {
                setState(() {
                  deg = true;
                  NovaEngine.degMode = true;
                });
              }, selected: deg),
              _chip(c, 'RAD', () {
                setState(() {
                  deg = false;
                  NovaEngine.degMode = false;
                });
              }, selected: !deg),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final f in _funcs)
                  _pill(c, f, () {
                    String s;
                    switch (f) {
                      case '√':
                        s = 'sqrt(';
                        break;
                      case '^':
                        s = '^';
                        break;
                      case '√s':
                        s = '';
                        break;
                      default:
                        s = '$f(';
                    }
                    _insert(s);
                  }),
                for (final k in _consts) _pill(c, k.$1, () => _insert(k.$2)),
              ]),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _eval,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c.primary, c.glow]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: c.glow.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Text('=  হিসাব', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            if (res != null)
              NovaOutput(
                text: res!.ok ? novaFmt(res!.value!) : (res!.error ?? ''),
                unit: res!.ok ? res!.unit : null,
                error: !res!.ok,
                steps: res!.steps,
                onSave: () {
                  novaSaveHistory(category: 'calc', expr: expr.text.trim(), result: novaFmt(res!.value!), unit: res!.unit, steps: res!.steps);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ইতিহাসে সংরক্ষিত হয়েছে')));
                },
              ),
          ]),
        ),
        const SizedBox(height: 14),
        novaSection(
          context,
          'সমীকরণ সমাধান',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            novaField(context,
                controller: solver,
                label: 'লিখুন: 2x+5=17 বা x²−5x+6=0',
                hint: '2x+5=17',
                style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _solve,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.glow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.glow.withValues(alpha: 0.4)),
                ),
                child: Text('সমাধান করুন', style: TextStyle(color: c.primary, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            if (sol != null) ...[
              if (!sol!.ok)
                NovaOutput(text: sol!.steps.isNotEmpty ? sol!.steps.first : 'সমাধান ব্যর্থ', error: true)
              else ...[
                for (final r in sol!.roots)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('x = ${novaFmt(r.$1)}${r.$2 != '0' ? ' + ${r.$2}' : ''}',
                          style: TextStyle(color: c.textPrimary, fontSize: 21, fontWeight: FontWeight.w800))),
                    ]),
                  ),
                if (sol!.steps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final s in sol!.steps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.textSecondary, shape: BoxShape.circle))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s, style: TextStyle(color: c.textPrimary.withValues(alpha: 0.85), fontSize: 12.5))),
                      ]),
                    ),
                ],
                Row(children: [
                  _actionChipWidget(context, Icons.history, 'ইতিহাসে', () {
                    novaSaveHistory(
                        category: sol!.category,
                        expr: solver.text.trim(),
                        result: sol!.roots.map((r) => '${novaFmt(r.$1)}${r.$2 != '0' ? r.$2 : ''}').join(', '),
                        steps: sol!.steps);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ইতিহাসে সংরক্ষিত হয়েছে')));
                  }),
                  const SizedBox(width: 8),
                  _actionChipWidget(context, Icons.note_add_outlined, 'নোটে', () => _saveEqToNotes()),
                ]),
              ],
            ],
          ]),
        ),
      ],
    );
  }

  void _saveEqToNotes() {
    final b = StringBuffer();
    b.writeln('# সমীকরণ সমাধান');
    b.writeln('**Equations:**');
    b.writeln(solver.text.trim());
    b.writeln('');
    for (final r in sol!.roots) {
      b.writeln('x = ${novaFmt(r.$1)}${r.$2 != '0' ? ' ${r.$2}' : ''}');
    }
    b.writeln('');
    b.writeln('**Steps:**');
    for (final s in sol!.steps) {
      b.writeln('- $s');
    }
    novaSaveToNotes(title: 'NOVA • সমীকরণ', content: b.toString());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নোটে যোগ হয়েছে')));
  }

  Widget _chip(AppColors c, String t, VoidCallback onTap, {bool selected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.cardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: TextStyle(color: selected ? Colors.black : c.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _pill(AppColors c, String t, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.primary.withValues(alpha: 0.35))),
          child: Text(t, style: TextStyle(color: c.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

Widget _actionChipWidget(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  final c = AppTheme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.glow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.glow.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: c.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}