import '../models/task.dart' show Recurrence;
import 'price_parser.dart' show PriceParser;

enum CommandType { task, note, expense, bazar }

class ParsedCommand {
  final CommandType type;
  final String title;
  final double? amount;
  final String? category;
  final DateTime? deadline;
  final int priority;
  final String raw;

  ParsedCommand({
    required this.type,
    required this.title,
    this.amount,
    this.category,
    this.deadline,
    this.priority = 1,
    this.raw = '',
  });
}

class CommandParser {
  static ParsedCommand? parse(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();

    // ─── Expense ────────────────────────────────────────────────────────────
    //  "spent 120 on lunch" | "খরচ 120 দুপুরের খাবার" | "120 tk lunch"
    final spent = RegExp(
      r'(?:spent|spend|খরচ\s*ক\w*লাম?|খরচ|ব্যয়\s*ক\w*লাম?|ব্যয়)\s*([\d.,]+)\s*(?:tk|taka|৳|টাকা)?\s*(?:on|for|করে)?\s*(.*)',
      caseSensitive: false,
    ).firstMatch(text);
    final numberFirst = RegExp(
      r'^([\d.,]+)\s*(?:tk|taka|৳|টাকা)\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(text);

    Match? expenseMatch;
    if (spent != null && RegExp(r'[\d.,]+').hasMatch(text)) {
      expenseMatch = spent;
      text = spent.group(0)!;
    } else if (numberFirst != null) {
      expenseMatch = numberFirst;
      text = numberFirst.group(0)!;
    }

    if (expenseMatch != null) {
      final amount = double.tryParse(expenseMatch.group(1)!.replaceAll(',', ''));
      var title = (expenseMatch.group(2) ?? 'খরচ').trim();
      if (title.isEmpty) title = 'খরচ';
      return ParsedCommand(
        type: CommandType.expense,
        title: title,
        amount: amount,
        category: _categorizeExpense(title),
      );
    }

    // ─── Bazar (দর) ────────────────────────────────────────────────────────
    // "১ কেজি ইলিশ ১২০০ টাকা" | "আপেল ৫০" | "২ ডজন ডিম ৩০০"
    final p = PriceParser.parse(text);
    if (p.ok &&
        p.total > 0 &&
        p.item.length >= 2 &&
        p.item != 'জিনিস' &&
        (p.unit.isNotEmpty ||
            RegExp(r'[৳টাকা]|দাম').hasMatch(text.toLowerCase()))) {
      return ParsedCommand(
        type: CommandType.bazar,
        title: p.item,
        raw: text,
      );
    }

    // ─── Note ───────────────────────────────────────────────────────────────
    final notePrefix = RegExp(
      r'^(?:note:?\s*|remember\s+to\s+|মনে\s+রাখ\w*\s*|নোট\s*[:\-]?\s*)',
      caseSensitive: false,
    );
    if (lower.startsWith('note') ||
        lower.contains('remember') ||
        notePrefix.hasMatch(lower) ||
        lower.contains('মনে রাখ')) {
      final title = text.replaceFirst(notePrefix, '').trim();
      return ParsedCommand(
        type: CommandType.note,
        title: title.isEmpty ? 'নতুন নোট' : title,
      );
    }

    // ─── Task (default, and any "+" prefix) ─────────────────────────────────
    var title = text.replaceFirst(RegExp(r'^[+\-]\s*'), '').trim();
    final deadline = parseDeadline(title);
    final priority = parsePriority(title);
    return ParsedCommand(
      type: CommandType.task,
      title: title.isEmpty ? 'নতুন কাজ' : title,
      deadline: deadline,
      priority: priority,
    );
  }

  static String _categorizeExpense(String title) {
    final l = title.toLowerCase();
    if (RegExp(r'lunch|dinner|breakfast|খাবার|ভাত|চা\b|কফি|ফুড').hasMatch(l)) {
      return 'food';
    }
    if (RegExp(r'internet|net\b|ফোন|ইন্টারনেট|রিচার্জ|balance').hasMatch(l)) {
      return 'internet';
    }
    if (RegExp(r'bus|train|rickshaw|uber|pathao|যাতায়াত|ভাড়া|ট্রান্সপোর্ট').hasMatch(l)) {
      return 'transport';
    }
    if (RegExp(r'shop|shopping|cloths|কাপড়|শপিং|জামা').hasMatch(l)) {
      return 'shopping';
    }
    return 'other';
  }

  static int parsePriority(String title) {
    if (RegExp(r'urgent|জরুরি|must|অবশ্যই|আগে\s+কর|এখনই|গুরুত্বপূর্ণ|জরুরী')
        .hasMatch(title.toLowerCase())) {
      return 2;
    }
    return 1;
  }

  /// পুনরাবৃত্তি detection: প্রতিদিন / প্রতি N দিন / প্রতি সপ্তাহ / প্রতি মাস /
  /// নির্দিষ্ট সপ্তাহের দিন (প্রতি সোমবার)।
  static Recurrence? parseRecurrence(String title) {
    final lower = _toAsciiDigits(title.toLowerCase());

    final nDays = RegExp(r'প্রতি\s*(\d{1,2})\s*দিন').firstMatch(lower);
    if (nDays != null) {
      return Recurrence(
          unit: 'daily', interval: int.parse(nDays.group(1)!));
    }
    if (RegExp(r'প্রতি\s*দিন|প্রতিদিন|রোজ\b|দৈনিক|every\s*day|daily')
        .hasMatch(lower)) {
      return const Recurrence(unit: 'daily');
    }

    final nWeeks = RegExp(r'প্রতি\s*(\d{1,2})\s*সপ্তাহ').firstMatch(lower);
    if (nWeeks != null) {
      return Recurrence(
          unit: 'weekly', interval: int.parse(nWeeks.group(1)!));
    }
    if (RegExp(r'প্রতি\s*সপ্তাহে|প্রতি\s*সপ্তাহ|weekly').hasMatch(lower)) {
      return const Recurrence(unit: 'weekly');
    }

    final nMonths = RegExp(r'প্রতি\s*(\d{1,2})\s*মাস').firstMatch(lower);
    if (nMonths != null) {
      return Recurrence(
          unit: 'monthly', interval: int.parse(nMonths.group(1)!));
    }
    if (RegExp(r'প্রতি\s*মাসে|মাসিক|monthly').hasMatch(lower)) {
      return const Recurrence(unit: 'monthly');
    }

    const weekdayMap = {
      'রবিবার': 7,
      'সোমবার': 1,
      'মঙ্গলবার': 2,
      'বুধবার': 3,
      'বৃহস্পতিবার': 4,
      'শুক্রবার': 5,
      'শনিবার': 6,
    };
    if (RegExp(r'প্রতি|every\s*week|weekly').hasMatch(lower)) {
      final weekdays = <int>[
        for (final m in weekdayMap.entries)
          if (lower.contains(m.key)) m.value,
      ];
      if (weekdays.isNotEmpty) {
        return Recurrence(unit: 'weekly', weekdays: weekdays);
      }
    }
    return null;
  }

  static DateTime? parseDeadline(String title) {
    final lower = _toAsciiDigits(title.toLowerCase());
    final now = DateTime.now();
    var day = now;

    if (RegExp(r'\btomorrow\b|কাল\b|আগামীকাল').hasMatch(lower)) {
      day = now.add(const Duration(days: 1));
    } else if (RegExp(r'\btoday\b|আজ\b').hasMatch(lower)) {
      day = now;
    } else {
      // Weekday names → next occurrence
      const map = {
        'sunday': DateTime.sunday,
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'রবিবার': DateTime.sunday,
        'সোমবার': DateTime.monday,
        'মঙ্গলবার': DateTime.tuesday,
        'বুধবার': DateTime.wednesday,
        'বৃহস্পতিবার': DateTime.thursday,
        'শুক্রবার': DateTime.friday,
        'শনিবার': DateTime.saturday,
      };
      for (final entry in map.entries) {
        if (lower.contains(entry.key)) {
          var diff = entry.value - now.weekday;
          if (diff <= 0) diff += 7;
          day = now.add(Duration(days: diff));
          break;
        }
      }
    }

    // Time part — order matters: "6:30 pm | 18:00" → "6 pm" → "৬টা"
    int? hour;
    var minute = 0;
    bool? isPm;

    final t1 = RegExp(
      r'(\d{1,2}):(\d{2})\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(lower);
    if (t1 != null) {
      hour = int.parse(t1.group(1)!) % 24;
      minute = int.parse(t1.group(2)!);
      final ap = t1.group(3);
      if (ap != null) isPm = ap.toLowerCase().startsWith('p');
    } else {
      final t2 = RegExp(
        r'(\d{1,2})\s*(am|pm)\b',
        caseSensitive: false,
      ).firstMatch(lower);
      if (t2 != null) {
        hour = int.parse(t2.group(1)!);
        isPm = t2.group(2)!.toLowerCase().startsWith('p');
      } else {
        final t3 = RegExp(r'(\d{1,2})\s*টা(য়|টা)?').firstMatch(lower);
        if (t3 != null) {
          hour = int.parse(t3.group(1)!);
        }
      }
    }

    if (hour != null && isPm == null) {
      final pmHint =
          RegExp(r'সন্ধ্যা|বিকাল|বিকাল|রাত|রাতে|দুপুর').hasMatch(lower) &&
              !RegExp(r'সকাল|ভোর').hasMatch(lower);
      isPm = pmHint;
    }

    var h = hour ?? 18;
    if (hour != null && isPm == true) {
      if (h == 12) {
        h = RegExp(r'রাত').hasMatch(lower) ? 0 : 12;
      } else if (h < 12) {
        h += 12;
      }
    }
    if (hour != null && isPm == false && h == 12) h = 0;

    return DateTime(day.year, day.month, day.day, h, minute);
  }

  /// বাংলা অঙ্ক (০-৯) → ASCII (0-9)। সময় পারসিং-এ ব্যবহৃত।
  static String _toAsciiDigits(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = bn.indexOf(ch);
      return i >= 0 ? '$i' : ch;
    }).join();
  }

  static int exportPriority(int priority) {
    return switch (priority) {
      2 => 2,
      0 => 0,
      _ => 1,
    };
  }

  static String priorityLabel(int priority) {
    return switch (priority) {
      2 => 'বেশি',
      1 => 'মাঝারি',
      _ => 'কম',
    };
  }

  static String typeLabel(CommandType type) {
    return switch (type) {
      CommandType.task => 'কাজ',
      CommandType.note => 'নোট',
      CommandType.expense => 'খরচ',
      CommandType.bazar => 'বাজার দর',
    };
  }
}