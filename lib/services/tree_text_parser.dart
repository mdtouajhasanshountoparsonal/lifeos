import 'emoji_intent.dart';
import 'market_parser.dart' show marketEmoji;
import 'text_normalizer.dart';

/// P2: একটি গাছের নোড।
class TreeNode {
  final String text;
  final String emoji;
  final List<TreeNode> children;

  const TreeNode({
    required this.text,
    required this.emoji,
    this.children = const [],
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'emoji': emoji,
        'children': children.map((e) => e.toMap()).toList(),
      };

  factory TreeNode.fromMap(dynamic src) {
    final m = src is Map ? src : const <dynamic, dynamic>{};
    final kids = (m['children'] as List?) ?? const [];
    return TreeNode(
      text: '${m['text'] ?? ''}',
      emoji: '${m['emoji'] ?? '📌'}',
      children: kids.map<TreeNode>(TreeNode.fromMap).toList(),
    );
  }
}

/// P2: টেক্সট থেকে তৈরি করা গাছের ব্লুপ্রিন্ট।
class TreeBlueprint {
  final String title;
  final String titleEmoji;
  final List<TreeNode> nodes;
  final int fixCount;
  final bool wasEmpty;

  const TreeBlueprint({
    required this.title,
    required this.titleEmoji,
    required this.nodes,
    required this.fixCount,
    this.wasEmpty = false,
  });

  bool get hasNodes => nodes.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'title': title,
        'titleEmoji': titleEmoji,
        'fixCount': fixCount,
        'wasEmpty': wasEmpty,
        'nodes': nodes.map((e) => e.toMap()).toList(),
      };

  factory TreeBlueprint.fromMap(dynamic src) {
    final m = src is Map ? src : const <dynamic, dynamic>{};
    return TreeBlueprint(
      title: '${m['title'] ?? ''}',
      titleEmoji: '${m['titleEmoji'] ?? '📌'}',
      fixCount: ((m['fixCount'] as num?) ?? 0).toInt(),
      wasEmpty: (m['wasEmpty'] as bool?) ?? false,
      nodes: ((m['nodes'] as List?) ?? const [])
          .map<TreeNode>(TreeNode.fromMap)
          .toList(),
    );
  }
}

/// TreeTextParser — P2: রুক্ষ টেক্সট → (normalize) → এমোজিসহ গাছ।
///
/// ধাপ:
///   1. TextNormalizer.run (offline + শেখা corrections)
///   2. মাপের আইটেম বাছাই (`মাছ ৩টা`, `২ কেজি আলু` → 🛒-এর child)
///   3. সংযোগকারী (`তারপর`, `এরপর`…) ধরে বাকি অংশ ভাগ
///   4. প্রথম অংশ = শিরোনাম, বাকিগুলো = নোড (EmojiIntent দিয়ে)
class TreeTextParser {
  TreeTextParser._();

  static TreeBlueprint parse(
    String raw, {
    Map<String, String>? learned,
    Map<String, String>? learnedEmoji,
  }) {
    final n = TextNormalizer.run(raw, learned: learned);
    return build(n, learnedEmoji: learnedEmoji);
  }

  static TreeBlueprint build(
    NormalizedText n, {
    Map<String, String>? learnedEmoji,
  }) {
    if (n.text.isEmpty) {
      return const TreeBlueprint(
        title: '',
        titleEmoji: '📌',
        nodes: [],
        fixCount: 0,
        wasEmpty: true,
      );
    }

    var rest = n.text;

    // ── 2) মাপের আইটেম ──
    final items = <TreeNode>[];
    rest = _extractItems(rest, items);

    // ── 3) সংযোগকারী ধরে ভাগ ──
    final parts = rest
        .split(_connectorRe)
        .map((s) => s.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final titleRaw = parts.isEmpty
        ? (items.isEmpty ? 'নোট' : 'বাজার')
        : parts.first;
    final title = titleRaw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final restParts = parts.length > 1 ? parts.sublist(1) : const <String>[];

    final nodes = <TreeNode>[];
    if (items.isNotEmpty) {
      if (parts.isEmpty) {
        // পুরো লেখাই আইটেমে চলে গেছে — title-এর নিচে সরাসরি আইটেম (দ্বিগুণ 'বাজার' নেই)
        nodes.addAll(items);
      } else {
        nodes.add(TreeNode(text: 'বাজার', emoji: '🛒', children: items));
      }
    }
    for (final p in restParts) {
      final c = p.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (c.isEmpty) continue;
      nodes.add(TreeNode(text: c, emoji: EmojiIntent.pick(c, learned: learnedEmoji)));
    }

    return TreeBlueprint(
      title: title.isEmpty ? 'নোট' : title,
      titleEmoji: EmojiIntent.pick(title, learned: learnedEmoji),
      nodes: nodes,
      fixCount: n.fixCount,
    );
  }

  // ────────────────────────────────────────────────────────────────────────

  static final RegExp _connectorRe = RegExp(
    r'\s*(?:তারপর|তার পরে|তারপরও|তার পরেও|এরপর|এর পরে|সবশেষে|অবশেষে|শেষে|প্রথমে|তার আগে|উপরন্তু)\s*',
  );

  static const _stopnames = {
    'কাজ', 'বাজার', 'আর', 'এবং', 'তাই', 'তারপর', 'আজ', 'কাল', 'আগে', 'পরে',
  };

  static const _unitGroup =
      r'(?:টা|টি|টা|খানা|কেজি|কিলো|কিলোগ্রাম|kg|kgs|g|gm|gr|গ্রাম|লিটার|লি|ml|মিলি|ডজন|হালি|কুড়ি|দিস্তা|জোড়া|সের|ভরি|পোয়া|প্যাক|পিস|বোতল|ডাব|শত|হাজার|মিটার|ইঞ্চি)';

  static final _nameFirstRe = RegExp(
    '(^|[\\s.,!?;:])'
    '([\\u0980-\\u09FF]+|[a-zA-Z]+)'
    '\\s+([0-9০-৯]+(?:[.,][0-9০-৯]+)?)\\s*'
    '($_unitGroup)?',
  );

  static final _qtyFirstRe = RegExp(
    '(^|[\\s.,!?;:])'
    '([0-9০-৯]+(?:[.,][0-9০-৯]+)?)\\s*'
    '($_unitGroup)'
    '\\s+([\\u0980-\\u09FF]+|[a-zA-Z]+)',
  );

  static String _extractItems(String text, List<TreeNode> out) {
    var rest = text;
    // qty-first আগে (`২ কেজি আলু`), তারপর name-first (`মাছ ৩টা`)
    // — যেন `আর ২ কেজি`-এর মতো connector ভুলভাবে item না হয়।
    while (true) {
      final qf = _qtyFirstRe.firstMatch(rest);
      if (qf != null) {
        final phrase = qf.group(0)!;
        final name = qf.group(4)!.trim();
        rest = rest.replaceFirst(RegExp(RegExp.escape(phrase)), ' ');
        if (_skip(name)) continue;
        out.add(TreeNode(
          text: _itemText(name, phrase),
          emoji: marketEmoji(name),
        ));
        continue;
      }
      final nf = _nameFirstRe.firstMatch(rest);
      if (nf != null) {
        final phrase = nf.group(0)!;
        final name = nf.group(2)!.trim();
        final isStop = _skip(name);
        rest = rest.replaceFirst(RegExp(RegExp.escape(phrase)), ' ');
        if (isStop) continue;
        out.add(TreeNode(
          text: _itemText(name, phrase),
          emoji: marketEmoji(name),
        ));
        continue;
      }
      break;
    }
    return rest;
  }

  static bool _skip(String name) {
    if (name.length <= 1) return true;
    return _stopnames.contains(name);
  }

  static String _itemText(String name, String phrase) {
    // phrase-এর ভেতর থেকে নাম বাদ → মূল (normalized) পরিমাণ+একক
    final qtyPart =
        phrase.replaceFirst(RegExp(RegExp.escape(name)), '').trim();
    return qtyPart.isEmpty ? name : '$name $qtyPart';
  }
}