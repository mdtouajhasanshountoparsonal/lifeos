class UnitInfo {
  final String dim;
  final double factor;
  final double offset;
  final String label;
  const UnitInfo(this.dim, this.factor, this.offset, this.label);
}

class NovaUnits {
  static const Map<String, UnitInfo> units = {
    // length
    'mm': UnitInfo('length', 0.001, 0, 'mm'),
    'cm': UnitInfo('length', 0.01, 0, 'cm'),
    'm': UnitInfo('length', 1, 0, 'm'),
    'km': UnitInfo('length', 1000, 0, 'km'),
    'inch': UnitInfo('length', 0.0254, 0, 'in'),
    'in': UnitInfo('length', 0.0254, 0, 'in'),
    'ft': UnitInfo('length', 0.3048, 0, 'ft'),
    'yd': UnitInfo('length', 0.9144, 0, 'yd'),
    'mile': UnitInfo('length', 1609.344, 0, 'mi'),
    // mass
    'mg': UnitInfo('mass', 1e-6, 0, 'mg'),
    'g': UnitInfo('mass', 0.001, 0, 'g'),
    'kg': UnitInfo('mass', 1, 0, 'kg'),
    'tonne': UnitInfo('mass', 1000, 0, 't'),
    'lb': UnitInfo('mass', 0.45359237, 0, 'lb'),
    'oz': UnitInfo('mass', 0.028349523125, 0, 'oz'),
    // time
    'ms': UnitInfo('time', 0.001, 0, 'ms'),
    's': UnitInfo('time', 1, 0, 's'),
    'min': UnitInfo('time', 60, 0, 'min'),
    'h': UnitInfo('time', 3600, 0, 'h'),
    'day': UnitInfo('time', 86400, 0, 'd'),
    // temperature
    'k': UnitInfo('temp', 1, 0, 'K'),
    'c': UnitInfo('temp', 1, 273.15, '°C'),
    'f': UnitInfo('temp', 5 / 9, 255.3722222222222, '°F'),
    // speed
    'm_s': UnitInfo('speed', 1, 0, 'm/s'),
    'km_h': UnitInfo('speed', 0.2777777778, 0, 'km/h'),
    'mph': UnitInfo('speed', 0.44704, 0, 'mph'),
    'knot': UnitInfo('speed', 0.5144444444, 0, 'kn'),
    'ft_s': UnitInfo('speed', 0.3048, 0, 'ft/s'),
    // area
    'm2': UnitInfo('area', 1, 0, 'm²'),
    'cm2': UnitInfo('area', 0.0001, 0, 'cm²'),
    'km2': UnitInfo('area', 1e6, 0, 'km²'),
    'ft2': UnitInfo('area', 0.09290304, 0, 'ft²'),
    'acre': UnitInfo('area', 4046.8564224, 0, 'acre'),
    'hectare': UnitInfo('area', 10000, 0, 'ha'),
    // volume
    'ml': UnitInfo('volume', 1e-6, 0, 'mL'),
    'l': UnitInfo('volume', 0.001, 0, 'L'),
    'm3': UnitInfo('volume', 1, 0, 'm³'),
    'cm3': UnitInfo('volume', 1e-6, 0, 'cm³'),
    'gal': UnitInfo('volume', 0.003785411784, 0, 'gal'),
    // force
    'n': UnitInfo('force', 1, 0, 'N'),
    'kn': UnitInfo('force', 1000, 0, 'kN'),
    'lbf': UnitInfo('force', 4.4482216153, 0, 'lbf'),
    'kgf': UnitInfo('force', 9.80665, 0, 'kgf'),
    'dyne': UnitInfo('force', 1e-5, 0, 'dyn'),
    // energy
    'j': UnitInfo('energy', 1, 0, 'J'),
    'kj': UnitInfo('energy', 1000, 0, 'kJ'),
    'cal': UnitInfo('energy', 4.184, 0, 'cal'),
    'kcal': UnitInfo('energy', 4184, 0, 'kcal'),
    'wh': UnitInfo('energy', 3600, 0, 'Wh'),
    'kwh': UnitInfo('energy', 3.6e6, 0, 'kWh'),
    'ev': UnitInfo('energy', 1.602176634e-19, 0, 'eV'),
    // power
    'w': UnitInfo('power', 1, 0, 'W'),
    'kw': UnitInfo('power', 1000, 0, 'kW'),
    'mw': UnitInfo('power', 1e6, 0, 'MW'),
    'hp': UnitInfo('power', 745.699872, 0, 'hp'),
    // pressure
    'pa': UnitInfo('pressure', 1, 0, 'Pa'),
    'kpa': UnitInfo('pressure', 1000, 0, 'kPa'),
    'mpa': UnitInfo('pressure', 1e6, 0, 'MPa'),
    'bar': UnitInfo('pressure', 1e5, 0, 'bar'),
    'atm': UnitInfo('pressure', 101325, 0, 'atm'),
    'mmhg': UnitInfo('pressure', 133.322387415, 0, 'mmHg'),
    'psi': UnitInfo('pressure', 6894.7572932, 0, 'psi'),
    // electrical
    'a': UnitInfo('current', 1, 0, 'A'),
    'ma': UnitInfo('current', 0.001, 0, 'mA'),
    'ua': UnitInfo('current', 1e-6, 0, 'µA'),
    'v': UnitInfo('voltage', 1, 0, 'V'),
    'kv': UnitInfo('voltage', 1000, 0, 'kV'),
    'mv': UnitInfo('voltage', 0.001, 0, 'mV'),
    'ohm': UnitInfo('resistance', 1, 0, 'Ω'),
    'kohm': UnitInfo('resistance', 1000, 0, 'kΩ'),
    'mohm': UnitInfo('resistance', 1e6, 0, 'MΩ'),
    'far': UnitInfo('capacitance', 1, 0, 'F'),
    'uf': UnitInfo('capacitance', 1e-6, 0, 'µF'),
    'mf': UnitInfo('capacitance', 1e-3, 0, 'mF'),
    'pf': UnitInfo('capacitance', 1e-12, 0, 'pF'),
    'hh': UnitInfo('inductance', 1, 0, 'H'),
    'mh': UnitInfo('inductance', 0.001, 0, 'mH'),
    // frequency
    'hz': UnitInfo('frequency', 1, 0, 'Hz'),
    'khz': UnitInfo('frequency', 1000, 0, 'kHz'),
    'mhz': UnitInfo('frequency', 1e6, 0, 'MHz'),
    'ghz': UnitInfo('frequency', 1e9, 0, 'GHz'),
  };

  static const Map<String, String> dimLabels = {
    'length': 'm', 'mass': 'kg', 'time': 's', 'temp': 'K', 'speed': 'm/s',
    'area': 'm²', 'volume': 'm³', 'force': 'N', 'energy': 'J', 'power': 'W',
    'pressure': 'Pa', 'current': 'A', 'voltage': 'V', 'resistance': 'Ω',
    'capacitance': 'F', 'inductance': 'H', 'frequency': 'Hz',
  };

  static const List<String> dimNames = [
    'length', 'mass', 'time', 'temp', 'speed', 'area', 'volume', 'force',
    'energy', 'power', 'pressure', 'current', 'voltage', 'resistance',
    'capacitance', 'inductance', 'frequency',
  ];

  static String dimLabel(String dim) => dimLabels[dim] ?? dim;

  static String? dimensionOf(String u) {
    var i = units[u.toLowerCase()];
    return i == null ? null : i.dim;
  }

  static double toBase(String u, double v) {
    var i = units[u.toLowerCase()];
    return i == null ? v : v * i.factor + i.offset;
  }

  static double fromBase(String u, double b) {
    var i = units[u.toLowerCase()];
    return i == null ? b : (b - i.offset) / i.factor;
  }

  static String baseLabel(String? dim) => dim == null ? '' : dimLabels[dim] ?? dim;

  static List<String> unitsForDimension(String dim) => units.entries
      .where((e) => e.value.dim == dim)
      .map((e) => e.key)
      .toList();

  /// "5 km + 300 m" → additive split
  static NovaUnitSplit? trySplitAdditive(String expr) {
    String s = expr.replaceAll(' ', '');
    if (s.isEmpty) return null;
    if (s.contains('*') || s.contains('/') || s.contains('^') || s.contains('(')) return null;
    if (!RegExp(r'^[\d.]+[a-z]+([+\-][\d.]+[a-z]+)+$').hasMatch(s)) return null;
    List<NovaUnitTerm> terms = [];
    StringBuffer cur = StringBuffer();
    bool neg = false;
    for (int i = 0; i < s.length; i++) {
      String ch = s[i];
      if (ch == '+' || ch == '-') {
        _tryAddUnitTerm(cur.toString(), neg, terms);
        neg = ch == '-';
        cur = StringBuffer();
      } else {
        cur.write(ch);
      }
    }
    _tryAddUnitTerm(cur.toString(), neg, terms);
    if (terms.isEmpty) return null;
    String? dim = NovaUnits.dimensionOf(terms.first.unit);
    if (dim == null) return null;
    for (final t in terms) {
      if (NovaUnits.dimensionOf(t.unit) != dim) return null;
    }
    return NovaUnitSplit(terms);
  }

  static void _tryAddUnitTerm(String raw, bool neg, List<NovaUnitTerm> terms) {
    final m = RegExp(r'^([\d.]+)([a-z]+)$').firstMatch(raw);
    if (m == null) return;
    double v = double.tryParse(m.group(1)!) ?? 0;
    terms.add(NovaUnitTerm(neg ? -v : v, m.group(2)!));
  }

  /// "20 m_s -> km_h" or "20 m_s to km_h"
  static NovaUnitConv? tryConvert(String expr) {
    String s = expr.replaceAll(' ', '');
    String body = s;
    String? target;
    int arrow = -1;
    int idx = s.indexOf('->');
    if (idx >= 0) {
      arrow = idx;
    } else if ((idx = s.indexOf('→')) >= 0) {
      arrow = idx;
    } else {
      final t = s.indexOf('to');
      if (t > 0) {
        arrow = t;
        body = s.substring(0, t);
        target = s.substring(t + 2);
      }
    }
    if (arrow >= 0) {
      body = s.substring(0, arrow);
      target = s.substring(arrow + 2);
    }
    final m = RegExp(r'^([\d.]+)([a-z]+)$').firstMatch(body);
    if (m == null) return null;
    double v = double.tryParse(m.group(1)!) ?? 0;
    String? from = m.group(2);
    String? to = target != null && target.isNotEmpty ? target : null;
    if (from != null && NovaUnits.dimensionOf(from) == null) return null;
    if (to != null && NovaUnits.dimensionOf(to) == null) return null;
    if (from != null && to != null && NovaUnits.dimensionOf(from) != NovaUnits.dimensionOf(to)) return null;
    return NovaUnitConv(v, from, to);
  }
}

class NovaUnitTerm {
  final double value;
  final String unit;
  NovaUnitTerm(this.value, this.unit);
}

class NovaUnitSplit {
  final List<NovaUnitTerm> terms;
  NovaUnitSplit(this.terms);
}

class NovaUnitConv {
  final double value;
  final String? fromUnit;
  final String? toUnit;
  NovaUnitConv(this.value, this.fromUnit, this.toUnit);
}