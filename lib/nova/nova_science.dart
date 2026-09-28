import 'dart:math' as math;

class NovaConstEntry {
  final String glyph;
  final String expr;
  final double value;
  final String unit;
  final String name;
  const NovaConstEntry(this.glyph, this.expr, this.value, this.unit, this.name);
}

const List<NovaConstEntry> NovaConstants = [
  NovaConstEntry('π', 'pi', 3.141592653589793, '', 'Pi (বৃত্তের পরিধি/ব্যাস)'),
  NovaConstEntry('e', 'e', 2.718281828459045, '', 'Euler সংখ্যা'),
  NovaConstEntry('c', 'c', 299792458.0, 'm/s', 'আলোর বেগ'),
  NovaConstEntry('g', 'g', 9.80665, 'm/s²', 'মাধ্যাকর্ষণ ত্বরণ'),
  NovaConstEntry('h', 'h', 6.62607015e-34, 'J·s', 'প্ল্যাংক ধ্রুবক'),
  NovaConstEntry('k', 'k', 1.380649e-23, 'J/K', 'বোল্টজমান ধ্রুবক'),
  NovaConstEntry('Nₐ', 'na', 6.02214076e23, '/mol', 'অ্যাভোগাড্রো সংখ্যা'),
  NovaConstEntry('qₑ', 'qe', 1.602176634e-19, 'C', 'ইলেকট্রনের চার্জ'),
  NovaConstEntry('R', 'r', 8.314462618, 'J/(mol·K)', 'গ্যাস ধ্রুবক'),
  NovaConstEntry('mₑ', 'me', 9.1093837015e-31, 'kg', 'ইলেকট্রন ভর'),
  NovaConstEntry('mₚ', 'mp', 1.67262192369e-27, 'kg', 'প্রোটন ভর'),
  NovaConstEntry('AU', 'au', 149597870700.0, 'm', 'জ্যোতির্বৈজ্ঞানিক একক'),
  NovaConstEntry('a₀', 'a0', 5.29177210903e-11, 'm', 'বোর ব্যাসার্ধ'),
  NovaConstEntry('μ₀', 'mu0', 1.25663706212e-6, 'N/A²', 'শূন্যতার ব্যাপ্তিযোগ্যতা'),
  NovaConstEntry('ε₀', 'eps0', 8.8541878128e-12, 'F/m', 'শূন্যতার তড়িৎভেদ্যতা'),
  NovaConstEntry('σ', 'sigma', 5.670374419e-8, 'W/m²K⁴', 'স্টেফান-বোল্টজমান ধ্রুবক'),
  NovaConstEntry('1 atm', 'stdatm', 101325.0, 'Pa', 'সাধারণ বায়ুচাপ'),
];

// ---------- Chemistry ----------

class NovaChemComposition {
  final String symbol;
  final int count;
  final double mass;
  NovaChemComposition(this.symbol, this.count, this.mass);
}

class NovaChemResult {
  final double molarMass;
  final List<NovaChemComposition> comps;
  final String formula;
  NovaChemResult(this.molarMass, this.comps, this.formula);
}

class NovaChem {
  static const Map<String, double> masses = {
    'H': 1.008, 'He': 4.0026, 'Li': 6.94, 'Be': 9.0122, 'B': 10.81,
    'C': 12.011, 'N': 14.007, 'O': 15.999, 'F': 18.998, 'Ne': 20.18,
    'Na': 22.99, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.085, 'P': 30.974,
    'S': 32.06, 'Cl': 35.45, 'Ar': 39.948, 'K': 39.098, 'Ca': 40.078,
    'Ti': 47.867, 'Cr': 51.996, 'Mn': 54.938, 'Fe': 55.845, 'Co': 58.933,
    'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38, 'Br': 79.904, 'Ag': 107.87,
    'Sn': 118.71, 'I': 126.9, 'Ba': 137.33, 'Au': 196.97, 'Hg': 200.59,
    'Pb': 207.2, 'U': 238.03,
  };

  static NovaChemResult? molarMass(String formula) {
    String s = formula.replaceAll(' ', '');
    if (s.isEmpty) return null;
    List<(String, int)> parts = _parseGroup(s, 0).$1;
    if (parts.isEmpty) return null;
    // merge
    Map<String, int> merged = {};
    for (final p in parts) {
      merged[p.$1] = (merged[p.$1] ?? 0) + p.$2;
    }
    if (merged.isEmpty) return null;
    List<NovaChemComposition> comps = [];
    double total = 0;
    for (final e in merged.entries) {
      if (!masses.containsKey(e.key)) return null;
      double m = masses[e.key]! * e.value;
      total += m;
      comps.add(NovaChemComposition(e.key, e.value, m));
    }
    return NovaChemResult(total, comps, formula);
  }

  static (List<(String, int)>, int) _parseGroup(String s, int i) {
    List<(String, int)> out = [];
    while (i < s.length) {
      String ch = s[i];
      if (ch == '(') {
        var inner = _parseGroup(s, i + 1);
        List<(String, int)> groupParts = inner.$1;
        int j = inner.$2;
        var cnt = _readInt(s, j);
        int mult = cnt.$2;
        i = cnt.$3;
        for (final p in groupParts) {
          out.add((p.$1, p.$2 * mult));
        }
      } else if (ch == ')') {
        return (out, i + 1);
      } else if (_isUpper(ch)) {
        String el = ch;
        if (i + 1 < s.length && _isLower(s[i + 1])) {
          el += s[i + 1];
          i += 2;
        } else {
          i += 1;
        }
        var cnt = _readInt(s, i);
        out.add((el, cnt.$2));
        i = cnt.$3;
      } else {
        i++;
      }
    }
    return (out, i);
  }

  static bool _isUpper(String c) => c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90;
  static bool _isLower(String c) => c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122;
  static bool _isD(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  static (bool, int, int) _readInt(String s, int i) {
    int count = 0;
    int j = i;
    while (j < s.length && _isD(s[j])) {
      count = count * 10 + (s[j].codeUnitAt(0) - 48);
      j++;
    }
    return (j > i, count == 0 ? 1 : count, j);
  }
}

// ---------- Physics formulas ----------

class NovaPhysVar {
  final String key;
  final String symbol;
  final String unit;
  final String name;
  const NovaPhysVar(this.key, this.symbol, this.unit, this.name);
}

class NovaPhysFormula {
  final String id;
  final String name;
  final String expression;
  final List<NovaPhysVar> vars;
  const NovaPhysFormula(this.id, this.name, this.expression, this.vars);

  double? compute(String target, Map<String, double> vals) {
    double g(String k) => vals[k] ?? double.nan;
    switch (id) {
      case 'fma':
        if (target == 'F') return g('m') * g('a');
        if (target == 'm') return g('F') / g('a');
        if (target == 'a') return g('F') / g('m');
        return null;
      case 'vuat':
        if (target == 'v') return g('u') + g('a') * g('t');
        if (target == 'u') return g('v') - g('a') * g('t');
        if (target == 'a') return (g('v') - g('u')) / g('t');
        if (target == 't') return (g('v') - g('u')) / g('a');
        return null;
      case 'work':
        if (target == 'W') return g('F') * g('d');
        if (target == 'F') return g('W') / g('d');
        if (target == 'd') return g('W') / g('F');
        return null;
      case 'ke':
        if (target == 'KE') return 0.5 * g('m') * g('v') * g('v');
        if (target == 'm') return g('KE') * 2 / (g('v') * g('v'));
        if (target == 'v') return math.sqrt(2 * g('KE') / g('m'));
        return null;
      case 'pe':
        if (target == 'PE') return g('g') * g('m') * g('h');
        if (target == 'm') return g('PE') / (g('g') * g('h'));
        if (target == 'h') return g('PE') / (g('g') * g('m'));
        if (target == 'g') return g('PE') / (g('m') * g('h'));
        return null;
      case 'power':
        if (target == 'P') return g('W') / g('t');
        if (target == 'W') return g('P') * g('t');
        if (target == 't') return g('W') / g('P');
        return null;
      case 'ohm':
        if (target == 'V') return g('I') * g('R');
        if (target == 'I') return g('V') / g('R');
        if (target == 'R') return g('V') / g('I');
        return null;
      case 'epower':
        if (target == 'P') return g('V') * g('I');
        if (target == 'V') return g('P') / g('I');
        if (target == 'I') return g('P') / g('V');
        return null;
      case 'momentum':
        if (target == 'p') return g('m') * g('v');
        if (target == 'm') return g('p') / g('v');
        if (target == 'v') return g('p') / g('m');
        return null;
      case 'wave':
        if (target == 'v') return g('f') * g('l');
        if (target == 'f') return g('v') / g('l');
        if (target == 'l') return g('v') / g('f');
        return null;
      case 'period':
        if (target == 'T') return 1 / g('f');
        if (target == 'f') return 1 / g('T');
        return null;
      case 'pressure':
        if (target == 'P') return g('F') / g('A');
        if (target == 'F') return g('P') * g('A');
        if (target == 'A') return g('F') / g('P');
        return null;
      case 'density':
        if (target == 'ρ') return g('m') / g('V');
        if (target == 'm') return g('ρ') * g('V');
        if (target == 'V') return g('m') / g('ρ');
        return null;
      case 'speed':
        if (target == 'v') return g('d') / g('t');
        if (target == 'd') return g('v') * g('t');
        if (target == 't') return g('d') / g('v');
        return null;
      default:
        return null;
    }
  }

  static Map<String, List<String>> solveHints(String id) {
    switch (id) {
      case 'fma':
        return {'F': ['m', 'a'], 'm': ['F', 'a'], 'a': ['F', 'm']};
      case 'vuat':
        return {'v': ['u', 'a', 't'], 'u': ['v', 'a', 't'], 'a': ['v', 'u', 't'], 't': ['v', 'u', 'a']};
      case 'work':
        return {'W': ['F', 'd'], 'F': ['W', 'd'], 'd': ['W', 'F']};
      case 'ke':
        return {'KE': ['m', 'v']};
      case 'pe':
        return {'PE': ['m', 'h', 'g']};
      case 'power':
        return {'P': ['W', 't'], 'W': ['P', 't'], 't': ['W', 'P']};
      case 'ohm':
        return {'V': ['I', 'R'], 'I': ['V', 'R'], 'R': ['V', 'I']};
      case 'epower':
        return {'P': ['V', 'I'], 'V': ['P', 'I'], 'I': ['P', 'V']};
      case 'momentum':
        return {'p': ['m', 'v']};
      case 'wave':
        return {'v': ['f', 'l'], 'f': ['v', 'l'], 'l': ['v', 'f']};
      case 'period':
        return {'T': ['f'], 'f': ['T']};
      case 'pressure':
        return {'P': ['F', 'A'], 'F': ['P', 'A'], 'A': ['P', 'F']};
      case 'density':
        return {'ρ': ['m', 'V'], 'm': ['ρ', 'V'], 'V': ['m', 'ρ']};
      case 'speed':
        return {'v': ['d', 't'], 'd': ['v', 't'], 't': ['d', 'v']};
      default:
        return {};
    }
  }
}

const List<NovaPhysFormula> NovaFormulas = [
  NovaPhysFormula('fma', 'নিউটনের দ্বিতীয় সূত্র', 'F = ma', [
    NovaPhysVar('F', 'F', 'N', 'বল'),
    NovaPhysVar('m', 'm', 'kg', 'ভর'),
    NovaPhysVar('a', 'a', 'm/s²', 'ত্বরণ'),
  ]),
  NovaPhysFormula('vuat', 'গতিবিদ্যা', 'v = u + at', [
    NovaPhysVar('v', 'v', 'm/s', 'শেষ বেগ'),
    NovaPhysVar('u', 'u', 'm/s', 'আদি বেগ'),
    NovaPhysVar('a', 'a', 'm/s²', 'ত্বরণ'),
    NovaPhysVar('t', 't', 's', 'সময়'),
  ]),
  NovaPhysFormula('work', 'কাজ', 'W = F·d', [
    NovaPhysVar('W', 'W', 'J', 'কাজ'),
    NovaPhysVar('F', 'F', 'N', 'বল'),
    NovaPhysVar('d', 'd', 'm', 'দূরত্ব'),
  ]),
  NovaPhysFormula('ke', 'গতিশক্তি', 'KE = ½mv²', [
    NovaPhysVar('KE', 'KE', 'J', 'গতিশক্তি'),
    NovaPhysVar('m', 'm', 'kg', 'ভর'),
    NovaPhysVar('v', 'v', 'm/s', 'বেগ'),
  ]),
  NovaPhysFormula('pe', 'স্থিতিশক্তি', 'PE = mgh', [
    NovaPhysVar('PE', 'PE', 'J', 'স্থিতিশক্তি'),
    NovaPhysVar('m', 'm', 'kg', 'ভর'),
    NovaPhysVar('h', 'h', 'm', 'উচ্চতা'),
    NovaPhysVar('g', 'g', 'm/s²', 'মাধ্যাকর্ষণ'),
  ]),
  NovaPhysFormula('power', 'ক্ষমতা', 'P = W/t', [
    NovaPhysVar('P', 'P', 'W', 'ক্ষমতা'),
    NovaPhysVar('W', 'W', 'J', 'কাজ/শক্তি'),
    NovaPhysVar('t', 't', 's', 'সময়'),
  ]),
  NovaPhysFormula('ohm', 'ওহমের সূত্র', 'V = IR', [
    NovaPhysVar('V', 'V', 'V', 'ভোল্টেজ'),
    NovaPhysVar('I', 'I', 'A', 'কারেন্ট'),
    NovaPhysVar('R', 'R', 'Ω', 'রেজিস্ট্যান্স'),
  ]),
  NovaPhysFormula('epower', 'তড়িৎ ক্ষমতা', 'P = VI', [
    NovaPhysVar('P', 'P', 'W', 'ক্ষমতা'),
    NovaPhysVar('V', 'V', 'V', 'ভোল্টেজ'),
    NovaPhysVar('I', 'I', 'A', 'কারেন্ট'),
  ]),
  NovaPhysFormula('momentum', 'ভরবেগ', 'p = mv', [
    NovaPhysVar('p', 'p', 'kg·m/s', 'ভরবেগ'),
    NovaPhysVar('m', 'm', 'kg', 'ভর'),
    NovaPhysVar('v', 'v', 'm/s', 'বেগ'),
  ]),
  NovaPhysFormula('wave', 'তরঙ্গ', 'v = fλ', [
    NovaPhysVar('v', 'v', 'm/s', 'তরঙ্গবেগ'),
    NovaPhysVar('f', 'f', 'Hz', 'কম্পাঙ্ক'),
    NovaPhysVar('l', 'λ', 'm', 'তরঙ্গদৈর্ঘ্য'),
  ]),
  NovaPhysFormula('period', 'পর্যায়কাল', 'T = 1/f', [
    NovaPhysVar('T', 'T', 's', 'পর্যায়কাল'),
    NovaPhysVar('f', 'f', 'Hz', 'কম্পাঙ্ক'),
  ]),
  NovaPhysFormula('pressure', 'চাপ', 'P = F/A', [
    NovaPhysVar('P', 'P', 'Pa', 'চাপ'),
    NovaPhysVar('F', 'F', 'N', 'বল'),
    NovaPhysVar('A', 'A', 'm²', 'ক্ষেত্রফল'),
  ]),
  NovaPhysFormula('density', 'ঘনত্ব', 'ρ = m/V', [
    NovaPhysVar('ρ', 'ρ', 'kg/m³', 'ঘনত্ব'),
    NovaPhysVar('m', 'm', 'kg', 'ভর'),
    NovaPhysVar('V', 'V', 'm³', 'আয়তন'),
  ]),
  NovaPhysFormula('speed', 'গড় বেগ', 'v = d/t', [
    NovaPhysVar('v', 'v', 'm/s', 'বেগ'),
    NovaPhysVar('d', 'd', 'm', 'দূরত্ব'),
    NovaPhysVar('t', 't', 's', 'সময়'),
  ]),
];

// ---------- Projectile ----------

class NovaProjectile {
  final double v0, angleDeg, g;
  final double rad;
  NovaProjectile(this.v0, this.angleDeg, this.g)
      : rad = angleDeg * math.pi / 180;

  double get timeOfFlight => 2 * v0 * math.sin(rad) / g;
  double get range => v0 * v0 * math.sin(2 * rad) / g;
  double get maxHeight => v0 * v0 * math.sin(rad) * math.sin(rad) / (2 * g);
  double x(double t) => v0 * math.cos(rad) * t;
  double y(double t) => v0 * math.sin(rad) * t - 0.5 * g * t * t;
  double vx(double t) => v0 * math.cos(rad);
  double vy(double t) => v0 * math.sin(rad) - g * t;
  double speed(double t) => math.sqrt(math.pow(vx(t), 2) + math.pow(vy(t), 2));
}