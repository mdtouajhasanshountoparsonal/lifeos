import 'dart:convert';
import 'dart:io';

import 'ai_fix_store.dart';
import 'ai_settings.dart';
import 'emoji_intent.dart';
import 'text_normalizer.dart';
import 'tree_text_parser.dart';

/// AiEnhancer — P2+ : "AI" = offline নিয়ম-ইঞ্জিন, পছন্দ করলে online
/// (Gemini/OpenAI API) ব্যবহার করা যায়। online-এর ফলাফল AiFixStore-এ
/// জমা হয়, ফলে পরের বার offline-ও স্মার্ট থাকে।
///
/// dual-mode:
///   `AiEnhancer.enhance(raw)`                        → offline (সাব-সেকেন্ড)
///   `AiEnhancer.enhance(raw, allowOnline: true)`     → AiSettings মতে Gemini/GPT,
///                                                        key না থাকলে offline-এ fallback
/// P5: online গেট = AiSettings.onlineEnabled (More→AI ENGINE-এ টগল), provider =
/// AiSettings.provider (gemini | openai)।
class EnhanceResult {
  final NormalizedText normalized;
  final TreeBlueprint tree;
  final bool usedOnline;
  final String? source;

  const EnhanceResult({
    required this.normalized,
    required this.tree,
    required this.usedOnline,
    this.source,
  });
}

abstract class AiProvider {
  Future<EnhanceResult> enhance(String raw);
}

/// offline: TextNormalizer + TreeTextParser + EmojiIntent (শেখা মেনে চলে)।
class OfflineAiProvider implements AiProvider {
  const OfflineAiProvider();

  @override
  Future<EnhanceResult> enhance(String raw) async {
    final learned = AiFixStore.ready ? AiFixStore.learnedWords : const <String, String>{};
    final learnedEmoji = AiFixStore.ready ? AiFixStore.learnedEmoji : const <String, String>{};
    final n = TextNormalizer.run(raw, learned: learned);
    final tree = TreeTextParser.build(n, learnedEmoji: learnedEmoji);
    return EnhanceResult(normalized: n, tree: tree, usedOnline: false, source: 'offline');
  }
}

/// online: Gemini generateContent REST (best-effort).
/// শেখা সংশোধন + এমোজি result-এ থেকে AiFixStore-এ জমা হয়।
class OnlineGeminiAiProvider implements AiProvider {
  final String apiKey;
  final String endpoint;

  const OnlineGeminiAiProvider({
    required this.apiKey,
    this.endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent',
  });

  bool get isConfigured => apiKey.isNotEmpty;

  static const _system = '''
তুমি একজন বাংলা লেখা গোছানোর সহকারী। ইনপুট বাংলা/বাংলিশ টেক্সট। আউটপুট শুধু JSON:
{
  "title": "সংক্ষিপ্ত শিরোনাম",
  "title_emoji": "একটি এমোজি",
  "nodes": [
    {"text": "লাইনের লেখা", "emoji": "এমোজি", "children": [{"text": "...", "emoji": "...", "children": []}]}
  ],
  "fixes": [["ভুল শব্দ", "শুদ্ধ শব্দ"]],
  "learned_emoji": [["শব্দ", "এমোজি"]]
}
- title অথবা nodes-এর একটিকে শিরোনাম/প্রথম নোড করা যাবে।
- বানান/বাক্য ঠিক করো, nodes গাছ-মতো গোছাও (মূল বিন্দু → সাব-বিন্দু)।
- কোনো কোড-ফেন্স বা ব্যাখ্যা নয়, শুধু JSON।
''';

  static const _designSystem = '''
তুমি বাংলা নোট ডিজাইনার। ইনপুট বাংলা/বাংলিশ নোট। এটাকে সুন্দর সাজানো মার্কডাউন নোটে বানাও:
- মূল শিরোনাম `#`, সাব-বিষয় `##` / `###` দিয়ে
- পয়েন্টগুলো `-` বুলেট, প্রয়োজনে এমোজি
- বানান/বাক্য ঠিক করো, অপ্রয়োজনীয় পুনরাবৃত্তি বাদ দাও
- দাম/টাকা/আইটেমের হিসাব থাকলে শেষে একটি "## 🧮 হিসাব" অংশে
  প্রতিটা আইটেম `- আইটেম নাম ৳দাম` আকারে (যেমন: `- মুরগি ৳৩২০`) দিও,
  যেন নোটের হিসাব-ডিজাইন সুন্দর দেখায়
- শুধু ডিজাইন করা নোটটা দাও — কোনো ব্যাখ্যা বা কোড-ফেন্স নয়
''';

  /// ইন্টারনেট থাকলে Gemini দিয়ে নোট ডিজাইন/লিখা (বদলে নতুন সুন্দর মার্কডাউন)।
  /// ব্যর্থ হলে মূল লেখাই ফেরত। লেখা কখনো হারায় না।
  Future<String> design(String raw) async {
    final t = raw.trim();
    if (!isConfigured || t.isEmpty) return raw;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(apiKey)}');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'contents': [
          {'role': 'user', 'parts': [{'text': '$_designSystem\n---\n$raw'}]}
        ],
        'generationConfig': {'temperature': 0.4},
      }));
      final res = await req.close();
      if (res.statusCode != 200) return raw;
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text is! String) return raw;
      var out = text.trim();
      if (out.startsWith('```')) {
        out = out
            .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }
      return out.isEmpty ? raw : out;
    } catch (_) {
      return raw;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<EnhanceResult> enhance(String raw) async {
    final offline = const OfflineAiProvider();
    if (!isConfigured) return offline.enhance(raw);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(apiKey)}');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'contents': [
          {'role': 'user', 'parts': [{'text': '$_system\n---\n$raw'}]}
        ],
        'generationConfig': {'temperature': 0.3},
      }));
      final res = await req.close();
      if (res.statusCode != 200) return await offline.enhance(raw);
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final rawText = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (rawText is! String) return await offline.enhance(raw);

      final map = _TreeJson.extract(rawText);
      if (map == null) return await offline.enhance(raw);
      final tree = _TreeJson.treeFromMap(map);
      if (tree == null) return await offline.enhance(raw);

      // online-এর শেখা → offline-এর জন্য জমা
      final fixes = (map['fixes'] is List)
          ? (map['fixes'] as List)
              .whereType<List>()
              .where((e) => e.length >= 2 && e[0] is String && e[1] is String)
              .map((e) => TextFix(e[0] as String, e[1] as String))
              .toList()
          : <TextFix>[];
      final learnedEmoji = (map['learned_emoji'] is List)
          ? (map['learned_emoji'] as List)
              .whereType<List>()
              .where((e) => e.length >= 2 && e[0] is String && e[1] is String)
              .map((e) => MapEntry(e[0] as String, e[1] as String))
              .toList()
          : <MapEntry<String, String>>[];
      if (fixes.isNotEmpty) await AiFixStore.rememberFixes(fixes);
      if (learnedEmoji.isNotEmpty) await AiFixStore.rememberEmojis(learnedEmoji);

      final n = TextNormalizer.run(raw, learned: AiFixStore.learnedWords);
      return EnhanceResult(
        normalized: n,
        tree: tree,
        usedOnline: true,
        source: 'gemini',
      );
    } catch (_) {
      return offline.enhance(raw);
    } finally {
      client.close(force: true);
    }
  }
}

/// P5: OpenAI (GPT) — Gemini provider-এর মতোই best-effort + শেখা-জমা + fallback।
class OnlineOpenAiProvider implements AiProvider {
  final String apiKey;
  final String model;
  final String endpoint;

  const OnlineOpenAiProvider({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.endpoint = 'https://api.openai.com/v1/chat/completions',
  });

  bool get isConfigured => apiKey.isNotEmpty;

  static const _system = '''
You are a Bengali text tidying assistant. Input is Bangla/Banglish text. Output ONLY JSON:
{
  "title": "short title",
  "title_emoji": "one emoji",
  "nodes": [
    {"text": "line text", "emoji": "emoji", "children": [{"text": "...", "emoji": "...", "children": []}]}
  ],
  "fixes": [["wrong word", "correct word"]],
  "learned_emoji": [["word", "emoji"]]
}
- Fix spelling and sentence casing; arrange nodes as a tree (main point -> sub-points).
- No code fences, no explanations, only JSON.
''';

  static const _openAiDesignSystem = '''
You are a Bengali note designer. Rework the Bangla/Banglish note into a beautiful markdown note:
- Main title with "#", subtopics with "##"/"###"
- Points as "-" bullets, add emojis where helpful
- Fix spelling/sentence casing, drop useless repetition
- If it contains prices/money/items, end with a "## 🧮 হিসাব" section, each item as "- item name ৳price" (e.g. "- মুরগি ৳৩২০")
- Output ONLY the redesigned note, no explanations, no code fences
''';

  /// GPT দিয়ে নোট ডিজাইন। ব্যর্থ হলে মূল লেখা ফেরত।
  Future<String> design(String raw) async {
    final t = raw.trim();
    if (!isConfigured || t.isEmpty) return raw;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse(endpoint);
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      req.write(jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': _openAiDesignSystem},
          {'role': 'user', 'content': raw},
        ],
        'temperature': 0.4,
      }));
      final res = await req.close();
      if (res.statusCode != 200) return raw;
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final text = decoded['choices']?[0]?['message']?['content'];
      if (text is! String) return raw;
      var out = text.trim();
      if (out.startsWith('```')) {
        out = out
            .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
            .replaceFirst(RegExp(r'```\s*$'), '')
            .trim();
      }
      return out.isEmpty ? raw : out;
    } catch (_) {
      return raw;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<EnhanceResult> enhance(String raw) async {
    final offline = const OfflineAiProvider();
    if (!isConfigured) return offline.enhance(raw);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final uri = Uri.parse(endpoint);
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      req.write(jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': _system},
          {'role': 'user', 'content': raw},
        ],
        'temperature': 0.3,
      }));
      final res = await req.close();
      if (res.statusCode != 200) return await offline.enhance(raw);
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      final rawText =
          decoded['choices']?[0]?['message']?['content'];
      if (rawText is! String) return await offline.enhance(raw);

      final map = _TreeJson.extract(rawText);
      if (map == null) return await offline.enhance(raw);
      final tree = _TreeJson.treeFromMap(map);
      if (tree == null) return await offline.enhance(raw);

      final fixes = (map['fixes'] is List)
          ? (map['fixes'] as List)
              .whereType<List>()
              .where((e) => e.length >= 2 && e[0] is String && e[1] is String)
              .map((e) => TextFix(e[0] as String, e[1] as String))
              .toList()
          : <TextFix>[];
      final learnedEmoji = (map['learned_emoji'] is List)
          ? (map['learned_emoji'] as List)
              .whereType<List>()
              .where((e) => e.length >= 2 && e[0] is String && e[1] is String)
              .map((e) => MapEntry(e[0] as String, e[1] as String))
              .toList()
          : <MapEntry<String, String>>[];
      if (fixes.isNotEmpty) await AiFixStore.rememberFixes(fixes);
      if (learnedEmoji.isNotEmpty) await AiFixStore.rememberEmojis(learnedEmoji);

      final n = TextNormalizer.run(raw, learned: AiFixStore.learnedWords);
      return EnhanceResult(
        normalized: n,
        tree: tree,
        usedOnline: true,
        source: 'openai',
      );
    } catch (_) {
      return offline.enhance(raw);
    } finally {
      client.close(force: true);
    }
  }
}

/// Gemini + OpenAI দুই provider-এর shared JSON প্রসেসিং।
class _TreeJson {
  static Map<String, dynamic>? extract(String raw) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '').replaceFirst(RegExp(r'```\s*$'), '');
    }
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final d = jsonDecode(t.substring(start, end + 1));
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  static TreeBlueprint? treeFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final nodeList = nodesFromList(map['nodes']);
    final title = (map['title'] as String?)?.trim() ?? '';
    final titleEmoji = (map['title_emoji'] as String?) ?? '📌';
    return TreeBlueprint(
      title: title.isEmpty ? 'নোট' : title,
      titleEmoji: titleEmoji.isEmpty ? '📌' : titleEmoji,
      nodes: nodeList,
      fixCount: 0,
      wasEmpty: false,
    );
  }

  static List<TreeNode> nodesFromList(dynamic list) {
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map<TreeNode?>((m) {
          final text = (m['text'] as String?)?.trim() ?? '';
          if (text.isEmpty) return null;
          final emo = m['emoji'] as String?;
          final emoji = (emo == null || emo.isEmpty)
              ? EmojiIntent.pick(text)
              : emo;
          return TreeNode(
            text: text,
            emoji: emoji,
            children: nodesFromList(m['children']),
          );
        })
        .whereType<TreeNode>()
        .toList();
  }

  const _TreeJson._();
}

/// সহজ প্রবেশ-বিন্দু।
class AiEnhancer {
  AiEnhancer._();

  static const _geminiEnv = String.fromEnvironment('LIFEOS_GEMINI_KEY');
  static const _openAiEnv = String.fromEnvironment('LIFEOS_OPENAI_KEY');

  /// offline-এ দ্রুত কাজ করে। [allowOnline] হলে AiSettings অনুযায়ী Gemini/GPT
  /// চেষ্টা করে — key/সংযোগ না থাকলে নিজে থেকেই offline-এ নেমে আসে।
  static Future<EnhanceResult> enhance(
    String raw, {
    bool allowOnline = false,
    String? geminiKey,
    String? openAiKey,
  }) async {
    await AiFixStore.init();
    if (allowOnline && AiSettings.onlineEnabled) {
      if (AiSettings.provider == AiSettings.openai) {
        final key = (openAiKey != null && openAiKey.isNotEmpty)
            ? openAiKey
            : _openAiEnv;
        if (key.isNotEmpty) {
          return OnlineOpenAiProvider(apiKey: key).enhance(raw);
        }
      } else {
        final key = (geminiKey != null && geminiKey.isNotEmpty)
            ? geminiKey
            : _geminiEnv;
        if (key.isNotEmpty) {
          return OnlineGeminiAiProvider(apiKey: key).enhance(raw);
        }
      }
    }
    return const OfflineAiProvider().enhance(raw);
  }

  /// "AI ডিজাইন/লিখা" — নোটের লেখাকে Gemini/GPT দিয়ে সুন্দর মার্কডাউন নোটে
  /// বদলায় (ইন্টারনেট না থাকলে বা ব্যর্থ হলে মূল লেখাই ফেরত, কিছু হারায় না)।
  static Future<String> design(
    String raw, {
    String? geminiKey,
    String? openAiKey,
  }) async {
    await AiFixStore.init();
    if (AiSettings.onlineEnabled) {
      if (AiSettings.provider == AiSettings.openai) {
        final key = (openAiKey != null && openAiKey.isNotEmpty)
            ? openAiKey
            : _openAiEnv;
        if (key.isNotEmpty) {
          return OnlineOpenAiProvider(apiKey: key).design(raw);
        }
      } else {
        final key = (geminiKey != null && geminiKey.isNotEmpty)
            ? geminiKey
            : _geminiEnv;
        if (key.isNotEmpty) {
          return OnlineGeminiAiProvider(apiKey: key).design(raw);
        }
      }
    }
    return raw;
  }
}