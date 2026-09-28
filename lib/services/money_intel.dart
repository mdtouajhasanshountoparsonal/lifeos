import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/expense.dart';

class MoneyCategory {
  final String key;
  final String label;
  final IconData icon;
  const MoneyCategory(this.key, this.label, this.icon);
}

const List<MoneyCategory> kMoneyCategories = [
  MoneyCategory('food', 'খাবার', Icons.restaurant_rounded),
  MoneyCategory('transport', 'যাতায়াত', Icons.directions_car_rounded),
  MoneyCategory('internet', 'ইন্টারনেট', Icons.wifi_rounded),
  MoneyCategory('shopping', 'শপিং', Icons.shopping_bag_rounded),
  MoneyCategory('gaming', 'গেমিং', Icons.sports_esports_rounded),
  MoneyCategory('education', 'শিক্ষা', Icons.school_rounded),
  MoneyCategory('home', 'বাড়ি', Icons.home_rounded),
  MoneyCategory('health', 'স্বাস্থ্য', Icons.health_and_safety_rounded),
  MoneyCategory('bills', 'বিল', Icons.receipt_long_rounded),
  MoneyCategory('other', 'অন্যান্য', Icons.more_horiz_rounded),
];

MoneyCategory catOf(String key) {
  final k = key == 'groceries' ? 'food' : key;
  for (final c in kMoneyCategories) {
    if (c.key == k) return c;
  }
  return kMoneyCategories.last;
}

class MoneyIntel {
  static final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');

  static const List<String> _bnMonths = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  static String bnMonthYear(DateTime m) => '${_bnMonths[m.month - 1]} ${m.year}';

  static String bnDay(DateTime d) {
    final now = DateTime.now();
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'গতকাল';
    return '${d.day} ${_bnMonths[d.month - 1]}';
  }

  static String fmt(double v) => '৳${_fmt.format(v.round())}';

  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

  static DateTime addMonth(DateTime m, int n) => DateTime(m.year, m.month + n, 1);

  static bool sameMonth(DateTime a, DateTime b) =>
      a.month == b.month && a.year == b.year;

  static List<Expense> inMonth(Box<Expense> box, DateTime month) =>
      box.values.where((e) => sameMonth(e.date, month)).toList();

  static double spendOf(List<Expense> es) => es
      .where((e) => !e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  static double incomeOf(List<Expense> es) => es
      .where((e) => e.isIncome)
      .fold(0.0, (s, e) => s + e.amount);

  static double daySpend(Box<Expense> box, DateTime day) {
    var total = 0.0;
    for (final e in box.values) {
      if (!e.isIncome && e.date.year == day.year && e.date.month == day.month && e.date.day == day.day) {
        total += e.amount;
      }
    }
    return total;
  }

  static double weekSpend(Box<Expense> box, DateTime now) {
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = now.add(const Duration(days: 1));
    var total = 0.0;
    for (final e in box.values) {
      if (!e.isIncome && !e.date.isBefore(start) && e.date.isBefore(end)) total += e.amount;
    }
    return total;
  }

  static List<({DateTime day, double total})> lastNDays(Box<Expense> box, int n) {
    final now = DateTime.now();
    final out = <({DateTime day, double total})>[];
    final byDay = <String, double>{};
    for (final e in box.values) {
      if (e.isIncome) continue;
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      byDay[key] = (byDay[key] ?? 0) + e.amount;
    }
    for (var i = n - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      out.add((day: d, total: byDay['${d.year}-${d.month}-${d.day}'] ?? 0));
    }
    return out;
  }

  static List<double> monthDaySpends(Box<Expense> box, DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var d = 1; d <= days; d++)
        daySpend(box, DateTime(month.year, month.month, d)),
    ];
  }

  static List<({String category, double total, int count})> categoryTotals(List<Expense> monthExpenses) {
    final map = <String, ({double total, int count})>{};
    for (final e in monthExpenses) {
      if (e.isIncome) continue;
      final cur = map[e.category] ?? (total: 0.0, count: 0);
      map[e.category] = (total: cur.total + e.amount, count: cur.count + 1);
    }
    final list = map.entries
        .map((e) => (category: e.key, total: e.value.total, count: e.value.count))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  static double? monthDelta(double thisSpend, double prevSpend) {
    if (prevSpend <= 0) return null;
    return (thisSpend - prevSpend) / prevSpend * 100;
  }

  static ({double today, double avg, bool unusual, double high}) anomalyToday(Box<Expense> box) {
    final todayTotal = daySpend(box, DateTime.now());
    final series = lastNDays(box, 15);
    double sum = 0;
    var count = 0;
    for (var i = 0; i < series.length - 1; i++) {
      if (series[i].total > 0) {
        sum += series[i].total;
        count++;
      }
    }
    final avg = count == 0 ? 0.0 : sum / count;
    final high = avg * 1.8;
    final unusual = todayTotal > 0 && avg > 0 && todayTotal > high && todayTotal >= 500;
    return (today: todayTotal, avg: avg, unusual: unusual, high: high);
  }

  static List<({String title, double amount, DateTime last, DateTime next})> recurring(Box<Expense> box) {
    final now = DateTime.now();
    final cut = now.subtract(const Duration(days: 95));
    final groups = <String, List<Expense>>{};
    for (final e in box.values) {
      if (e.isIncome || e.date.isBefore(cut)) continue;
      final t = e.title.trim().toLowerCase();
      if (t.isEmpty) continue;
      groups.putIfAbsent(t, () => []).add(e);
    }
    final out = <({String title, double amount, DateTime last, DateTime next})>[];
    for (final g in groups.values) {
      if (g.length < 2) continue;
      final sorted = g..sort((a, b) => a.date.compareTo(b.date));
      var consistent = true;
      for (var i = 1; i < sorted.length; i++) {
        final prev = sorted[i - 1];
        final cur = sorted[i];
        final span = (cur.date.difference(prev.date).inDays).abs();
        if (span < 20 || span > 40) {
          consistent = false;
          break;
        }
        if (prev.amount > 0 && (cur.amount / prev.amount - 1).abs() > 0.15) {
          consistent = false;
          break;
        }
      }
      if (!consistent) continue;
      final last = sorted.last;
      out.add((
        title: last.title,
        amount: last.amount,
        last: last.date,
        next: DateTime(last.date.year, last.date.month + 1, last.date.day),
      ));
    }
    out.sort((a, b) => a.next.compareTo(b.next));
    return out;
  }

  static Map<String, double> budgets(Box settings) {
    final v = settings.get('budgets');
    if (v is Map) {
      return v.map((k, val) => MapEntry('$k', val is num ? val.toDouble() : 0));
    }
    return {};
  }

  static void saveBudgets(Box settings, Map<String, double> budgets) {
    settings.put('budgets', budgets);
  }
}