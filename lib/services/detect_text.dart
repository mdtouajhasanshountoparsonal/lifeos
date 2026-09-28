/// Offline, heuristic-aware text classification + insight generators.
/// Nothing here ever leaves the device (no network).
class TextInsight {
  TextInsight._();

  static final RegExp _otp = RegExp(
    r'(otp|one[ -]?time\s*pin|verification\s*code|security\s*code|\u0986\u09aa\u09a8\u09be\u09b0\s*\u0995\u09cb\u09a1|\u0995\u09cb\u09a1)',
    caseSensitive: false,
  );
  static final RegExp _secretKeyword = RegExp(
    r'(password|passwd|pin|secret|api[_-]?key|access[_-]?token|client[_-]?secret|private\s*key|otp|verification)|(\u09aa\u09be\u09b8\u09aa\u09b0\u09cd\u09a1|\u09aa\u09bf\u09a8|\u0997\u09cb\u09aa\u09a8)',
    caseSensitive: false,
  );

  /// Categorizes clipboard/shared text without sending it anywhere.
  static String typeOf(String text) {
    final t = text.trim();
    if (t.isEmpty) return 'text';
    if (t.startsWith('http://') || t.startsWith('https://')) return 'link';
    if (t.contains('@') && t.contains('.') && !t.contains(' ')) return 'email';
    if (RegExp(r'\bSSID\b|WIFI:', caseSensitive: false).hasMatch(t)) return 'wifi';
    final phone = RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(t) &&
        !RegExp(r'^\d{4,6}$').hasMatch(t);

    if (phone) return 'phone';
    if ((t.startsWith('{') && t.contains(':')) || (t.startsWith('[') && t.contains(':'))) return 'json';
    if (RegExp(r'\b(class|function|def|import|void|return|const|var)\b', caseSensitive: false).hasMatch(t) &&
        (t.contains(';') || t.contains('=>') || t.contains('{') || t.contains('\n'))) {
      return 'code';
    }
    return 'text';
  }

  /// True when the text likely contains credentials/private info and should be
  /// masked by default.
  static bool isSensitive(String text) {
    final t = text.toLowerCase();
    if (_secretKeyword.hasMatch(t)) return true;
    final digits = RegExp(r'\d{4,8}').allMatches(t).map((m) => m.group(0)!).toList();
    if (digits.isNotEmpty && _otp.hasMatch(t)) return true;
    // a lone password-like value (mostly symbols+digits, unbroken)
    if (t.length <= 20 && RegExp(r'^[A-Za-z0-9!@#$%^&*_.+-]{5,}$').hasMatch(t) &&
        RegExp(r'\d').hasMatch(t) && RegExp(r'[A-Z]|[@!#$%^&*]').hasMatch(t)) {
      return true;
    }
    return false;
  }

  static List<String> splitSentences(String text) {
    return text
        .split(RegExp(r'[\n।.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 12)
        .toList();
  }

  /// Returns a heuristic one-line summary (first meaningful sentence, then the
  /// longest remaining sentence).
  static String oneLineSummary(String text) {
    final s = splitSentences(text);
    if (s.isEmpty) return text.trim();
    if (s.length == 1) return s.first;
    final first = s.first;
    var best = s.skip(1).reduce((a, b) => a.length >= b.length ? a : b);
    if (first.length >= best.length) return first;
    return '$first — ... — $best';
  }

  /// Extracts up to five key points offline: always the first sentence, then
  /// keyword-rich or longest remaining sentences.
  static List<String> keyPoints(String text) {
    final s = splitSentences(text);
    if (s.isEmpty) return [];
    final points = <String>[s.first];
    final kw = RegExp(
      r'(important|essential|must|always|never|however|therefore|means|result|because|\u09af\u09a4\u09c7|\u0995\u09be\u09b0\u09a3|\u09a4\u09be\u0987|\u09ae\u09be\u09a8\u09c7|\u09ae\u09a8\u09c7 \u09b0\u09be\u0996|\u098f\u09ac\u0982|\u09b9\u09b2\u09c7)',
      caseSensitive: false,
    );
    final scored = s.skip(1).map((x) => (x, kw.hasMatch(x) ? 2 : 0, x.length));
    final chosen = scored.toList()
      ..sort((a, b) {
        final ka = a.$2 + a.$3; // keyword bonus then prefer longer
        final kb = b.$2 + b.$3;
        return kb.compareTo(ka);
      });
    for (final c in chosen.take(4)) {
      points.add(c.$1);
    }
    return points.toSet().toList().take(5).toList();
  }
}