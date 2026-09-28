import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_store.dart';

/// একটি মডিউলের ব্যক্তিগত রেকর্ড (known/total) — স্কোর নয়, কতটুকু জানি ✓।
class ModuleProgress {
  final String name;
  final int known;
  final int total;

  const ModuleProgress({
    required this.name,
    required this.known,
    required this.total,
  });

  /// মুখস্থের মতো স্থির লক্ষ্য ছাড়া রেকর্ড — মোট থাকে না।
  bool get countOnly => total <= 0;

  bool get knownAll => !countOnly && known >= total;
}

/// শিক্ষক/ড্যাশের জন্য পুরো প্রগ্রেস-সারাংশ।
class DeenProgressSummary {
  final List<ModuleProgress> modules;
  final int questionsToday;
  final int totalKnown;
  final String nextStep;

  const DeenProgressSummary({
    required this.modules,
    required this.questionsToday,
    required this.totalKnown,
    required this.nextStep,
  });
}

/// M11.2 — AI শিক্ষকের ব্যক্তিগত প্রগ্রেস (রেকর্ড, বিচার নয়)।
/// পড়া শুধু `deen_arabic` + `memorization` বক্স থেকে; কোনোরকম লজিক বদল হয় না।
class DeenProgress {
  DeenProgress._();

  static const _arabicBox = 'deen_arabic';

  static Box get _box => Hive.box(_arabicBox);

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// আজ শিক্ষকের কাছে ক'টা প্রশ্ন জিজ্ঞেস হয়েছে (ব্যক্তিগত সংখ্যা মাত্র)।
  static int questionsToday() {
    final m = _box.get('teacher_count');
    if (m is! Map) return 0;
    return ((m[_dayKey(DateTime.now())] as num?) ?? 0).toInt();
  }

  static void recordQuestion() {
    final key = _dayKey(DateTime.now());
    final m = Map<String, dynamic>.from(
      _box.get('teacher_count', defaultValue: <String, dynamic>{}) as Map,
    );
    m[key] = ((m[key] as num?) ?? 0).toInt() + 1;
    _box.put('teacher_count', m);
  }

  /// কনটেন্ট + রেকর্ড মিলিয়ে সারাংশ; মনে রাখবে কোন মডিউল কতটুকু এগোয়েছে।
  static Future<DeenProgressSummary> summary() async {
    final words = await ArabicSeed.words();
    final vocab = await ArabicSeed.vocab();
    final letters = await ArabicSeed.letters();
    final harakat = await ArabicSeed.harakat();
    final roots = await ArabicSeed.roots();
    final grammar = await ArabicSeed.grammar();

    final known = DeenStore.arabicKnown();
    final wordIds = {for (final w in words) w.id};

    final knownWords = known.where(wordIds.contains).length;
    final knownVocab = known.where((k) => k.startsWith('vocab:')).length;
    final knownLetters = known.where((k) => k.startsWith('letter:')).length;
    final knownHarakat = known.where((k) => k.startsWith('harakat:')).length;
    final knownRoots = known.where((k) => k.startsWith('root:')).length;
    final knownGrammar = known.where((k) => k.startsWith('grammar:')).length;
    final memorized = DeenStore.memorizationAll().length;

    final modules = <ModuleProgress>[
      ModuleProgress(name: 'অক্ষর', known: knownLetters, total: letters.length),
      ModuleProgress(name: 'হরকত', known: knownHarakat, total: harakat.length),
      ModuleProgress(name: 'শব্দ পড়া', known: knownWords, total: words.length),
      ModuleProgress(
        name: 'শব্দভাণ্ডার',
        known: knownVocab,
        total: vocab.length,
      ),
      ModuleProgress(name: 'মূলধাতু', known: knownRoots, total: roots.length),
      ModuleProgress(
        name: 'ব্যাকরণ',
        known: knownGrammar,
        total: grammar.length,
      ),
      ModuleProgress(name: 'মুখস্থ সব', known: memorized, total: 0),
    ];

    final nextStep = _nextStep(modules);

    return DeenProgressSummary(
      modules: modules,
      questionsToday: questionsToday(),
      totalKnown: known.length,
      nextStep: nextStep,
    );
  }

  static String _nextStep(List<ModuleProgress> m) {
    final words = m[2];
    final vocab = m[3];
    if (!words.knownAll) {
      return 'শব্দ পড়া মডিউলে ${words.total - words.known} টি শব্দ বাকি — সেগুলো "জানি ✓" করে এগোও।';
    }
    if (!vocab.knownAll) {
      return 'শব্দভাণ্ডার মডিউলে ${vocab.total - vocab.known} টি বাকি — প্রতিটা কুরআনের শব্দ, অর্থ দিয়ে জুড়ে।';
    }
    if (m[4].knownAll) {
      return 'মূলধাতু শেষ — এবার মূলধাতু থেকে নানা শব্দের ব্যাকরণ দেখো।';
    }
    return 'সব জানা ধাপ পেরিয়ে গেছো — মূলধাতু, ব্যাকরণ, আর মুখস্থের রিভিউ চালিয়ে রাখো।';
  }
}
