import 'dart:math';

class PxEvent {
  final int id;
  final int ts;
  final String type;
  final String? pkg;
  final String? extra;

  const PxEvent({
    required this.id,
    required this.ts,
    required this.type,
    this.pkg,
    this.extra,
  });

  factory PxEvent.fromMap(Map<String, dynamic> m) => PxEvent(
        id: (m['id'] as int?) ?? 0,
        ts: (m['ts'] as num?)?.toInt() ?? 0,
        type: (m['type'] as String?) ?? '',
        pkg: m['pkg'] as String?,
        extra: m['extra'] as String?,
      );
}

class ChargeSession {
  final int startTs;
  final int endTs;
  final int? startPercent;
  final int? endPercent;

  const ChargeSession({
    required this.startTs,
    required this.endTs,
    this.startPercent,
    this.endPercent,
  });

  int get durationSec => max(0, (endTs - startTs) ~/ 1000);
}

class ScreenSession {
  final int startTs;
  final int endTs;

  const ScreenSession({required this.startTs, required this.endTs});

  int get durationSec => max(0, (endTs - startTs) ~/ 1000);
}

class BatteryPoint {
  final int ts;
  final int percent;
  final double tempC;
  final bool charging;

  const BatteryPoint({
    required this.ts,
    required this.percent,
    required this.tempC,
    required this.charging,
  });
}

class CallEntry {
  final String number;
  final int type; // 1 incoming, 2 outgoing, 3 missed, 4 voicemail, 5 rejected
  final int durationSec;
  final int date;

  const CallEntry({
    required this.number,
    required this.type,
    required this.durationSec,
    required this.date,
  });

  factory CallEntry.fromMap(Map<String, dynamic> m) => CallEntry(
        number: (m['number'] as String?) ?? '',
        type: (m['type'] as num?)?.toInt() ?? 0,
        durationSec: (m['duration'] as num?)?.toInt() ?? 0,
        date: (m['date'] as num?)?.toInt() ?? 0,
      );
}

class AppUsage {
  final String pkg;
  final int totalTimeSec;
  final int lastTimeMs;

  const AppUsage({
    required this.pkg,
    required this.totalTimeSec,
    required this.lastTimeMs,
  });

  factory AppUsage.fromMap(Map<String, dynamic> m) => AppUsage(
        pkg: (m['pkg'] as String?) ?? '',
        totalTimeSec: ((m['totalTime'] as num?)?.toInt() ?? 0) ~/ 1000,
        lastTimeMs: (m['lastTime'] as num?)?.toInt() ?? 0,
      );
}

class InstalledApp {
  final String pkg;
  final String label;

  const InstalledApp({required this.pkg, required this.label});

  factory InstalledApp.fromMap(Map<String, dynamic> m) => InstalledApp(
        pkg: (m['pkg'] as String?) ?? '',
        label: (m['label'] as String?) ?? '',
      );
}

// ─── Parsing helpers ────────────────────────────────────────────────────────

List<BatteryPoint> batterySeries(List<PxEvent> evs) {
  final out = <BatteryPoint>[];
  for (final e in evs) {
    if (e.type != 'battery' || e.extra == null) continue;
    final parts = e.extra!.split(':');
    if (parts.length < 4) continue;
    final level = int.tryParse(parts[0]);
    final scale = int.tryParse(parts[1]);
    final temp = double.tryParse(parts[2]) ?? 0;
    final charging = parts[3] == '1';
    if (level == null || scale == null || scale <= 0) continue;
    out.add(BatteryPoint(
      ts: e.ts,
      percent: (level * 100 / scale).round().clamp(0, 100),
      tempC: temp,
      charging: charging,
    ));
  }
  return out;
}

int? nearestPercent(List<BatteryPoint> series, int ts) {
  BatteryPoint? best;
  for (final p in series) {
    if (p.ts > ts) break;
    best = p;
  }
  if (best == null && series.isNotEmpty) best = series.first;
  return best?.percent;
}

int nearestPercentAtOrBefore(List<BatteryPoint> series, int ts) {
  BatteryPoint? best;
  for (final p in series) {
    if (p.ts > ts) break;
    best = p;
  }
  if (best == null && series.isNotEmpty) best = series.first;
  return best?.percent ?? -1;
}

List<ChargeSession> chargeSessions(List<PxEvent> evs, List<BatteryPoint> series) {
  final out = <ChargeSession>[];
  PxEvent? on;
  for (final e in evs) {
    if (e.type == 'charge_on') {
      on = e;
    } else if (e.type == 'charge_off' && on != null) {
      out.add(ChargeSession(
        startTs: on.ts,
        endTs: e.ts,
        startPercent: nearestPercent(series, on.ts),
        endPercent: nearestPercent(series, e.ts),
      ));
      on = null;
    }
  }
  return out;
}

List<ScreenSession> screenSessions(List<PxEvent> evs) {
  final out = <ScreenSession>[];
  PxEvent? open;
  for (final e in evs) {
    if (e.type == 'screen_on') {
      open = e;
    } else if (e.type == 'screen_off' && open != null) {
      out.add(ScreenSession(startTs: open.ts, endTs: e.ts));
      open = null;
    }
  }
  if (open != null) {
    out.add(ScreenSession(startTs: open.ts, endTs: DateTime.now().millisecondsSinceEpoch));
  }
  return out;
}

Map<String, int> notifCounts(List<PxEvent> evs) {
  final m = <String, int>{};
  for (final e in evs) {
    if (e.type == 'notif' && e.pkg != null) {
      final pkg = e.pkg!;
      m[pkg] = (m[pkg] ?? 0) + 1;
    }
  }
  return m;
}

List<int> notifByHour(List<PxEvent> evs) {
  final hours = List<int>.filled(24, 0);
  for (final e in evs) {
    if (e.type != 'notif') continue;
    final h = DateTime.fromMillisecondsSinceEpoch(e.ts).hour;
    hours[h]++;
  }
  return hours;
}

List<MapEntry<int, String>> networkTimeline(List<PxEvent> evs) {
  final out = <MapEntry<int, String>>[];
  for (final e in evs) {
    if (e.type == 'network' && e.extra != null) {
      out.add(MapEntry(e.ts, e.extra!));
    }
  }
  return out;
}

// ─── Formatting helpers ──────────────────────────────────────────────────────

String fmtShortTime(int ts) {
  final t = DateTime.fromMillisecondsSinceEpoch(ts);
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String fmtDur(int sec) {
  if (sec < 60) return '${sec}s';
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String fmtDurShort(int sec) {
  if (sec < 3600) {
    final m = (sec / 60).round();
    return '${m}m';
  }
  final h = sec / 3600;
  return '${h.toStringAsFixed(1)}h';
}

String limitName(String name, [int len = 16]) {
  if (name.length <= len) return name;
  return '${name.substring(0, len - 1)}…';
}

String medianLabel(String pkg) {
  final parts = pkg.split('.');
  final last = parts.isNotEmpty ? parts.last : pkg;
  const skip = {'app', 'android', 'com', 'lifeos'};
  if (skip.contains(last.toLowerCase())) return pkg;
  final parts2 = last.split(RegExp(r'[ _]'));
  return parts2.isNotEmpty ? parts2.first : pkg;
}