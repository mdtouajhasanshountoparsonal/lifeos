import 'dart:math' as math;
import 'nova_units.dart';

const double e = 2.7182818284590452353602874713527;
const double pi = 3.1415926535897932384626433832795;

class NovaCalcResult {
  final double? value;
  final String? unit;
  final List<String> steps;
  final String? error;
  NovaCalcResult({this.value, this.unit, this.steps = const [], this.error});
  bool get ok => error == null && value != null;
}

String fmtNum(double v) {
  if (v.isNaN) return 'NaN';
  if (v.isInfinite) return v.isNegative ? '-∞' : '∞';
  if (v.abs() == 0) return '0';
  if (v.abs() >= 1e12 || v.abs() < 1e-8) {
    return v.toStringAsExponential(6).replaceFirst('e', 'e');
  }
  String s = v.toStringAsFixed(10);
  while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
    s = s.substring(0, s.length - 1);
  }
  if (s.length > 14) s = v.toStringAsExponential(6).replaceFirst('e', 'e');
  return s;
}

String fmtSmart(double v) {
  String s = fmtNum(v);
  if (s.contains('e')) return s;
  List<String> p = s.split('.');
  if (p.length == 2) {
    String intPart = p[0];
    StringBuffer b = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      var d = intPart[i];
      b.write(d);
      int fromRight = intPart.length - 1 - i;
      if (fromRight > 0 && fromRight % 3 == 0) b.write(',');
    }
    return '$b.${p[1]}';
  }
  return s;
}

enum Tok { num, iden, op, lp, rp, comma, sup2, sup3 }

const Set<String> _prefixFuncs = {
  'sqrt', 'cbrt', 'abs', 'exp', 'sin', 'cos', 'tan', 'ln', 'log', 'sinh',
  'cosh', 'tanh', 'ceil', 'floor', 'round', 'asin', 'acos', 'atan', 'sign',
  'deg', 'rad',
};

class Token {
  final Tok type;
  final double? num;
  final String? str;
  Token(this.type, {this.num, this.str});
}

class _Parser {
  final List<Token> tokens;
  int pos = 0;
  final Map<String, double> vars;
  final List<String> steps;
  final bool deg;
  final String? _exprForScope;

  _Parser(this.tokens, {required this.vars, required this.steps, required this.deg, String? expr})
      : _exprForScope = expr;

  Token? peek([int ahead = 0]) {
    int i = pos + ahead;
    return i < tokens.length ? tokens[i] : null;
  }

  Token next() => tokens[pos++];

  bool atEnd() => pos >= tokens.length;

  double parseExpr() {
    List<double> terms = [parseTerm()];
    List<String> ops = [];
    while (true) {
      Token? t = peek();
      if (t != null && t.type == Tok.op && (t.str == '+' || t.str == '-')) {
        ops.add(t.str!);
        next();
        terms.add(parseTerm());
      } else {
        break;
      }
    }
    double v = terms.first;
    for (int i = 0; i < ops.length; i++) {
      double before = v;
      v = ops[i] == '+' ? v + terms[i + 1] : v - terms[i + 1];
      steps.add('${ops[i]} → ${fmtSmart(before)} ${ops[i]} ${fmtSmart(terms[i + 1])} = ${fmtSmart(v)}');
    }
    return v;
  }

  double parseTerm() {
    double v = parseUnary();
    while (true) {
      Token? t = peek();
      if (t == null) break;
      if (t.type == Tok.op) {
        String op = t.str!;
        if (op == 'deg') {
          next();
          v = v * pi / 180;
          steps.add('° → ${fmtSmart(v)} rad');
          continue;
        }
        if (op == '*' || op == '/' || op == '%') {
          next();
          double rhs = parseUnary();
          double before = v;
          if (op == '*') {
            v = v * rhs;
            steps.add('× → ${fmtSmart(before)} × ${fmtSmart(rhs)} = ${fmtSmart(v)}');
          } else if (op == '/') {
            if (rhs == 0) throw Exception('Division by zero');
            v = v / rhs;
            steps.add('÷ → ${fmtSmart(before)} ÷ ${fmtSmart(rhs)} = ${fmtSmart(v)}');
          } else {
            v = v * rhs / 100;
            steps.add('% → $before% of ${fmtSmart(rhs)} = ${fmtSmart(v)}');
          }
        } else if (op == '^') {
          next();
          double expo = parseUnary();
          double before = v;
          v = math.pow(before, expo).toDouble();
          steps.add('^ → ${fmtSmart(before)}^${fmtSmart(expo)} = ${fmtSmart(v)}');
          continue;
        } else {
          break;
        }
      } else if (t.type == Tok.iden || t.type == Tok.lp || t.type == Tok.num) {
        // implicit multiplication: 2x, 2(3), (2)(3), x(2)
        double rhs = parseUnary();
        double before = v;
        v = v * rhs;
        steps.add('· → ${fmtSmart(before)} × ${fmtSmart(rhs)} = ${fmtSmart(v)}');
      } else {
        break;
      }
    }
    return v;
  }

  double parseUnary() {
    Token? t = peek();
    if (t != null && t.type == Tok.op && (t.str == '-' || t.str == '+')) {
      String s = next().str!;
      double v = parseUnary();
      return s == '-' ? -v : v;
    }
    return parsePower();
  }

  double parsePower() {
    Token? t = peek();
    if (t != null && t.type == Tok.op && t.str == '√') {
      next();
      double v = parseUnary();
      return math.sqrt(v);
    }
    if (t != null && t.type == Tok.op && t.str == '^') {
      // leading pow edge: treat ^ as invalid; just proceed
    }
    return parseAtom();
  }

  double parseAtom() {
    Token? t = peek();
    if (t == null) throw Exception('Unexpected end');
    if (t.type == Tok.lp) {
      next();
      double v = parseExpr();
      Token? close = next();
      if (close.type != Tok.rp) throw Exception('Missing )');
      return v;
    }
    if (t.type == Tok.num) {
      Token tk = next();
      return maybeApplySuffixAndFactorial(tk.num!);
    }
    if (t.type == Tok.iden) {
      Token tk = next();
      String name = tk.str!.toLowerCase();
      // function call
      Token? n = peek();
      if (n != null && n.type == Tok.lp) {
        if (name == 'min' || name == 'max' || name == 'hypot') {
          next(); // (
          List<double> args = [];
          while (true) {
            args.add(parseExpr());
            Token? p = peek();
            if (p != null && p.type == Tok.comma) {
              next();
            } else {
              break;
            }
          }
          Token? close = next();
          if (close.type != Tok.rp) throw Exception('Missing )');
          double r = switch (name) {
            'min' => args.reduce(math.min),
            'max' => args.reduce(math.max),
            _ => args.isEmpty ? 0 : args.reduce((a, b) => math.sqrt(a * a + b * b)),
          };
          steps.add('$name(...) = ${fmtSmart(r)}');
          return r;
        }
        next(); // (
        double arg = parseExpr();
        Token? close = next();
        if (close.type != Tok.rp) throw Exception('Missing )');
        if (name == 'pow') {
          // pow(x, y) handled below? we only grabbed one arg. Simplify: pow(a,b) unsupported; use a^b
          throw Exception('Use ^ for powers');
        }
        double r = applyFunction(name, arg);
        steps.add('$name(${fmtSmart(arg)}) = ${fmtSmart(r)}');
        return r;
      }
      // prefix unary function without parens: √25, sin30
      if (_prefixFuncs.contains(name)) {
        double arg = parseUnary();
        double r = applyFunction(name, arg);
        steps.add('$name(${fmtSmart(arg)}) = ${fmtSmart(r)}');
        return maybeApplySuffixAndFactorial(r);
      }
      // identity: constant, variable, or unit-like token (ignored as multiplier 1)
      if (name == 'ans') {
        return maybeApplySuffixAndFactorial(NovaEngine.lastAns);
      }
      if (name == 'x' && vars.containsKey('x')) {
        return maybeApplySuffixAndFactorial(vars['x']!);
      }
      if (vars.containsKey(name)) {
        return maybeApplySuffixAndFactorial(vars[name]!);
      }
      double? c = NovaEngine.constants[name];
      if (c != null) {
        steps.add('$name = ${fmtSmart(c)}');
        return maybeApplySuffixAndFactorial(c);
      }
      // unknown identifier -> treat as 1 (unit), but record
      if (_isUnitLike(name)) {
        return 1;
      }
      throw Exception('Unknown: $name');
    }
    throw Exception('Unexpected token');
  }

  bool _isUnitLike(String s) {
    return NovaUnits.units.containsKey(s.replaceAll('²', '').replaceAll('³', '')) ||
        NovaUnits.units.containsKey(s);
  }

  double maybeApplySuffixAndFactorial(double v) {
    // handle x² x³ superscripts and ! factorial trailing
    bool applied = false;
    while (true) {
      Token? t = peek();
      if (t != null && t.type == Tok.sup2) {
        next();
        v = v * v;
        applied = true;
      } else if (t != null && t.type == Tok.sup3) {
        next();
        v = v * v * v;
        applied = true;
      } else if (t != null && t.type == Tok.op && t.str == '!') {
        next();
        if (v < 0 || v != v.roundToDouble()) throw Exception('Factorial needs non-negative integer');
        double f = 1;
        for (int i = 2; i <= v.round(); i++) f *= i;
        v = f;
        applied = true;
      } else {
        break;
      }
    }
    if (applied) steps.add('= ${fmtSmart(v)}');
    return v;
  }

  double applyFunction(String name, double a) {
    switch (name) {
      case 'sin':
        return math.sin(degOrRad(a, 1));
      case 'cos':
        return math.cos(degOrRad(a, 1));
      case 'tan':
        return math.tan(degOrRad(a, 1));
      case 'asin':
        return degOrRad(math.asin(a), -1);
      case 'acos':
        return degOrRad(math.acos(a), -1);
      case 'atan':
        return degOrRad(math.atan(a), -1);
      case 'sinh':
        return (math.exp(a) - math.exp(-a)) / 2;
      case 'cosh':
        return (math.exp(a) + math.exp(-a)) / 2;
      case 'tanh':
        final ea = math.exp(a), ena = math.exp(-a);
        return (ea - ena) / (ea + ena);
      case 'log':
        return math.log(a) / math.ln10;
      case 'ln':
        return math.log(a);
      case 'sqrt':
        return math.sqrt(a);
      case 'cbrt':
        return a.sign * math.pow(a.abs(), 1 / 3).toDouble();
      case 'abs':
        return a.abs();
      case 'floor':
        return a.floorToDouble();
      case 'ceil':
        return a.ceilToDouble();
      case 'round':
        return a.roundToDouble();
      case 'exp':
        return math.exp(a);
      case 'sign':
        return a.isNegative ? -1 : (a > 0 ? 1 : 0);
      case 'deg':
        return a * 180 / pi;
      case 'rad':
        return a * pi / 180;
      default:
        throw Exception('Unknown function: $name');
    }
  }

  double degOrRad(double a, int mode) {
    // if explicit degree marks handled in tokenizer as 'deg' suffix? Simplify: mode from engine flag
    if ((mode == 1 && deg) || (mode == -1 && !deg)) return a * pi / 180;
    return a;
  }
}

/// Tokenizer supporting numbers, identifiers, operators, implicit superscripts, deg marks, °
List<Token> tokenize(String s) {
  List<Token> out = [];
  int i = 0;
  String norm = s
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('·', '*')
      .replaceAll('π', 'pi')
      .replaceAll('π', 'pi')
      .replaceAll('θ', 't')
      .replaceAll('°', 'deg')
      .replaceAll('²', 'S2')
      .replaceAll('³', 'S3')
      .replaceAll('^2', 'S2')
      .replaceAll('^3', 'S3')
      .replaceAll('√', ' sqrt ');
  while (i < norm.length) {
    String ch = norm[i];
    if (ch == ' ') { i++; continue; }
    if (_isDigit(ch) || ch == '.') {
      int j = i;
      bool dot = false;
      while (j < norm.length && (_isDigit(norm[j]) || norm[j] == '.')) {
        if (norm[j] == '.') dot = true;
        j++;
      }
      // scientific notation e12 or E-3 (only if followed by digits)
      if (j < norm.length && (norm[j] == 'e' || norm[j] == 'E')) {
        int k = j + 1;
        if (k < norm.length && (norm[k] == '+' || norm[k] == '-')) k++;
        if (k < norm.length && _isDigit(norm[k])) {
          int m = k;
          while (m < norm.length && _isDigit(norm[m])) m++;
          j = m;
        }
      }
      double v = double.tryParse(norm.substring(i, j)) ?? 0;
      out.add(Token(Tok.num, num: v));
      i = j;
      continue;
    }
    if (_isLetter(ch) || ch == '_') {
      int j = i;
      while (j < norm.length && (_isLetter(norm[j]) || norm[j] == '_' || _isDigit(norm[j]))) j++;
      String word = norm.substring(i, j);
      if (word == 'S2') { out.add(Token(Tok.sup2)); i = j; continue; }
      if (word == 'S3') { out.add(Token(Tok.sup3)); i = j; continue; }
      if (word == 'deg') { out.add(Token(Tok.op, str: 'deg')); i = j; continue; }
      out.add(Token(Tok.iden, str: word));
      i = j;
      continue;
    }
    switch (ch) {
      case '(': out.add(Token(Tok.lp)); i++; break;
      case ')': out.add(Token(Tok.rp)); i++; break;
      case ',': out.add(Token(Tok.comma)); i++; break;
      case '+':
      case '-':
      case '*':
      case '/':
      case '^':
      case '!':
      case '%':
        out.add(Token(Tok.op, str: ch)); i++; break;
      case '√': out.add(Token(Tok.op, str: '√')); i++; break;
      default:
        i++;
    }
  }
  // remove 'deg' op tokens and convert following number to radians? handled by parser via deg tracking.
  return out;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
bool _isLetter(String c) {
  int u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
}

class NovaEngine {
  static double lastAns = 0;
  static bool degMode = false;
  static const Map<String, double> constants = {
    'pi': pi,
    'e': e,
    'c': 299792458.0,
    'g': 9.80665,
    'h': 6.62607015e-34,
    'k': 1.380649e-23,
    'na': 6.02214076e23,
    'qe': 1.602176634e-19,
    'r': 8.314462618,
    'me': 9.1093837015e-31,
    'mp': 1.67262192369e-27,
    'au': 149597870700.0,
    'a0': 5.29177210903e-11,
    'mu0': 1.25663706212e-6,
    'eps0': 8.8541878128e-12,
    'sigma': 5.670374419e-8,
    'stdatm': 101325.0,
  };

  static NovaCalcResult evaluate(String expr, {double? x, Map<String, double>? vars, bool record = false}) {
    List<String> steps = [];
    try {
      String clean = expr.trim();
      if (clean.isEmpty) throw Exception('খালি এক্সপ্রেশন');
      // unit additive detection
      String? unitPrototype;
      NovaUnitSplit? us = NovaUnits.trySplitAdditive(clean);
      if (us != null) {
        double total = 0;
        for (final t in us.terms) {
          total += NovaUnits.toBase(t.unit, t.value);
        }
        String unitOut = us.terms.first.unit;
        double out = NovaUnits.fromBase(unitOut, total);
        steps.add('সকল পদকে ${NovaUnits.baseLabel(NovaUnits.dimensionOf(us.terms.first.unit))} এ রূপান্তর');
        for (final t in us.terms) {
          steps.add('${t.value} ${t.unit} → ${fmtSmart(NovaUnits.toBase(t.unit, t.value)).replaceFirst(RegExp(r'\.0$'), '')} ${t.unit}');
        }
        steps.add('সমষ্টি = ${fmtSmart(out)} $unitOut');
        NovaCalcResult r = NovaCalcResult(value: out, unit: unitOut, steps: steps);
        if (record) lastAns = out;
        return r;
      }
      // unit conversion
      NovaUnitConv? conv = NovaUnits.tryConvert(clean);
      if (conv != null) {
        double base = conv.fromUnit != null ? NovaUnits.toBase(conv.fromUnit!, conv.value) : conv.value;
        double out = conv.toUnit != null ? NovaUnits.fromBase(conv.toUnit!, base) : base;
        steps.add('${conv.value} ${conv.fromUnit} → ${fmtSmart(base)} (base) → ${fmtSmart(out)} ${conv.toUnit}');
        NovaCalcResult r = NovaCalcResult(value: out, unit: conv.toUnit, steps: steps);
        if (record) lastAns = out;
        return r;
      }
      // plain numeric expression
      List<Token> toks = tokenize(clean);
      if (toks.isEmpty) throw Exception('ভুল ইনপুট');
      Map<String, double> ctxVars = {...?vars};
      if (x != null) ctxVars['x'] = x;
      _Parser p = _Parser(toks, vars: ctxVars, steps: steps, deg: degMode);
      double v = p.parseExpr();
      if (!p.atEnd()) throw Exception('ভুল এক্সপ্রেশন');
      NovaCalcResult r = NovaCalcResult(value: v, steps: steps, unit: unitPrototype);
      if (record) lastAns = v;
      return r;
    } catch (err) {
      return NovaCalcResult(error: err.toString().replaceFirst('Exception: ', ''));
    }
  }
}