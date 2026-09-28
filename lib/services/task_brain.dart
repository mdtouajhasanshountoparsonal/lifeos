import '../models/task.dart';
import 'command_parser.dart';
import 'market_parser.dart' show marketEmoji, matchUnit, parseNumber;

/// TaskBrain — টেক্সট থেকে কাজকে Structured Tree-তে বানানোর layer।
///
/// Tier 1-2: Title + Deadline + Priority (+ Category)
/// Tier 3:   Item + Quantity (`মাছ ২ কেজি`, `আলু ৫ কেজি`)
/// Tier 4:   Expected cost (`৫০০ টাকার মধ্যে`)
class TaskBrain {
  final String title;
  final DateTime? deadline;
  final int priority;
  final String? category;
  final List<TaskItem> items;
  final double? expectedCost;
  final Recurrence? recurrence;

  TaskBrain({
    required this.title,
    this.deadline,
    this.priority = 1,
    this.category,
    this.items = const [],
    this.expectedCost,
    this.recurrence,
  });

  bool get isShopping => category == 'Shopping' || items.isNotEmpty;

  static TaskBrain? analyze(String raw) {
    final base = CommandParser.parse(raw);
    if (base == null || base.type != CommandType.task) return null;

    var text = base.title;

    // ── Tier 4: expected cost ──
    double? cost;
    final costRe = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:টাকা|টাকার|tk\b|taka|৳)',
      caseSensitive: false,
    );
    final cm = costRe.firstMatch(text);
    if (cm != null) {
      cost = parseNumber(cm.group(1)!);
      text = text.replaceFirst(RegExp(RegExp.escape(cm.group(0)!)), ' ');
    }

    // ── Tier 3: shopping items ──
    final items = <TaskItem>[];
    if (_shoppingHint(text)) {
      text = _extractItems(text, items);
    }

    var title = _clean(text);
    if (title.isEmpty) title = base.title;

    return TaskBrain(
      title: title.isEmpty ? 'নতুন কাজ' : title,
      deadline: CommandParser.parseDeadline(title),
      priority: CommandParser.parsePriority(title),
      category: _category(title),
      items: items,
      expectedCost: cost,
      recurrence: CommandParser.parseRecurrence(title),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  static const _stopwords = [
    'বাজার', 'কেনা', 'কিনে', 'কিনবো', 'কিনবে', 'কিনতে', 'কিনব',
    'লাগবে', 'আনব', 'আনা', 'আনতে', 'আর', 'এবং', 'থেকে', 'করে',
    'কাল', 'আজ', 'সকাল', 'বিকাল', 'সন্ধ্যা', 'রাত', 'দুপুর',
  ];

  static String _extractItems(String text, List<TaskItem> out) {
    final itemRe = RegExp(
      r'([\u0980-\u09FF][\u0980-\u09FF]*|[a-zA-Z][a-zA-Z]*)\s+'
      r'([0-9০-৯]+(?:[.,][0-9০-৯]+)?)\s*'
      r'(kg|kgs|g|gm|gr|গ্রাম|কেজি|কিলো|কিলোগ্রাম|লিটার|লি|ml|মিলি|ডজন|পিস|প্যাক|বোতল|ডাব|শুঁটি)s?(?!\d)',
      caseSensitive: false,
    );

    var rest = text;
    while (true) {
      final m = itemRe.firstMatch(rest);
      if (m == null) break;
      final phrase = m.group(0)!;
      rest = rest.replaceFirst(RegExp(RegExp.escape(phrase)), ' ');
      final name = m.group(1)!.trim();
      if (_stopwords.contains(name) || name.length <= 1) continue;
      final qty = parseNumber(m.group(2)!);
      final unit = matchUnit(m.group(3)!);
      out.add(TaskItem(
        name: name,
        qty: qty,
        unit: unit,
        emoji: marketEmoji(name),
      ));
    }
    return rest;
  }

  static bool _shoppingHint(String text) {
    return RegExp(
      r'বাজার|কিন|কেনা|কেনা|ক্রয়|বাই\b|buy|market|shopping|purchase|লাগবে|আনব|আনতে',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static String? _category(String text) {
    final l = text.toLowerCase();
    if (RegExp(r'পড়[াু]|পড়ব|শেখ|শিখ|study|learn|exam|পরীক্ষা|grammar|english|গণিত|math|class')
            .hasMatch(l)) {
      return 'Study';
    }
    if (RegExp(r'বাজার|কিন|কেনা|buy|market|shopping|purchase').hasMatch(l)) {
      return 'Shopping';
    }
    if (RegExp(r'ডাক্তার|হাসপাতাল|ওষুধ|medicine|চেকআপ|hospital|clinic|ভ্যাকসিন|vaccine')
            .hasMatch(l)) {
      return 'Health';
    }
    if (RegExp(r'মিটিং|meeting|অফিস|office|project|প্রজেক্ট|ডেডলাইন').hasMatch(l)) {
      return 'Work';
    }
    if (RegExp(r'ঘর|বাসা|রুম|পরিষ্কার|clean|room|laundry|লন্ড্রি').hasMatch(l)) {
      return 'Home';
    }
    return null;
  }

  static String _clean(String s) {
    var t = s;
    // শেষের অ্যাকশন/সংযোগকারী শব্দ টাইটেল থেকে বাদ (যেন "বাজার থেকে" clean থাকে)
    bool changed = true;
    while (changed) {
      final before = t;
      t = t.replaceFirst(
        RegExp(r'\s+(?:কিনবো|কিনবে|কিনে|কিনব|কিনতে|আনব|আনতে|লাগবে|আর|এবং)\s*$'),
        '',
      );
      changed = t != before;
    }
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ── উপস্থাপনা helper ────────────────────────────────────────────────────

  static String categoryLabel(String? cat) => switch (cat) {
        'Study' => 'পড়াশোনা',
        'Shopping' => 'বাজার',
        'Health' => 'স্বাস্থ্য',
        'Work' => 'কাজ',
        'Home' => 'ঘর',
        _ => 'অন্যান্য',
      };

  static String categoryEmoji(String? cat) => switch (cat) {
        'Study' => '📚',
        'Shopping' => '🛒',
        'Health' => '💊',
        'Work' => '💼',
        'Home' => '🏠',
        _ => '📌',
      };
}