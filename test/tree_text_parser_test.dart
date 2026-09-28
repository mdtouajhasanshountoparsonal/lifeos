import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/tree_text_parser.dart';

void main() {
  group('TreeTextParser — টেক্সট → গাছ', () {
    test('মাপের আইটেম শপিং-নোডের child হয়', () {
      final t = TreeTextParser.parse('আজ ৩টা মাছ আর ২ কেজি আলু কিনবো');
      expect(t.wasEmpty, isFalse);
      expect(t.title, 'আজ আর কিনবো');
      expect(t.nodes.length, 1);
      final shop = t.nodes[0];
      expect(shop.text, 'বাজার');
      expect(shop.emoji, '🛒');
      expect(shop.children.length, 2);
      expect(shop.children[0].emoji, '🐟');
      expect(shop.children[0].text, 'মাছ ৩টা');
      expect(shop.children[1].emoji, '🥔');
      expect(shop.children[1].text, 'আলু ২ কেজি');
    });

    test('সংযোগকারী ধরে নোড ভাগ হয়', () {
      final t = TreeTextParser.parse('গণিত চর্চা করবো তারপর ব্যায়াম করবো');
      expect(t.title, 'গণিত চর্চা করবো');
      expect(t.nodes.length, 1);
      expect(t.nodes[0].text, 'ব্যায়াম করবো');
      expect(t.nodes[0].emoji, '🏋️');
    });

    test('p1-উদাহরণ end-to-end (বাংলিশ + item + তারপর)', () {
      final t = TreeTextParser.parse(
          'kaj 3ta mach 2kg alu kinter por basay fira laundry korbo tarpor raatay byaayam');
      expect(t.title, 'কাজ কিনতে পরে বাসায় ফিরে লন্ড্রি করবো');
      expect(t.fixCount, greaterThan(0));
      final shop = t.nodes.firstWhere((n) => n.text == 'বাজার');
      expect(shop.children.map((c) => c.text), ['মাছ ৩টা', 'আলু ২ কেজি']);
      final workout = t.nodes.firstWhere((n) => n.emoji == '🏋️');
      expect(workout.text, 'রাতে ব্যায়াম');
    });

    test('শুধু এক বাক্য → শুধু শিরোনাম', () {
      final t = TreeTextParser.parse('ফ্লাটার শিখবো');
      expect(t.title, 'ফ্লাটার শিখবো');
      expect(t.nodes, isEmpty);
    });

    test('খালি টেক্সট → wasEmpty', () {
      final t = TreeTextParser.parse('   ');
      expect(t.wasEmpty, isTrue);
      expect(t.title, isEmpty);
    });
  });
}