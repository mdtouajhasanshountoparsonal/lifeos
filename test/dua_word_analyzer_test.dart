import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';

void main() {
  test('splitWords splits on whitespace and drops empties', () {
    expect(DuaWordAnalyzer.splitWords('بِسْمِ  اللَّهِ\nالرَّحْمَٰنِ'),
        ['بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ']);
    expect(DuaWordAnalyzer.splitWords('   '), isEmpty);
  });

  test('analyze breaks a word into letters + named harakat', () {
    final i = DuaWordAnalyzer.analyze('رَبِّ');
    expect(i.base, 'رب');
    expect(i.segments.length, 2);
    expect(i.segments[0].letter, 'ر');
    expect(i.segments[0].marks.map((m) => m.name), contains('ফাত্হা'));
    expect(i.segments[1].letter, 'ب');
    expect(i.segments[1].marks.map((m) => m.name), contains('শাদ্দ'));
    expect(i.segments[1].marks.map((m) => m.name), contains('কাসরা'));
  });

  test('normalize folds alef forms and drops tatweel', () {
    expect(DuaWordAnalyzer.normalize('أَحْمَد'), 'احمد');
    expect(DuaWordAnalyzer.normalize('كــتَاب'), 'كتاب');
  });

  test('younus dua style word is segmented with sukun', () {
    final i = DuaWordAnalyzer.analyze('سُبْحَانَكَ');
    expect(i.base, 'سبحانك');
    expect(i.segments.length, 6);
    expect(i.segments[1].marks.single.name, 'সুকুন');
  });
}
