import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/dua_word_analyzer.dart';
import 'package:lifeos/services/review_scheduler.dart';

/// একটি সুপারিশকৃত দোয়া + কেন সুপারিশ করলাম (ব্যবহারকারী দেখতে পায়)।
class DuaSuggestion {
  final DuaItem dua;
  final String reason;
  final int score;

  /// এই দোয়ায় ব্যবহারকারীর চিহ্নিত কঠিন শব্দ (থাকলে)।
  final List<String> hardWords;

  const DuaSuggestion({
    required this.dua,
    required this.reason,
    required this.score,
    this.hardWords = const [],
  });
}

/// 🤖 অবস্থা-ভিত্তিক দোয়া সুপারিশ — কেবল অ্যাপের যাচাইকৃত `dua.json`
/// থেকে বেছে নেয়। কোনো নতুন দোয়া বা উপদেশ বানায় না; শুধু *কোনটা আগে*
/// পড়া উচিত তা ঠিক করে এবং কারণ দেখায়।
class DuaRecommender {
  DuaRecommender._();

  /// সময় অনুযায়ী প্রাসঙ্গিক section (সবসময়ের দোয়া সব সময় মিলে)।
  static const _allTime = <String>{
    'কুরআনের দোয়া',
    'সালাতের ভিতরের যিকির',
    'জ্ঞান ও পড়াশোনা',
    'সফর ও যানবাহন',
  };

  static List<String> sectionsFor(DateTime now) {
    final h = now.hour;
    if (h >= 20 || h < 5) {
      return ['ঘুম ও ঘুম থেকে ওঠা', 'বিপদ ও দুশ্চিন্তা', ..._allTime];
    }
    if (h < 11) {
      return [
        'আবহাওয়া',
        'অসুস্থতা ও সুস্থতা',
        'ঘরে প্রবেশ/বের হওয়া',
        ..._allTime,
      ];
    }
    if (h < 17) {
      return [
        'খাবার ও পান',
        'ওযু ও টয়লেট',
        'রিজিক ও ঋণ',
        ..._allTime,
      ];
    }
    return [
      'মসজিদ ও আযান',
      'ক্ষমা ও তাওবা',
      'পরিবার',
      ..._allTime,
    ];
  }

  /// দোয়ার আরবি শব্দগুলো ভাণ্ডারে মিলিয়ে (হাজার-হাজার লুপ নয়, ম্যাপ থেকে)।
  static Future<List<({String base, String knownKey, String hardKey})>>
  _wordLinks(DuaItem d) async {
    final out = <({String base, String knownKey, String hardKey})>[];
    for (final token in DuaWordAnalyzer.splitWords(d.arabic)) {
      final base = DuaWordAnalyzer.normalize(token);
      if (base.isEmpty) continue;
      final w = await DuaWordLookup.word(base);
      if (w != null) {
        out.add((base: base, knownKey: w.id, hardKey: 'hard:${w.id}'));
        continue;
      }
      final v = await DuaWordLookup.vocab(base);
      if (v != null) {
        out.add((
          base: base,
          knownKey: 'vocab:${v.id}',
          hardKey: 'hard:vocab:${v.id}',
        ));
      }
    }
    return out;
  }

  /// সব দোয়া স্কোর করে সাজানো তালিকা (সেরা আগে)।
  /// [duas] দিলে নিজের তালিকা ব্যবহার হয় (পরীক্ষায় আসল JSON থেকে)।
  static Future<List<DuaSuggestion>> ranked({
    DateTime? now,
    List<DuaItem>? duas,
  }) async {
    final when = now ?? DateTime.now();
    final list = duas ?? await DeenSeed.duas();
    if (list.isEmpty) return const [];
    final sections = sectionsFor(when).toSet();
    final known = DeenStore.arabicKnown();
    final hard = DeenStore.arabicHard();
    final learned = <String>{
      for (final d in list)
        if (known.contains('dua-learn:${d.id}')) d.id,
    };

    final out = <DuaSuggestion>[];
    for (final d in list) {
      var score = 0;
      final reasons = <String>[];

      // ১) সময়-উপযোগী section
      if (sections.contains(d.section)) {
        score += 4;
        reasons.add('এই সময়ের জন্য প্রাসঙ্গিক');
      } else {
        score += 1;
      }

      // ২) পড়া হয়নি এমন দোয়া আগে
      if (!learned.contains(d.id)) {
        score += 3;
        reasons.add('এখনো পড়া হয়নি');
      } else {
        score += 1;
        reasons.add('পড়া হয়েছে — পুনরাল্লাপ ভালো হবে');
      }

      // ৩) পুনরাল্লাপের সময় হয়ে গেছে কি না — নতুন চিহ্নিত হলে নয়, কারণ
      //    এইমাত্র শেখা জিনিসকে "ভুলে যাওয়ার সময়" বলা মানে হতো না।
      final rev = ReviewScheduler.get('dua-learn:${d.id}');
      final dueIn = ReviewScheduler.daysUntilDue('dua-learn:${d.id}');
      if (rev != null && !rev.isNew && dueIn <= 0) {
        score += 4;
        reasons.add('পুনরাল্লাপের সময় হয়েছে');
      }

      // ৪) কঠিন শব্দের সঙ্গে সংযোগ — দোয়া আর আরবি ইঞ্জিন যুক্ত হয়
      final links = await _wordLinks(d);
      final hardHere = links.where((l) => hard.contains(l.hardKey)).map((l) => l.base).toList();
      if (hardHere.isNotEmpty) {
        score += 5;
        reasons.add('তোমার কঠিন শব্দ এতে আছে');
      }

      // ৫) পরিচিত শব্দ দিয়ে তৈরি হলে ভালো পড়া যায়
      final knownHere = links.where((l) => known.contains(l.knownKey)).length;
      if (links.isNotEmpty && knownHere == links.length && knownHere > 0) {
        score += 2;
        reasons.add('তোমার জানা শব্দ দিয়ে তৈরি');
      }

      out.add(
        DuaSuggestion(
          dua: d,
          score: score,
          reason: reasons.take(2).join(' · '),
          hardWords: hardHere,
        ),
      );
    }

    out.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return a.dua.id.compareTo(b.dua.id); // স্থিতিশীল সাজানো
    });
    return out;
  }

  /// আজকের একটি সুপারিশ — দিনভিত্তিক স্থিতিশীল, প্রতিদিন ঘুরে যায়।
  static Future<DuaSuggestion?> today({DateTime? now, List<DuaItem>? duas}) async {
    final when = now ?? DateTime.now();
    final list = await ranked(now: when, duas: duas);
    if (list.isEmpty) return null;
    final dayOfYear = when.difference(DateTime(when.year)).inDays;
    return list[dayOfYear % list.length];
  }

  /// নির্দিষ্ট প্রসঙ্গে সুপারিশ (যেমন "বিপদের সময়") — মিল না থাকলে সেরা সাধারণ।
  static Future<DuaSuggestion?> forSection(String section, {DateTime? now}) async {
    final list = await ranked(now: now);
    for (final s in list) {
      if (s.dua.section == section) return s;
    }
    return list.isEmpty ? null : list.first;
  }
}
