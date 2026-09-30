import 'package:flutter/foundation.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/review_scheduler.dart';

/// পুনরাল্লাপে দেখানো যায় এমন একটি একক।
class ReviewUnit {
  final String key;
  final String kind;
  final String arabic;
  final String reading;
  final String bangla;

  const ReviewUnit({
    required this.key,
    required this.kind,
    required this.arabic,
    required this.reading,
    required this.bangla,
  });
}

/// পুনরাল্লাপযোগ্য আলোচ্য — কোরান শব্দ, শব্দভাণ্ডার ও দোয়া।
/// অক্ষর/সংযোগ/কুরআন-পঠন ইতিমধ্যে নিজস্ব পথে ফিরে আসে, তাই এখানে নেই।
class ReviewContent {
  ReviewContent._();

  static List<ReviewUnit>? _cache;

  /// [words]/[vocab]/[duas] দিলে নিজের তালিকা ব্যবহার হয় (পরীক্ষায় আসল JSON)।
  static Future<List<ReviewUnit>> units({
    List<ArabicWordItem>? words,
    List<VocabItem>? vocab,
    List<DuaItem>? duas,
  }) async {
    final injected = words != null || vocab != null || duas != null;
    if (!injected) {
      final cached = _cache;
      if (cached != null) return cached;
    }
    final out = <ReviewUnit>[];
    for (final w in words ?? await ArabicSeed.words()) {
      out.add(
        ReviewUnit(
          key: w.id,
          kind: 'শব্দ',
          arabic: w.arabic,
          reading: w.reading,
          bangla: w.bangla,
        ),
      );
    }
    for (final v in vocab ?? await ArabicSeed.vocab()) {
      out.add(
        ReviewUnit(
          key: 'vocab:${v.id}',
          kind: 'শব্দভাণ্ডার',
          arabic: v.arabic,
          reading: v.reading,
          bangla: v.bangla,
        ),
      );
    }
    for (final d in duas ?? await DeenSeed.duas()) {
      if (d.transliteration.trim().isEmpty) continue;
      out.add(
        ReviewUnit(
          key: 'dua-learn:${d.id}',
          kind: 'দুআ',
          arabic: d.arabic,
          reading: d.transliteration,
          bangla: d.bangla,
        ),
      );
    }
    return injected ? out : (_cache = out);
  }

  /// আগের সংস্করণে "জানি ✓" চাপা এককগুলোকে তালিকায় ঢোকায়, যাতে সেগুলো
  /// হারিয়ে না যায়। নতুন করে চাপা এককের জন্য [ReviewScheduler.seed] যথেষ্ট।
  static Future<int> backfill({List<ReviewUnit>? units}) async {
    final keys = {for (final u in units ?? await ReviewContent.units()) u.key};
    final missing = DeenStore.arabicKnown()
        .where(keys.contains)
        .where((k) => ReviewScheduler.get(k) == null)
        .toList();
    if (missing.isNotEmpty) ReviewScheduler.seedKnown(missing);
    return missing.length;
  }

  /// আজ ধরা পড়বে এমন *দেখানো-যায়* এককের সংখ্যা — journey-র ব্যাজ এটাই দেখায়,
  /// যাতে সংখ্যা বেড়ে গিয়ে খালি স্ক্রিন দেখানো না হয়।
  static Future<int> dueCount({List<ReviewUnit>? units}) async {
    final keys = {for (final u in units ?? await ReviewContent.units()) u.key};
    return ReviewScheduler.dueToday().where(keys.contains).length;
  }

  @visibleForTesting
  static void clearCache() => _cache = null;
}
