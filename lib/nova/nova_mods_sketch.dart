import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'nova_engine.dart';
import 'nova_widgets.dart';

class SimpleCalcTab extends StatefulWidget {
  const SimpleCalcTab({super.key});
  @override
  State<SimpleCalcTab> createState() => _SimpleCalcTabState();
}

class _SimpleCalcTabState extends State<SimpleCalcTab> {
  static const _pencils = [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFFFFF176),
    Color(0xFF81C784),
    Color(0xFF4FC3F7),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
    Color(0xFFF06292),
    Color(0xFF26A69A),
    Color(0xFF8D6E63),
  ];
  static const Color _ink = Color(0xFF33324A);

  String _expr = '';
  String? _result;
  String? _error;
  double? _ans;

  static const _numStart = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'};

  void _press(String s) {
    setState(() {
      if (_result != null) {
        if (_numStart.contains(s)) {
          _expr = s;
        } else if (_ans != null) {
          _expr = '${_ans!}$s';
        }
      } else {
        _expr += s;
      }
      _result = null;
      _error = null;
    });
  }

  void _clear() {
    setState(() {
      _expr = '';
      _result = null;
      _error = null;
      _ans = null;
    });
  }

  void _backspace() {
    setState(() {
      if (_expr.isEmpty) {
        _result = null;
        _error = null;
        _ans = null;
        return;
      }
      _expr = _expr.substring(0, _expr.length - 1);
      _result = null;
      _error = null;
    });
  }

  void _eval() {
    if (_expr.trim().isEmpty) return;
    final r = NovaEngine.evaluate(_expr, record: true);
    setState(() {
      if (r.ok) {
        _result = novaFmt(r.value!);
        _ans = r.value;
        _error = null;
        novaSaveHistory(
            category: 'calc',
            expr: _expr.trim(),
            result: _result!,
            unit: r.unit,
            steps: r.steps);
      } else {
        _result = null;
        _error = r.error ?? 'ভুল এক্সপ্রেশন';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _paper(context, c),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final t in [
              ('√ x² ! ^', _pencils[2]),
              ('% () sin cos', _pencils[4]),
              ('log ln π e', _pencils[5]),
            ])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: t.$2.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.$2.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      t.$1,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '✏️ স্কেচ আঁকা, কিন্তু ভিতরে পূর্ণ NOVA ইঞ্জিন — সব কাজই আসল গণিত',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: c.textSecondary.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _paper(BuildContext context, AppColors c) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HandRect(
          color: _ink,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E8),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tape(context),
                const SizedBox(height: 8),
                _display(c),
                const SizedBox(height: 12),
                _pad(c),
                const SizedBox(height: 10),
                _extras(c),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tape(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.rotate(
        angle: -0.06,
        child: Container(
          width: 120,
          height: 26,
          decoration: BoxDecoration(
            color: _pencils[3].withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _display(AppColors c) {
    return _HandRect(
      color: _pencils[5],
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _expr.isEmpty ? '· · ·' : _expr,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.55),
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: _pencils[0], fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else if (_result != null)
              Text(
                _result!,
                style: TextStyle(
                  color: _pencils[5],
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _pad(AppColors c) {
    final rows = <List<(String, _KeyKind, int)>>[
      [('C', _KeyKind.fn, 0), ('⌫', _KeyKind.fn, 1), ('(', _KeyKind.op, 2), (')', _KeyKind.op, 3), ('%', _KeyKind.op, 4)],
      [('7', _KeyKind.num, 0), ('8', _KeyKind.num, 1), ('9', _KeyKind.num, 2), ('÷', _KeyKind.op, 0)],
      [('4', _KeyKind.num, 3), ('5', _KeyKind.num, 4), ('6', _KeyKind.num, 5), ('×', _KeyKind.op, 1)],
      [('1', _KeyKind.num, 6), ('2', _KeyKind.num, 7), ('3', _KeyKind.num, 8), ('−', _KeyKind.op, 2)],
      [('0', _KeyKind.num, 9), ('.', _KeyKind.num, 0), ('=', _KeyKind.eq, 0), ('+', _KeyKind.op, 3)],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                for (final (label, kind, seed) in row)
                  Expanded(
                    flex: label == '0' ? 2 : 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _key(
                        label: label,
                        kind: kind,
                        seed: seed,
                        onTap: () {
                          switch (label) {
                            case 'C':
                              _clear();
                            case '⌫':
                              _backspace();
                            case '=':
                              _eval();
                            case '÷':
                              _press('/');
                            case '×':
                              _press('*');
                            case '−':
                              _press('-');
                            default:
                              _press(label);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _extras(AppColors c) {
    final list = <(String, String)>[
      ('xʸ', '^'),
      ('x²', '^2'),
      ('x³', '^3'),
      ('√', 'sqrt('),
      ('!', '!'),
      ('π', 'pi'),
      ('e', 'e'),
      ('sin(', 'sin('),
      ('cos(', 'cos('),
      ('tan(', 'tan('),
      ('log(', 'log('),
      ('ln(', 'ln('),
    ];
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      alignment: WrapAlignment.center,
      children: [
        for (final (i, (label, insert)) in list.indexed)
          _smallKey(
            label: label,
            color: _pencils[(i + 2) % _pencils.length],
            onTap: () => _press(insert),
          ),
      ],
    );
  }

  Color _colorFor(_KeyKind k, int seed) {
    switch (k) {
      case _KeyKind.fn:
        return _pencils[0];
      case _KeyKind.eq:
        return _pencils[3];
      case _KeyKind.op:
        return _pencils[5];
      case _KeyKind.num:
        return _pencils[seed % _pencils.length];
    }
  }

  Widget _key({
    required String label,
    required _KeyKind kind,
    required int seed,
    required VoidCallback onTap,
  }) {
    final color = _colorFor(kind, seed);
    return SizedBox(
      height: 62,
      child: Transform.rotate(
        angle: ((-1.2 + (seed % 5) * 0.6) * math.pi / 180),
        child: _HandRect(
          color: color,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kind == _KeyKind.eq
                      ? color.withValues(alpha: 0.92)
                      : color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: label.length <= 1 ? 22 : 16,
                    fontWeight: kind == _KeyKind.eq ? FontWeight.w900 : FontWeight.w800,
                    color: kind == _KeyKind.eq ? Colors.white : _ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallKey({required String label, required Color color, required VoidCallback onTap}) {
    return Transform.rotate(
      angle: ((math.sin(color.hashCode.toDouble()) * 1.4) * math.pi / 180).clamp(-0.03, 0.03),
      child: _HandRect(
        color: color,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                label,
                style: TextStyle(color: _ink, fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyKind { num, op, fn, eq }

class _HandRect extends StatelessWidget {
  final Color color;
  final Widget child;
  const _HandRect({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandRectPainter(color),
      child: child,
    );
  }
}

class _HandRectPainter extends CustomPainter {
  final Color color;
  _HandRectPainter(this.color);

  double _j(int i, double seed) => math.sin(seed * 7.31 + i * 2.7) * 1.15;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seed = color.hashCode * 0.013;
    final r = 14.0;

    List<Offset> pts = [
      Offset(r + _j(0, seed), 1 + _j(1, seed)),
      Offset(w / 2 + _j(2, seed), 1.5 + _j(3, seed)),
      Offset(w - r + _j(4, seed), 1 + _j(5, seed)),
      Offset(w - r + _j(6, seed), h / 2 + _j(7, seed)),
      Offset(w - r + _j(8, seed), h - r + _j(9, seed)),
      Offset(w / 2 + _j(10, seed), h - r + _j(11, seed)),
      Offset(r + _j(12, seed), h - r + _j(13, seed)),
      Offset(r + _j(14, seed), h / 2 + _j(15, seed)),
    ];

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..quadraticBezierTo(w - r + _j(16, seed), 2, pts[2].dx, pts[2].dy)
      ..quadraticBezierTo(w - 2, r + _j(17, seed), pts[3].dx, pts[3].dy)
      ..quadraticBezierTo(w - 2, h - r + _j(18, seed), pts[4].dx, pts[4].dy)
      ..quadraticBezierTo(pts[5].dx, h - 2, pts[5].dx, pts[5].dy)
      ..quadraticBezierTo(w / 2 + _j(19, seed), h - 2, pts[6].dx, pts[6].dy)
      ..quadraticBezierTo(2, h - r + _j(20, seed), pts[6].dx, pts[6].dy)
      ..lineTo(pts[7].dx, pts[7].dy)
      ..quadraticBezierTo(2, r + _j(21, seed), pts[0].dx, pts[0].dy)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path.shift(const Offset(1.15, 0.9)), paint..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _HandRectPainter oldDelegate) => oldDelegate.color != color;
}