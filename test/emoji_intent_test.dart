import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/emoji_intent.dart';
import 'package:lifeos/services/text_normalizer.dart';

void main() {
  group('EmojiIntent — প্রসঙ্গ-সচেতন এমোজি', () {
    test('activity সময়-এর আগে', () {
      expect(EmojiIntent.pick('রাতে ব্যায়াম'), '🏋️');
      expect(EmojiIntent.pick('রাতে'), '🌙');
    });

    test('ক্যাটাগরি picks', () {
      expect(EmojiIntent.pick('বাজার থেকে'), '🛒');
      expect(EmojiIntent.pick('ডাক্তারের কাছে'), '💊');
      expect(EmojiIntent.pick('লন্ড্রি করবো'), '🧺');
      expect(EmojiIntent.pick('ফ্লাটার শিখবো'), '📚');
      expect(EmojiIntent.pick('সকালে ঘুম ভাঙবে'), '😴');
      expect(EmojiIntent.pick('ওষুধ কিনবো'), '💊');
    });

    test('চেনা না হলে 📌', () {
      expect(EmojiIntent.pick('random কথাবার্তা'), '📌');
      expect(EmojiIntent.pick(''), '📌');
    });

    test('learned emoji প্রথমে', () {
      expect(EmojiIntent.pick('বাজার', learned: {'বাজার': '🧺'}), '🧺');
    });
  });

  group('TextNormalizer + learned', () {
    test('learned সংশোধন merge হয়', () {
      final r = TextNormalizer.run('মাচ কিনবো', learned: {'মাচ': 'মাছ'});
      expect(r.text, 'মাছ কিনবো');
    });

    test('learned ছাড়া একই থাকে', () {
      expect(TextNormalizer.run('মাচ কিনবো').text, 'মাচ কিনবো');
    });
  });
}