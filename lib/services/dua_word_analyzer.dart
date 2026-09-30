import 'package:lifeos/services/arabic_quran_text.dart';
import 'package:lifeos/services/arabic_seed.dart';

/// একটি তাশকিল/হরকত চিহ্ন — দোয়ার শব্দ ভাঙার সময় ব্যবহার।
class DuaMark {
  final String mark;
  final String name;

  const DuaMark(this.mark, this.name);
}

/// একটি অক্ষার + তার উপরে/নিচে থাকা চিহ্নগুলো।
class DuaLetterSeg {
  final String letter;
  final List<DuaMark> marks;

  const DuaLetterSeg(this.letter, this.marks);

  String get glyph => letter + marks.map((m) => m.mark).join();
  String get markNames => marks.map((m) => m.name).join(', ');
}

/// দোয়ার একটি শব্দ — তাশকিলসহ মূল রূপ, মূল স্পেলিং ও অক্ষর-ভাঙা।
class DuaWordInfo {
  final String raw;
  final String base;
  final List<DuaLetterSeg> segments;

  const DuaWordInfo({
    required this.raw,
    required this.base,
    required this.segments,
  });
}

/// দোয়া ↔ আরবি পড়ার সেতু: শব্দ ভাঙা + অ্যাপের যাচাইকৃত শব্দ-ভাণ্ডারে খোঁজা।
class DuaWordAnalyzer {
  DuaWordAnalyzer._();

  /// হরকত/তাশকিল চিহ্ন → বাংলা নাম।
  static const markNames = <String, String>{
    '\u064E': 'ফাত্হা',
    '\u064F': 'ডাম্মা',
    '\u0650': 'কাসরা',
    '\u0652': 'সুকুন',
    '\u0651': 'শাদ্দ',
    '\u064B': 'তানভীন',
    '\u064C': 'তানভীন',
    '\u064D': 'তানভীন',
    '\u0653': 'মাদ্দাহ',
    '\u0654': 'মাদ্দাহ',
    '\u0655': 'হাম্জা',
    '\u0670': 'দাগড় আলিফ',
    '\u0656': 'বিপর্যয় আলিফ',
    '\u0657': 'হাম্জা',
    '\u0658': 'হাম্জা',
    '\u06DB': 'ছোট কার',
    '\u06E2': 'ছোট মীম',
    '\u06E5': 'ছোট হা',
  };

  /// আরবি বর্ণমালার অক্ষর কোড-রেঞ্জ (হামজা থেকে ইয়া-পর্যন্ত)।
  static bool _isLetter(int c) => c >= 0x0621 && c <= 0x064A;

  /// তাশকিল-মুক্ত স্পেলিং — তুলনার জন্য (আলেফ/হামজা একীভূত, তাত্বিল বাদ)।
  static String normalize(String s) => s
      .replaceAll(arMarks, '')
      .replaceAll('\u0640', '')
      .replaceAll(alefForms, '\u0627')
      .trim();

  /// দোয়ার লাইনকে শব্দে ভাঙা (RTL-এর জন্য মিলিয়ে)।
  static List<String> splitWords(String arabic) => arabic
      .split(RegExp(r'\s+'))
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty)
      .toList();

  /// একটি শব্দ অক্ষর + চিহ্নে ভাঙা।
  static DuaWordInfo analyze(String raw) {
    final segs = <DuaLetterSeg>[];
    for (final rune in raw.trim().runes) {
      if (_isLetter(rune)) {
        segs.add(DuaLetterSeg(String.fromCharCode(rune), const []));
      } else if (segs.isNotEmpty) {
        final m = markNames[String.fromCharCode(rune)];
        if (m != null) {
          final last = segs.removeLast();
          segs.add(
            DuaLetterSeg(last.letter, [...last.marks, DuaMark(String.fromCharCode(rune), m)]),
          );
        }
        // অন্য চিহ্ন (যম-আমির মতো Q-মার্ক) — উপেক্ষা, কিন্তু অক্ষর ধরে রাখি
      }
    }
    return DuaWordInfo(
      raw: raw.trim(),
      base: normalize(raw),
      segments: segs,
    );
  }
}

/// অ্যাপের যাচাইকৃত ভাণ্ডারে (শব্দ চর্চা / কুরআন শব্দ / বর্ণমালা) শব্দটি খোঁজে।
class DuaWordLookup {
  DuaWordLookup._();

  static Future<Map<String, ArabicWordItem>>? _words;
  static Future<Map<String, VocabItem>>? _vocab;
  static Future<Map<String, ArabicLetterItem>>? _letters;

  static Future<Map<String, ArabicWordItem>> _wordMap() =>
      _words ??= _buildWords();
  static Future<Map<String, VocabItem>> _vocabMap() =>
      _vocab ??= _buildVocab();
  static Future<Map<String, ArabicLetterItem>> _letterMap() =>
      _letters ??= _buildLetters();

  static Future<Map<String, ArabicWordItem>> _buildWords() async {
    final m = <String, ArabicWordItem>{};
    for (final w in await ArabicSeed.words()) {
      m[DuaWordAnalyzer.normalize(w.arabic)] = w;
    }
    return m;
  }

  static Future<Map<String, VocabItem>> _buildVocab() async {
    final m = <String, VocabItem>{};
    for (final v in await ArabicSeed.vocab()) {
      m[DuaWordAnalyzer.normalize(v.arabic)] = v;
    }
    return m;
  }

  static Future<Map<String, ArabicLetterItem>> _buildLetters() async {
    final m = <String, ArabicLetterItem>{};
    for (final l in await ArabicSeed.letters()) {
      m[DuaWordAnalyzer.normalize(l.letter)] = l;
    }
    return m;
  }

  static Future<ArabicWordItem?> word(String base) async =>
      (await _wordMap())[base];

  static Future<VocabItem?> vocab(String base) async =>
      (await _vocabMap())[base];

  /// একটি বর্ণ — ২৮ অক্ষরের ভাণ্ডারে থাকলে তার তথ্য, না থাকলে null।
  static Future<ArabicLetterItem?> letter(String ch) async =>
      (await _letterMap())[DuaWordAnalyzer.normalize(ch)];
}
