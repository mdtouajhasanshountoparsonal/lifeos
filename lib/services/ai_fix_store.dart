import 'package:hive/hive.dart';

import 'text_normalizer.dart' show TextFix;

/// AiFixStore — P2: online-AI-এর শেখা সংশোধনগুলো জমা রাখে,
/// যেন পরের বার **offline**-এও সেগুলো কাজ করে।
///
/// দুটি ম্যাপ রাখা হয়:
/// - `words` : ভুল শব্দ → শুদ্ধ শব্দ (TextNormalizer-এ learned হিসেবে merge হয়)
/// - `emoji` : বিষয়/শব্দ → এমোজি (EmojiIntent-এ learned হিসেবে চেক হয়)
class AiFixStore {
  AiFixStore._();

  static const _boxName = 'learned_fixes';
  static Box<dynamic>? _box;
  static bool _initDone = false;

  static bool get ready => _box != null;

  static Future<void> init() async {
    if (_initDone && _box != null) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _initDone = true;
  }

  static Map<String, String> _mmap(String key) {
    final b = _box;
    if (b == null) return const {};
    final raw = b.get(key);
    if (raw is Map) {
      return Map<String, String>.from(
        raw.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    return const {};
  }

  static Map<String, String> get learnedWords => _mmap('words');

  static Map<String, String> get learnedEmoji => _mmap('emoji');

  static Future<void> rememberFixes(Iterable<TextFix> fixes) =>
      _remember('words', fixes.map((f) => MapEntry(f.before, f.after)));

  static Future<void> rememberEmojis(Iterable<MapEntry<String, String>> fixes) =>
      _remember('emoji', fixes);

  static Future<void> _remember(String key, Iterable<MapEntry<String, String>> fixes) async {
    final b = _box;
    if (b == null) return;
    final live = fixes
        .where((e) => e.key.trim().isNotEmpty && e.key.trim() != e.value.trim())
        .toList();
    if (live.isEmpty) return;
    final merged = <String, String>{
      ..._mmap(key),
      for (final e in live) e.key: e.value,
    };
    await b.put(key, merged);
  }

  static Future<void> forgetWord(String from) async {
    final b = _box;
    if (b == null) return;
    final m = Map<String, String>.from(_mmap('words'))..remove(from);
    await b.put('words', m);
  }

  static Future<void> clear() async {
    final b = _box;
    if (b == null) return;
    await b.clear();
  }
}