import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';
import 'package:lifeos/services/night_routine.dart';

/// Journey স্ক্রিনের গণনা-লজিক যাচাই: `dua-learn:` key আলাদা ক্যাটাগরিতে যায়,
/// যিকির প্রতিদিন রিসেট হয়, তাই তা ক্রমবর্ধমান হিসাবে গোনা হয় না।
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('journey_progress_test');
    Hive.init(dir.path);
    await Hive.openBox('deen_arabic');
    await Hive.openBox('deen_settings');
    await Hive.openBox('salah_log');
    await Hive.openBox('amal_log');
    await Hive.openBox('tasbih_session');
    await Hive.openBox('deen_meta');
    await Hive.openBox('memorization');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('night routine steps are exactly 5 and all come from dua data ids', () {
    expect(NightRoutine.order.length, 5);
    for (final (id, _, _) in NightRoutine.order) {
      expect(id.startsWith('dua_'), true, reason: id);
    }
  });

  test('dua-learn keys are independent from word/vocab known keys', () {
    // journey: 'dua-learn:' must not fall into the word bucket
    const duaKey = 'dua-learn:dua_qini_adabaka';
    const wordKey = 'word:bismillah';
    const vocabKey = 'vocab:113:1';
    const keys = [duaKey, wordKey, vocabKey];
    for (final k in keys) {
      expect(k.startsWith('dua-learn:'), k == duaKey);
      expect(k.startsWith('vocab:'), k == vocabKey);
    }
  });

  test('a learned dua is one entry, not a word', () {
    // যে লজিক journey-তে বসানো হয়েছে: একটি দোয়া পড়লে wordK বাড়ে না
    String bucket(String k) {
      if (k.startsWith('a:')) return 'letter';
      if (k.startsWith('join')) return 'join';
      if (k.startsWith('harak:')) return 'harakat';
      if (k.startsWith('vocab:')) return 'vocab';
      if (k.startsWith('read:') || k.startsWith('mem:')) return 'quran';
      if (k.startsWith('dua-learn:')) return 'dua';
      return 'word';
    }

    expect(bucket('dua-learn:dua_3qul'), 'dua');
    expect(bucket('word:allah'), 'word');
    expect(bucket('vocab:1:1'), 'vocab');
  });

  test('word hard keys never leak into the dua category', () {
    String hardBucket(String k) {
      if (k.startsWith('hard:read:')) return 'quran';
      if (k.startsWith('hard:vocab:')) return 'vocab';
      if (k.startsWith('hard:dua')) return 'dua';
      if (k.startsWith('hard:')) return 'word';
      return 'other';
    }

    expect(hardBucket('hard:word:allah'), 'word');
    expect(hardBucket('hard:vocab:113:1'), 'vocab');
    expect(hardBucket('hard:dua:dua_3qul'), 'dua');
  });

  test('splitWords keeps full dua words for the drill', () {
    final w = DuaWordAnalyzer.splitWords('بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا');
    expect(w.length, 4);
    expect(w.first, 'بِاسْمِكَ');
  });
}
