import 'dart:math' as math;
import 'nova_engine.dart';

class NovaSolveResult {
  final List<String> steps;
  final List<(double, String)> roots; // (real, imag) pairs
  final String expression;
  final String category;
  bool get ok => roots.isNotEmpty;
  NovaSolveResult(this.steps, this.roots, this.expression, this.category);
}

class NovaMath {
  /// Solve linear ax+b=c or polynomial in x with degree <= 2 from full string "2x+5=17" / "x^2-5x+6=0"
  static NovaSolveResult solveEquation(String expr) {
    String E = expr.replaceAll(' ', '').replaceAll('=', '=');
    List<String> steps = [];
    double rhs = 0;
    String lhs = E;
    if (E.contains('=')) {
      List<String> parts = E.split('=');
      if (parts.length != 2) {
        return NovaSolveResult(['= চিহ্নের দুই পাশ ঠিক নেই'], [], E, 'equ');
      }
      lhs = parts[0];
      double r = double.tryParse(parts[1]) ?? _evalNum(parts[1]);
      if (r.isNaN) {
        NovaCalcResult er = NovaEngine.evaluate(parts[1]);
        if (!er.ok) return NovaSolveResult(['RHS বোঝা যায়নি: ${parts[1]}'], [], E, 'equ');
        r = er.value!;
      }
      rhs = r;
    }
    lhs = _normalize(lhs);
    if (!lhs.contains('x') && !lhs.contains('X')) {
      return NovaSolveResult(['x পাওয়া যায়নি'], [], E, 'equ');
    }
    // collect coefficients
    List<double> coefs = _polyCoeffs(lhs);
    // move rhs: c0 -= rhs
    coefs[0] = coefs[0] - rhs;
    steps.add('$E');
    double a = coefs.length > 2 ? coefs[2] : 0;
    double b = coefs.length > 1 ? coefs[1] : 0;
    double c = coefs[0];
    if (a.abs() < 1e-12) {
      // linear
      if (b.abs() < 1e-12) {
        return NovaSolveResult([...steps, 'দুই পাশকে একত্রিত করে কোনো চলক নেই'], [], E, 'equ');
      }
      double x = -c / b;
      steps.add('${fmtSmart(b)}x ${c >= 0 ? '+ ' : '- '}${fmtSmart(c.abs())} = 0');
      steps.add('x = ${fmtSmart(-c)} ÷ ${fmtSmart(b)}');
      steps.add('x = ${fmtSmart(x)}');
      return NovaSolveResult(steps, [(x, '0')], E, 'linear');
    }
    double d = b * b - 4 * a * c;
    steps.add('${_fmtPoly(coefs)} = 0');
    steps.add('a = ${fmtSmart(a)}, b = ${fmtSmart(b)}, c = ${fmtSmart(c)}');
    steps.add('নিরূপক D = b² − 4ac = ${fmtSmart(d)}');
    if (d < -1e-12) {
      double rd = math.sqrt(-d);
      double re = -b / (2 * a);
      double im = rd / (2 * a);
      steps.add('D < 0 → জটিল মূল');
      steps.add('x₁ = ${fmtSmart(re)} + ${fmtSmart(im)}i');
      steps.add('x₂ = ${fmtSmart(re)} − ${fmtSmart(im)}i');
      return NovaSolveResult(steps, [(re, '${fmtSmart(im)}'), (re, '−${fmtSmart(im)}')], E, 'quadratic');
    }
    double s = math.sqrt(d);
    double x1 = (-b + s) / (2 * a);
    double x2 = (-b - s) / (2 * a);
    steps.add('x = (−b ± √D) ÷ 2a');
    steps.add('x₁ = ${fmtSmart(x1)}');
    steps.add('x₂ = ${fmtSmart(x2)}');
    return NovaSolveResult(steps, [(x1, '0'), (x2, '0')], E, 'quadratic');
  }

  static double _evalNum(String s) {
    NovaCalcResult r = NovaEngine.evaluate(s);
    return r.ok ? r.value! : double.nan;
  }

  static String _normalize(String s) => s.toLowerCase().replaceAll(' ', '');

  /// returns [c0, c1, c2, ...] for polynomial a0 + a1 x + a2 x² + ...
  static List<double> _polyCoeffs(String s) {
    List<double> coefs = [0, 0, 0];
    if (!s.contains('x')) return [double.tryParse(s) ?? 0, 0, 0];
    String expr = s
        .replaceAll('^2', 'S2')
        .replaceAll('²', 'S2')
        .replaceAll('^3', 'S3')
        .replaceAll('³', 'S3')
        .replaceAll('*', '');
    List<String> bodyParts = <String>[];
    int start = 0;
    for (int i = 1; i < expr.length; i++) {
      if (expr[i] == '+' || expr[i] == '-') {
        bodyParts.add(expr.substring(start, i));
        start = i;
      }
    }
    bodyParts.add(expr.substring(start));
    for (final raw in bodyParts) {
      if (raw.trim().isEmpty) continue;
      String t = raw;
      double sign = 1;
      if (t.startsWith('-')) {
        sign = -1;
        t = t.substring(1);
      } else if (t.startsWith('+')) {
        t = t.substring(1);
      }
      int power = 0;
      if (t.contains('S3')) {
        power = 3;
        t = t.replaceAll('S3', '');
      } else if (t.contains('S2')) {
        power = 2;
        t = t.replaceAll('S2', '');
      } else if (t.contains('x')) {
        power = 1;
      }
      t = t.replaceAll('x', '');
      double val = t.isEmpty ? 1 : (double.tryParse(t) ?? 0);
      while (coefs.length <= power) coefs.add(0);
      coefs[power] += sign * val;
    }
    return coefs;
  }

  static String _fmtPoly(List<double> coefs) {
    List<String> parts = [];
    for (int i = coefs.length - 1; i >= 0; i--) {
      double v = coefs[i];
      if (v.abs() < 1e-12) continue;
      String vpart = i == 0 ? '' : (i == 1 ? 'x' : (i == 2 ? 'x²' : (i == 3 ? 'x³' : 'x^$i')));
      double a = v.abs();
      String coefS = (i >= 1 && a == 1) ? '' : fmtSmart(a);
      parts.add(v < 0 ? '-$coefS$vpart' : '$coefS$vpart');
    }
    return parts.isEmpty ? '0' : parts.join(' + ').replaceAll(' + -', ' − ');
  }

  // ---------- Calculational ----------

  static double at(double Function(double) f, double x) => f(x);

  static double centralDiff(double Function(double) f, double x, {double h = 1e-5}) {
    return (f(x + h) - f(x - h)) / (2 * h);
  }

  static double simpson(double Function(double) f, double a, double b, {int n = 2000}) {
    if (n % 2 != 0) n++;
    double h = (b - a) / n;
    double s = f(a) + f(b);
    for (int i = 1; i < n; i++) {
      s += (i % 2 == 0 ? 2 : 4) * f(a + i * h);
    }
    return s * h / 3;
  }

  /// symbolic derivative for polynomial expr of x → string
  static String symbolicDerivative(String expr) {
    String s = expr.toLowerCase().replaceAll(' ', '');
    if (!s.contains('x')) {
      NovaCalcResult r = NovaEngine.evaluate(s);
      return r.ok ? '0' : '??';
    }
    s = s.replaceAll('^2', 'S2').replaceAll('²', 'S2').replaceAll('^3', 'S3').replaceAll('³', 'S3');
    List<String> out = [];
    for (final raw in RegExp(r'[+-]?[^+-]+').allMatches(s)) {
      String t = raw.group(0)!.trim();
      if (t.isEmpty) continue;
      double sign = t.startsWith('-') ? -1 : 1;
      String body = t.replaceFirst(RegExp(r'^[+-]'), '');
      body = body.replaceAll('*', '');
      int power = 0;
      if (body.contains('S3')) {
        power = 3;
        body = body.replaceAll('S3', '').replaceAll('x', '');
      } else if (body.contains('S2')) {
        power = 2;
        body = body.replaceAll('S2', '').replaceAll('x', '');
      } else if (body.contains('x')) {
        power = 1;
        body = body.replaceAll('x', '');
      }
      double coef = body.isEmpty ? 1 : (double.tryParse(body) ?? 0);
      coef *= sign;
      if (power == 0) continue; // constant → derivative 0
      double ncoef = coef * power;
      int npower = power - 1;
      if (ncoef.abs() < 1e-12) continue;
      String c = (ncoef == 1 && npower >= 1) ? '' : (ncoef == -1 && npower >= 1 ? '−' : fmtSmart(ncoef));
      String xp = npower == 0 ? '' : (npower == 1 ? 'x' : 'x$npower'.replaceAll('x2', 'x²').replaceAll('x3', 'x³'));
      out.add('$c$xp');
    }
    if (out.isEmpty) return '0';
    StringBuffer b = StringBuffer();
    for (int i = 0; i < out.length; i++) {
      String term = out[i];
      bool isNeg = term.startsWith('−');
      if (i > 0 && !isNeg) b.write(' + ');
      b.write(term);
    }
    String res = b.toString();
    res = res.replaceAll('−', '-');
    return res.isEmpty ? '0' : res;
  }

  // ---------- Matrix ----------

  static double det3(List<List<double>> m) {
    return m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
        m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
        m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  }

  static double det2(List<List<double>> m) => m[0][0] * m[1][1] - m[0][1] * m[1][0];

  static double det(List<List<double>> m) {
    int n = m.length;
    if (n == 0) return 0;
    if (n == 1) return m[0][0];
    if (n == 2) return det2(m);
    if (n == 3) return det3(m);
    // general cofactor
    double s = 0;
    for (int j = 0; j < n; j++) {
      s += m[0][j] * cofactor(m, 0, j);
    }
    return s;
  }

  static double cofactor(List<List<double>> m, int r, int c) {
    List<List<double>> sub = [];
    for (int i = 0; i < m.length; i++) {
      if (i == r) continue;
      List<double> row = [];
      for (int j = 0; j < m.length; j++) {
        if (j == c) continue;
        row.add(m[i][j]);
      }
      sub.add(row);
    }
    return (r + c) % 2 == 0 ? det(sub) : -det(sub);
  }

  static List<List<double>> transpose(List<List<double>> m) {
    int n = m.length;
    List<List<double>> r = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        r[j][i] = m[i][j];
      }
    }
    return r;
  }

  static List<List<double>>? inverse(List<List<double>> m) {
    double d = det(m);
    if (d.abs() < 1e-12) return null;
    int n = m.length;
    List<List<double>> adj = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        adj[j][i] = cofactor(m, i, j);
      }
    }
    return List.generate(n, (i) => List.generate(n, (j) => adj[i][j] / d));
  }

  static int rank(List<List<double>> m) {
    int n = m.length;
    List<List<double>> a = [for (var r in m) List.of(r)];
    int rank = 0;
    for (int col = 0; col < n && rank < n; col++) {
      int pivot = -1;
      for (int r = rank; r < n; r++) {
        if (a[r][col].abs() > 1e-9) {
          pivot = r;
          break;
        }
      }
      if (pivot == -1) continue;
      var tmp = a[rank];
      a[rank] = a[pivot];
      a[pivot] = tmp;
      double pv = a[rank][col];
      for (int j = 0; j < n; j++) {
        a[rank][j] /= pv;
      }
      for (int r = 0; r < n; r++) {
        if (r != rank && a[r][col].abs() > 1e-12) {
          double f = a[r][col];
          for (int j = 0; j < n; j++) {
            a[r][j] -= f * a[rank][j];
          }
        }
      }
      rank++;
    }
    return rank;
  }

  static List<List<double>> multiply(List<List<double>> a, List<List<double>> b) {
    int n = a.length;
    List<List<double>> r = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        double s = 0;
        for (int k = 0; k < n; k++) {
          s += a[i][k] * b[k][j];
        }
        r[i][j] = s;
      }
    }
    return r;
  }

  /// symmetric 2x2 eigenvalues + unit eigenvectors
  static List<Map<String, dynamic>> eigen2x2(List<List<double>> m) {
    double a = m[0][0], b = m[0][1], c = m[1][0], d = m[1][1];
    if ((b - c).abs() > 1e-9) {
      // general 2x2 through characteristic
      double tr = a + d;
      double detv = a * d - b * c;
      double disc = tr * tr - 4 * detv;
      if (disc < 0) return [];
      double sq = math.sqrt(disc);
      double l1 = (tr + sq) / 2;
      double l2 = (tr - sq) / 2;
      return [
        {'lam': l1, 'vec': _eigvec2(a, b, c, d, l1)},
        {'lam': l2, 'vec': _eigvec2(a, b, c, d, l2)},
      ];
    }
    // symmetric
    double l1 = a + b;
    double l2 = a - b;
    return [
      {'lam': l1, 'vec': [1.0, 1.0]},
      {'lam': l2, 'vec': [-1.0, 1.0]},
    ];
  }

  static List<double> _eigvec2(double a, double b, double c, double d, double lamb) {
    if ((a - lamb).abs() > 1e-9 || b.abs() > 1e-9) {
      List<double> v = [-(b), (a - lamb)];
      return (v[1].abs() > 1e-12) ? v : [1.0, 0.0];
    }
    return [1.0, 0.0];
  }

  // ---------- Vectors ----------

  static double dot(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < math.min(a.length, b.length); i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  static List<double> cross3(List<double> a, List<double> b) {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0],
    ];
  }

  static double norm3(List<double> a) => math.sqrt(dot(a, a));

  // ---------- Statistics ----------

  static List<double>? parseData(String s) {
    List<double> out = [];
    for (final m in RegExp(r'[-+]?[\d.]+').allMatches(s)) {
      double? v = double.tryParse(m.group(0)!);
      if (v != null) out.add(v);
    }
    return out.isEmpty ? null : out;
  }

  static Map<String, dynamic> stats(List<double> data) {
    List<double> d = List.of(data)..sort();
    double sum = d.fold(0, (a, b) => a + b);
    int n = d.length;
    double mean = sum / n;
    double variance = d.map((xx) => (xx - mean) * (xx - mean)).fold<double>(0, (a, b) => a + b) / n;
    // mode
    Map<double, int> f = {};
    for (final x in d) {
      f[x] = (f[x] ?? 0) + 1;
    }
    double? mode;
    int mx = 0;
    f.forEach((k, v) {
      if (v > mx) {
        mx = v;
        mode = k;
      }
    });
    double median = n % 2 == 1 ? d[n ~/ 2] : (d[n ~/ 2 - 1] + d[n ~/ 2]) / 2;
    double q1 = _quart(d, 0.25);
    double q3 = _quart(d, 0.75);
    double iqr = q3 - q1;
    List<double> bins = [];
    int nbins = math.min(10, math.max(4, (n / 5).round()));
    if (nbins > 0 && d.last > d.first) {
      double step = (d.last - d.first) / nbins;
      for (int i = 0; i < nbins; i++) {
        bins.add(0);
      }
      for (final x in d) {
        int idx = ((x - d.first) / step).floor().clamp(0, nbins - 1);
        bins[idx] = bins[idx] + 1;
      }
    }
    return {
      'n': n,
      'sum': sum,
      'mean': mean,
      'median': median,
      'mode': mode,
      'var': variance,
      'std': math.sqrt(variance),
      'min': d.first,
      'max': d.last,
      'range': d.last - d.first,
      'q1': q1,
      'q3': q3,
      'iqr': iqr,
      'bins': bins,
      'sorted': d,
    };
  }

  static double _quart(List<double> d, double p) {
    int n = d.length;
    double pos = p * (n - 1);
    int lo = pos.floor();
    int hi = pos.ceil();
    double frac = pos - lo;
    return d[lo] + (d[hi] - d[lo]) * frac;
  }
}