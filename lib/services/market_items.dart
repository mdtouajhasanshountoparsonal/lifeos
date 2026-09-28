import 'package:hive_flutter/hive_flutter.dart';

/// 🧺 offline বাজার ফর্মের আইটেম-তালিকা (ক্যাটাগরি অনুযায়ী)।
/// seed-তালিকা + ব্যবহারকারীর নিজের যোগ করা (Hive 'market_items') — সব offline।
class MarketItems {
  MarketItems._();

  /// ক্যাটাগরি → আইটেম (seed)।
  static const Map<String, List<String>> seed = {
    '🍎 ফল': ['আপেল', 'কলা', 'কমলা', 'লেবু', 'লিসু', 'আম', 'কাঁঠাল', 'পেঁপে', 'তরমুজ', 'আঙুর', 'পেয়ারা', 'ডালিম'],
    '🐟 মাছ': ['ইলিশ', 'পাঙ্গাশ', 'কাতলা', 'রুই', 'তেলাপিয়া', 'চিংড়ি', 'পাবদা', 'টেংরা', 'বোয়াল', 'মলা', 'কই', 'মাগুর'],
    '🍗 মাংস-ডিম-দুধ': ['মুরগির মাংস', 'গরুর মাংস', 'খাসির মাংস', 'ডিম', 'দুধ'],
    '🥔 তরকারি': ['আলু', 'বেগুন', 'মিষ্টি কুমড়া', 'টমেটো', 'শসা', 'লাউ', 'করলা', 'ঢেঁড়স', 'পেঁয়াজ', 'রসুন', 'আদা', 'কাঁচা মরিচ'],
    '🍚 দানা-ডাল': ['চাল', 'মসুর ডাল', 'মুগ ডাল', 'ছোলা', 'গমের আটা', 'সুজি', 'চিনি', 'লবণ'],
    '🧂 মসলা-তেল': ['সরিষার তেল', 'সয়াবিন তেল', 'জিরা', 'হলুদ', 'মরিচ গুঁড়া', 'ধনিয়া'],
    '🛒 অন্যান্য': ['সাবান', 'শ্যাম্পু', 'ফেসওয়াশ', 'ব্লিচ', 'পাউডার'],
  };

  static List<String> get _cats => seed.keys.toList();

  static Box _box() => Hive.box('market_items');

  static List<String> _custom(String cat) {
    final b = _box();
    final all = b.get('custom');
    if (all is! Map) return const [];
    final list = all[cat];
    return list is List ? list.map((e) => '$e').toList() : const [];
  }

  /// ক্যাটাগরির সব আইটেম (seed + নিজের যোগ করা), ক্রম ঠিক।
  static List<String> list(String cat) {
    final out = [...?seed[cat]];
    for (final x in _custom(cat)) {
      final v = x.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }

  /// নিজের আইটেম ক্যাটাগরিতে যোগ (Hive-এ থাকে)।
  static void add(String cat, String item) {
    final v = item.trim();
    if (v.isEmpty) return;
    if (!_cats.contains(cat)) return;
    final b = _box();
    final all = Map<String, dynamic>.from(b.get('custom') is Map
        ? (b.get('custom') as Map).cast<String, dynamic>()
        : <String, dynamic>{});
    final cur = List<String>.from(all[cat] is List ? all[cat] as List : <String>[]);
    if (!cur.contains(v)) cur.add(v);
    all[cat] = cur;
    b.put('custom', all);
  }

  static List<String> get categories => _cats;

  /// সেভ করা item যেন ফর্ম-তালিকায় থাকে: আগে থেকেই কোনো তালিকায় থাকলে না,
  /// নাহলে "অন্যান্য"-এ যোগ (কোনো ডুপ্লিকেট হয় না)।
  static void addForItem(String item) {
    final v = item.trim();
    if (v.isEmpty) return;
    for (final cat in _cats) {
      if (list(cat).any((x) => x == v)) return; // আছেই → কিছু করব না
    }
    add('🛒 অন্যান্য', v);
  }
}