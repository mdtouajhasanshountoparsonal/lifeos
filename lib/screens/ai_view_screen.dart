import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/services/text_normalizer.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';

/// 🔍 AI-দিয়ে বানানো গাছ — ক্লিক করলে এখানে details পেজ আসে:
/// ১) শুধু AI-র লেখা (select → long-press → copy), ২) ✅ টিক-মার্ক (হয়ে গেছে)।
/// মূল নোটের লেখা কখনো বদলায় না; টিকগুলো Hive-এ জমা থাকে।
class AiViewScreen extends StatefulWidget {
  final String noteId;
  final String content;

  const AiViewScreen({super.key, required this.noteId, required this.content});

  @override
  State<AiViewScreen> createState() => _AiViewScreenState();
}

class _AiRow {
  final TreeNode node;
  final int depth;
  final bool isLast;
  final List<bool> trail;

  const _AiRow(this.node, this.depth, this.isLast, this.trail);
}

class _AiViewScreenState extends State<AiViewScreen> {
  late TreeBlueprint _tree;
  final List<_AiRow> _rows = [];
  late List<int> _ticks;

  Box get _box => Hive.box('ai_trees');

  List<int> _loadTicks() {
    final v = _box.get('ticks_n_${widget.noteId}');
    if (v is List) {
      return v.map((e) => (e as num).toInt()).toList();
    }
    return const [];
  }

  void _saveTicks() => _box.put('ticks_n_${widget.noteId}', _ticks);

  @override
  void initState() {
    super.initState();
    final saved = AiTreeStore.get(widget.noteId, task: false);
    _tree = BeautifiedTreeCard.resolve(saved?.blueprint, widget.content);
    _ticks = _loadTicks();
    void walk(TreeNode n, int depth, bool isLast, List<bool> trail) {
      _rows.add(_AiRow(n, depth, isLast, trail));
      final nextTrail = [...trail, isLast];
      for (var i = 0; i < n.children.length; i++) {
        walk(n.children[i], depth + 1, i == n.children.length - 1, nextTrail);
      }
    }

    for (var i = 0; i < _tree.nodes.length; i++) {
      walk(_tree.nodes[i], 0, i == _tree.nodes.length - 1, const []);
    }
  }

  void _toggle(int index) {
    setState(() {
      if (_ticks.contains(index)) {
        _ticks.remove(index);
      } else {
        _ticks.add(index);
      }
      _saveTicks();
    });
  }

  /// AI-র লেখা: মূল ডালগুলো ১. ২. ৩. নম্বর-সহ, বাচ্চাগুলো ├─ └─ গাইড-সহ।
  String _numberedText() {
    final b = StringBuffer();
    if (_tree.title.isNotEmpty) {
      b.writeln('${_tree.titleEmoji} ${_tree.title}');
      b.writeln('');
    }
    for (var i = 0; i < _tree.nodes.length; i++) {
      final n = _tree.nodes[i];
      b.writeln(
          '${TextNormalizer.banglaDigits((i + 1).toString())}. ${n.emoji} ${n.text}');
      void walk(TreeNode c, int d, bool last) {
        final pre = StringBuffer();
        for (var k = 1; k < d + 1; k++) {
          pre.write('   ');
        }
        pre.write(last ? '└─ ' : '├─ ');
        b.writeln('$pre${c.emoji} ${c.text}');
        for (var k = 0; k < c.children.length; k++) {
          walk(c.children[k], d + 1, k == c.children.length - 1);
        }
      }

      for (var k = 0; k < n.children.length; k++) {
        walk(n.children[k], 0, k == n.children.length - 1);
      }
    }
    return b.toString();
  }

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _numberedText()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ AI লেখা কপি হয়েছে'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (!_tree.hasNodes) {
      return Scaffold(
        backgroundColor: c.background,
        body: const Center(child: Text('এখানে AI-র লেখা নেই')),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(c),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                children: [
                  _selectableBlock(c),
                  const SizedBox(height: 14),
                  _tickBlock(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary, size: 22),
          ),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(_tree.titleEmoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tree.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'সব কপি',
            onPressed: _copyAll,
            icon: Icon(Icons.copy_all_rounded, size: 20, color: c.glow),
          ),
        ],
      ),
    );
  }

  Widget _selectableBlock(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('AI-র লেখা (চেপে ধরে select → copy)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.primary)),
              const Spacer(),
              GestureDetector(
                onTap: _copyAll,
                child: Text('কপি',
                    style: TextStyle(
                        fontSize: 11, color: c.glow, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectionArea(
            child: Text(
              _numberedText(),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickBlock(AppColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.glow.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text('তালিকা — হয়ে গেলে টিক দাও',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _rows.length; i++)
            _tickRow(c, _rows[i], i),
        ],
      ),
    );
  }

  Widget _tickRow(AppColors c, _AiRow r, int index) {
    final ticked = _ticks.contains(index);
    final prefix = StringBuffer();
    for (var d = 1; d < r.depth; d++) {
      prefix.write(r.trail[d - 1] ? '     ' : '│    ');
    }
    if (r.depth > 0) {
      prefix.write(r.isLast ? '└─ ' : '├─ ');
    }
    return InkWell(
      onTap: () => _toggle(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                ticked ? '☑' : '☐',
                style: TextStyle(
                  fontSize: 19,
                  height: 1,
                  color: ticked ? c.glow : c.textSecondary,
                ),
              ),
            ),
            Text(prefix.toString(),
                style: TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: c.glow.withValues(alpha: 0.45))),
            Text(r.node.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                r.node.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: ticked
                      ? c.textSecondary
                      : (r.depth == 0 ? c.primary : c.textPrimary),
                  decoration:
                      ticked ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}