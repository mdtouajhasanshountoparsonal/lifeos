import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/unfold_animation.dart';

/// P3: সরল লেখা → "সুন্দর AI গাছ" কার্ড।
///
/// - ইনপুট [raw] ঠিকমত normalize করে [TreeBlueprint] বানায় (P1+P2 ইঞ্জিন)
/// - একটা AnimationController দিয়ে সব লাইন "উপর থেকে নিচে" ভাঁজ খোলে
///   ([UnfoldItem] staggered slide+fade — কাগজ উল্টানোর অনুভূতি)
/// - Tree-গাইড লাইন (├─ └─ │) গাছের মূল-ডালের চেহারা দেয়
/// - [fixCount] > 0 হলে ✨ ব্যাজ দেখায় (AI/নরমালাইজার কত জায়গা ঠিক করেছে)
/// - [blueprint] দিলে নিজে parse না করে সেটাই দেখায় (online-AI ফলাফল বসানোর জন্য);
///   [aiSource] != null হলে সোর্স-ব্যাজ (🌐 Gemini / 🤖 offline) দেখায়
/// - online-AI গাছ খালি (কোনো node নেই) হলে নিজে [raw] থেকে গাছ বানায় —
///   তাই AI-র লেখা কখনোই "faka/অদৃশ্য" হয় না
/// - খালি লেখায় [SizedBox.shrink] — কোথাও বসালে নিরাপদ
class BeautifiedTreeCard extends StatefulWidget {
  final String raw;
  final TreeBlueprint? blueprint;
  final String? aiSource;
  final bool animate;
  final Duration base;

  const BeautifiedTreeCard({
    super.key,
    required this.raw,
    this.blueprint,
    this.aiSource,
    this.animate = true,
    this.base = const Duration(milliseconds: 1500),
  });

  /// blueprint-এর ভেতর node না থাকলে (AI কিছুই গাছ করতে পারেনি) নিজের parse।
  static TreeBlueprint resolve(TreeBlueprint? bp, String raw) {
    final t = bp ?? TreeTextParser.parse(raw);
    return t.hasNodes ? t : TreeTextParser.parse(raw);
  }

  @override
  State<BeautifiedTreeCard> createState() => _BeautifiedTreeCardState();
}

class _BeautifiedTreeCardState extends State<BeautifiedTreeCard>
    with SingleTickerProviderStateMixin {
  late TreeBlueprint _tree;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _tree = BeautifiedTreeCard.resolve(widget.blueprint, widget.raw);
    _controller = AnimationController(vsync: this, duration: widget.base);
    if (widget.animate && _tree.hasNodes) {
      _controller.forward();
    } else if (!widget.animate) {
      // list-ভিউ: animation ছাড়াই পুরো গাছ সরাসরি দৃশ্যমান
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(BeautifiedTreeCard old) {
    super.didUpdateWidget(old);
    if (widget.blueprint != null && widget.blueprint != old.blueprint) {
      _tree = BeautifiedTreeCard.resolve(widget.blueprint, widget.raw);
    } else if (widget.raw != old.raw && widget.blueprint == null) {
      _tree = TreeTextParser.parse(widget.raw);
    } else {
      return;
    }
    _controller.reset();
    if (widget.animate && _tree.hasNodes) {
      _controller.forward();
    } else if (!widget.animate) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tree.wasEmpty) return const SizedBox.shrink();
    final c = AppTheme.of(context);
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: c.cardColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.glow.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: c.glow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _buildRows(c),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────

  List<Widget> _buildRows(AppColors c) {
    final rows = <Widget>[];
    var index = 1; // শিরোনাম = index 0
    final total =
        1 + _tree.nodes.fold<int>(0, (a, n) => a + _nodeSize(n));

    rows.add(UnfoldItem(
      animation: _controller,
      index: 0,
      count: total,
      child: _titleRow(c),
    ));

    for (final n in _tree.nodes) {
      _addRows(n, 0, false, const [], c, rows, () => index++, total);
    }
    return rows;
  }

  static int _nodeSize(TreeNode n) =>
      1 + n.children.fold<int>(0, (a, c) => a + _nodeSize(c));

  void _addRows(
    TreeNode n,
    int depth,
    bool isLast,
    List<bool> trail,
    AppColors c,
    List<Widget> rows,
    int Function() nextIndex,
    int total,
  ) {
    rows.add(UnfoldItem(
      animation: _controller,
      index: nextIndex(),
      count: total,
      child: _nodeRow(n, depth, isLast, trail, c),
    ));
    final nextTrail = [...trail, isLast];
    for (var i = 0; i < n.children.length; i++) {
      _addRows(
        n.children[i],
        depth + 1,
        i == n.children.length - 1,
        nextTrail,
        c,
        rows,
        nextIndex,
        total,
      );
    }
  }

  String _treeText() {
    final b = StringBuffer();
    if (_tree.title.isNotEmpty) {
      b.writeln('${_tree.titleEmoji} ${_tree.title}');
    }
    void walk(TreeNode n, int depth, bool isLast) {
      final pre = StringBuffer();
      for (var d = 1; d < depth; d++) {
        pre.write('│   ');
      }
      if (depth > 0) pre.write(isLast ? '└─ ' : '├─ ');
      b.writeln('$pre${n.emoji} ${n.text}');
      for (var i = 0; i < n.children.length; i++) {
        walk(n.children[i], depth + 1, i == n.children.length - 1);
      }
    }

    for (var i = 0; i < _tree.nodes.length; i++) {
      walk(_tree.nodes[i], 0, i == _tree.nodes.length - 1);
    }
    return b.toString();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _treeText()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ গাছ কপি হয়েছে'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _titleRow(AppColors c) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Text(_tree.titleEmoji, style: const TextStyle(fontSize: 21)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            _tree.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: 'কপি',
          onPressed: _copy,
          icon: Icon(Icons.copy_rounded, size: 16, color: c.textSecondary),
        ),
        if (_tree.fixCount > 0)
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.glow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '✨ ${_tree.fixCount}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.glow,
                ),
              ),
            ),
          ),
        if (widget.aiSource != null)
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (widget.aiSource == 'gemini'
                        ? c.secondary
                        : c.textSecondary)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.aiSource == 'gemini' ? '🌐 Gemini' : '🤖 offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.aiSource == 'gemini'
                      ? c.secondary
                      : c.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _nodeRow(TreeNode n, int depth, bool isLast, List<bool> trail, AppColors c) {
    final prefix = StringBuffer();
    for (var d = 1; d < depth; d++) {
      prefix.write(trail[d - 1] ? '    ' : '│   ');
    }
    if (depth > 0) {
      prefix.write(isLast ? '└─ ' : '├─ ');
    }
    return Padding(
      padding: EdgeInsets.only(top: depth == 0 ? 12 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix.isNotEmpty)
            Text(
              prefix.toString(),
              style: TextStyle(
                fontSize: 15,
                height: 1,
                color: c.glow.withValues(alpha: 0.5),
              ),
            ),
          Text(n.emoji, style: const TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              n.text,
              style: TextStyle(
                fontSize: depth == 0 ? 17 : 15.5,
                fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w600,
                height: 1.3,
                color: depth == 0 ? c.primary : c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}