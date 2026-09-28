import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';

/// A small markdown-ish renderer used by the advanced notes editor.
///
/// Block rules:
///  - `# `, `## `, `### `  -> headings
///  - `- `                  -> bullet point
///  - `1. `, `2. ` ...      -> numbered item
///
/// Inline rules:
///  - `**text**`            -> bold
///  - `*text*`              -> italic
///  - `__text__`            -> underline
///  - `<big>text</big>`     -> larger font
///  - `<small>text</small>` -> smaller font
///  - `<b>`, `<i>`, `<u>`   -> tag aliases
class MarkupText extends StatelessWidget {
  final String content;
  final Color? baseColor;

  /// When true, checklist boxes become tappable; [onToggleCheck] receives the
  /// 0-based line index of the tapped item.
  final bool interactiveChecks;
  final ValueChanged<int>? onToggleCheck;

  const MarkupText(this.content,
      {super.key, this.baseColor, this.interactiveChecks = false, this.onToggleCheck});

  static final RegExp _inlineRe = RegExp(
    r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|(__([^_]+)__)|(<big>|</big>)|(<small>|</small>)|(<b>|</b>)|(<i>|</i>)|(<u>|</u>)',
  );

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final color = baseColor ?? c.textPrimary;
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    const pad = EdgeInsets.only(bottom: 4);
    final children = <Widget>[];
    int auto = 0;
    int lineIndex = 0;
    for (final raw in lines) {
      final curLine = lineIndex;
      lineIndex++;
      final line = raw.trimRight();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }
      final trimmed = line.trimLeft();
      TextStyle base = TextStyle(fontSize: 14, height: 1.5, color: color);
      String display = trimmed;
      bool bullet = false;
      bool quote = false;
      bool checklist = false;
      bool checked = false;
      if (trimmed == '---' || trimmed == '***') {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 1.4,
            decoration: BoxDecoration(
              color: AppTheme.of(context).textSecondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('### ')) {
        display = trimmed.substring(4);
        base = base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
      } else if (trimmed.startsWith('## ')) {
        display = trimmed.substring(3);
        base = base.copyWith(fontSize: 19, fontWeight: FontWeight.w700);
      } else if (trimmed.startsWith('# ')) {
        display = trimmed.substring(2);
        base = base.copyWith(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3);
      } else if (trimmed.startsWith('> ')) {
        display = trimmed.substring(2);
        quote = true;
      } else if (trimmed.startsWith('- ')) {
        var rest = trimmed.substring(2);
        final chk = RegExp(r'^(\[\s?\]|\[x\]|☐|☑)\s+').firstMatch(rest);
        if (chk != null) {
          checklist = true;
          checked = chk.group(1)!.contains('x') || chk.group(1) == '☑';
          display = rest.substring(chk.group(0)!.length);
        } else {
          display = rest;
          bullet = true;
        }
      } else {
        final chk = RegExp(r'^(\[\s?\]|\[x\]|☐|☑)\s+').firstMatch(trimmed);
        if (chk != null) {
          checklist = true;
          checked = chk.group(1)!.contains('x') || chk.group(1) == '☑';
          display = trimmed.substring(chk.group(0)!.length);
        } else {
          final num = RegExp(r'^(\d+)[.)]\s+').firstMatch(trimmed);
          if (num != null) {
            auto = int.parse(num.group(1)!);
            display = trimmed.substring(num.group(0)!.length);
            bullet = true;
          }
        }
      }
      final spans = _parseInline(display, base);
      if (bullet) {
        auto = auto == 0 ? 1 : auto;
        children.add(RichText(
          text: TextSpan(
            style: base,
            children: [
              TextSpan(
                text: auto > 0 ? '$auto. ' : '• ',
                style: TextStyle(color: AppTheme.of(context).primary, fontWeight: FontWeight.w700),
              ),
              ...spans,
            ],
          ),
          textScaler: MediaQuery.textScalerOf(context),
        ));
        if (auto > 0) auto++;
      } else if (checklist) {
        final box = GestureDetector(
          onTap: interactiveChecks && onToggleCheck != null ? () => onToggleCheck!(curLine) : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: checked
                  ? AppTheme.of(context).primary
                  : AppTheme.of(context).textSecondary,
            ),
          ),
        );
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box,
            Expanded(
              child: RichText(
                text: TextSpan(style: base.copyWith(decoration: checked ? TextDecoration.lineThrough : null), children: spans),
                textScaler: MediaQuery.textScalerOf(context),
              ),
            ),
          ],
        ));
      } else if (quote) {
        children.add(Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.of(context).primary.withValues(alpha: 0.6), width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RichText(
              text: TextSpan(style: base.copyWith(fontStyle: FontStyle.italic, color: AppTheme.of(context).textSecondary), children: spans),
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        ));
      } else {
        children.add(RichText(
          text: TextSpan(style: base, children: spans),
          textScaler: MediaQuery.textScalerOf(context),
        ));
      }
      children.add(Padding(padding: pad, child: const SizedBox.shrink()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  List<TextSpan> _parseInline(String s, TextStyle base) {
    final spans = <TextSpan>[];
    final tags = <String>[]; // active open tags: b, i, u, big, small
    final matches = _inlineRe.allMatches(s).toList();
    int pos = 0;
    for (final m in matches) {
      if (m.start > pos) {
        spans.add(TextSpan(text: s.substring(pos, m.start), style: _apply(base, tags)));
      }
      pos = m.end;
      // classify
      String? wrapped;
      String? open;
      String? close;
      if (m.group(1) != null) wrapped = m.group(2);
      if (m.group(3) != null) wrapped = m.group(4);
      if (m.group(5) != null) wrapped = m.group(6);
      final tagTok = m.group(7) ?? m.group(8) ?? m.group(9) ?? m.group(10);
      if (tagTok != null) {
        if (tagTok.startsWith('</')) {
          close = tagTok.substring(2, tagTok.length - 1);
        } else {
          open = tagTok.substring(1, tagTok.length - 1);
        }
      }
      if (wrapped != null) {
        final tag = m.group(1) != null
            ? 'b'
            : (m.group(3) != null ? 'i' : 'u');
        spans.add(TextSpan(text: wrapped, style: _apply(base, [...tags, tag])));
      } else if (open != null) {
        tags.add(open);
      } else if (close != null) {
        tags.remove(close);
      }
    }
    if (pos < s.length) {
      spans.add(TextSpan(text: s.substring(pos), style: _apply(base, tags)));
    }
    return spans;
  }

  TextStyle _apply(TextStyle base, List<String> tags) {
    var st = base;
    if (tags.contains('b')) st = st.copyWith(fontWeight: FontWeight.w700);
    if (tags.contains('i')) st = st.copyWith(fontStyle: FontStyle.italic);
    if (tags.contains('u')) st = st.copyWith(decoration: TextDecoration.underline);
    if (tags.contains('big')) st = st.copyWith(fontSize: (st.fontSize ?? 14) + 4);
    if (tags.contains('small')) st = st.copyWith(fontSize: ((st.fontSize ?? 14) - 2).clamp(9.0, 30.0));
    return st;
  }

  /// Renders markup into a `TextSpan` (markers hidden) — used by the note
  /// editor so **bold** / *italic* / __underline__ / <big> / <small> appear
  /// formatted *while typing* inside the TextField itself.
  static TextSpan renderInlineSpans(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    var bold = false;
    var italic = false;
    var under = false;
    var big = false;
    var small = false;

    void flush() {
      if (buf.isEmpty) return;
      var st = base;
      if (bold) st = st.copyWith(fontWeight: FontWeight.w700);
      if (italic) st = st.copyWith(fontStyle: FontStyle.italic);
      if (under) st = st.copyWith(decoration: TextDecoration.underline);
      if (big) st = st.copyWith(fontSize: (st.fontSize ?? 14) + 3);
      if (small) st = st.copyWith(fontSize: ((st.fontSize ?? 14) - 1.5).clamp(9.0, 30.0));
      spans.add(TextSpan(text: buf.toString(), style: st));
      buf.clear();
    }

    var i = 0;
    while (i < text.length) {
      final rest = text.substring(i);
      if (rest.startsWith('**')) {
        flush();
        bold = !bold;
        i += 2;
      } else if (rest.startsWith('__')) {
        flush();
        under = !under;
        i += 2;
      } else if (rest.startsWith('*')) {
        flush();
        italic = !italic;
        i += 1;
      } else if (rest.startsWith('<big>')) {
        flush();
        big = true;
        i += 5;
      } else if (rest.startsWith('</big>')) {
        flush();
        big = false;
        i += 6;
      } else if (rest.startsWith('<small>')) {
        flush();
        small = true;
        i += 7;
      } else if (rest.startsWith('</small>')) {
        flush();
        small = false;
        i += 8;
      } else if (rest.startsWith('<b>')) {
        flush();
        bold = true;
        i += 3;
      } else if (rest.startsWith('</b>')) {
        flush();
        bold = false;
        i += 4;
      } else if (rest.startsWith('<i>')) {
        flush();
        italic = true;
        i += 3;
      } else if (rest.startsWith('</i>')) {
        flush();
        italic = false;
        i += 4;
      } else if (rest.startsWith('<u>')) {
        flush();
        under = true;
        i += 3;
      } else if (rest.startsWith('</u>')) {
        flush();
        under = false;
        i += 4;
      } else {
        final code = text.codeUnitAt(i);
        buf.writeCharCode(code);
        i++;
        // keep surrogate pairs (emoji) together
        if (code >= 0xD800 && code <= 0xDBFF && i < text.length) {
          buf.writeCharCode(text.codeUnitAt(i));
          i++;
        }
      }
    }
    flush();
    return TextSpan(style: base, children: spans);
  }
}

/// Removes all markup tokens so plain text can be used for search/preview.
String stripMarkup(String s) {
  var out = s.replaceAll('\r\n', '\n');
  out = out
      .replaceAllMapped(
        RegExp(r'(\*{2}|_{2})(.*?)\1', multiLine: true),
        (m) => m.group(2) ?? '',
      )
      .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'</?(big|small)>'), '')
      .replaceAll(RegExp(r'</?[biu]>'), '');
  final lines = out.split('\n').map((l) {
    var t = l;
    if (t.trim() == '---' || t.trim() == '***') return ' ';
    t = t.replaceFirst(RegExp(r'^#{1,3} '), '');
    t = t.replaceFirst(RegExp(r'^>\s+'), '');
    t = t.replaceFirst(RegExp(r'^(\[\s?\]|\[x\]|☐|☑)\s+'), '');
    t = t.replaceFirst(RegExp(r'^\d+[.)]\s+'), '').replaceFirst(RegExp(r'^-\s+'), '');
    return t;
  }).join('\n');
  return lines.trim();
}

/// Wraps [text] with [before]/[after] around the current selection, or inserts
/// them at the cursor. Returns the new selection.
TextSelection wrapSelection(TextEditingController ctrl, TextSelection sel, String before, String after) {
  final text = ctrl.text;
  final start = sel.start;
  final end = sel.end;
  final selected = text.substring(start, end);
  final newText = text.substring(0, start) + before + selected + after + text.substring(end);
  ctrl.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: start + before.length + selected.length + after.length));
  return ctrl.selection;
}

/// Inserts [token] at the current selection, and if this is a block token
/// (heading/bullet/numbering), it is placed at the start of its line.
TextSelection insertToken(TextEditingController ctrl, TextSelection sel, String token, {bool block = false}) {
  final text = ctrl.text;
  var lineStart = 0;
  if (block) {
    final idx = text.lastIndexOf('\n', sel.start <= 0 ? 0 : sel.start - 1);
    lineStart = idx < 0 ? 0 : idx + 1;
  }
  final start = block ? lineStart : sel.start;
  final end = block ? lineStart : sel.end;
  final newText = text.substring(0, start) + token + text.substring(end);
  final caret = start + token.length;
  ctrl.value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: caret));
  return ctrl.selection;
}