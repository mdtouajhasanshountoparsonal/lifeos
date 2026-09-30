import 'dart:convert';
import 'dart:io';

import 'package:lifeos/services/ai_settings.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/services/deen_progress.dart';
import 'package:lifeos/services/dua_recommender.dart';

/// আরবি শিক্ষকের উত্তর — offline/local data প্রথমে, ইচ্ছা হলে Gemini।
class TeacherReply {
  final String title;
  final String body;
  final String? arabic;
  final bool fromGemini;

  const TeacherReply({
    required this.title,
    required this.body,
    this.arabic,
    this.fromGemini = false,
  });
}

class ArabicTeacher {
  ArabicTeacher._();

  static const _geminiEnv = String.fromEnvironment('LIFEOS_GEMINI_KEY');

  /// প্রশ্নের উত্তর: online চালু থাকলে Gemini-চেষ্টা → ব্যর্থ হলে/বন্ধ থাকলে offline।
  static Future<TeacherReply> ask(String question, {String? geminiKey}) async {
    final q = question.trim();
    if (q.isEmpty) {
      return const TeacherReply(
        title: 'কী প্রশ্ন?',
        body: 'আরবি পড়া, শব্দ, ব্যাকরণ — কিছু লিখুন।',
      );
    }
    DeenProgress.recordQuestion();
    await AiSettings.init();
    final key = (geminiKey != null && geminiKey.isNotEmpty)
        ? geminiKey
        : _geminiEnv;
    if (AiSettings.onlineEnabled && key.isNotEmpty) {
      try {
        final online = await _askGemini(q, key);
        return online;
      } catch (_) {
        // নিচে offline-এ নামা
      }
    }
    return offlineAnswer(q);
  }

  static Future<TeacherReply> offlineAnswer(String q) async {
    final t = q.replaceAll(RegExp(r'[?؟।!]'), '').trim().toLowerCase();

    final letters = await ArabicSeed.letters();
    final harakat = await ArabicSeed.harakat();
    final vocab = await ArabicSeed.vocab();
    final roots = await ArabicSeed.roots();

    // 1) হরকত
    for (final h in harakat) {
      if (t.contains(h.name.toLowerCase()) ||
          t.contains(h.reading.toLowerCase())) {
        return TeacherReply(
          title: '${h.name} — ${h.bangla}',
          arabic: h.mark,
          body:
              'উচ্চারণ: ${h.reading}\n\n${h.bangla}\n\nবর্ণমালা পড়তে গেলে প্রথমে অক্ষর চেনা, তারপর এই ছোট চিহ্নগুলো — হরকত — যোগ হয়ে শব্দ হয়।',
        );
      }
    }

    // 2) অক্ষর
    for (final l in letters) {
      if (t.contains(l.name.toLowerCase()) ||
          t.contains(l.reading.toLowerCase()) ||
          (l.example.isNotEmpty && t.contains(l.example))) {
        return TeacherReply(
          title: 'অক্ষর: ${l.name} (${l.reading})',
          arabic: l.example,
          body:
              'শুরু-মধ্য-শেষ রূপ ভিন্ন হয়। উদাহরণ শব্দ: ${l.example} → "${l.exampleReading}" — মানে ${l.exampleBangla}।\n\nঅনুশীলন: আলফাবেট শিখা-তে প্রতিটি অক্ষরের ৪ রূপ দেখুন।',
        );
      }
    }

    // 3) শব্দভাণ্ডার (কুরআন)
    for (final v in vocab) {
      if (t.contains(v.reading.toLowerCase()) ||
          t.contains(v.bangla.toLowerCase()) ||
          (v.arabic.isNotEmpty && t.contains(v.arabic))) {
        final occ = v.occurrences
            .map(
              (o) =>
                  '• ${o.surahName} ${o.surah}:${o.ayah} — ${o.arabic} → ${o.bangla}',
            )
            .join('\n');
        return TeacherReply(
          title: '${v.arabic} — ${v.reading}',
          arabic: v.arabic,
          body:
              'অর্থ: ${v.bangla}\nমূলধাতু: ${v.root}\n\nকুরআনে যেখানে এসেছে:\n${occ.isEmpty ? '—' : occ}\n\nএটা "শব্দভাণ্ডার" মডিউলে "জানি ✓" করে রাখুন।',
        );
      }
    }

    // 4) মূলধাতু
    for (final r in roots) {
      if (t.contains(r.rootMeaning.toLowerCase()) ||
          t.contains(r.root.replaceAll(' ', ''))) {
        final branches = r.derived
            .map((d) => '• ${d.arabic} (${d.reading}) — ${d.bangla}')
            .join('\n');
        return TeacherReply(
          title: 'মূলধাতু: ${r.root} — “${r.rootMeaning}”',
          arabic: r.root,
          body:
              'এক শিকড় থেকে বড় হওয়া শব্দগুলো:\n$branches\n\nআরবি শব্দের শিকড় চেনা = শব্দের ভেতর ঢোকার চাবি।',
        );
      }
    }

    // 4½) ব্যক্তিগত প্রগ্রেস (M11.2 — রেকর্ড, বিচার নয়)
    if (t.contains('প্রগ্রেস') ||
        t.contains('progress') ||
        t.contains('পরিসংখ্যান') ||
        t.contains('কতটুকু') ||
        t.contains('কোন ধাপ') ||
        t.contains('আমার রেকর্ড')) {
      final s = await DeenProgress.summary();
      final lines = [
        for (final m in s.modules)
          m.countOnly
              ? '• ${m.name}: ${_bn(m.known)}'
              : '• ${m.name}: ${_bn(m.known)} / ${_bn(m.total)}',
      ].join('\n');
      return TeacherReply(
        title: 'আপনার প্রগ্রেস — রেকর্ড',
        body:
            '$lines\n\n🎯 পরের ধাপ: ${s.nextStep}\n📝 আজ শিক্ষকের কাছে ${_bn(s.questionsToday)} বার প্রশ্ন করেছেন।\n\nরেকর্ড — বিচার নয়। নিজের গতিতে এগোন।',
      );
    }

    // ৪¾) অবস্থা-ভিত্তিক দোয়া সুপারিশ — কেবল যাচাইকৃত dua.json থেকে।
    if (t.contains('দোয়া') ||
        t.contains('duaa') ||
        t.contains('dua') ||
        t.contains('সুপারিশ') ||
        t.contains('recommend') ||
        t.contains('কোন দোয়া')) {
      final s = await DuaRecommender.today();
      if (s != null) {
        final d = s.dua;
        final extra = s.hardWords.isEmpty
            ? ''
            : '\n🩹 তোমার কঠিন শব্দ: ${s.hardWords.join(', ')}';
        return TeacherReply(
          title: 'আজকের দোয়া: ${d.transliteration.split(';').first}',
          arabic: d.arabic,
          body:
              '${d.bangla}\n\n📚 সূত্র: ${d.hasSource ? d.source : 'source নেই'}${d.hasSource && d.authenticity.isNotEmpty ? ' (${d.authenticityLabel})' : ''}\n📂 সেকশন: ${d.section}${d.count != null && d.count! > 1 ? '\n🔁 ${d.count} বার' : ''}\n\n🤖 কেন এটা: ${s.reason}$extra\n\nআমি অ্যাপের সেভ করা যাচাইকৃত দোয়া থেকেই বেছে নিই — নতুন কিছু বানাই না। দোয়ার যেকোনো শব্দে চাপ দিলে অক্ষর-হরকত ভাঙা ও অর্থ পাবে।',
        );
      }
    }

    // 5) দিকনির্দেশনা
    if (t.contains('start') ||
        t.contains('শুরু') ||
        t.contains('কীভাবে') ||
        t.contains('কোথা') ||
        t.contains('plan') ||
        t.contains('beaten')) {
      return const TeacherReply(
        title: 'আরবি পড়া শেখার পথ',
        body: '১) অক্ষর চেনা (২৮টি — আলফাবেট) →\n২) হরকত (ফাতহা-কাসরা-দাম্মা) →\n৩) ছোট শব্দ পড়া →\n৪) কুরআনের শব্দ (সূরা ফাতিহা) →\n৫) শব্দভাণ্ডার + মূলধাতু + ব্যাকরণ।\n\nপ্রতিটি ধাপে "রেকর্ড — স্কোর নয়", নিজের গতিতে।',
      );
    }
    if (t.contains('ফাতিহা') || t.contains('fatiha')) {
      return const TeacherReply(
        title: 'সূরা আল-ফাতিহা',
        body: 'কুরআনের ওপেনিং সূরা — ৭ আয়াত। "কুরআনের শব্দ" মডিউলে শব্দ ধরে ধরে অর্থসহ পড়া যায়; "🎯 নিজে বলো" মোডে মুখস্থ পরীক্ষাও।\n\nখাতা: সূরা/দোয়া মুখস্থ অ্যাপের রুটিনেও আল-ফাতিহা আছে।',
      );
    }
    if (t.contains('ব্যাকরণ') || t.contains('grammar')) {
      return const TeacherReply(
        title: 'ব্যাকরণ মডিউল',
        body: '"📖 ব্যাকরণ — ছোট ছোট পাঠ" মডিউলে আছে: নাম, আল, নামবাক্য, ক্রিয়াবাক্য, অবস্থা-শব্দ, সর্বনাম, আর বাক্য গড়া।\n\nপ্রতিটি পাঠে কুরআনের শব্দেরই উদাহরণ।',
      );
    }

    // 6) শেষ রক্ষা
    return const TeacherReply(
      title: 'অফলাইনে এই প্রশ্নের উত্তর প্রস্তুত নেই',
      body: 'আমার বাক্সে এই বিষয়ে সেভ করা তথ্য নেই (source আছে শুধু অক্ষর/হরকত/শব্দ/শব্দভাণ্ডার/মূলধাতু/ব্যাকরণ)।\n\nবিকল্প:\n• অন্য শব্দ/অক্ষর দিয়ে জিজ্ঞেস করুন\n• সেটিংস-এ "Online AI" চালু করে ইন্টারনেটে প্রশ্ন করুন\n• মডিউলগুলো ঘুরে দেখুন — উত্তর সেখানে আছে।',
    );
  }

  static String _bn(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }

  static const _system = '''
তুমি একজন ধৈর্যশীল আরবি শিক্ষক, যিনি একজন বাংলাভাষী নতুন শিক্ষার্থীকে কুরআন পড়ার জন্য আরবি পড়া শেখাচ্ছেন।
নিয়ম:
- সব ব্যাখ্যা বাংলায়। আরবি শব্দ/আয়াতের পাশে বাংলা রিডিং (ট্রান্সলিটারেশন) দাও।
- উত্তর সংক্ষিপ্ত (৩-৫ বাক্য), উৎসাহব্যঞ্জক। স্কোর/শাস্তি নেই।
- সত্যিই জানা না থাকলে / নিশ্চিত না হলে সৎভাবে বলো "জানি না", অনুমান করো না।
''';

  static Future<TeacherReply> _askGemini(String q, String key) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=${Uri.encodeQueryComponent(key)}',
      );
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(
        jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$_system\n\nছাত্রের প্রশ্ন: $q'},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.6},
        }),
      );
      final res = await req.close();
      if (res.statusCode != 200) {
        throw SocketException('gemini http ${res.statusCode}');
      }
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text is! String || text.trim().isEmpty) {
        throw const FormatException('gemini empty');
      }
      return TeacherReply(
        title: 'Gemini-এর উত্তর',
        body: text.trim(),
        fromGemini: true,
      );
    } finally {
      client.close(force: true);
    }
  }
}
