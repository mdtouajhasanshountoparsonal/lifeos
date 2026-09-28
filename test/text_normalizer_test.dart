import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/text_normalizer.dart';

void main() {
  group('TextNormalizer — বাংলিশ → বাংলা', () {
    test('p1 উদাহরণ: kaj 3ta mach 2kg alu kinbo', () {
      final r = TextNormalizer.run('kaj 3ta mach 2kg alu kinbo');
      expect(r.text, 'কাজ ৩টা মাছ ২ কেজি আলু কিনবো');
      expect(r.sentences.length, 1);
      expect(r.fixCount, greaterThan(0));
    });

    test('একাধিক ইউনিট + রোমান r/dal', () {
      final r = TextNormalizer.run('2kg alu r 500 gm dal');
      expect(r.text, '২ কেজি আলু আর ৫০০ গ্রাম ডাল');
    });

    test('দশমিক ওয়েট: 2.5 kg', () {
      final r = TextNormalizer.run('bazar theke 2.5 kg alu kinbo');
      expect(r.text, 'বাজার থেকে ২.৫ কেজি আলু কিনবো');
    });

    test('currency: 500 টাকা → ৫০০ টাকা', () {
      final r = TextNormalizer.run('এখন 500 টাকা লাগবে');
      expect(r.text, 'এখন ৫০০ টাকা লাগবে');
    });

    test('tk সংক্ষেপও কাজ করে', () {
      expect(TextNormalizer.normalize('500 tk রিজার্ভ'), '৫০০ টাকা রিজার্ভ');
    });
  });

  group('TextNormalizer — বানান ও সাজেশন', () {
    test('বাংলা টাইপো ঠিক হয়', () {
      final r = TextNormalizer.run('সকালে আসতে নাগের');
      expect(r.text, 'সকালে আসতে হবে');
      expect(r.fixes.any((f) => f.before == 'নাগের' && f.after == 'হবে'), isTrue);
    });

    test('sentence case: বাক্যের ASCII শুরু বড় হয়', () {
      final r = TextNormalizer.run('kaj done hoy. go home');
      expect(r.text, 'কাজ done হয়. Go home');
    });

    test('বাক্য ভাগ করা হয়', () {
      final s = TextNormalizer.splitSentences('আজ কাজ করবো। তারপর ঘুমাবো।');
      expect(s.length, 2);
      expect(s[0], 'আজ কাজ করবো।');
      expect(s[1], 'তারপর ঘুমাবো।');
      expect(s.first.endsWith('।'), isTrue);
    });

    test('দশমিক সংখ্যা বাক্য-ভাগ ভাঙে না', () {
      final s = TextNormalizer.splitSentences('আলু ২.৫ কেজি। তারপর যাবো।');
      expect(s.length, 2);
      expect(s[0], 'আলু ২.৫ কেজি।');
    });

    test('ফাঁকা টেক্সট', () {
      final r = TextNormalizer.run('   ');
      expect(r.text, isEmpty);
      expect(r.sentences, isEmpty);
    });
  });

  group('TextNormalizer — সংরক্ষণ', () {
    test('fix রেকর্ড হয় (✨ badge-এর জন্য)', () {
      final r = TextNormalizer.run('kinbo 3ta dim');
      expect(r.fixes.any((f) => f.before == 'kinbo'), isTrue);
      expect(r.fixes.any((f) => f.before == '3ta'), isTrue);
    });
  });
}