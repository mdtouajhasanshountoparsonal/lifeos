import 'dart:convert';

import 'package:flutter/services.dart';

/// আরবি বর্ণমালার ফন্ট — কুরআন পড়া শেখার path।
class ArabicLetterItem {
  final String id;
  final String letter; // isolated রূপ (বড় দেখাতে)
  final String name; // বাংলা নাম
  final String reading; // বাংলা উচ্চারণ
  final String isolated;
  final String initial;
  final String medial;
  final String finalJ;
  final String example; // example word (আরবি)
  final String exampleReading;
  final String exampleBangla;
  final bool connectsForward;

  const ArabicLetterItem({
    required this.id,
    required this.letter,
    required this.name,
    required this.reading,
    required this.isolated,
    required this.initial,
    required this.medial,
    required this.finalJ,
    required this.example,
    required this.exampleReading,
    required this.exampleBangla,
    required this.connectsForward,
  });
}

/// হরকত (স্বরচিহ্ন)।
class HarakaItem {
  final String id;
  final String name;
  final String mark; // ব-এর ওপর demo: بَ
  final String reading;
  final String bangla;

  const HarakaItem({
    required this.id,
    required this.name,
    required this.mark,
    required this.reading,
    required this.bangla,
  });
}

/// শব্দ পড়ার চর্চা।
class ArabicWordItem {
  final String id;
  final String arabic;
  final String reading;
  final String bangla;
  final String source;

  const ArabicWordItem({
    required this.id,
    required this.arabic,
    required this.reading,
    required this.bangla,
    required this.source,
  });

  bool get hasSource => source.trim().isNotEmpty;
}

/// কুরআনের শব্দ (word-by-word)।
class QuranWordItem {
  final String id;
  final String arabic;
  final String reading;
  final String bangla;

  const QuranWordItem({
    required this.id,
    required this.arabic,
    required this.reading,
    required this.bangla,
  });
}

/// একটি সূরা, আয়াত-ভিত্তিক + শব্দ-ভিত্তিক আলাদা data।
class QuranSurahItem {
  final String id;
  final String name;
  final List<QuranAyahItem> ayahs;

  const QuranSurahItem({
    required this.id,
    required this.name,
    required this.ayahs,
  });
}

class QuranAyahItem {
  final int ayah;
  final String arabic;
  final String bangla;
  final List<QuranWordItem> words;

  const QuranAyahItem({
    required this.ayah,
    required this.arabic,
    required this.bangla,
    required this.words,
  });
}

/// কুরআন শব্দভাণ্ডার — শব্দ + কোথায় কোথায় এসেছে।
class QuranOccurrenceItem {
  final int surah;
  final String surahName;
  final int ayah;
  final String arabic;
  final String bangla;

  const QuranOccurrenceItem({
    required this.surah,
    required this.surahName,
    required this.ayah,
    required this.arabic,
    required this.bangla,
  });
}

class VocabItem {
  final String id;
  final String arabic;
  final String reading;
  final String bangla;
  final String root;
  final List<QuranOccurrenceItem> occurrences;

  const VocabItem({
    required this.id,
    required this.arabic,
    required this.reading,
    required this.bangla,
    required this.root,
    required this.occurrences,
  });
}

/// মূলধাতু (root) — এক শিকড় থেকে নানা শব্দ।
class RootDerivedItem {
  final String arabic;
  final String reading;
  final String bangla;
  final String type;

  const RootDerivedItem({
    required this.arabic,
    required this.reading,
    required this.bangla,
    required this.type,
  });
}

class RootItem {
  final String root;
  final String rootMeaning;
  final List<RootDerivedItem> derived;

  const RootItem({
    required this.root,
    required this.rootMeaning,
    required this.derived,
  });
}

/// ব্যাকরণের ছোট পাঠ — একটি শব্দ/বাক্য কীভাবে গড়া।
class GrammarExampleItem {
  final String arabic;
  final String reading;
  final String bangla;
  final String note;

  const GrammarExampleItem({
    required this.arabic,
    required this.reading,
    required this.bangla,
    required this.note,
  });
}

class GrammarLessonItem {
  final String id;
  final String title;
  final String emoji;
  final List<String> explanation;
  final List<GrammarExampleItem> examples;
  final String tip;

  const GrammarLessonItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.explanation,
    required this.examples,
    required this.tip,
  });
}

/// কনটেন্ট-স্টোর তথ্য — কোন ফাইল, ভার্সন, কতগুলো আইটেম।
class ContentFileItem {
  final String path;
  final String kind;
  final int version;
  final int count;
  final String source;

  const ContentFileItem({
    required this.path,
    required this.kind,
    required this.version,
    required this.count,
    required this.source,
  });
}

/// assets/deen/arabic_*.json লোড + validate।
class ArabicSeed {
  static List<ArabicLetterItem>? _letters;
  static List<HarakaItem>? _harakat;
  static List<ArabicWordItem>? _words;
  static List<QuranSurahItem>? _quran;
  static List<VocabItem>? _vocab;
  static List<RootItem>? _roots;
  static List<GrammarLessonItem>? _grammar;
  static List<ContentFileItem>? _manifest;

  static Future<List<ArabicLetterItem>> letters() async {
    if (_letters != null) return _letters!;
    final raw = await rootBundle.loadString('assets/deen/arabic_letters.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <ArabicLetterItem>[];
    for (final l in (data['letters'] as List? ?? const [])) {
      final m = l as Map<String, dynamic>;
      list.add(ArabicLetterItem(
        id: (m['id'] as String? ?? '').trim(),
        letter: (m['letter'] as String? ?? '').trim(),
        name: (m['name'] as String? ?? '').trim(),
        reading: (m['reading'] as String? ?? '').trim(),
        isolated: (m['isolated'] as String? ?? '').trim(),
        initial: (m['initial'] as String? ?? '').trim(),
        medial: (m['medial'] as String? ?? '').trim(),
        finalJ: (m['final'] as String? ?? '').trim(),
        example: (m['example'] as String? ?? '').trim(),
        exampleReading: (m['exampleReading'] as String? ?? '').trim(),
        exampleBangla: (m['exampleBangla'] as String? ?? '').trim(),
        connectsForward: (m['connectsForward'] as bool?) ?? true,
      ));
    }
    _letters = list;
    return list;
  }

  static Future<List<HarakaItem>> harakat() async {
    if (_harakat != null) return _harakat!;
    final raw = await rootBundle.loadString('assets/deen/arabic_harakat.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <HarakaItem>[];
    for (final h in (data['harakat'] as List? ?? const [])) {
      final m = h as Map<String, dynamic>;
      list.add(HarakaItem(
        id: (m['id'] as String? ?? '').trim(),
        name: (m['name'] as String? ?? '').trim(),
        mark: (m['mark'] as String? ?? '').trim(),
        reading: (m['reading'] as String? ?? '').trim(),
        bangla: (m['bangla'] as String? ?? '').trim(),
      ));
    }
    _harakat = list;
    return list;
  }

  static Future<List<ArabicWordItem>> words() async {
    if (_words != null) return _words!;
    final raw = await rootBundle.loadString('assets/deen/arabic_words.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <ArabicWordItem>[];
    for (final w in (data['words'] as List? ?? const [])) {
      final m = w as Map<String, dynamic>;
      list.add(ArabicWordItem(
        id: (m['id'] as String? ?? '').trim(),
        arabic: (m['arabic'] as String? ?? '').trim(),
        reading: (m['reading'] as String? ?? '').trim(),
        bangla: (m['bangla'] as String? ?? '').trim(),
        source: (m['source'] as String? ?? '').trim(),
      ));
    }
    _words = list;
    return list;
  }

  /// কুরআন word-by-word — এখন সূরা ফাতিহা; পরে সব সুরা।
  static Future<List<QuranSurahItem>> quran() async {
    if (_quran != null) return _quran!;
    final raw = await rootBundle.loadString('assets/deen/quran_words.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final surahs = <QuranSurahItem>[];
    final id = (data['id'] as String? ?? '').trim();
    final name = (data['name'] as String? ?? '').trim();
    final ayahs = <QuranAyahItem>[];
    for (final a in (data['ayahs'] as List? ?? const [])) {
      final m = a as Map<String, dynamic>;
      final words = <QuranWordItem>[];
      for (final w in (m['words'] as List? ?? const [])) {
        final wm = w as Map<String, dynamic>;
        words.add(QuranWordItem(
          id: (wm['id'] as String? ?? '').trim(),
          arabic: (wm['arabic'] as String? ?? '').trim(),
          reading: (wm['reading'] as String? ?? '').trim(),
          bangla: (wm['bangla'] as String? ?? '').trim(),
        ));
      }
      ayahs.add(QuranAyahItem(
        ayah: ((m['ayah'] as num?) ?? 0).toInt(),
        arabic: (m['arabic'] as String? ?? '').trim(),
        bangla: (m['bangla'] as String? ?? '').trim(),
        words: words,
      ));
    }
    if (id.isNotEmpty) {
      surahs.add(QuranSurahItem(id: id, name: name, ayahs: ayahs));
    }
    _quran = surahs;
    return surahs;
  }

  static Future<List<VocabItem>> vocab() async {
    if (_vocab != null) return _vocab!;
    final raw = await rootBundle.loadString('assets/deen/quran_vocab.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <VocabItem>[];
    for (final v in (data['words'] as List? ?? const [])) {
      final m = v as Map<String, dynamic>;
      final occ = <QuranOccurrenceItem>[];
      for (final o in (m['occurrences'] as List? ?? const [])) {
        final om = o as Map<String, dynamic>;
        occ.add(QuranOccurrenceItem(
          surah: ((om['surah'] as num?) ?? 0).toInt(),
          surahName: (om['surahName'] as String? ?? '').trim(),
          ayah: ((om['ayah'] as num?) ?? 0).toInt(),
          arabic: (om['arabic'] as String? ?? '').trim(),
          bangla: (om['bangla'] as String? ?? '').trim(),
        ));
      }
      list.add(VocabItem(
        id: (m['id'] as String? ?? '').trim(),
        arabic: (m['arabic'] as String? ?? '').trim(),
        reading: (m['reading'] as String? ?? '').trim(),
        bangla: (m['bangla'] as String? ?? '').trim(),
        root: (m['root'] as String? ?? '').trim(),
        occurrences: occ,
      ));
    }
    _vocab = list;
    return list;
  }

  static Future<List<RootItem>> roots() async {
    if (_roots != null) return _roots!;
    final raw = await rootBundle.loadString('assets/deen/root_words.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <RootItem>[];
    for (final r in (data['roots'] as List? ?? const [])) {
      final m = r as Map<String, dynamic>;
      final derived = <RootDerivedItem>[];
      for (final d in (m['derived'] as List? ?? const [])) {
        final dm = d as Map<String, dynamic>;
        derived.add(RootDerivedItem(
          arabic: (dm['arabic'] as String? ?? '').trim(),
          reading: (dm['reading'] as String? ?? '').trim(),
          bangla: (dm['bangla'] as String? ?? '').trim(),
          type: (dm['type'] as String? ?? '').trim(),
        ));
      }
      list.add(RootItem(
        root: (m['root'] as String? ?? '').trim(),
        rootMeaning: (m['rootMeaning'] as String? ?? '').trim(),
        derived: derived,
      ));
    }
    _roots = list;
    return list;
  }

  static Future<List<GrammarLessonItem>> grammar() async {
    if (_grammar != null) return _grammar!;
    final raw = await rootBundle.loadString('assets/deen/arabic_grammar.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <GrammarLessonItem>[];
    for (final l in (data['lessons'] as List? ?? const [])) {
      final m = l as Map<String, dynamic>;
      final examples = <GrammarExampleItem>[];
      for (final e in (m['examples'] as List? ?? const [])) {
        final em = e as Map<String, dynamic>;
        examples.add(GrammarExampleItem(
          arabic: (em['arabic'] as String? ?? '').trim(),
          reading: (em['reading'] as String? ?? '').trim(),
          bangla: (em['bangla'] as String? ?? '').trim(),
          note: (em['note'] as String? ?? '').trim(),
        ));
      }
      list.add(GrammarLessonItem(
        id: (m['id'] as String? ?? '').trim(),
        title: (m['title'] as String? ?? '').trim(),
        emoji: (m['emoji'] as String? ?? '').trim(),
        explanation: (m['explanation'] as List? ?? const []).map((e) => (e as String? ?? '').trim()).toList(),
        examples: examples,
        tip: (m['tip'] as String? ?? '').trim(),
      ));
    }
    _grammar = list;
    return list;
  }

  static Future<List<ContentFileItem>> manifest() async {
    if (_manifest != null) return _manifest!;
    final raw = await rootBundle.loadString('assets/deen/content_manifest.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = <ContentFileItem>[];
    for (final f in (data['files'] as List? ?? const [])) {
      final m = f as Map<String, dynamic>;
      list.add(ContentFileItem(
        path: (m['path'] as String? ?? '').trim(),
        kind: (m['kind'] as String? ?? '').trim(),
        version: ((m['version'] as num?) ?? 0).toInt(),
        count: ((m['count'] as num?) ?? 0).toInt(),
        source: (m['source'] as String? ?? '').trim(),
      ));
    }
    _manifest = list;
    return list;
  }
}