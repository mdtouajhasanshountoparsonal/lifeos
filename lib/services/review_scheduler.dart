import 'package:hive_flutter/hive_flutter.dart';

/// একটি পুনরাল্লাপ-রেকর্ড — কোন শব্দ কত "পাকা" (Leitner বাক্স)।
class ReviewItem {
  final String id;

  /// ০ = নতুন/কঠিন, বাড়তে থাকলে পরের দিনগুলো আরও দূরে।
  final int box;

  /// কবে আবার দেখানো হবে (`yyyy-MM-dd`)।
  final String due;

  /// শেষবার কবে দেখানো হয়েছিল (`yyyy-MM-dd`)।
  final String last;

  const ReviewItem({
    required this.id,
    required this.box,
    required this.due,
    required this.last,
  });

  bool get isNew => last.isEmpty;
}

/// 🔁 পুনরাল্লাপ (spaced repetition) — "জানি ✓" চাপলে ভুলে যাওয়ার আগে
/// আবার দেখানোর সময় ঠিক করা। লাইটনার-ধাঁচের বাক্স, কোনো AI/স্কোর নয়।
class ReviewScheduler {
  ReviewScheduler._();

  static const _box = 'deen_review';
  static const _key = 'items';

  /// বাক্স ০…৫-এর পরবর্তী দিন ব্যবধান (Leitner)।
  static const intervals = <int>[1, 2, 4, 8, 16, 35];

  static Box<dynamic> get _b => Hive.box(_box);

  static Map<String, dynamic> get _map {
    final v = _b.get(_key);
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  static int _daysBetween(String from, String to) {
    final a = DateTime.tryParse(from);
    final b = DateTime.tryParse(to);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays;
  }

  static ReviewItem? get(String id) {
    final m = _map;
    if (!m.containsKey(id)) return null;
    final v = m[id];
    if (v is! Map) return null;
    final d = Map<String, dynamic>.from(v);
    return ReviewItem(
      id: id,
      box: ((d['b'] as num?) ?? 0).toInt(),
      due: (d['d'] as String?) ?? '',
      last: (d['l'] as String?) ?? '',
    );
  }

  static List<ReviewItem> all() {
    final m = _map;
    final out = <ReviewItem>[];
    for (final id in m.keys) {
      final it = get(id.toString());
      if (it != null) out.add(it);
    }
    return out;
  }

  static void _put(ReviewItem it) {
    final m = _map..[it.id] = {'b': it.box, 'd': it.due, 'l': it.last};
    _b.put(_key, m);
  }

  static String get _today => _dayKey(DateTime.now());

  /// `DeenStore.dayKey`-এর মতোই ফরম্যাট, যাতে দুটো তালিকা একই দিন-চিহ্ন ব্যবহার করে।
  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// "জানি ✓" চাপলে নতুন শব্দ/দোয়া সময়ভিত্তিক তালিকায় ঢোকে।
  static void seed(String id) {
    if (get(id) != null) return;
    _put(ReviewItem(id: id, box: 0, due: _today, last: ''));
  }

  /// আজ কোনগুলো ধরা পড়বে — আজকের তালিকায় আর দ্বিতীয়বার আসে না।
  static List<String> dueToday() {
    final today = _today;
    final out = <String>[];
    for (final it in all()) {
      if (it.last == today) continue;
      if (it.due.isEmpty || it.due.compareTo(today) <= 0) out.add(it.id);
    }
    out.sort();
    return out;
  }

  /// সহজ লাগলে পরের বাক্সে, কঠিন লাগলে আবার শুরু (০ বাক্সে)।
  static ReviewItem rate(String id, {required bool easy}) {
    final today = _today;
    final cur = get(id);
    final box = cur == null
        ? 0
        : (easy
              ? (cur.box + 1).clamp(0, intervals.length - 1)
              : 0);
    final next = ReviewItem(
      id: id,
      box: box,
      due: _dayKey(DateTime.now().add(Duration(days: intervals[box]))),
      last: today,
    );
    _put(next);
    return next;
  }

  /// রিভিউ ছাড়াই মুছে ফেলা (যেমন অপ্রয়োজনীয় হয়ে গেলে)।
  static void forget(String id) {
    final m = _map..remove(id);
    _b.put(_key, m);
  }

  /// "জানি ✓" হিসাবে চিহ্নিত সব একক — লজিক বদলাবে না, শুধু তালিকা।
  static void seedKnown(List<String> ids) {
    for (final id in ids) {
      if (get(id) == null) _put(ReviewItem(id: id, box: 0, due: _today, last: ''));
    }
  }

  /// কয়েকদিন পরে কবে (তথ্য হিসাবের জন্য)।
  static int daysUntilDue(String id) {
    final it = get(id);
    if (it == null) return 0;
    return _daysBetween(_today, it.due);
  }

  static int get count => all().length;

  static int get dueCount => dueToday().length;
}
