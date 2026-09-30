import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/pray_times.dart';

enum SalahMode {
  jamaat('জামাতে'),
  alone('একা'),
  qada('কাজা');

  const SalahMode(this.label);
  final String label;

  static SalahMode? fromKey(String? k) {
    if (k == null) return null;
    return SalahMode.values.firstWhere(
      (m) => m.name == k,
      orElse: () => SalahMode.alone,
    );
  }
}

class SalahEntry {
  final SalahMode? mode;
  final DateTime? ts;

  const SalahEntry({this.mode, this.ts});

  bool get done => mode != null && ts != null;

  Map<String, dynamic> toMap() => {
    'mode': mode?.name,
    'ts': ts?.toIso8601String(),
  };

  factory SalahEntry.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null) return const SalahEntry();
    return SalahEntry(
      mode: SalahMode.fromKey(m['mode'] as String?),
      ts: DateTime.tryParse(m['ts'] as String? ?? ''),
    );
  }
}

/// DEEN মডিউলের store — শুধু নতুন boxes, কোনো পুরোনো ফাইল স্পর্শ করে না।
class DeenStore {
  static const prayers = <String>['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  static const _settingsBox = 'deen_settings';
  static const _logBox = 'salah_log';
  static const _amalBox = 'amal_log';
  static const _tasbihBox = 'tasbih_session';
  static const _metaBox = 'deen_meta';
  static const _memorizationBox = 'memorization';
  static const _arabicBox = 'deen_arabic';

  static Box get _settings => Hive.box(_settingsBox);
  static Box get _log => Hive.box(_logBox);
  static Box get _amal => Hive.box(_amalBox);
  static Box get _tasbih => Hive.box(_tasbihBox);
  static Box get _meta => Hive.box(_metaBox);
  static Box get _memorization => Hive.box(_memorizationBox);
  static Box get _arabic => Hive.box(_arabicBox);

  // ─── আরবি পড়া রেকর্ড (جاد shared id; 'জানি ✓' → positive jamai, no score) ──
  static List<String> _knownList() {
    final v = _arabic.get('known');
    if (v is List) return List<String>.from(v.map((e) => e.toString()));
    return <String>[];
  }

  static Set<String> arabicKnown() => _knownList().toSet();

  static bool isArabicKnown(String id) => arabicKnown().contains(id);

  static void arabicMark(String id) {
    final list = _knownList();
    if (!list.contains(id)) {
      list.add(id);
      _arabic.put('known', list);
    }
  }

  static void arabicUnmark(String id) {
    final list = _knownList()..remove(id);
    _arabic.put('known', list);
  }

  // ─── কঠিন শব্দ (hard) — সমস্যা চিহ্নিত + সেগুলোতে বেশি মুখস্থ ──
  static List<String> _hardList() {
    final v = _arabic.get('hard');
    if (v is List) return List<String>.from(v.map((e) => e.toString()));
    return <String>[];
  }

  static Set<String> arabicHard() => _hardList().toSet();

  static bool isHard(String k) => _hardList().contains(k);

  static void hardMark(String k) {
    final list = _hardList();
    if (!list.contains(k)) {
      list.add(k);
      _arabic.put('hard', list);
    }
  }

  static void hardUnmark(String k) {
    final list = _hardList()..remove(k);
    _arabic.put('hard', list);
  }

  /// জানি ✓ মানে একসাথে: বেস পরিচিতি + কঠিন-তালিকা থেকে বাদ।
  static void resolveHardAndKnown(String hardKey, String knownKey) {
    hardUnmark(hardKey);
    arabicMark(knownKey);
  }

  // ─── কুরআন আয়াতের দুই ধরনের প্রগ্রেস: পড়া শেষ (read:) + মুখস্থ (mem:) ──
  static List<String> _memList() {
    final v = _arabic.get('mem');
    if (v is List) return List<String>.from(v.map((e) => e.toString()));
    return <String>[];
  }

  static Set<String> quranMems() => _memList().toSet();

  static bool isQuranMem(String k) => _memList().contains(k);

  static void quranMemMark(String k) {
    final list = _memList();
    if (!list.contains(k)) {
      list.add(k);
      _arabic.put('mem', list);
    }
  }

  static void quranMemUnmark(String k) {
    final list = _memList()..remove(k);
    _arabic.put('mem', list);
  }

  /// "পড়া শেষ ✓" — `read:<index>:<n>` কিগুলো (অন্য known আইটেম নয়)।
  static Set<String> quranReads() =>
      arabicKnown().where((k) => k.startsWith('read:')).toSet();

  static bool isQuranRead(String k) =>
      _knownList().contains(k) && k.startsWith('read:');

  // ─── Settings ─────────────────────────────────────────────────────────
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String get methodKey =>
      _settings.get('method', defaultValue: PrayMethod.karachi.key) as String;

  static String get asrKey =>
      _settings.get('asr', defaultValue: AsrJuristic.shafi.key) as String;

  static String get highLatKey =>
      _settings.get('highLat', defaultValue: HighLatRule.middle.key) as String;

  static double get lat =>
      (_settings.get('lat', defaultValue: 23.8103) as num).toDouble();

  static double get lng =>
      (_settings.get('lng', defaultValue: 90.4125) as num).toDouble();

  /// UTC থেকে মিনিট (ঢাকা: 360)
  static double get tzMinutes =>
      (_settings.get('tzMinutes', defaultValue: 360) as num).toDouble();

  static Map<PrayerKind, double> get offsets {
    final raw = _settings.get('offsets', defaultValue: {});
    final map = <PrayerKind, double>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final k = PrayerKind.values.where((p) => p.name == e.key).firstOrNull;
        if (k != null) map[k] = (e.value as num).toDouble();
      }
    }
    return map;
  }

  // ─── Notification settings ───────────────────────────────────────────
  static bool get notifEnabled =>
      _settings.get('notifEnabled', defaultValue: false) as bool;

  static bool waqtEnabled(String prayer) {
    final raw = _settings.get('notifToggles', defaultValue: {});
    if (raw is Map && raw[prayer] is bool) return raw[prayer] as bool;
    return true;
  }

  static void saveNotifSettings({
    required bool enabled,
    required Map<String, bool> toggles,
  }) {
    _settings.putAll({'notifEnabled': enabled, 'notifToggles': toggles});
  }

  static void saveSettings({
    required String method,
    required String asr,
    required String highLat,
    required double lat,
    required double lng,
    required double tzMinutes,
    Map<PrayerKind, double>? offsets,
  }) {
    _settings.putAll({
      'method': method,
      'asr': asr,
      'highLat': highLat,
      'lat': lat,
      'lng': lng,
      'tzMinutes': tzMinutes,
      if (offsets != null)
        'offsets': {for (final e in offsets.entries) e.key.name: e.value},
    });
  }

  // ─── Salah log ────────────────────────────────────────────────────────
  static Map<String, SalahEntry> dayLog(String key) {
    final out = <String, SalahEntry>{};
    final v = _log.get(key);
    if (v is Map) {
      for (final p in prayers) {
        out[p] = SalahEntry.fromMap(v[p] as Map?);
      }
    }
    return out;
  }

  static void setSalah(String key, String prayer, SalahMode mode) {
    final day = Map<String, dynamic>.from(
      _log.get(key, defaultValue: {}) as Map,
    );
    day[prayer] = SalahEntry(mode: mode, ts: DateTime.now()).toMap();
    _log.put(key, day);
  }

  /// "এখনো করিনি" → assumption নয়, আগের অবস্থা ফেরানো (undo)।
  static void clearSalah(String key, String prayer) {
    final v = _log.get(key);
    if (v is Map) {
      final day = Map<String, dynamic>.from(v);
      day.remove(prayer);
      if (day.isEmpty) {
        _log.delete(key);
      } else {
        _log.put(key, day);
      }
    }
  }

  /// [end] পর্যন্ত (যেমন আজ) ৭ দিনের log — ইতিহাস grid-এর জন্য।
  static List<({String key, DateTime date, Map<String, SalahEntry> log})>
  lastNDays(int n, DateTime end) {
    final list = <({String key, DateTime date, Map<String, SalahEntry> log})>[];
    final base = DateTime(end.year, end.month, end.day);
    for (var i = n - 1; i >= 0; i--) {
      final d = base.subtract(Duration(days: i));
      list.add((key: dayKey(d), date: d, log: dayLog(dayKey(d))));
    }
    return list;
  }

  // ─── Post-prayer flow (amal_log) ──────────────────────────────────────
  /// নামাজের পরের ফ্লো-র সংরক্ষিত অবস্থা (mid-done resume-এর জন্য)।
  static PostPrayerSave? postPrayerSave(String key, String prayer) {
    final day = _amal.get(key);
    if (day is! Map) return null;
    final pp = day['post_prayer'];
    if (pp is! Map) return null;
    final m = pp[prayer];
    if (m is! Map) return null;
    return PostPrayerSave(
      step: ((m['step'] as num?) ?? 0).toInt(),
      counts: [
        for (final e in (m['counts'] as List? ?? const [])) (e as num).toInt(),
      ],
      done: m['done'] == true,
    );
  }

  static void savePostPrayer(
    String key,
    String prayer, {
    required int step,
    required List<int> counts,
    required bool done,
  }) {
    final day = Map<String, dynamic>.from(
      _amal.get(key, defaultValue: {}) as Map,
    );
    final pp = Map<String, dynamic>.from(day['post_prayer'] as Map? ?? {});
    pp[prayer] = {
      'step': step,
      'counts': counts,
      'done': done,
      'ts': DateTime.now().toIso8601String(),
    };
    day['post_prayer'] = pp;
    _amal.put(key, day);
  }

  /// আজকের কোনো ওয়াক্তের post-prayer চলছে (সম্পূর্ণ নয়) — resume banner-এর জন্য।
  static String? todayPendingPostPrayer() {
    final day = _amal.get(dayKey(DateTime.now()));
    if (day is! Map) return null;
    final pp = day['post_prayer'];
    if (pp is! Map) return null;
    for (final p in prayers) {
      final m = pp[p];
      if (m is Map && m['done'] != true) return p;
    }
    return null;
  }

  /// আজকের post-prayer সম্পূর্ণ ওয়াক্তের তালিকা (ইতিবাচক রেকর্ড, গিল্টি নয়)।
  static List<String> todayCompletedPostPrayers() {
    final day = _amal.get(dayKey(DateTime.now()));
    if (day is! Map) return const [];
    final pp = day['post_prayer'];
    if (pp is! Map) return const [];
    return [
      for (final p in prayers)
        if (pp[p] is Map && pp[p]['done'] == true) p,
    ];
  }

  // ─── Smart Tasbih (tasbih_session) ────────────────────────────────────
  static Map<String, dynamic> tasbihCurrent() {
    final v = _tasbih.get('current');
    if (v is Map) return Map<String, dynamic>.from(v);
    return {
      'name': 'সুবহানাল্লাহ',
      'arabic': 'سُبْحَانَ اللَّهِ',
      'target': 33,
      'count': 0,
    };
  }

  static void saveTasbihCurrent({
    required String name,
    required String arabic,
    required int target,
    required int count,
  }) {
    _tasbih.put('current', {
      'name': name,
      'arabic': arabic,
      'target': target,
      'count': count,
    });
  }

  static List<Map<String, dynamic>> tasbihRuns() {
    final v = _tasbih.get('runs');
    if (v is List) {
      return [
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
      ];
    }
    return const [];
  }

  static void addTasbihRun({
    required String name,
    required int count,
    required int target,
  }) {
    final runs = [...tasbihRuns()];
    runs.insert(0, {
      'name': name,
      'count': count,
      'target': target,
      'ts': DateTime.now().toIso8601String(),
    });
    _tasbih.put('runs', runs.take(30).toList());
  }

  static void clearTasbihRuns() => _tasbih.delete('runs');

  // ─── Bookmarks (deen_meta) ────────────────────────────────────────────
  /// saved list — item key: `dua:...` / `hadith:...`।
  static List<String> deenBookmarks() => List<String>.from(
    _meta.get('bookmarks', defaultValue: <String>[]) as List,
  );

  static bool isBookmarked(String key) => deenBookmarks().contains(key);

  static void toggleBookmark(String key) {
    final list = deenBookmarks();
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.insert(0, key);
    }
    _meta.put('bookmarks', list);
  }

  // ─── আজকের আমল (amal_log: adhkar/quran/memorized) ────────────────────
  static Map<String, dynamic> _todayAmalMap() {
    final day = _amal.get(dayKey(DateTime.now()));
    return Map<String, dynamic>.from(day is Map ? day : const {});
  }

  /// আজকের সম্পন্ন আজকার id-এর তালিকা (`{day}.adhkar_done`).
  static List<String> adhkarDoneToday() {
    final v = _todayAmalMap()['adhkar_done'];
    if (v is List) return List<String>.from(v);
    return <String>[];
  }

  static bool isAdhkarDone(String id) => adhkarDoneToday().contains(id);

  static void toggleAdhkar(String id) {
    final day = Map<String, dynamic>.from(
      _amal.get(dayKey(DateTime.now()), defaultValue: {}) as Map,
    );
    final list = adhkarDoneToday();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    day['adhkar_done'] = list;
    _amal.put(dayKey(DateTime.now()), day);
  }

  /// রুটিনের আজকের শেষ ধাপগুলো (`{day}.night_done`) — যিকির-স্ট্যাট থেকে আলাদা,
  /// তাই "আজকের আমল"-এর যিকির গণনা বাড়ে না।
  static List<String> nightStepsDoneToday() {
    final v = _todayAmalMap()['night_done'];
    if (v is List) return List<String>.from(v);
    return <String>[];
  }

  static bool isNightStepDone(String id) => nightStepsDoneToday().contains(id);

  static void toggleNightStep(String id) {
    final day = Map<String, dynamic>.from(
      _amal.get(dayKey(DateTime.now()), defaultValue: {}) as Map,
    );
    final list = nightStepsDoneToday();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    day['night_done'] = list;
    _amal.put(dayKey(DateTime.now()), day);
  }

  /// কুরআন পড়া (মিনিট) আজকে — ব্যক্তিগত রেকর্ড, স্কোর নয়।
  static int quranMinutesToday() {
    final v = _todayAmalMap()['quran_min'];
    return (v as num?)?.toInt() ?? 0;
  }

  static void addQuranMinutes(int delta) {
    final day = Map<String, dynamic>.from(
      _amal.get(dayKey(DateTime.now()), defaultValue: {}) as Map,
    );
    final cur = (day['quran_min'] as num?)?.toInt() ?? 0;
    day['quran_min'] = (cur + delta).clamp(0, 1440);
    _amal.put(dayKey(DateTime.now()), day);
  }

  // ─── অ্যাড-ক্যার ডেইলি লার্ন মেটা (deen_meta) ─────────────────────────
  static String? get dailyLearnDate => _meta.get('daily_learn_date') as String?;

  static void setDailyLearnDone() =>
      _meta.put('daily_learn_date', dayKey(DateTime.now()));

  static String? get lastRecallDate => _meta.get('last_recall') as String?;

  static void setLastRecallDone() =>
      _meta.put('last_recall', dayKey(DateTime.now()));

  // ─── Memorization (memorization box) ──────────────────────────────────
  static const List<int> reviewIntervalsDays = [1, 3, 7, 15, 30];

  static MemorizationEntry? memorizationGet(String id) {
    final v = _memorization.get(id);
    if (v is! Map) return null;
    return MemorizationEntry.fromMap(v);
  }

  /// নতুন আইটেমে মুখস্থ শুরু (level 1, আগামীকাল review)।
  static void memorizationStart(String id) {
    _memorization.put(
      id,
      MemorizationEntry(
        level: 1,
        nextReview: DateTime.now().add(const Duration(days: 1)),
        streak: 0,
        wrong: 0,
      ).toMap(),
    );
  }

  /// সফল recall/পড়া → level বাড়ে, interval অনুযায়ী next review।
  static void memorizationSuccess(String id, MemorizationEntry e) {
    final level = (e.level + 1).clamp(1, 5);
    final days = reviewIntervalsDays[level - 1];
    _memorization.put(
      id,
      MemorizationEntry(
        level: level,
        nextReview: DateTime.now().add(Duration(days: days)),
        streak: e.streak + 1,
        wrong: e.wrong,
      ).toMap(),
    );
  }

  /// ভুল → level 1-এ ফিরে, আজ রাতের পর আবার।
  static void memorizationMistake(String id, MemorizationEntry e) {
    _memorization.put(
      id,
      MemorizationEntry(
        level: 1,
        nextReview: DateTime.now().add(const Duration(hours: 4)),
        streak: 0,
        wrong: e.wrong + 1,
      ).toMap(),
    );
  }

  static void memorizationRemove(String id) => _memorization.delete(id);

  static Map<String, MemorizationEntry> memorizationAll() {
    final out = <String, MemorizationEntry>{};
    for (final k in _memorization.keys) {
      final v = _memorization.get(k);
      if (v is Map) out[k.toString()] = MemorizationEntry.fromMap(v);
    }
    return out;
  }

  /// এখন পর্যালোচনার (recall) সময় হয়েছে এমন আইটেম।
  static List<String> dueMemorizationIds(DateTime now) => [
    for (final e in memorizationAll().entries)
      if (!e.value.nextReview.isAfter(now)) e.key,
  ];

  /// আজ নতুন করে শেখা/পর্যালোচনা করা আইটেমের তালিকা।
  static List<String> memorizedTodayIds() {
    final today = dayKey(DateTime.now());
    return [
      for (final e in memorizationAll().entries)
        if (dayKey(e.value.lastReview) == today) e.key,
    ];
  }
}

/// একটি মুখস্থ আইটেমের অবস্থা (SM-2-স্টাইল spaced repetition)।
class MemorizationEntry {
  final int level; // 1..5
  final DateTime nextReview;
  final int streak;
  final int wrong;
  final DateTime lastReview;

  MemorizationEntry({
    required this.level,
    required this.nextReview,
    required this.streak,
    required this.wrong,
    DateTime? lastReview,
  }) : lastReview = lastReview ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get isDueNow => !nextReview.isAfter(DateTime.now());

  Map<String, dynamic> toMap() => {
    'level': level,
    'nextReview': nextReview.toIso8601String(),
    'streak': streak,
    'wrong': wrong,
    'lastReview': lastReview.toIso8601String(),
  };

  factory MemorizationEntry.fromMap(Map<dynamic, dynamic> m) =>
      MemorizationEntry(
        level: ((m['level'] as num?) ?? 1).toInt().clamp(1, 5),
        nextReview:
            DateTime.tryParse(m['nextReview'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        streak: ((m['streak'] as num?) ?? 0).toInt(),
        wrong: ((m['wrong'] as num?) ?? 0).toInt(),
        lastReview: DateTime.tryParse(m['lastReview'] as String? ?? ''),
      );
}

/// Namaj-পরবর্তী ফ্লো-র সংরক্ষিত অবস্থা।
class PostPrayerSave {
  final int step;
  final List<int> counts;
  final bool done;

  const PostPrayerSave({
    required this.step,
    required this.counts,
    required this.done,
  });
}
