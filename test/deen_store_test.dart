import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/deen_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('deen_hive_test');
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

  test('mem mark/unmark roundtrip', () {
    const k = 'mem:114:1';
    expect(DeenStore.quranMems().contains(k), false);
    DeenStore.quranMemMark(k);
    expect(DeenStore.quranMems().contains(k), true);
    DeenStore.quranMemUnmark(k);
    expect(DeenStore.quranMems().contains(k), false);
  });

  test('read mark persists into quranReads only for read: prefix', () {
    const aKey = 'read:114:1';
    const other = 'word:bismillah';
    DeenStore.arabicMark(aKey);
    DeenStore.arabicMark(other);
    expect(DeenStore.quranReads().contains(aKey), true);
    expect(DeenStore.quranReads().contains('read:114:2'), false);
    expect(DeenStore.quranReads().contains(other), false);
    expect(DeenStore.isArabicKnown(aKey), true);
    DeenStore.arabicUnmark(aKey);
    DeenStore.arabicUnmark(other);
    expect(DeenStore.quranReads().contains(aKey), false);
  });
}
