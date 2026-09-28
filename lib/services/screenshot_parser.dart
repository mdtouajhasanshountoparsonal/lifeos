enum ScreenshotKind { expense, error, message }

class ScreenshotParseResult {
  final ScreenshotKind kind;
  final String title;
  final String content;
  final double? amount;
  final String? category;
  final DateTime? date;
  final DateTime? reminderDate;
  final String? reminderText;

  ScreenshotParseResult({
    required this.kind,
    required this.title,
    required this.content,
    this.amount,
    this.category,
    this.date,
    this.reminderDate,
    this.reminderText,
  });
}

class ScreenshotParser {
  static final Map<String, String> _banglaDigits = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
  };

  static String normalizeDigits(String text) {
    final buf = StringBuffer();
    for (final ch in text.split('')) {
      buf.write(_banglaDigits[ch] ?? ch);
    }
    return buf.toString();
  }

  static ScreenshotParseResult parse(String rawOcr) {
    final text = normalizeDigits(rawOcr.trim());
    final lower = text.toLowerCase();

    // ─── 1) Strong error hints → "Error" note ───────────────────────────────
    final errorHints = RegExp(
      r'\berror\b|\bexception\b|\btraceback\b|\bcrashed\b|force stop|not responding'
      r'|ত্রুটি|অ্যাপ\s+থাম\w*|এক্সেপশন|unable to|failed to|failure to',
      caseSensitive: false,
    );
    if (errorHints.hasMatch(lower)) {
      final title = _firstMeaningfulLine(text);
      return ScreenshotParseResult(
        kind: ScreenshotKind.error,
        title: 'ত্রুটি: $title',
        content: text,
      );
    }

    // ─── 2) Money present → Expense ─────────────────────────────────────────
    final amount = _extractAmount(text);
    if (amount != null) {
      return ScreenshotParseResult(
        kind: ScreenshotKind.expense,
        title: _expenseTitle(text, amount),
        content: text,
        amount: amount.amount,
        category: _categorize(text),
        date: _extractDate(lower) ?? DateTime.now(),
      );
    }

    // ─── 3) Everything else → Important message / note ──────────────────────
    final title = _firstMeaningfulLine(text);
    final deadline = _parseDeadline(lower);
    return ScreenshotParseResult(
      kind: ScreenshotKind.message,
      title: title.isEmpty ? 'গুরুত্বপূর্ণ বার্তা' : title,
      content: text,
      reminderDate: deadline,
      reminderText: deadline != null ? title : null,
    );
  }

  static _AmountMatch? _extractAmount(String text) {
    final money = RegExp(
      r'([\d][\d,.]*\.?\d{0,2})\s*(?:টাকা|tk|taka|৳|bdt|rs|₹|\$|usd|eur)'
      r'|(?:টাকা|tk|taka|৳|bdt|rs|₹|\$|usd)\s*([\d][\d,.]*\.?\d{0,2})',
      caseSensitive: false,
    );

    double? best;
    String? bestRaw;
    for (final m in money.allMatches(text)) {
      final numStr = (m.group(1) ?? m.group(2))!.replaceAll(',', '');
      final v = double.tryParse(numStr);
      if (v != null && (best == null || v > best)) {
        best = v;
        bestRaw = m.group(0);
      }
    }

    // Fallback: a bold "Total/Mোট/amount/sum" line with a number
    if (best == null) {
      final total = RegExp(
        r'^(?:total|grand\s*total|amount|sum|due|মোট|বাকি)\s*[:$]?\s*([\d][\d,.]*\.?\d{0,2})',
        caseSensitive: false,
        multiLine: true,
      );
      final m = total.firstMatch(text);
      if (m != null) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null) {
          return _AmountMatch(v, m.group(0)!);
        }
      }
      return null;
    }

    return _AmountMatch(best, bestRaw ?? '$best');
  }

  static String _expenseTitle(String text, _AmountMatch amount) {
    final idx = text.indexOf(amount.raw);
    if (idx >= 0) {
      final before = text.substring(0, idx).trim();
      if (before.isNotEmpty) {
        final line = before.split('\n').last.trim();
        if (line.length >= 3) return line.length > 60 ? line.substring(0, 60) : line;
      }
    }
    return 'খরচ';
  }

  static String _categorize(String text) {
    final l = text.toLowerCase();
    if (RegExp(r'restaurant|lunch|dinner|breakfast|foodpanda|hungry|hotel|caf|খাবার|লাঞ্চ|উঠেছ ঝেছ').hasMatch(l)) return 'food';
    if (RegExp(r'grocery|mart|super|vegetable|বাজার|সবজি|কিরানা').hasMatch(l)) return 'groceries';
    if (RegExp(r'transport|bus|train|rickshaw|pathao|uber|truck|fuel|petrol|পেট্রোল|রিকশা|ভাড়া|মিটার').hasMatch(l)) return 'transport';
    if (RegExp(r'electr|water|gas|internet|wifi|বিদ্যুৎ|পানি|গ্যাস|ইন্টারনেট|বিল\b|n\s*বিল').hasMatch(l)) return 'bills';
    if (RegExp(r'shop|mall|cloths|fashion|জামা|শপিং|মাল').hasMatch(l)) return 'shopping';
    if (RegExp(r'pharmacy|doctor|hospital|medicine|ওষুধ|ডাক্তার|মেডিসিন').hasMatch(l)) return 'health';
    return 'other';
  }

  static DateTime? _extractDate(String lower) {
    final dmy = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b')
        .firstMatch(lower);
    if (dmy != null) {
      final a = int.parse(dmy.group(1)!);
      final b = int.parse(dmy.group(2)!);
      var y = int.parse(dmy.group(3)!);
      if (y < 100) y += 2000;
      // assume day-month-year (Bangladesh convention)
      final day = a > 12 ? a : b;
      final month = a > 12 ? b : a;
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(y, month, day);
      }
    }
    final md = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{2,4})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    if (md != null) {
      final day = int.parse(md.group(1)!);
      final mon = months[md.group(2)!.substring(0, 3)];
      var y = int.parse(md.group(3)!);
      if (y < 100) y += 2000;
      if (mon != null) return DateTime(y, mon, day);
    }
    return null;
  }

  static DateTime? _parseDeadline(String lower) {
    final now = DateTime.now();
    var day = now;
    if (RegExp(r'\btoday\b|আজ\b').hasMatch(lower)) {
      day = now;
    } else if (RegExp(r'\btomorrow\b|আগামীকাল|কাল\s').hasMatch(lower)) {
      day = now.add(const Duration(days: 1));
    } else {
      const map = {
        'sunday': DateTime.sunday, 'monday': DateTime.monday,
        'tuesday': DateTime.tuesday, 'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday, 'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'রবিবার': DateTime.sunday, 'সোমবার': DateTime.monday,
        'মঙ্গলবার': DateTime.tuesday, 'বুধবার': DateTime.wednesday,
        'বৃহস্পতিবার': DateTime.thursday, 'শুক্রবার': DateTime.friday,
        'শনিবার': DateTime.saturday,
      };
      for (final e in map.entries) {
        if (lower.contains(e.key)) {
          var diff = e.value - now.weekday;
          if (diff <= 0) diff += 7;
          day = now.add(Duration(days: diff));
          break;
        }
      }
    }

    var hour = 18;
    var minute = 0;
    final time = RegExp(
      r'(\d{1,2})\s*(?::(\d{2}))?\s*(am|pm)\b|(\d{1,2}):(\d{2})\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (time != null) {
      if (time.group(4) != null) {
        hour = int.parse(time.group(4)!) % 24;
        minute = int.parse(time.group(5)!);
      } else {
        hour = int.parse(time.group(1)!) % 24;
        minute = int.parse(time.group(2) ?? '0');
        final isPm = time.group(3)?.toLowerCase() == 'pm';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
      }
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static String _firstMeaningfulLine(String text) {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.length >= 3) return t.length > 60 ? t.substring(0, 60) : t;
    }
    return text.length > 60 ? text.substring(0, 60) : text;
  }

  static String kindLabel(ScreenshotKind kind) {
    return switch (kind) {
      ScreenshotKind.expense => 'খরচ',
      ScreenshotKind.error => 'ত্রুটি টাইটেল',
      ScreenshotKind.message => 'গুরুত্বপূর্ণ বার্তা',
    };
  }

  static String kindEmoji(ScreenshotKind kind) {
    return switch (kind) {
      ScreenshotKind.expense => '💸',
      ScreenshotKind.error => '⚠️',
      ScreenshotKind.message => '📌',
    };
  }
}

class _AmountMatch {
  final double amount;
  final String raw;
  _AmountMatch(this.amount, this.raw);
}