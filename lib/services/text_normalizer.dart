/// TextNormalizer — P1: রুক্ষ বাংলা/বাংলিশ লেখাকে পরিচ্ছন্ন বাংলায় বানায়।
///
/// ধাপসমূহ:
///   1. বাংলিশ → বাংলা dictionary (kaj→কাজ, kinbo→কিনবো, …)
///   2. ইউনিট/সংখ্যা (2kg→২ কেজি, 500 tk→৫০০ টাকা, 3ta→৩টা)
///   3. বাংলা বানান টাইপো ফিক্স (নাগের→হবে)
///   4. অবশিষ্ট সংখ্যা → বাংলা সংখ্যা (500→৫০০)
///   5. Sentence case (বাক্যের প্রথম ASCII অক্ষর বড়)
///   বাংলা বর্ণমালায় বড়/ছোট হাতের নেই — তাই শুধু ASCII-অক্ষরে case ঠিক হয়।
class TextFix {
  final String before;
  final String after;
  const TextFix(this.before, this.after);
}

class NormalizedText {
  final String text;
  final List<String> sentences;
  final List<TextFix> fixes;

  const NormalizedText({
    required this.text,
    required this.sentences,
    required this.fixes,
  });

  int get fixCount => fixes.length;

  NormalizedText copyWith({String? text, List<String>? sentences}) =>
      NormalizedText(
        text: text ?? this.text,
        sentences: sentences ?? this.sentences,
        fixes: fixes,
      );
}

class TextNormalizer {
  TextNormalizer._();

  static NormalizedText run(String raw, {Map<String, String>? learned}) {
    final fixes = <TextFix>[];
    var t = raw.replaceAll('\u200d', ' ').trim().replaceAll(RegExp(r'\s+'), ' ');

    // ── সংখ্যা + ইউনিট/করেন্সি/সাফিক্স ─────────────────────────────────
    t = _replaceAll(t, _unitRe, (m) {
      fixes.add(TextFix(m.group(0)!, '${_bengali(m.group(1)!)} ${_units[m.group(2)!.toLowerCase()]!}'));
      return '${_bengali(m.group(1)!)} ${_units[m.group(2)!.toLowerCase()]!}';
    });
    t = _replaceAll(t, _moneyRe, (m) {
      fixes.add(TextFix(m.group(0)!, '${_bengali(m.group(1)!)} টাকা'));
      return '${_bengali(m.group(1)!)} টাকা';
    });
    t = _replaceAll(t, _countSuffixRe, (m) {
      fixes.add(TextFix(m.group(0)!, '${_bengali(m.group(1)!)}টা'));
      return '${_bengali(m.group(1)!)}টা';
    });

    // ── বাংলিশ dictionary (দীর্ঘ শব্দ আগে) ──────────────────────────────
    t = _replaceWords(t, _banglish, fixes);
    // ── বাংলা টাইপো + online-AI-এর শেখা সংশোধন ─────────────────────────
    if (learned != null && learned.isNotEmpty) {
      t = _replaceWords(t, {..._typos, ...learned}, fixes);
    } else {
      t = _replaceWords(t, _typos, fixes);
    }

    // ── অবশিষ্ট দাঁড়ানো সংখ্যা → বাংলা ──────────────────────────────────
    t = _replaceAll(t, _standaloneDigitRe, (m) {
      fixes.add(TextFix(m.group(0)!, _bengali(m.group(0)!)));
      return _bengali(m.group(0)!);
    });

    t = _sentenceCase(t).trim().replaceAll(RegExp(r'\s+'), ' ');

    return NormalizedText(
      text: t,
      sentences: splitSentences(t),
      fixes: fixes,
    );
  }

  static String normalize(String raw) => run(raw).text;

  /// সংখ্যার ভেতরের অঙ্কগুলো বাংলা করে (1000→১০০০)। টুল public-ভাবে usable।
  static String banglaDigits(String s) => _bengali(s);

  /// বাক্যে ভাগ: `।`, `.` (দশমিক নয়), `!`, `?` এ সেন্টেন্স শেষ হয়।
  static List<String> splitSentences(String text) {
    if (text.trim().isEmpty) return const [];
    final runes = text.runes.toList();
    final parts = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final ch = String.fromCharCode(runes[i]);
      buf.write(ch);
      var boundary = ch == '।';
      if (ch == '.' || ch == '!' || ch == '?') {
        final prev = i > 0 ? String.fromCharCode(runes[i - 1]) : ' ';
        final next = i + 1 < runes.length ? String.fromCharCode(runes[i + 1]) : '';
        final isDecimal = ch == '.' && _isDigit(prev) && _isDigit(next);
        final endsAt = next.isEmpty || next == ' ';
        boundary = !isDecimal && endsAt;
      }
      if (boundary) {
        parts.add(buf.toString().trim());
        buf.clear();
      }
    }
    if (buf.isNotEmpty) parts.add(buf.toString().trim());
    return parts.where((s) => s.isNotEmpty).toList();
  }

  // ────────────────────────────────────────────────────────────────────────

  static const _bn = '০১২৩৪৫৬৭৮৯';
  static String _bengali(String s) {
    final buf = StringBuffer();
    for (final unit in s.runes) {
      final ch = String.fromCharCode(unit);
      if (ch == '.') {
        buf.write('.');
      } else {
        final idx = '0123456789'.indexOf(ch);
        buf.write(idx >= 0 ? _bn[idx] : ch);
      }
    }
    return buf.toString();
  }

  static bool _isDigit(String ch) {
    if (ch.isEmpty) return false;
    return RegExp(r'[0-9০-৯]').hasMatch(ch);
  }

  static String _replaceAll(String t, RegExp re, String Function(Match) fn) =>
      t.replaceAllMapped(re, fn);

  static String _replaceWords(
      String t, Map<String, String> dict, List<TextFix> fixes) {
    final keys = dict.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    var out = t;
    for (final k in keys) {
      final v = dict[k]!;
      final esc = RegExp.escape(k);
      final ascii = RegExp(r'^[\x00-\x7F]+$').hasMatch(k);
      final re = ascii
          ? RegExp('\\b$esc\\b', caseSensitive: false)
          : RegExp('(?<![\\u0980-\\u09FF])$esc(?![\\u0980-\\u09FF])');
      out = out.replaceAllMapped(re, (m) {
        fixes.add(TextFix(m[0]!, v));
        return v;
      });
    }
    return out;
  }

  static String _sentenceCase(String text) {
    final buf = StringBuffer();
    var cap = true;
    for (final unit in text.runes) {
      final ch = String.fromCharCode(unit);
      if (ch == '।' || ch == '.' || ch == '!' || ch == '?') {
        buf.write(ch);
        cap = true;
      } else if (ch == ' ' || ch == '\t') {
        buf.write(ch);
      } else if (cap && RegExp(r'[a-z]').hasMatch(ch)) {
        buf.write(ch.toUpperCase());
        cap = false;
      } else {
        buf.write(ch);
        cap = false;
      }
    }
    return buf.toString();
  }

  // ── regex ───────────────────────────────────────────────────────────────

  static final _unitRe = RegExp(
    r'(?<![0-9a-zA-Z])(\d+(?:[.,]\d+)?)\s*'
    r'(kg|kgs|kila|kilo|gr|g|gm|ltr|lt|litre|l|ml|pcs|pc|pkt|pk|dz|dozen|botol)\b',
    caseSensitive: false,
  );

  static final _moneyRe = RegExp(
    r'(?<![0-9a-zA-Z])(\d+(?:[.,]\d+)?)\s*(?:tk|taka|টাকা|৳)',
    caseSensitive: false,
  );

  static final _countSuffixRe = RegExp(
    r'(?<![0-9a-zA-Z])(\d+)\s*(?:ta|ti|টা|টি)',
    caseSensitive: false,
  );

  static final _standaloneDigitRe = RegExp(
    r'(?<![0-9a-zA-Z])\d+(?:\.\d+)?(?![0-9a-zA-Z])',
  );

  static const _units = {
    'kg': 'কেজি',
    'kgs': 'কেজি',
    'kila': 'কেজি',
    'kilo': 'কেজি',
    'gr': 'গ্রাম',
    'g': 'গ্রাম',
    'gm': 'গ্রাম',
    'ltr': 'লিটার',
    'lt': 'লিটার',
    'litre': 'লিটার',
    'l': 'লিটার',
    'ml': 'মিলি',
    'pcs': 'পিস',
    'pc': 'পিস',
    'pkt': 'প্যাক',
    'pk': 'প্যাক',
    'dz': 'ডজন',
    'dozen': 'ডজন',
    'botol': 'বোতল',
  };

  // ── বাংলিশ dictionary ───────────────────────────────────────────────────

  static const _banglish = {
    // সাধারণ
    'kaj': 'কাজ',
    'kajta': 'কাজটা',
    'kajti': 'কাজটি',
    'korbo': 'করবো',
    'korbe': 'করবে',
    'kori': 'করি',
    'korte': 'করতে',
    'kore': 'করে',
    'korechi': 'করেছি',
    'korle': 'করলে',
    'kinbo': 'কিনবো',
    'kinbe': 'কিনবে',
    'kina': 'কেনা',
    'kinte': 'কিনতে',
    'kinter': 'কিনতে',
    'kine': 'কিনে',
    'ashbo': 'আসবো',
    'asbo': 'আসবো',
    'asho': 'আসো',
    'ashbe': 'আসবে',
    'ashar': 'আসার',
    'take': 'তাকে',
    'jabo': 'যাবো',
    'jabe': 'যাবে',
    'jai': 'যাই',
    'jete': 'যেতে',
    'geye': 'গিয়ে',
    'dibo': 'দেবো',
    'dite': 'দিতে',
    'debe': 'দেবে',
    'hoy': 'হয়',
    'hobe': 'হবে',
    'hoilo': 'হইলো',
    'chole': 'চলে',
    'shes': 'শেষ',
    'sesh': 'শেষ',
    'koto': 'কত',
    'kotay': 'কোথায়',
    'kemone': 'কেমন',
    'kemon': 'কেমন',
    'kintu': 'কিন্তু',
    'kinto': 'কিন্তু',
    'thake': 'থেকে',
    'theke': 'থেকে',
    'diye': 'দিয়ে',
    'die': 'দিয়ে',
    'niye': 'নিয়ে',
    'kono': 'কোনো',
    'kon': 'কোন',
    'ki': 'কি',
    'keno': 'কেন',
    'ekhane': 'এখানে',
    'okhane': 'ওখানে',
    'ar': 'আর',
    'r': 'আর',
    'and': 'এবং',
    'ebong': 'এবং',
    'por': 'পরে',
    'pore': 'পরে',
    'age': 'আগে',
    'tarpor': 'তারপর',
    'erpor': 'এরপর',
    'seshe': 'শেষে',
    'sese': 'শেষে',
    'bhabo': 'ভাবো',
    'bhebe': 'ভেবে',
    'bujhbe': 'বুঝবে',
    'bujhbo': 'বুঝবো',
    // সময়
    'somoy': 'সময়',
    'raat': 'রাত',
    'raate': 'রাতে',
    'raatay': 'রাতে',
    'sokal': 'সকাল',
    'sokale': 'সকালে',
    'bikal': 'বিকাল',
    'bikale': 'বিকালে',
    'dupur': 'দুপুর',
    'dupure': 'দুপুরে',
    'sonjha': 'সন্ধ্যা',
    'sonjhay': 'সন্ধ্যায়',
    'agami': 'আগামী',
    'agami_kal': 'আগামীকাল',
    'aaj': 'আজ',
    'aj': 'আজ',
    // বাজার-জিনিস
    'bazar': 'বাজার',
    'market': 'বাজার',
    'mach': 'মাছ',
    'alu': 'আলু',
    'dal': 'ডাল',
    'bhat': 'ভাত',
    'dim': 'ডিম',
    'gosto': 'গোশত',
    'mangso': 'মাংস',
    'sag': 'শাক',
    'sak': 'শাক',
    'tomato': 'টমেটো',
    'piaj': 'পেঁয়াজ',
    'pioj': 'পেঁয়াজ',
    'ada': 'আদা',
    'halud': 'হলুদ',
    'morich': 'মরিচ',
    'lobon': 'লবণ',
    'cha': 'চা',
    // ঘর-বাসা
    'bashay': 'বাসায়',
    'basay': 'বাসায়',
    'fira': 'ফিরে',
    'basha': 'বাসা',
    'room': 'রুম',
    'ghor': 'ঘর',
    'laundry': 'লন্ড্রি',
    'byaayam': 'ব্যায়াম',
    'toilet': 'টয়লেট',
    'paper': 'পেপার',
    'kagoj': 'কাগজ',
    'kagaj': 'কাগজ',
    'chobi': 'ছবি',
    'dhon': 'ধন',
    // ব্যক্তি
    'ami': 'আমি',
    'amar': 'আমার',
    'amra': 'আমরা',
    'tumi': 'তুমি',
    'tumar': 'তোমার',
    'apni': 'আপনি',
    'apnar': 'আপনার',
    'tay': 'তাই',
    'soto': 'ছোট',
    'hater': 'হাতের',
    'mistake': 'মিস্টেক',
  };

  // ── বাংলা বানান টাইপো ───────────────────────────────────────────────────

  static const _typos = {
    'নাগের': 'হবে',
    'আনটে': 'আনতে',
    'কিলাবো': 'কিনবো',
  };
}