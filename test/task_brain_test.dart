import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/command_parser.dart';
import 'package:lifeos/services/task_brain.dart';

void main() {
  group('TaskBrain — shopping tree', () {
    test('items + quantities + deadline পার্স', () {
      final b = TaskBrain.analyze(
          'কাল বিকাল ৫টায় বাজার থেকে মাছ ২ কেজি আর আলু ৫ কেজি কিনবো');
      expect(b, isNotNull);
      expect(b!.category, 'Shopping');
      expect(b.priority, 1);
      expect(b.items.length, 2);
      expect(b.items[0].name, 'মাছ');
      expect(b.items[0].qty, 2);
      expect(b.items[0].unit, 'kg');
      expect(b.items[0].emoji, '🐟');
      expect(b.items[1].name, 'আলু');
      expect(b.items[1].qty, 5);
    });

    test('আগামীকাল সকাল ৮টা → priority + Study', () {
      final b = TaskBrain.analyze(
          'আগামীকাল সকাল ৮টায় জরুরি করে ফ্লাটার শিখবো');
      expect(b, isNotNull);
      expect(b!.priority, 2);
      expect(b.category, 'Study');
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(b.deadline!.day, tomorrow.day);
      expect(b.deadline!.hour, 8);
      expect(b.deadline!.minute, 0);
    });

    test('expected cost ধরা পড়ে', () {
      final b = TaskBrain.analyze('বাজার থেকে মাছ কিনবো 500 টাকা');
      expect(b, isNotNull);
      expect(b!.expectedCost, 500);
      expect(b.category, 'Shopping');
    });

    test('আজ সন্ধ্যা ৬টা → today evening', () {
      final b = TaskBrain.analyze('আজ সন্ধ্যা ৬টায় কোল্ড কফি কিনবো');
      expect(b, isNotNull);
      expect(b!.deadline!.day, DateTime.now().day);
      expect(b.deadline!.hour, 18);
    });

    test('plain task without deadline words defaults', () {
      final b = TaskBrain.analyze('Room Clean করবো');
      expect(b, isNotNull);
      expect(b!.category, 'Home');
    });
  });

  group('Recurrence (P4)', () {
    test('প্রতি দিন → daily recurrence', () {
      final b = TaskBrain.analyze('প্রতি দিন সকাল ৯টায় দাঁত ব্রাশ করবো');
      expect(b, isNotNull);
      final r = b!.recurrence;
      expect(r, isNotNull);
      expect(r!.unit, 'daily');
      expect(r.interval, 1);
      expect(b.deadline!.hour, 9);
    });

    test('প্রতি ২ দিন → interval 2 daily', () {
      final r = CommandParser.parseRecurrence('প্রতি ২ দিন ওষুধ খাবো');
      expect(r, isNotNull);
      expect(r!.unit, 'daily');
      expect(r.interval, 2);
    });

    test('প্রতি সোমবার → weekly সোমবার (weekday 1)', () {
      final r = CommandParser.parseRecurrence('প্রতি সোমবার বই পড়বো');
      expect(r, isNotNull);
      expect(r!.unit, 'weekly');
      expect(r.weekdays, [1]);
    });

    test('প্রতি সপ্তাহে → weekly', () {
      final r = CommandParser.parseRecurrence('প্রতি সপ্তাহে রিপোর্ট দেবো');
      expect(r, isNotNull);
      expect(r!.unit, 'weekly');
      expect(r.weekdays, isEmpty);
    });

    test('প্রতি মাসে → monthly', () {
      final r = CommandParser.parseRecurrence('প্রতি মাসে বিল দেবো');
      expect(r, isNotNull);
      expect(r!.unit, 'monthly');
    });

    test('বিনা recurrence শব্দে null', () {
      expect(CommandParser.parseRecurrence('গণিত পড়বো'), isNull);
      expect(CommandParser.parseRecurrence('ঘর পরিষ্কার করবো'), isNull);
    });

    test('nextOccurrence daily আয়নের পরের দিন', () {
      final rec = const Recurrence(unit: 'daily', hour: 9);
      final from = DateTime(2026, 9, 25, 20, 0);
      final next = rec.nextOccurrence(from: from);
      expect(next.day, 26);
      expect(next.hour, 9);
    });

    test('nextOccurrence weekly সোমবার → পরের সোমবার', () {
      // 2026-09-25 শুক্রবার
      final rec = const Recurrence(unit: 'weekly', weekdays: [1]);
      final from = DateTime(2026, 9, 25, 20, 0);
      final next = rec.nextOccurrence(from: from);
      expect(next.weekday, DateTime.monday);
      expect(next.day, 28);
    });

    test('nextOccurrence monthly month-end clamp', () {
      final rec = const Recurrence(unit: 'monthly');
      final from = DateTime(2026, 1, 31, 20, 0);
      final next = rec.nextOccurrence(from: from);
      expect(next.month, 2);
      expect(next.day, 28);
    });
  });
}