import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';

/// অ্যাপে যেটা ইনস্টল করা আছে তা ঠিক না — যাচাইকৃত অক্ষর-পড়া
/// বানানো নয়, কেবল অ্যাপের নিজস্ব ফাইল থেকে নেওয়া।
void seedLetters(List<Map<String, dynamic>> letters) {
  Hive.box('content_data').put(
    'arabic/letters.json',
    jsonEncode({'letters': letters}),
  );
  Hive.box('content_meta').put('arabic/letters.json', {
    'v': 1,
    'bytes': 1,
    'updated': DateTime.now().toIso8601String(),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('pronouncer_test');
    Hive.init(dir.path);
    await Hive.openBox('content_data');
    await Hive.openBox('content_meta');
    await Hive.openBox('deen_arabic');
    await Hive.openBox('deen_settings');
    await Hive.openBox('salah_log');
    await Hive.openBox('amal_log');
    await Hive.openBox('tasbih_session');
    await Hive.openBox('deen_meta');
    await Hive.openBox('memorization');
    await Hive.openBox('deen_review');

    // অ্যাপের যাচাইকৃত অক্ষর-তালিকার একটি ছোট অংশ
    seedLetters([
      {
        'id': 'l_ba',
        'letter': 'ب',
        'name': 'বা',
        'reading': 'ba',
        'isolated': 'ب',
        'initial': 'بـ',
        'medial': 'ـبـ',
        'final': 'ـب',
        'example': 'باب',
        'exampleReading': 'bab',
        'exampleBangla': 'দরজা',
        'connectsForward': true,
      },
      {
        'id': 'l_ain_no_reading',
        'letter': 'ع',
        'name': 'আইন',
        'reading': '',
        'isolated': 'ع',
        'initial': 'عـ',
        'medial': 'ـعـ',
        'final': 'ـع',
        'example': '',
        'exampleReading': '',
        'exampleBangla': '',
        'connectsForward': true,
      },
      {
        'id': 'l_ta_marbuta',
        'letter': 'ة',
        'name': 'তা মারবূতা',
        'reading': 'ta marbuta',
        'isolated': 'ة',
        'initial': '',
        'medial': '',
        'final': 'ة',
        'example': '',
        'exampleReading': '',
        'exampleBangla': '',
        'connectsForward': false,
      },
    ]);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('a word breaks into letters that keep their marks', () async {
    final g = await DuaPronouncer.of('بِسْمِ');
    expect(g, isNotNull);
    expect(g!.base, 'بسم');
    expect(g.syllables.map((s) => s.letter).join(''), 'بسم');
    // তাশকিল চিহ্ন গ্লাইফে থাকে, হারিয়ে যায় না
    expect(g.syllables.first.glyph.contains('ِ'), true);
    expect(g.syllables.first.marks, isNotEmpty);
    // যাচাইকৃত পড়া বসেছে
    expect(g.syllables.first.reading, 'ba');
  });

  test('a letter with no verified reading is left blank, not invented', () async {
    final g = await DuaPronouncer.of('ع');
    expect(g, isNotNull);
    expect(g!.syllables.first.reading, '');
    expect(g.syllables.first.bangla, 'আইন', reason: 'নামটা যাচাইকৃত');
  });

  test('a letter absent from the app data is still shown, reading blank',
      () async {
    final g = await DuaPronouncer.of('ص');
    expect(g, isNotNull);
    expect(g!.syllables.first.letter, 'ص');
    expect(g.syllables.first.reading, '', reason: 'অজানা অক্ষরে ভুল পড়া নয়');
    expect(g.syllables.first.glyph, 'ص', reason: 'গ্লাইফ তবু দেখানো হয়');
  });

  test('words() breaks a line word by word, without duplicates', () async {
    final list = await DuaPronouncer.words('بِبَابٌ بِبَابٌ');
    expect(list, isNotEmpty);
    final bases = list.map((w) => w.base).toList();
    expect(bases.toSet().length, bases.length, reason: 'একই শব্দ দুবার নয়');
    for (final w in list) {
      expect(w.syllables, isNotEmpty);
    }
  });

  test('words() honours the limit so the card does not grow forever', () async {
    final long = '${'بِ ' * 40}';
    final list = await DuaPronouncer.words(long, limit: 5);
    expect(list.length, lessThanOrEqualTo(5));
  });

  test('an empty or mark-only string yields no guide', () async {
    expect(await DuaPronouncer.of(''), isNull);
    expect(await DuaPronouncer.of('   '), isNull);
    expect(await DuaPronouncer.words(''), isEmpty);
  });
}
