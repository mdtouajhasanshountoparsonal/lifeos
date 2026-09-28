import 'dart:math' as math;

/// Calculation methods (দ্রষ্টব্য: এগুলো গাণিতিক প্রথা — ধর্মীয় রায় নয়)।
enum PrayMethod {
  mwl('MWL (Muslim World League)', 'mwl'),
  karachi('Karachi (Bangladesh)', 'karachi'),
  isna('ISNA (North America)', 'isna'),
  egyptian('Egyptian (Egyptian General)', 'egyptian'),
  makkah('Umm al-Qura (Makkah)', 'makkah'),
  tehran('Tehran', 'tehran'),
  jafari('Jafari (Shia)', 'jafari');

  const PrayMethod(this.label, this.key);
  final String label;
  final String key;

  static PrayMethod fromKey(String key) => PrayMethod.values
      .firstWhere((m) => m.key == key, orElse: () => PrayMethod.karachi);
}

/// আসর মাযহাব
enum AsrJuristic {
  shafi("Shafi'i / Hanbali / Maliki", 'shafi'),
  hanafi('Hanafi', 'hanafi');

  const AsrJuristic(this.label, this.key);
  final String label;
  final String key;

  static AsrJuristic fromKey(String key) => AsrJuristic.values
      .firstWhere((a) => a.key == key, orElse: () => AsrJuristic.shafi);
}

/// উচ্চ অক্ষাংশের নিয়ম (৪৮°+ ল্যাটে দরকার হয়)
enum HighLatRule {
  middle('Middle of the night', 'middle'),
  seventh('One-seventh of the night', 'seventh'),
  angle('Angle-based', 'angle');

  const HighLatRule(this.label, this.key);
  final String label;
  final String key;

  static HighLatRule fromKey(String key) => HighLatRule.values
      .firstWhere((h) => h.key == key, orElse: () => HighLatRule.middle);
}

enum PrayerKind { fajr, sunrise, dhuhr, asr, maghrib, isha }

class _MethodParams {
  final double fajrAngle;
  final double ishaAngle;
  final double? maghribAngle;
  final double? ishaMins;

  const _MethodParams(this.fajrAngle, this.ishaAngle,
      [this.maghribAngle, this.ishaMins]);
}

const _params = <String, _MethodParams>{
  'mwl': _MethodParams(18, 17),
  'karachi': _MethodParams(18, 18),
  'isna': _MethodParams(15, 15),
  'egyptian': _MethodParams(19.5, 17.5),
  'makkah': _MethodParams(18.5, 99, null, 90),
  'tehran': _MethodParams(17.7, 14, 4.5),
  'jafari': _MethodParams(16, 14, 4),
};

/// ৫ ওয়াক্ত + সূর্যোদয়ের হিসাব
class PrayerTimeResult {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerTimeResult({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  DateTime? of(PrayerKind kind) {
    switch (kind) {
      case PrayerKind.fajr:
        return fajr;
      case PrayerKind.sunrise:
        return sunrise;
      case PrayerKind.dhuhr:
        return dhuhr;
      case PrayerKind.asr:
        return asr;
      case PrayerKind.maghrib:
        return maghrib;
      case PrayerKind.isha:
        return isha;
    }
  }

  /// এখন কোন ওয়াক্ত (next upcoming)
  PrayerKind? nextFrom(DateTime now) {
    final order = [PrayerKind.fajr, PrayerKind.dhuhr, PrayerKind.asr, PrayerKind.maghrib, PrayerKind.isha];
    for (final k in order) {
      if (of(k)!.isAfter(now)) return k;
    }
    return null; // আজ সব হয়ে গেছে — পরেরটা আগামীকাল ফজর
  }
}

class PrayTimesEngine {
  /// Offline Sun-position গণনা (pure math)। একটা দিনের লোকাল সময় বের করা হয়।
  /// [tzMinutes] = UTC থেকে মিনিট (ঢাকা: 360)।
  static PrayerTimeResult compute({
    required DateTime date,
    required double lat,
    required double lng,
    required double tzMinutes,
    PrayMethod method = PrayMethod.karachi,
    AsrJuristic asr = AsrJuristic.shafi,
    HighLatRule highLat = HighLatRule.middle,
    Map<PrayerKind, double> offsets = const {},
  }) {
    double off(PrayerKind k) => offsets[k] ?? 0;

    final p = _params[method.key]!;
    final jDate = _julian(date.year, date.month, date.day) - lng / (15 * 24);
    final mid = _midDay(12, jDate);

    var fajrH = _sunAngleTime(p.fajrAngle, mid, jDate, lat, ccw: true);
    final sunriseH = _sunAngleTime(0.833, mid, jDate, lat, ccw: true);
    final dhuhrH = mid;
    final asrH = _asrTime(asr == AsrJuristic.hanafi ? 2 : 1, mid, jDate, lat);
    final sunsetH = _sunAngleTime(0.833, mid, jDate, lat);
    var maghribH = p.maghribAngle != null
        ? _sunAngleTime(p.maghribAngle!, mid, jDate, lat)
        : sunsetH;
    var ishaH = p.ishaMins != null
        ? maghribH + (p.ishaMins! + off(PrayerKind.isha)) / 60.0
        : _sunAngleTime(p.ishaAngle, mid, jDate, lat);

    if (lat.abs() > 48) {
      var night = sunsetH - sunriseH;
      if (night < 0) night += 24;
      final frac = _nightFraction(highLat, night);
      if (fajrH.isNaN || fajrH < 0) fajrH = sunriseH - frac;
      if (ishaH.isNaN || ishaH > 24) ishaH = sunsetH + frac;
    }

    fajrH += off(PrayerKind.fajr) / 60.0;
    var dhuhrMin = dhuhrH + off(PrayerKind.dhuhr) / 60.0;
    var asrMin = asrH + off(PrayerKind.asr) / 60.0;
    var maghribMin = maghribH + off(PrayerKind.maghrib) / 60.0;
    var ishaMin = ishaH;

    final shift = (tzMinutes - lng * 4) / 60.0;

    DateTime toClock(double solarHour) {
      final local = _fixHour(solarHour + shift) * 60;
      final total = ((local + 1440 * 40) % 1440).round();
      return DateTime(date.year, date.month, date.day)
          .add(Duration(minutes: total));
    }

    final sunrise = toClock(sunriseH + off(PrayerKind.sunrise) / 60.0);

    return PrayerTimeResult(
      fajr: toClock(fajrH),
      sunrise: sunrise,
      dhuhr: toClock(dhuhrMin),
      asr: toClock(asrMin),
      maghrib: toClock(maghribMin),
      isha: toClock(ishaMin),
    );
  }

  static double _nightFraction(HighLatRule rule, double night) {
    switch (rule) {
      case HighLatRule.middle:
        return night / 2;
      case HighLatRule.seventh:
        return night / 7;
      case HighLatRule.angle:
        return night / 7;
    }
  }

  // ─── Sun-position helpers ─────────────────────────────────────────────
  static double _d2r(double d) => d * math.pi / 180.0;
  static double _r2d(double r) => r * 180.0 / math.pi;
  static double _sinD(double d) => math.sin(_d2r(d));
  static double _cosD(double d) => math.cos(_d2r(d));
  static double _tanD(double d) => math.tan(_d2r(d));
  static double _acosD(double x) => _r2d(math.acos(x));

  static double _fixAngle(double a) {
    a = a - 360 * (a / 360).floorToDouble();
    a += a < 0 ? 360 : 0;
    return a;
  }

  static double _fixHour(double h) {
    h = h - 24 * (h / 24).floorToDouble();
    h += h < 0 ? 24 : 0;
    return h;
  }

  static double _julian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  static double _declination(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sinD(g) + 0.020 * _sinD(2 * g));
    final e = 23.439 - 0.00000036 * d;
    return _r2d(math.asin(_sinD(e) * _sinD(l)));
  }

  static double _equationOfTime(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sinD(g) + 0.020 * _sinD(2 * g));
    final e = 23.439 - 0.00000036 * d;
    final ra = _r2d(math.atan2(_cosD(e) * _sinD(l), _cosD(l)));
    return (q / 15.0) - _fixHour(ra / 15.0);
  }

  static double _midDay(double time, double jDate) =>
      _fixHour(12 - _equationOfTime(jDate + time / 24.0));

  static double _sunAngleTime(double angle, double time, double jDate,
      double lat, {bool ccw = false}) {
    final decl = _declination(jDate + time / 24.0);
    final noon = _midDay(time, jDate);
    final denom = _cosD(decl) * _cosD(lat);
    if (denom.abs() < 1e-9) return double.nan;
    var cosv = (-_sinD(angle) - _sinD(decl) * _sinD(lat)) / denom;
    cosv = cosv.clamp(-1.0, 1.0);
    final t = (1.0 / 15.0) * _acosD(cosv);
    return _fixHour(noon + (ccw ? -t : t));
  }

  static double _asrTime(double factor, double time, double jDate, double lat) {
    final decl = _declination(jDate + time / 24.0);
    final tan = math.atan(1.0 / (factor + _tanD((lat - decl).abs())));
    final angle = -_r2d(tan);
    return _sunAngleTime(angle, time, jDate, lat);
  }
}