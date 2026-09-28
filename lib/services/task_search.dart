import 'package:hive/hive.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/task.dart';

/// Smart Search (P6, Point 16) — "যে কাজগুলো ৫০০ টাকার বেশি" → Task + Money + Notes
/// একসাথে খোঁজা। Query বুঝে বুঝে: text match, cost filter, priority, status, date।
class SearchHit {
  final String kind; // task | expense | note
  final String title;
  final String subtitle;
  final double? amount;
  final Task? task;
  final SearchTone tone;
  SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.amount,
    this.task,
    this.tone = SearchTone.normal,
  });
}

enum SearchTone { normal, urgent, completed, overdue }

class TaskSearchService {
  static List<SearchHit> run(
    String query, {
    required Box<Task> tasks,
    required Box<Expense> exps,
    required Box<Note> notes,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final words = q.toLowerCase();

    // ── অর্থ / cost filter ──
    double? minCost;
    double? maxCost;
    bool moneyFilter = false;
    final ascii = _toAscii(words);
    final costM = RegExp(r'(\d+(?:\.\d+)?)\s*টাকা').firstMatch(ascii);
    if (costM != null) {
      moneyFilter = true;
      final v = double.parse(costM.group(1)!);
      if (words.contains('কম') ||
          words.contains('নিচে') ||
          words.contains('চেয়ে কম') ||
          words.contains('<')) {
        maxCost = v;
      } else {
        minCost = v;
      }
    } else if (RegExp(r'টাকা|taka\b|৳').hasMatch(words)) {
      moneyFilter = true;
      for (final m in RegExp(r'(\d+(?:\.\d+)?)').allMatches(ascii)) {
        final v = double.parse(m.group(1)!);
        if (words.contains('কম') || words.contains('নিচে')) {
          maxCost ??= v;
        } else {
          minCost ??= v;
        }
      }
    }
    // "$300" বা "৩০০" বা ">300" টাকা বোঝায় যদি টাকা-ছাড়া সংখ্যা আর কিছু বুঝায়?
    final arrowM = RegExp(r'>\s*(\d+)|>=*\s*(\d+)').firstMatch(words);
    if (arrowM != null) {
      moneyFilter = true;
      minCost = double.parse((arrowM.group(1) ?? arrowM.group(2))!);
    }

    // ── status / date hint ──
    final wantCompleted = RegExp(r'সম্পন্ন|শেষ\s*করা|done|finished|completed')
        .hasMatch(words);
    final wantPending = RegExp(r'বাকি|pending|remains|আগে').hasMatch(words);
    final wantUrgent = RegExp(r'জরুরি|urgent|গুরুত্বপূর্ণ').hasMatch(words);
    final isToday = RegExp(r'আজ|today').hasMatch(words);
    final isTomorrow = RegExp(r'কাল|আগামীকাল|tomorrow').hasMatch(words);
    final wantOverdue = RegExp(r'ওভারডিউ|পেরিয়ে|overdue|missed').hasMatch(words);

    // ── text term (সংখ্যা/টাকা/স্ট্যাটাস/তারিখ শব্দ বাদ) ──
    var term = q;
    term = term
        .replaceAll(RegExp(r'[০-৯0-9]+\s*টাকা|৳|টাকা|taka\b', caseSensitive: false), ' ')
        .replaceAll(
            RegExp(r'যে\s+কাজগুলো|কাজগুলো|খরচগুলো|note|নোট|টাস্ক|টাকার',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'জরুরি|urgent|গুরুত্বপূর্ণ', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'ওভারডিউ|পেরিয়ে|overdue|missed', caseSensitive: false), ' ')
        .replaceAll(
            RegExp(r'আজ|কাল|আগামীকাল|tomorrow|\btoday\b', caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'বাকি|pending|সম্পন্ন|শেষ\s*করা', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'কম|বেশি|উপর|নিচে'), ' ');
    term = term.replaceAll(RegExp(r'>\s*\d+'), ' ');
    final cleanTerm = term.trim();
    final emptyTerm = cleanTerm.isEmpty;

    final hits = <SearchHit>[];

    // ── Tasks ──
    for (final t in tasks.values) {
      if (t.archived) continue;
      if (wantCompleted && !t.isCompleted) continue;
      if (wantPending && t.isCompleted) continue;
      if (wantUrgent && t.priority < 2) continue;
      if (wantOverdue &&
          (t.isCompleted || t.deadline == null || !t.deadline!.isBefore(DateTime.now()))) {
        continue;
      }
      if (moneyFilter) {
        final c = t.expectedCost;
        if (minCost != null && (c == null || c < minCost)) continue;
        if (maxCost != null && (c == null || c > maxCost)) continue;
      } else if (!emptyTerm) {
        final hay = [
          t.title,
          t.description ?? '',
          t.location ?? '',
          ...t.itemList.map((i) => i.name),
        ].join(' ').toLowerCase();
        if (!hay.contains(cleanTerm.toLowerCase())) continue;
      }
      if (isToday &&
          (t.deadline == null ||
              t.deadline!.day != DateTime.now().day)) {
        continue;
      }
      if (isTomorrow) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        if (t.deadline == null ||
            DateTime(t.deadline!.year, t.deadline!.month, t.deadline!.day) !=
                DateTime(tomorrow.year, tomorrow.month, tomorrow.day)) {
          continue;
        }
      }
      final detail = <String>[
        if (t.priority >= 2) '🔥 জরুরি',
        if (t.isCompleted) '✅ শেষ',
        if (t.expectedCost != null) '৳${_num(t.expectedCost!)}',
        if (t.deadline != null) '📅 ${_date(t.deadline!)}',
        if (t.recurrenceObj != null) '🔁 ${t.recurrenceObj!.label}',
      ].join(' · ');
      hits.add(SearchHit(
        kind: 'task',
        title: t.title,
        subtitle: detail,
        amount: t.expectedCost,
        task: t,
        tone: t.isCompleted
            ? SearchTone.completed
            : (t.priority >= 2 ? SearchTone.urgent : SearchTone.normal),
      ));
    }

    // ── Money / Expenses ──
    final termLower = cleanTerm.toLowerCase();
    for (final e in exps.values) {
      if (moneyFilter) {
        if (minCost != null && e.amount < minCost) continue;
        if (maxCost != null && e.amount > maxCost) continue;
      } else if (!emptyTerm &&
          !e.title.toLowerCase().contains(termLower) &&
          !e.category.toLowerCase().contains(termLower)) {
        continue;
      }
      if (isToday && !_sameDay(e.date, DateTime.now())) continue;
      hits.add(SearchHit(
        kind: 'expense',
        title: e.title,
        subtitle: '💸 ${_catLabel(e.category)} · ${_date(e.date)}',
        amount: e.amount,
      ));
    }

    // ── Notes ──
    if (!moneyFilter) {
      for (final n in notes.values) {
        if (n.isArchived) continue;
        final hay = '${n.title} ${n.content}'.toLowerCase();
        if (!emptyTerm && !hay.contains(termLower)) continue;
        hits.add(SearchHit(
          kind: 'note',
          title: n.title,
          subtitle: '📝 ${n.content.length > 60 ? n.content.substring(0, 60) : n.content}',
        ));
      }
    }
    return hits;
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// বাংলা অঙ্ক (০-৯) → ASCII (0-9)।
  static String _toAscii(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = bn.indexOf(ch);
      return i >= 0 ? '$i' : ch;
    }).join();
  }

  static String _catLabel(String cat) {
    const map = {
      'food': 'খাবার',
      'transport': 'যাতায়াত',
      'internet': 'ইন্টারনেট',
      'shopping': 'শপিং',
      'gaming': 'গেমিং',
      'education': 'শিক্ষা',
      'home': 'বাড়ি',
      'health': 'স্বাস্থ্য',
      'bills': 'বিল',
    };
    return map[cat] ?? 'অন্যান্য';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _date(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'আজ';
    final tomorrow = now.add(const Duration(days: 1));
    if (_sameDay(d, tomorrow)) return 'কাল';
    return '${d.day}/${d.month}';
  }
}