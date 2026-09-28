import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/market_parser.dart';

void main() {
  group('icon dictionary', () {
    test('bangla items map to icons', () {
      expect(marketEmoji('আলু'), '🥔');
      expect(marketEmoji('বেগুন'), '🍆');
      expect(marketEmoji('কুমড়া'), '🎃');
      expect(marketEmoji('পেঁয়াজ'), '🧅');
      expect(marketEmoji('মাছ'), '🐟');
      expect(marketEmoji('ডিম'), '🥚');
      expect(marketEmoji('এলোমেলো জিনিস'), '🛍️');
    });

    test('english + mixed typed', () {
      expect(marketEmoji('alu'), '🥔');
      expect(marketEmoji('potato'), '🥔');
      expect(marketEmoji('egg'), '🥚');
    });
  });

  group('number parser', () {
    test('bangla digits convert', () {
      expect(parseNumber('৫০'), 50);
      expect(parseNumber('১২.৫'), 12.5);
      expect(parseNumber('10'), 10);
    });
  });

  group('market line parser', () {
    test('qty unit price', () {
      final it = parseMarketLine('আলু 10 kg 50', 2)!;
      expect(it.label, 'আলু');
      expect(it.qty, 10);
      expect(it.unit, 'kg');
      expect(it.unitPrice, 50);
      expect(it.total, 500);
      expect(it.line, 2);
      expect(it.emoji, '🥔');
    });

    test('qty x price (piece)', () {
      final it = parseMarketLine('ডিম 12 x 10', 0)!;
      expect(it.qty, 12);
      expect(it.unit, isNull);
      expect(it.total, 120);
    });

    test('bangla qty + unit + price', () {
      final it = parseMarketLine('পেঁয়াজ ২ কেজি ৬০', 1)!;
      expect(it.qty, 2);
      expect(it.unit, 'kg');
      expect(it.total, 120);
    });

    test('single number = price', () {
      final it = parseMarketLine('আলু ৫০', 0)!;
      expect(it.qty, isNull);
      expect(it.unitPrice, 50);
      expect(it.total, 50);
    });

    test('non-market lines ignored', () {
      expect(parseMarketLine('আজকের বাজার', 0), isNull);
      expect(parseMarketLine('# আজকের বাজার', 0), isNull);
      expect(parseMarketLine('আলু কিনতে হবে অনেক', 0), isNull);
    });

    test('glued unit token splits (10kg, 12x)', () {
      final it = parseMarketLine('আলু 10kg 50', 0)!;
      expect(it.qty, 10);
      expect(it.unit, 'kg');
      expect(it.total, 500);
      final it2 = parseMarketLine('ডিম 12x 10', 0)!;
      expect(it2.qty, 12);
      expect(it2.total, 120);
      final it3 = parseMarketLine('দুধ 2 বোতল 40', 0)!;
      expect(it3.unit, 'bot');
      expect(it3.total, 80);
    });
  });

  group('full content', () {
    test('grand total', () {
      const content = '# আজকের বাজার\nআলু 10 kg 50\nবেগুন 2 kg 30\nমাছ 450\n';
      final items = parseMarketItems(content);
      expect(items.length, 3);
      expect(marketTotal(items), 10 * 50 + 2 * 30 + 450);
      expect(marketTotalText(items), '৳1010');
    });
  });

  group('sections', () {
    test('## sections group items + subtotal', () {
      const content =
          '## সবজি\nআলু 10 kg 50\nবেগুন 2 kg 30\n'
          '## মাছ\nইলিশ 2 kg 700\n'
          '## মাংস\nগরু 1 kg 850';
      final secs = parseMarketSections(content);
      expect(secs.length, 3);
      expect(secs[0].title, 'সবজি');
      expect(secs[0].items.length, 2);
      expect(secs[0].subtotal, 500 + 60);
      expect(secs[1].title, 'মাছ');
      expect(secs[1].subtotal, 1400);
      expect(secs[2].title, 'মাংস');
      expect(secs[2].subtotal, 850);
      final all = secs.expand((s) => s.items).toList();
      expect(marketTotal(all), 500 + 60 + 1400 + 850);
    });

    test('items before any heading go to title-null section', () {
      const content = 'আলু 10 kg 50\n## মাছ\nইলিশ 450';
      final secs = parseMarketSections(content);
      expect(secs.length, 2);
      expect(secs[0].title, isNull);
      expect(secs[0].emoji, '🧺');
      expect(secs[0].items.length, 1);
      expect(secs[1].title, 'মাছ');
      expect(secs[1].emoji, '🐟');
    });

    test('heading with bold markup', () {
      const content = '## **সবজি**\nআলু 50';
      final secs = parseMarketSections(content);
      expect(secs.length, 1);
      expect(secs[0].title, 'সবজি');
    });
  });
}
