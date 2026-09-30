import 'package:lifeos/services/deen_seed.dart';

/// রুটিনের একটি ধাপ — যাচাইকৃত দোয়া-ডেটা থেকে সাজানো (কোনো নতুন ধর্মীয় লেখা নয়)।
class NightRoutineStep {
  /// দোয়া-ডেটার id — অর্থ, সূত্র ও authenticity সেখান থেকেই আসে।
  final String duaId;

  /// তালিকায় দেখানো ছোট নাম (ডেটার নিজের বাংলা অর্থের সারাংশ)।
  final String label;

  /// কখন পড়তে হবে।
  final String when;

  /// ডেটা থেকে লোড করা দোয়া (লোড না হলে `null`)।
  final DuaItem? dua;

  const NightRoutineStep({
    required this.duaId,
    required this.label,
    required this.when,
    this.dua,
  });

  bool get loaded => dua != null;
  int get count => dua?.count ?? 1;
  String get source => dua?.hasSource == true ? dua!.source : 'source নেই';
  String get authenticity => dua?.authenticityLabel ?? '';
}

/// 🌙 ঘুম ও সকাল রুটিন — ধাপে ধাপে, ধীরে ও স্মরণে।
class NightRoutine {
  NightRoutine._();

  /// রুটিনের ধাপ — ক্রম, `dua.json`-এর যাচাইকৃত id-এর উপর ভিত্তি করে।
  /// কঠিনায়তুল কুরসি ও তিন কুল — ঘুমানোর আগে; আলহামদুলিল্লাহ — সকালে।
  static const order = <(String, String, String)>[
    ('dua_ayatul_kursi', 'আয়াতুল কুরসি', 'ঘুমানোর আগে'),
    ('dua_3qul', 'তিন কুল — ইখলাস, ফালাক, নাস', 'ঘুমানোর আগে'),
    ('dua_bismik_allahumma', 'বিস্মিকাল্লাহ দিয়ে ঘুমানোর দোয়া', 'ঘুমানোর আগে'),
    ('dua_qini_adabaka', 'ঘুমের আগে — ক্বিনী আযাবাকা', 'ঘুমানোর আগে'),
    ('dua_wake_hamd', 'ঘুম থেকে উঠে — আলহামদুলিল্লাহ', 'সকালে ঘুম থেকে উঠে'),
  ];

  /// ডেটা থেকে ধাপগুলো বানানো — যে দোয়া নেই সেটা `dua: null` থাকে, বাদ দেওয়া হয় না।
  static Future<List<NightRoutineStep>> build() async {
    final duas = await DeenSeed.duas();
    final byId = {for (final d in duas) d.id: d};
    return [
      for (final (id, label, time) in order)
        NightRoutineStep(duaId: id, label: label, when: time, dua: byId[id]),
    ];
  }

  /// ডেটা পাওয়া গেছে এমন ধাপগুলো (ফ্লোতে দেখানো হয়)।
  static List<NightRoutineStep> available(List<NightRoutineStep> steps) =>
      steps.where((s) => s.loaded).toList();
}
