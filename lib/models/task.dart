import 'package:hive/hive.dart';
import '../services/market_parser.dart' show marketNumText;

part 'task.g.dart';

/// Task-এর ভেতরের একটি কেনাকাটা/সাব-আইটেম — plain class, Task-এ map হিসেবে থাকে।
class TaskItem {
  final String name;
  final double? qty;
  final String? unit;
  final String emoji;

  const TaskItem({required this.name, this.qty, this.unit, this.emoji = '🛍️'});

  Map<String, dynamic> toMap() => {
        'name': name,
        'qty': qty,
        'unit': unit,
        'emoji': emoji,
      };

  factory TaskItem.fromMap(dynamic src) {
    final m = src is Map ? src : const <String, dynamic>{};
    return TaskItem(
      name: (m['name'] as String?) ?? '',
      qty: (m['qty'] as num?)?.toDouble(),
      unit: m['unit'] as String?,
      emoji: (m['emoji'] as String?) ?? '🛍️',
    );
  }

  String get qtyText {
    final q = qty;
    if (q == null) return '';
    return marketNumText(q) + (unit == null ? '' : ' $unit');
  }
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int priority; // 0=low, 1=medium, 2=high

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? deadline;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  int estimatedMinutes;

  @HiveField(8)
  int actualMinutes;

  @HiveField(9)
  String? category;

  @HiveField(10)
  String? parentId;

  @HiveField(11)
  int order;

  @HiveField(12)
  List<Map<String, dynamic>>? items;

  @HiveField(13)
  double? expectedCost;

  @HiveField(14)
  DateTime? completedAt;

  @HiveField(15)
  String? location;

  @HiveField(16)
  bool archived;

  @HiveField(17)
  Map<String, dynamic>? recurrence; // Recurrence.toMap()

  @HiveField(18)
  List<Map<String, dynamic>>? history; // TaskHistoryEntry.toMap()

  @HiveField(19)
  bool expenseSaved; // Money-তে সেভ/না-সেভ সিদ্ধান্ত নেওয়া হয়েছে

  Task({
    required this.id,
    required this.title,
    this.description,
    this.priority = 0,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.category,
    this.parentId,
    this.order = 0,
    this.items,
    this.expectedCost,
    this.completedAt,
    this.location,
    this.archived = false,
    this.recurrence,
    this.history,
    this.expenseSaved = false,
  });

  bool get hasChildrenPlaceholder => items != null && items!.isNotEmpty;

  List<TaskItem> get itemList =>
      (items ?? const []).map(TaskItem.fromMap).toList();

  void setItemList(List<TaskItem> list) =>
      items = list.map((e) => e.toMap()).toList();

  Recurrence? get recurrenceObj =>
      recurrence == null ? null : Recurrence.fromMap(recurrence);

  void setRecurrence(Recurrence r) => recurrence = r.toMap();

  List<TaskHistoryEntry> get historyList =>
      (history ?? const []).map(TaskHistoryEntry.fromMap).toList();

  /// সবশেষ history মুক্তা সারি — 40 অথবা কম।
  void addHistory(String action, String detail) {
    final list = history ?? <Map<String, dynamic>>[];
    list.insert(0, TaskHistoryEntry(DateTime.now(), action, detail).toMap());
    if (list.length > 40) list.removeRange(40, list.length);
    history = list;
  }
}

/// পুনরাবৃত্তি (recurring) — Task-এ map হিসেবে থাকে, Hive-safe।
class Recurrence {
  final String unit; // daily | weekly | monthly
  final int interval; // প্রতি N দিন/সপ্তাহ/মাস
  final List<int> weekdays; // 1=সোম ... 7=রবি (weekly unit-এ)
  final int hour; // reminder সময়
  final int minute;

  const Recurrence({
    this.unit = 'daily',
    this.interval = 1,
    this.weekdays = const [],
    this.hour = 18,
    this.minute = 0,
  });

  Map<String, dynamic> toMap() => {
        'unit': unit,
        'interval': interval,
        'weekdays': weekdays,
        'hour': hour,
        'minute': minute,
      };

  factory Recurrence.fromMap(dynamic src) {
    if (src is! Map) return const Recurrence();
    return Recurrence(
      unit: (src['unit'] as String?) ?? 'daily',
      interval: ((src['interval'] as num?) ?? 1).toInt(),
      weekdays: ((src['weekdays'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      hour: ((src['hour'] as num?) ?? 18).toInt(),
      minute: ((src['minute'] as num?) ?? 0).toInt(),
    );
  }

  String get label {
    if (unit == 'monthly') {
      return interval != 1 ? 'প্রতি $interval মাস' : 'প্রতি মাস';
    }
    if (unit == 'weekly') {
      if (weekdays.isEmpty) return interval != 1 ? 'প্রতি $interval সপ্তাহ' : 'প্রতি সপ্তাহ';
      if (weekdays.length == 1) return 'প্রতি ${weekdayNames[weekdays.first - 1]}';
      final names = weekdays.map((d) => weekdayNames[d - 1].replaceAll('বার', '')).toList();
      return 'প্রতি ${names.join('-')}';
    }
    return interval != 1 ? 'প্রতি $interval দিন' : 'প্রতি দিন';
  }

  /// from-এর পরে next সংঘটন। deadline null হলে সন্ধ্যা ৬টা ধরে।
  DateTime nextOccurrence({required DateTime from, DateTime? time}) {
    final h = time?.hour ?? hour;
    final m = time?.minute ?? minute;
    final base = DateTime(from.year, from.month, from.day, h, m);
    if (unit == 'monthly') {
      var y = from.year;
      var mo = from.month + interval;
      while (mo > 12) {
        mo -= 12;
        y++;
      }
      var day = from.day;
      final last = DateTime(y, mo + 1, 0).day;
      if (day > last) day = last;
      return DateTime(y, mo, day, h, m);
    }
    if (unit == 'weekly') {
      if (weekdays.isEmpty) return base.add(Duration(days: 7 * interval));
      for (var d = 1; d <= 14; d++) {
        final cand = DateTime(from.year, from.month, from.day + d, h, m);
        if (weekdays.contains(cand.weekday)) {
          return cand;
        }
      }
      return base.add(const Duration(days: 7));
    }
    return base.add(Duration(days: interval));
  }

  static const weekdayNames = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];
}

/// Task History (Time Machine) entry — Task-এ map হিসেবে থাকে।
class TaskHistoryEntry {
  final DateTime at;
  final String action; // তৈরি | সম্পাদনা | ডেডলাইন | অগ্রাধিকার | শেষ | আর্কাইভ | ফেরানো | নকল
  final String detail;

  const TaskHistoryEntry(this.at, this.action, this.detail);

  Map<String, dynamic> toMap() => {
        'at': at.toIso8601String(),
        'action': action,
        'detail': detail,
      };

  factory TaskHistoryEntry.fromMap(dynamic src) {
    final m = src is Map ? src : const <String, dynamic>{};
    return TaskHistoryEntry(
      (m['at'] as String?) != null
          ? DateTime.tryParse(m['at'] as String) ?? DateTime.now()
          : DateTime.now(),
      (m['action'] as String?) ?? '',
      (m['detail'] as String?) ?? '',
    );
  }
}
