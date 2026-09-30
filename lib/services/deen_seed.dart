import 'package:lifeos/services/content_repository.dart';

/// একটি নামাজ-পরবর্তী ধাপ (৩৩/৩৩/৩৪, ইস্তিগফার, আয়াতুল কুরসি)।
class PostPrayerStep {
  final String id;
  final String arabic;
  final String bangla;
  final String meaning;
  final String transliteration;
  final String source;
  final int repeat;
  final bool readOnly;

  const PostPrayerStep({
    required this.id,
    required this.arabic,
    required this.bangla,
    required this.meaning,
    required this.transliteration,
    required this.source,
    required this.repeat,
    required this.readOnly,
  });

  /// source-field নিয়ম: খালি হলে UI-তে "source নেই" ব্যাজ — কখনো "হাদিস অনুযায়ী" লাগবে না।
  bool get hasSource => source.trim().isNotEmpty;
}

/// 🤲 দুআ লাইব্রেরির একটি item।
///
/// `authenticity`: sahih | hasan | quran — প্রতিটি item-এ source-সহ যাচাই।
/// `count`: source-অনুযায়ী পড়ার প্রস্তাবিত সংখ্যা (null = নির্দিষ্ট নয়)।
/// `level`: আরবি শেখার গভীরতা (১ = ছোট/মুখস্থ, ৩ = দীর্ঘ পাঠ্য)।
class DuaItem {
  final String id;
  final String section;
  final String type;
  final String arabic;
  final String transliteration;
  final String bangla;
  final String source;
  final String authenticity;
  final int? count;
  final int level;

  const DuaItem({
    required this.id,
    required this.section,
    required this.type,
    required this.arabic,
    required this.transliteration,
    required this.bangla,
    required this.source,
    this.authenticity = '',
    this.count,
    this.level = 1,
  });

  bool get hasSource => source.trim().isNotEmpty;
  bool get isQuranic => type == 'quran';

  String get authenticityLabel => switch (authenticity) {
    'sahih' => 'সহিহ',
    'hasan' => 'হাসান',
    'quran' => 'কুরআন',
    _ => '',
  };

  bool matches(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return bangla.toLowerCase().contains(t) ||
        arabic.contains(t) ||
        transliteration.toLowerCase().contains(t) ||
        source.toLowerCase().contains(t) ||
        section.toLowerCase().contains(t);
  }
}

/// 📜 হাদিস লাইব্রেরির একটি item।
class HadithItem {
  final String id;
  final String topic;
  final String arabic;
  final String bangla;
  final String book;
  final String number;
  final String grade;

  const HadithItem({
    required this.id,
    required this.topic,
    required this.arabic,
    required this.bangla,
    required this.book,
    required this.number,
    required this.grade,
  });

  bool get hasSource => book.trim().isNotEmpty || number.trim().isNotEmpty;

  String get sourceLabel =>
      book.isEmpty ? 'source নেই' : (number.isEmpty ? book : '$book $number');

  bool matches(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return bangla.toLowerCase().contains(t) ||
        arabic.toLowerCase().contains(t) ||
        sourceLabel.toLowerCase().contains(t) ||
        topic.toLowerCase().contains(t);
  }
}

/// 🌅 সকাল-সন্ধ্যার যিকির item।
class AdhkarItem {
  final String id;
  final String time;
  final String arabic;
  final String bangla;
  final int repeat;
  final String source;

  const AdhkarItem({
    required this.id,
    required this.time,
    required this.arabic,
    required this.bangla,
    required this.repeat,
    required this.source,
  });

  bool get hasSource => source.trim().isNotEmpty;

  bool get isMorning => time == 'morning' || time == 'both';
  bool get isEvening => time == 'evening' || time == 'both';
}

/// 📖 একটি সুরার item (সূরা ফাতিহা + জুয 'আম্মা + সব)।
class SurahAyah {
  final int n;
  final String ar;
  final String bn;

  /// বাংলা-বানানে পড়া (স্বয়ংক্রিয় মেকানিক্যাল ট্রান্সলিটারেশন)।
  final String tl;

  const SurahAyah({
    required this.n,
    required this.ar,
    required this.bn,
    this.tl = '',
  });
}

class SurahItem {
  final String id;
  final int index;
  final String name;
  final String arabicName;
  final String nameMeaning;
  final String revelation;
  final int ayahCount;
  final List<String> tags;
  final String arabic;
  final String bangla;
  final String transliteration;
  final List<SurahAyah> ayahs;

  const SurahItem({
    required this.id,
    required this.index,
    required this.name,
    required this.arabicName,
    required this.nameMeaning,
    required this.revelation,
    required this.ayahCount,
    required this.tags,
    required this.arabic,
    required this.bangla,
    required this.transliteration,
    this.ayahs = const [],
  });

  /// সুরার সোর্স সবসময় থাকে — কুরআন।
  String get source => 'সূরা $name ($arabicName) · কুরআন';

  bool get hasSource => true;

  String get meta =>
      '${_bn(index)} নং · ${_bn(ayahCount)} আয়াত · $nameMeaning';
}

/// 🧠 memorization-এ দেখানোর জন্য অভিন্ন item — দুআ বা সুরা যেকোনো।
class MemItem {
  final String key; // 'dua:<id>' | 'surah:<id>'
  final String label;
  final String arabic;
  final String bangla;
  final String transliteration;
  final String source;
  final bool isSurah;

  const MemItem({
    required this.key,
    required this.label,
    required this.arabic,
    required this.bangla,
    this.transliteration = '',
    required this.source,
    required this.isSurah,
  });

  bool get hasSource => source.trim().isNotEmpty;
}

/// ContentRepository থেকে ইসলামিক কনটেন্ট লোড + validate — GitHub রিপো, লোকাল Hive ক্যাশ।
class DeenSeed {
  static List<PostPrayerStep>? _postPrayer;
  static List<DuaItem>? _duas;
  static List<HadithItem>? _hadiths;
  static List<AdhkarItem>? _adhkar;
  static List<SurahItem>? _surahs;

  static Future<List<PostPrayerStep>> postPrayer() async {
    if (_postPrayer != null) return _postPrayer!;
    final data = await ContentRepository.loadMap('post_prayer.json');
    final steps = <PostPrayerStep>[];
    for (final s in (data?['steps'] as List? ?? const [])) {
      final m = s as Map<String, dynamic>;
      steps.add(
        PostPrayerStep(
          id: (m['id'] as String? ?? '').trim(),
          arabic: (m['arabic'] as String? ?? '').trim(),
          bangla: (m['bangla'] as String? ?? '').trim(),
          meaning: (m['meaning'] as String? ?? '').trim(),
          transliteration: (m['transliteration'] as String? ?? '').trim(),
          source: (m['source'] as String? ?? '').trim(),
          repeat: ((m['repeat'] as num?) ?? 1).toInt(),
          readOnly: m['readOnly'] == true,
        ),
      );
    }
    if (steps.isEmpty) {
      throw StateError('post_prayer.json-এ কোনো ধাপ নেই');
    }
    _postPrayer = steps;
    return steps;
  }

  static Future<List<DuaItem>> duas() async {
    if (_duas != null) return _duas!;
    final data = await ContentRepository.loadMap('dua.json');
    final list = <DuaItem>[];
    for (final d in (data?['duas'] as List? ?? const [])) {
      final m = d as Map<String, dynamic>;
      list.add(
        DuaItem(
          id: (m['id'] as String? ?? '').trim(),
          section: (m['section'] as String? ?? '').trim(),
          type: (m['type'] as String? ?? 'general').trim(),
          arabic: (m['arabic'] as String? ?? '').trim(),
          transliteration: (m['transliteration'] as String? ?? '').trim(),
          bangla: (m['bangla'] as String? ?? '').trim(),
          source: (m['source'] as String? ?? '').trim(),
          authenticity: (m['authenticity'] as String? ?? '').trim(),
          count: (m['count'] as num?)?.toInt(),
          level: ((m['level'] as num?) ?? 1).toInt(),
        ),
      );
    }
    _duas = list;
    return list;
  }

  /// UI-তে সেকশন ক্রম — json-এর `sections` অ্যারে বা প্রথম-আগমন ক্রম।
  static Future<List<String>> duaSections() async {
    final data = await ContentRepository.loadMap('dua.json');
    final list = data?['sections'];
    if (list is List) return list.cast<String>();
    return const [];
  }

  static Future<List<HadithItem>> hadiths() async {
    if (_hadiths != null) return _hadiths!;
    final data = await ContentRepository.loadMap('hadith.json');
    final list = <HadithItem>[];
    for (final h in (data?['hadiths'] as List? ?? const [])) {
      final m = h as Map<String, dynamic>;
      list.add(
        HadithItem(
          id: (m['id'] as String? ?? '').trim(),
          topic: (m['topic'] as String? ?? '').trim(),
          arabic: (m['arabic'] as String? ?? '').trim(),
          bangla: (m['bangla'] as String? ?? '').trim(),
          book: (m['book'] as String? ?? '').trim(),
          number: (m['number'] as String? ?? '').trim(),
          grade: (m['grade'] as String? ?? '').trim(),
        ),
      );
    }
    _hadiths = list;
    return list;
  }

  static Future<List<AdhkarItem>> adhkar() async {
    if (_adhkar != null) return _adhkar!;
    final data = await ContentRepository.loadMap('adhkar.json');
    final list = <AdhkarItem>[];
    for (final a in (data?['adhkar'] as List? ?? const [])) {
      final m = a as Map<String, dynamic>;
      list.add(
        AdhkarItem(
          id: (m['id'] as String? ?? '').trim(),
          time: (m['time'] as String? ?? 'both').trim(),
          arabic: (m['arabic'] as String? ?? '').trim(),
          bangla: (m['bangla'] as String? ?? '').trim(),
          repeat: ((m['repeat'] as num?) ?? 1).toInt(),
          source: (m['source'] as String? ?? '').trim(),
        ),
      );
    }
    _adhkar = list;
    return list;
  }

  static Future<List<SurahItem>> surahs() async {
    if (_surahs != null) return _surahs!;
    final indexData = await ContentRepository.loadMap(
      'quran/surahs_index.json',
    );
    final index = indexData?['surahs'] as List? ?? const [];
    final list = <SurahItem>[];
    for (final s in index) {
      final im = s as Map<String, dynamic>;
      final id = (im['id'] as String? ?? '').trim();
      final idx = ((im['index'] as num?) ?? 0).toInt();
      final fileKey = 'quran/${idx.toString().padLeft(3, '0')}_$id.json';
      final m = await ContentRepository.loadMap(fileKey);
      list.add(
        SurahItem(
          id: id,
          index: idx,
          name: (m?['name'] as String? ?? im['name'] as String? ?? '').trim(),
          arabicName: (m?['arabicName'] as String? ?? '').trim(),
          nameMeaning: (m?['nameMeaning'] as String? ?? '').trim(),
          revelation: (m?['revelation'] as String? ?? '').trim(),
          ayahCount: ((m?['ayahCount'] as num?) ?? 0).toInt(),
          tags: [
            for (final t in (m?['tags'] as List? ?? const []))
              t.toString().trim(),
          ],
          arabic: (m?['arabic'] as String? ?? '').trim(),
          bangla: (m?['bangla'] as String? ?? '').trim(),
          transliteration: (m?['transliteration'] as String? ?? '').trim(),
          ayahs: [
            for (final a in (m?['ayahs'] as List? ?? const []))
              SurahAyah(
                n: ((a as Map<String, dynamic>)['n'] as num?)?.toInt() ?? 0,
                ar: (a['ar'] as String? ?? '').trim(),
                bn: (a['bn'] as String? ?? '').trim(),
                tl: (a['tl'] as String? ?? '').trim(),
              ),
          ],
        ),
      );
    }
    _surahs = list;
    return list;
  }

  /// 🧠 মুখস্থ পুল — দুআ + ছোট সুরা দুটোই (hive-এ সংরক্ষণ key: `dua:<id>`/`surah:<id>`)।
  static Future<List<MemItem>> memPool() async {
    final duaList = await duas();
    final surahList = await surahs();
    return [
      for (final s in surahList)
        if (s.arabic.trim().isNotEmpty)
          MemItem(
            key: 'surah:${s.id}',
            label: 'সূরা ${s.name}',
            arabic: s.arabic,
            bangla: s.bangla,
            transliteration: s.transliteration,
            source: s.source,
            isSurah: true,
          ),
      for (final d in duaList)
        MemItem(
          key: 'dua:${d.id}',
          label: d.section,
          arabic: d.arabic,
          bangla: d.bangla,
          source: d.source,
          isSurah: false,
        ),
    ];
  }
}

String _bn(int n) {
  const bn = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((ch) {
    final i = ch.codeUnitAt(0);
    return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
  }).join();
}
