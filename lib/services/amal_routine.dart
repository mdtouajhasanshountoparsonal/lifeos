import 'package:hive_flutter/hive_flutter.dart';

/// একটা রুটিন আইটেমের ধরন — কোন মডিউলের সাথে যুক্ত।
enum AmalType { tasbih, adhkar, quran, dua, custom }

/// রুটিনের একটা আইটেম — user-এর নিজের বাছাই করা দৈনিক আমল।
///
/// নীতি: app কোনো সংখ্যা religious requirement হিসেবে চাপিয়ে দেয় না।
/// [sourceRef] শুধু তখনই সেট হয় যখন verified source-এ নির্দিষ্ট সংখ্যা বর্ণিত
/// (যেমন সুবহানাল্লাহ ৩৩) — নয়তো null, তখন সেটা "আমার লক্ষ্য"।
class AmalItem {
  final String id; // স্থায়ী — রুটিনে এডিট করলেও id বদলায় না, log এর সাথে মেলে
  final AmalType type;
  final String title; // বাংলা নাম, যেমন "সুবহানাল্লাহ"
  final String? arabic; // তাসবিহ হলে জিকিরের আরবি
  final int target; // কাউন্ট-ভিত্তিক হলে সংখ্যা, 1 মানে "একবার করলেই শেষ"
  final bool isCounted; // false = চেকবক্স (adhkar/quran/dua), true = counter
  final String? sourceRef; // যেমন "আবু দাউদ ৫০৬৫" — null হলে user-defined
  final String? emoji;
  final bool enabled; // রুটিন থেকে সাময়িক বাদ (delete না করে)
  final String? reminderMin; // "HH:mm" — পরে DeenNotifications-এ যুক্ত হবে

  const AmalItem({
    required this.id,
    required this.type,
    required this.title,
    this.arabic,
    required this.target,
    required this.isCounted,
    this.sourceRef,
    this.emoji,
    this.enabled = true,
    this.reminderMin,
  });

  AmalItem copyWith({
    String? title,
    String? arabic,
    int? target,
    bool? isCounted,
    String? sourceRef,
    String? emoji,
    bool? enabled,
    String? reminderMin,
    bool clearReminder = false,
  }) =>
      AmalItem(
        id: id,
        type: type,
        title: title ?? this.title,
        arabic: arabic ?? this.arabic,
        target: target ?? this.target,
        isCounted: isCounted ?? this.isCounted,
        sourceRef: sourceRef ?? this.sourceRef,
        emoji: emoji ?? this.emoji,
        enabled: enabled ?? this.enabled,
        reminderMin: clearReminder ? null : (reminderMin ?? this.reminderMin),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        if (arabic != null) 'arabic': arabic,
        'target': target,
        'isCounted': isCounted,
        if (sourceRef != null) 'sourceRef': sourceRef,
        if (emoji != null) 'emoji': emoji,
        'enabled': enabled,
        if (reminderMin != null) 'reminderMin': reminderMin,
      };

  factory AmalItem.fromMap(Map<dynamic, dynamic> m) => AmalItem(
        id: m['id'] as String? ?? '',
        type: AmalType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => AmalType.custom,
        ),
        title: m['title'] as String? ?? 'আমল',
        arabic: m['arabic'] as String?,
        target: ((m['target'] as num?) ?? 1).toInt().clamp(1, 100000),
        isCounted: m['isCounted'] == true,
        sourceRef: m['sourceRef'] as String?,
        emoji: m['emoji'] as String?,
        enabled: m['enabled'] != false,
        reminderMin: m['reminderMin'] as String?,
      );
}

/// ব্যবহারকারীর দৈনিক রুটিন — একটাই রুটিন (v1), ভবিষ্যতে একাধিক হতে পারে।
///
/// ডেটা: `amal_routines` box → key 'v1' → routine map।
/// আজকের progress পড়া হয় `amal_log` থেকে — লেখা হয় সেশন/চেক টগল থেকে।
class AmalRoutineStore {
  static const _boxName = 'amal_routines';
  static const _key = 'v1';

  static Box get _box => Hive.box(_boxName);

  // ─── প্রথমবারের seed — শুধু verified source-গুলোতে ref আছে ──────────────
  static const seedItems = <AmalItem>[
    AmalItem(
      id: 'subhanallah',
      type: AmalType.tasbih,
      title: 'সুবহানাল্লাহ',
      arabic: 'سُبْحَانَ اللَّهِ',
      target: 33,
      isCounted: true,
      sourceRef: 'মুসলিম ৫৯৬',
      emoji: '📿',
    ),
    AmalItem(
      id: 'alhamdulillah',
      type: AmalType.tasbih,
      title: 'আলহামদুলিল্লাহ',
      arabic: 'الْحَمْدُ لِلَّهِ',
      target: 33,
      isCounted: true,
      sourceRef: 'মুসলিম ৫৯৬',
      emoji: '📿',
    ),
    AmalItem(
      id: 'allahu_akbar',
      type: AmalType.tasbih,
      title: 'আল্লাহু আকবার',
      arabic: 'اللَّهُ أَكْبَرُ',
      target: 33,
      isCounted: true,
      sourceRef: 'মুসলিম ৫৯৬',
      emoji: '📿',
    ),
    AmalItem(
      id: 'istighfar',
      type: AmalType.tasbih,
      title: 'ইস্তিগফার',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      target: 100,
      isCounted: true,
      sourceRef: 'বুখারী ৬৩০৭',
      emoji: '🤲',
    ),
    AmalItem(
      id: 'quran_min',
      type: AmalType.quran,
      title: 'কুরআন তিলাওয়াত',
      target: 1,
      isCounted: false, // quranMinutesToday() > 0 হলেই সম্পন্ন
      emoji: '📖',
    ),
  ];

  static List<AmalItem> load() {
    final v = _box.get(_key);
    if (v is List && v.isNotEmpty) {
      return [
        for (final e in v)
          if (e is Map) AmalItem.fromMap(e),
      ];
    }
    return List<AmalItem>.from(seedItems);
  }

  static void save(List<AmalItem> items) {
    _box.put(_key, [for (final i in items) i.toMap()]);
  }

  /// রুটিন কখনো সেভ করা হয়নি কি (প্রথমবারে seed দেখানোর জন্য)।
  static bool isUntouched() => _box.get(_key) == null;

  static AmalItem? byId(String id) {
    for (final i in load()) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// রুটিনের তাসবিহ আইটেম কি — নাম দিয়ে (taibih রান সেভ করার সময় মেলানোর জন্য)।
  static AmalItem? tasbihByName(String name) {
    for (final i in load()) {
      if (i.type == AmalType.tasbih && i.title == name) return i;
    }
    return null;
  }

  // ─── আজকের progress (পড়া — amal_log থেকে) ──────────────────────────────
  // লেখা: toggleTodayItem() / DeenStore.addTasbihRun-bridge / addQuranMinutes

  static Box get _amal => Hive.box('amal_log');

  /// `{itemId: completedCount}` — আজকের।
  static Map<String, int> todayProgress() {
    final day = _amal.get(_dayKey());
    final out = <String, int>{};
    if (day is! Map) return out;
    final amal = day['routine_amal'];
    if (amal is! Map) return out;
    for (final e in amal.entries) {
      out[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
    }
    return out;
  }

  /// রুটিনের একটা আইটেম আজ কতবার সম্পন্ন হয়েছে (0 = শুরুই হয়নি)।
  static int todayCount(String itemId) => todayProgress()[itemId] ?? 0;

  /// চেকবক্স-ধরনের আইটেম আজ সম্পন্ন কি?
  static bool isTodayDone(String itemId) => todayCount(itemId) > 0;

  /// কাউন্ট-ভিত্তিক আইটেম আজ লক্ষ্য পূর্ণ কি?
  static bool isTodayComplete(AmalItem item) =>
      todayCount(item.id) >= item.target;

  /// রুটিন আইটেমের progress আজ বাড়ানো/টগল করা।
  /// [delta] কাউন্টেড আইটেমে +N, চেকবক্সে 0/1 হিসেবে ব্যবহার হয়।
  static void addTodayProgress(String itemId, int delta) {
    final dayKey = _dayKey();
    final day = Map<String, dynamic>.from(
      _amal.get(dayKey, defaultValue: {}) as Map,
    );
    final amal = Map<String, dynamic>.from(day['routine_amal'] as Map? ?? {});
    final cur = (amal[itemId] as num?)?.toInt() ?? 0;
    final next = cur + delta;
    if (next <= 0) {
      amal.remove(itemId);
    } else {
      amal[itemId] = next;
    }
    day['routine_amal'] = amal;
    _amal.put(dayKey, day);
  }

  /// চেকবক্স টগল — done হলে 1, undo হলে 0।
  static void toggleToday(String itemId) {
    addTodayProgress(itemId, isTodayDone(itemId) ? -1 : 1);
  }

  static String _dayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  // ─── সারসংক্ষেপ (Today card-এর জন্য) ────────────────────────────────────
  /// আজকের রুটিন সামগ্রিক অগ্রগতি 0..1 — শুধু enabled আইটেম গোনা হয়।
  static double todayRatio() {
    final items = [for (final i in load()) if (i.enabled) i];
    if (items.isEmpty) return 0;
    var done = 0;
    for (final i in items) {
      if (isTodayComplete(i)) done++;
    }
    return done / items.length;
  }

  static int enabledCount() =>
      [for (final i in load()) if (i.enabled) i].length;

  /// আজকের বাকি আইটেমগুলো (enabled + incomplete)।
  static List<AmalItem> todayRemaining() => [
        for (final i in load())
          if (i.enabled && !isTodayComplete(i)) i,
      ];
}
