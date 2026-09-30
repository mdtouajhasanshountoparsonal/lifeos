import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/review_content.dart';
import 'package:lifeos/services/review_scheduler.dart';

const _word = ArabicWordItem(
  id: 'w1',
  arabic: 'الله',
  reading: 'allah',
  bangla: 'আল্লাহ',
  source: 'quran',
);

const _vocab = VocabItem(
  id: 'v1',
  arabic: 'رحمة',
  reading: 'rahmah',
  bangla: 'দয়া',
  root: 'ر-ح-م',
  occurrences: [],
);

const _dua = DuaItem(
  id: 'dua_3qul',
  section: 'কুরআন থেকে',
  type: 'general',
  arabic: 'بسم الله',
  transliteration: 'bismillah',
  bangla: 'বিসমিল্লাহ',
  source: 'সূরা আল-ফাতিহা',
  authenticity: 'কুরআনের আয়াত',
  count: 3,
  level: 1,
);

const _duaNoReading = DuaItem(
  id: 'no_reading',
  section: 'কুরআন থেকে',
  type: 'general',
  arabic: 'ا',
  transliteration: '   ',
  bangla: 'কিছু',
  source: '',
  authenticity: '',
  count: null,
  level: 1,
);

ReviewUnit u(String key) => ReviewUnit(
  key: key,
  kind: 'শব্দ',
  arabic: 'ا',
  reading: 'alif',
  bangla: 'আলিফ',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('review_content_test');
    Hive.init(dir.path);
    for (final b in [
      'deen_arabic',
      'deen_settings',
      'salah_log',
      'amal_log',
      'tasbih_session',
      'deen_meta',
      'memorization',
      'deen_review',
    ]) {
      await Hive.openBox(b);
    }
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('units carry words, vocab and duas with their own keys', () async {
    final list = await ReviewContent.units(
      words: const [_word],
      vocab: const [_vocab],
      duas: const [_dua],
    );
    expect(list.map((e) => e.key), ['w1', 'vocab:v1', 'dua-learn:dua_3qul']);
    expect(list.map((e) => e.kind), ['শব্দ', 'শব্দভাণ্ডার', 'দুআ']);
    expect(list.last.bangla, 'বিসমিল্লাহ');
  });

  test('a dua with no transliteration is skipped — পড়া যায় না', () async {
    final list = await ReviewContent.units(duas: const [_duaNoReading]);
    expect(list, isEmpty);
  });

  test('backfill pulls in known items from before the feature existed', () async {
    DeenStore.arabicMark('w1');
    ReviewScheduler.forget('w1');
    expect(ReviewScheduler.get('w1'), null, reason: 'আগের সংস্করণে ছিল না');

    final added = await ReviewContent.backfill(units: [u('w1')]);
    expect(added, 1);
    expect(ReviewScheduler.get('w1'), isNotNull);
    expect(ReviewScheduler.get('w1')!.due.isNotEmpty, true);
  });

  test('backfill ignores known items the review screen cannot show', () async {
    // অক্ষর/কুরআন-পঠন নিজস্ব পথে ফিরে আসে, তাই এখানে ঢোকা উচিত নয়
    DeenStore.arabicMark('letter:ا');
    ReviewScheduler.forget('letter:ا');
    final added = await ReviewContent.backfill(units: [u('w1')]);
    expect(added, 0);
    expect(ReviewScheduler.get('letter:ا'), null);
  });

  test('backfill is idempotent — it never resets progress', () async {
    DeenStore.arabicMark('w1');
    ReviewScheduler.rate('w1', easy: true);
    expect(ReviewScheduler.get('w1')!.box, 1);

    final again = await ReviewContent.backfill(units: [u('w1')]);
    expect(again, 0);
    expect(ReviewScheduler.get('w1')!.box, 1, reason: 'বাক্স মুছে যাবে না');
  });

  test('dueCount counts only units the screen can actually show', () async {
    // নতুন key — আগের টেস্টে রেট হয়ে যাওয়া key ব্যবহার করলে গণনা ভাঙবে
    final units = [u('d1'), u('d2')];
    ReviewScheduler.seed('d1');
    ReviewScheduler.seed('d2');
    ReviewScheduler.seed('letter:ز');

    expect(ReviewScheduler.dueCount, 3, reason: 'raw গণনা সব key ধরে');
    expect(await ReviewContent.dueCount(units: units), 2);
  });
}
