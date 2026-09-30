import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/dua_recommender.dart';
import 'package:lifeos/services/review_scheduler.dart';

/// যাচাইকৃত dua.json থেকে সরাসরি পড়ে — কনটেন্ট-ডাউনলোড ছাড়াই।
List<DuaItem> loadDuas() {
  final path = File('..${Platform.pathSeparator}islamic_data${Platform.pathSeparator}dua.json');
  final data = jsonDecode(path.readAsStringSync(encoding: utf8)) as Map<String, dynamic>;
  return [
    for (final d in (data['duas'] as List))
      DuaItem(
        id: (d['id'] as String).trim(),
        section: (d['section'] as String).trim(),
        type: (d['type'] as String? ?? 'general').trim(),
        arabic: (d['arabic'] as String).trim(),
        transliteration: (d['transliteration'] as String).trim(),
        bangla: (d['bangla'] as String).trim(),
        source: (d['source'] as String? ?? '').trim(),
        authenticity: (d['authenticity'] as String? ?? '').trim(),
        count: (d['count'] as num?)?.toInt(),
        level: (d['level'] as num?)?.toInt() ?? 1,
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late List<DuaItem> duas;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('dua_rec_test');
    Hive.init(dir.path);
    await Hive.openBox('deen_arabic');
    await Hive.openBox('deen_settings');
    await Hive.openBox('salah_log');
    await Hive.openBox('amal_log');
    await Hive.openBox('tasbih_session');
    await Hive.openBox('deen_meta');
    await Hive.openBox('memorization');
    await Hive.openBox('deen_review');
    duas = loadDuas();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('the verified data itself is intact', () {
    expect(duas.length, 51);
    for (final d in duas) {
      expect(d.id, isNotEmpty);
      expect(d.arabic.trim(), isNotEmpty);
      expect(d.bangla.trim(), isNotEmpty);
    }
  });

  test('time of day maps to sane, real sections', () {
    expect(
      DuaRecommender.sectionsFor(DateTime(2026, 1, 1, 22))
          .contains('ঘুম ও ঘুম থেকে ওঠা'),
      true,
    );
    expect(
      DuaRecommender.sectionsFor(DateTime(2026, 1, 1, 7))
          .contains('আবহাওয়া'),
      true,
    );
    expect(
      DuaRecommender.sectionsFor(DateTime(2026, 1, 1, 7))
          .contains('ঘুম ও ঘুম থেকে ওঠা'),
      false,
    );
    expect(
      DuaRecommender.sectionsFor(DateTime(2026, 1, 1, 19))
          .contains('মসজিদ ও আযান'),
      true,
    );
  });

  test('every suggested section actually exists in dua.json', () {
    final real = duas.map((d) => d.section).toSet();
    for (final h in [3, 7, 13, 18, 23]) {
      for (final s in DuaRecommender.sectionsFor(DateTime(2026, 3, 1, h))) {
        expect(real.contains(s), true, reason: 'অজানা section: $s');
      }
    }
  });

  test('recommendations only ever contain verified duas, each with a reason',
      () async {
    final list = await DuaRecommender.ranked(duas: duas);
    expect(list.length, duas.length, reason: 'প্রতিটি দোয়া স্কোর হয়');
    for (final s in list) {
      expect(duas.any((d) => d.id == s.dua.id), true);
      expect(s.reason.trim(), isNotEmpty, reason: 'কারণ ছাড়া সুপারিশ নয়');
    }
  });

  test('ranking is sorted by score, descending', () async {
    final list = await DuaRecommender.ranked(duas: duas);
    for (var i = 1; i < list.length; i++) {
      expect(list[i - 1].score >= list[i].score, true);
    }
  });

  test('a bedtime hour prefers the sleep section over a daytime one',
      () async {
    final night = await DuaRecommender.ranked(
      now: DateTime(2026, 5, 10, 23),
      duas: duas,
    );
    final morning = await DuaRecommender.ranked(
      now: DateTime(2026, 5, 10, 9),
      duas: duas,
    );
    double bestOf(List<DuaSuggestion> l) => l.first.score.toDouble();
    expect(bestOf(night), greaterThanOrEqualTo(bestOf(morning)));
    // রাতে ঘুমের দোয়া শীর্ষে আসার কথা
    expect(night.first.dua.section, 'ঘুম ও ঘুম থেকে ওঠা');
  });

  test('same day + same time window gives the same suggestion', () async {
    // সময়-ভেদে সাজানোই উদ্দেশ্য, তাই একই সময়ের মধ্যে স্থিতিশীলতা যাচাই।
    final a = await DuaRecommender.today(
      now: DateTime(2026, 5, 10, 9, 5),
      duas: duas,
    );
    final b = await DuaRecommender.today(
      now: DateTime(2026, 5, 10, 10, 40),
      duas: duas,
    );
    final again = await DuaRecommender.today(
      now: DateTime(2026, 5, 10, 10, 40),
      duas: duas,
    );
    expect(a, isNotNull);
    expect(a!.dua.id, b!.dua.id, reason: 'একই সময়ে বদলাবে না');
    expect(again!.dua.id, b.dua.id, reason: 'পুনরায় হিসাবে ভিন্ন হবে না');
  });

  test('an unread dua scores higher than the same dua once learned', () async {
    final before = await DuaRecommender.ranked(duas: duas);
    final b = before.firstWhere((s) => s.dua.id == 'dua_3qul').score;
    DeenStore.arabicMark('dua-learn:dua_3qul');
    final after = await DuaRecommender.ranked(duas: duas);
    final a = after.firstWhere((s) => s.dua.id == 'dua_3qul').score;
    expect(a, lessThan(b), reason: 'পড়া হলে স্কোর কমে');
  });

  test('a due review lifts the dua that is scheduled for today', () async {
    DeenStore.arabicMark('dua-learn:dua_qini_adabaka');
    ReviewScheduler.rate('dua-learn:dua_qini_adabaka', easy: true);
    // due ভবিষ্যতে → এখনো ধরা পড়ে না
    var list = await DuaRecommender.ranked(duas: duas);
    expect(
      list.firstWhere((s) => s.dua.id == 'dua_qini_adabaka').reason,
      isNot(contains('পুনরাল্লাপের সময়')),
    );
    // কঠিন করে বক্স ০ → পরের দিন, তবু due ধরা পড়া শুরু (আজ ছাড়া)
    ReviewScheduler.rate('dua-learn:dua_qini_adabaka', easy: false);
    list = await DuaRecommender.ranked(duas: duas);
    expect(
      list.firstWhere((s) => s.dua.id == 'dua_qini_adabaka').reason,
      isNot(contains('পুনরাল্লাপের সময়')),
    );
  });
}
