import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/ai_fix_store.dart';
import 'package:lifeos/services/text_normalizer.dart';

void main() {
  late Directory tmp;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('lifos_ai_fix_test');
    Hive.init(tmp.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await AiFixStore.init();
    await AiFixStore.clear();
  });

  tearDown(() async {
    await AiFixStore.clear();
  });

  group('AiFixStore — online-AI-এর শেখা জমা', () {
    test('fix শেখা → read + emoji', () async {
      await AiFixStore.rememberFixes([const TextFix('মাচ', 'মাছ')]);
      await AiFixStore.rememberEmojis([const MapEntry('বাজার', '🧺')]);
      expect(AiFixStore.learnedWords['মাচ'], 'মাছ');
      expect(AiFixStore.learnedEmoji['বাজার'], '🧺');
      await AiFixStore.forgetWord('মাচ');
      expect(AiFixStore.learnedWords.containsKey('মাচ'), isFalse);
    });

    test('শেখা offline normalize-এ ব্যবহার হয়', () async {
      await AiFixStore.rememberFixes([const TextFix('মাচ', 'মাছ')]);
      final r = await AiEnhancer.enhance('মাচ কিনবো');
      expect(r.usedOnline, isFalse);
      expect(r.source, 'offline');
      expect(r.normalized.text, 'মাছ কিনবো');
      expect(r.tree.title, 'মাছ কিনবো');
    });

    test('শেখা emoji parser-এ প্রাধান্য পায়', () async {
      await AiFixStore.rememberEmojis([const MapEntry('বাজার', '🧺')]);
      final r = await AiEnhancer.enhance('বাজার থেকে কিনবো');
      expect(r.tree.titleEmoji, '🧺');
    });

    test('online key নেই → offline fallback', () async {
      final r = await AiEnhancer.enhance(
        '2kg alu kinbo',
        allowOnline: true,
        geminiKey: '',
      );
      expect(r.usedOnline, isFalse);
      expect(r.tree.nodes.single.text, 'বাজার');
    });
  });
}