import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/review_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('review_test');
    Hive.init(dir.path);
    await Hive.openBox('deen_arabic');
    await Hive.openBox('deen_settings');
    await Hive.openBox('salah_log');
    await Hive.openBox('amal_log');
    await Hive.openBox('tasbih_session');
    await Hive.openBox('deen_meta');
    await Hive.openBox('memorization');
    await Hive.openBox('deen_review');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('marking a word known seeds the review queue', () {
    expect(ReviewScheduler.get('w1'), null);
    DeenStore.arabicMark('w1');
    final it = ReviewScheduler.get('w1');
    expect(it, isNotNull);
    expect(it!.isNew, true);
    expect(ReviewScheduler.dueToday().contains('w1'), true);
  });

  test('marking the same word twice does not reset its box', () {
    const k = 'w2';
    DeenStore.arabicMark(k);
    ReviewScheduler.rate(k, easy: true);
    final afterEasy = ReviewScheduler.get(k)!.box;
    DeenStore.arabicMark(k);
    expect(ReviewScheduler.get(k)!.box, afterEasy);
  });

  test('easy rating climbs the Leitner ladder and pushes due date out', () {
    const k = 'w3';
    DeenStore.arabicMark(k);
    var last = ReviewScheduler.rate(k, easy: true);
    expect(last.box, 1);
    expect(ReviewScheduler.dueToday().contains(k), false, reason: 'due today → পরের দিন');
    expect(ReviewScheduler.daysUntilDue(k), ReviewScheduler.intervals[1]);

    for (var i = 0; i < 10; i++) {
      last = ReviewScheduler.rate(k, easy: true);
    }
    expect(last.box, ReviewScheduler.intervals.length - 1,
        reason: 'সর্বোচ্চ বাক্সে আটকে থাকে, উল্টে যায় না');
  });

  test('hard rating sends the item back to box 0 for tomorrow', () {
    const k = 'w4';
    DeenStore.arabicMark(k);
    ReviewScheduler.rate(k, easy: true);
    ReviewScheduler.rate(k, easy: true);
    expect(ReviewScheduler.get(k)!.box, 2);
    final back = ReviewScheduler.rate(k, easy: false);
    expect(back.box, 0);
    expect(ReviewScheduler.daysUntilDue(k), 1,
        reason: 'কঠিন হলে পরের দিনই আবার দেখানো হয়');
    expect(ReviewScheduler.dueToday().contains(k), false,
        reason: 'আজকের পর্যায়ে আর দেখাবে না — একই দিনে চক্র হবে না');
  });

  test('an item rated today does not appear twice in one day', () {
    const k = 'w5';
    DeenStore.arabicMark(k);
    expect(ReviewScheduler.dueToday().contains(k), true);
    ReviewScheduler.rate(k, easy: true);
    expect(ReviewScheduler.dueToday().contains(k), false);
    ReviewScheduler.rate(k, easy: false);
    // আজকার রেকর্ড মুছে ফেললে (forget) আবার দেখা যাবে
    ReviewScheduler.forget(k);
    DeenStore.arabicMark(k);
    expect(ReviewScheduler.dueToday().contains(k), true);
  });

  test('seedKnown backfills without overwriting existing boxes', () {
    const a = 'bk1';
    const b = 'bk2';
    DeenStore.arabicMark(b);
    ReviewScheduler.rate(b, easy: true);
    expect(ReviewScheduler.get(b)!.box, 1);
    ReviewScheduler.seedKnown([a, b]);
    expect(ReviewScheduler.get(a), isNotNull);
    expect(ReviewScheduler.get(b)!.box, 1, reason: 'আগের বাক্স অক্ষত থাকে');
  });

  test('intervals are strictly increasing', () {
    for (var i = 1; i < ReviewScheduler.intervals.length; i++) {
      expect(
        ReviewScheduler.intervals[i] > ReviewScheduler.intervals[i - 1],
        true,
      );
    }
  });
}
