import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/command_parser.dart' show CommandParser;
import 'package:lifeos/services/detect_text.dart';
import 'package:lifeos/services/task_brain.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/note_chooser_sheet.dart';

class ClipboardInboxScreen extends StatefulWidget {
  const ClipboardInboxScreen({super.key});

  @override
  State<ClipboardInboxScreen> createState() => _ClipboardInboxScreenState();
}

class _ClipboardInboxScreenState extends State<ClipboardInboxScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'all';
  final Map<String, bool> _revealed = {};
  final Set<String> _clipTreeLoading = {};

  static const _filters = ['all', 'link', 'text', 'email', 'wifi', 'phone', 'code', 'sensitive'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoGrab());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoGrab();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  /// পর্দা খুললেই / অ্যাপে ফিরতেই সিস্টেম clipboard থেকে latest কপি auto-জমা
  /// (নীরবে — ডুপ্লিকেট হলে এড়িয়ে যায়)।
  Future<void> _autoGrab() async {
    try {
      if (!Hive.isBoxOpen('clipboard')) return;
      final data = await Clipboard.getData('text/plain');
      final t = data?.text?.trim();
      if (t == null || t.isEmpty || !mounted) return;
      final box = Hive.box('clipboard');
      final exists = box.values.any((x) => x is Map && x['text'] == t);
      if (exists) return;
      _add(t);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('📋 কপি করা লেখা জমা হলো'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
    } catch (_) {}
  }

  void _add(String text) {
    final now = DateTime.now();
    final sensitive = TextInsight.isSensitive(text);
    final box = Hive.box('clipboard');
    box.add({
      'id': now.millisecondsSinceEpoch.toString(),
      'text': text,
      'type': TextInsight.typeOf(text),
      'at': now.toIso8601String(),
      'sensitive': sensitive,
      'starred': false,
    });
  }

  Future<void> _grabClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final t = data?.text;
      if (t == null || t.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ক্লিপবোর্ড খালি')));
        }
        return;
      }
      _add(t);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ক্লিপবোর্ড থেকে জমা হয়েছে'), backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ক্লিপবোর্ড পড়া যায়নি')));
      }
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    }
  }

  bool _isTaskHint(String text) {
    final b = TaskBrain.analyze(text);
    if (b == null) return false;
    return b.deadline != null ||
        b.recurrence != null ||
        b.priority >= 2 ||
        b.items.isNotEmpty ||
        b.isShopping ||
        b.category == 'Study' ||
        RegExp(r'করব|কিনব|শিখব|আনব|শেষ\s*কর|বানাব|ডেডলাইন|টাস্ক',
                caseSensitive: false)
            .hasMatch(text);
  }

  void _makeTask(String text) {
    final b = TaskBrain.analyze(text) ??
        TaskBrain(title: text.trim().replaceAll(RegExp(r'\s+'), ' '));
    final now = DateTime.now();
    Hive.box<Task>('tasks').add(Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: b.title.isEmpty ? text.trim() : b.title,
      priority: CommandParser.exportPriority(b.priority),
      createdAt: now,
      deadline: b.deadline,
      category: b.category,
      expectedCost: b.expectedCost,
      recurrence: b.recurrence?.toMap(),
    )..setItemList(b.items));
    _toast('📌 কাজ লাগানো হলো — Tasks-এ দেখুন');
  }

  Map<String, dynamic> _entry(dynamic raw) {
    return Map<String, dynamic>.from(raw is Map ? raw : const {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Smart Clipboard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _grabClipboard,
                    style: IconButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.content_paste_go_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'খুঁজুন...',
                  hintStyle: TextStyle(color: c.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(f.toUpperCase(), style: const TextStyle(fontSize: 11)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        visualDensity: VisualDensity.compact,
                        selectedColor: c.primary,
                        labelStyle: TextStyle(
                          color: _filter == f ? Colors.white : c.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('clipboard').listenable(),
                builder: (context, box, _) {
                  final raw = box.values.toList().reversed.toList();
                  final items = raw
                      .map(_entry)
                      .where((e) => _filter == 'all' || (e['type'] == _filter) || (_filter == 'sensitive' && e['sensitive'] == true))
                      .where((e) => _query.isEmpty || (e['text'] as String).toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_add_check_rounded, size: 64, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('কিছু copy/share করুন — এখানে জমা হবে',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Chrome/YouTube → Share → LifeOS', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, i) => EntranceItem(order: i, child: _card(c, items[i])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _genTree(String id, String text) async {
    if (AiTreeStore.getClip(id) != null) {
      AiTreeStore.removeClip(id);
      setState(() {});
      return;
    }
    setState(() => _clipTreeLoading.add(id));
    try {
      final r = await AiEnhancer.enhance(text, allowOnline: true)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      AiTreeStore.saveClip(id, r.tree, source: r.source);
      setState(() => _clipTreeLoading.remove(id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _clipTreeLoading.remove(id));
    }
  }

  Widget _card(AppColors c, Map<String, dynamic> e) {
    final id = e['id'] as String;
    final text = e['text'] as String? ?? '';
    final type = e['type'] as String? ?? 'text';
    final at = e['at'] as String?;
    final sensitive = e['sensitive'] == true;
    final starred = e['starred'] == true;
    final revealed = _revealed[id] ?? (!sensitive);

    final masked = sensitive && !revealed;
    final display = masked ? '•••••••••••• (সংবেদনশীল — দেখতে ট্যাপ করুন)' : text;

    final kp = revealed ? TextInsight.keyPoints(text) : const <String>[];
    final sum = revealed ? TextInsight.oneLineSummary(text) : '';
    final clipTree = AiTreeStore.getClip(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: sensitive ? Border.all(color: c.glow.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sensitive ? c.glow.withValues(alpha: 0.15) : c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sensitive ? '🔐 ${type.toUpperCase()}' : type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sensitive ? c.glow : c.primary),
                ),
              ),
              const Spacer(),
              if (at != null)
                Text(DateFormat('MMM d, HH:mm').format(DateTime.parse(at)),
                    style: TextStyle(fontSize: 10, color: c.textSecondary.withValues(alpha: 0.7))),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onLongPress: () => _showActionSphere(e),
            onTap: sensitive && !revealed
                ? () => setState(() => _revealed[id] = true)
                : () => setState(() => _revealed[id] = !revealed),
            child: Text(
              display,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.5),
            ),
          ),
          if (revealed && sum.isNotEmpty && text.length > 60) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.surfaceColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✨ মূল কথাসমূহ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.glow)),
                  const SizedBox(height: 4),
                  for (final p in kp.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text('• $p', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.textSecondary)),
                    ),
                ],
              ),
            ),
          ],
          if (clipTree != null) ...[
            const SizedBox(height: 10),
            BeautifiedTreeCard(
              raw: text,
              blueprint: clipTree.blueprint,
              aiSource: clipTree.source,
              animate: false,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _mini(c, Icons.copy_rounded, () {
                Clipboard.setData(ClipboardData(text: text));
                _toast('কপি হয়েছে');
              }),
              const SizedBox(width: 8),
              _mini(c, Icons.note_add_rounded, () async {
                final dest = await NoteChooser.pick(context);
                if (dest == null) return;
                NoteChooser.appendTo(
                  noteId: dest['id'] as String?,
                  title: dest['title'] as String?,
                  block: '# 📋 ${type.toUpperCase()}\n>$text',
                );
                _toast('নোটে যোগ হয়েছে: ${dest['title']}');
              }),
              const SizedBox(width: 8),
              _mini(c, starred ? Icons.star_rounded : Icons.star_border_rounded, () {
                final b = Hive.box('clipboard');
                final idx = b.values.toList().indexWhere((x) => (x is Map) && x['id'] == id);
                if (idx >= 0) {
                  final entry = Map<String, dynamic>.from(b.getAt(idx) as Map);
                  entry['starred'] = !starred;
                  b.putAt(idx, entry);
                  setState(() {});
                }
              }, color: starred ? Colors.amber : null),
              const SizedBox(width: 8),
              if (_clipTreeLoading.contains(id))
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: c.glow),
                  ),
                )
              else
                _mini(c, Icons.auto_awesome_rounded, () => _genTree(id, text),
                    color: clipTree != null ? c.glow : null),
              const Spacer(),
              if (type == 'link')
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'লিংক',
                  onPressed: () => _toast('লিংক: ${text.length > 40 ? '${text.substring(0, 40)}…' : text}'),
                  icon: Icon(Icons.open_in_new_rounded, size: 18, color: c.textSecondary),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final b = Hive.box('clipboard');
                  final idx = b.values.toList().indexWhere((x) => (x is Map) && x['id'] == id);
                  if (idx >= 0) b.deleteAt(idx);
                  setState(() {});
                },
                icon: Icon(Icons.delete_outline, size: 18, color: c.expense),
              ),
            ],
          ),
          if (!sensitive && _isTaskHint(text)) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.primary,
                  side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _makeTask(text),
                icon: const Icon(Icons.task_alt_rounded, size: 15),
                label: const Text('কাজ বানাও',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mini(AppColors c, IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: c.surfaceColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 17, color: color ?? c.primary),
      ),
    );
  }

  /// কার্ডে লং-প্রেস → action bubbles-এর ring (ছেড়ে দেওয়া যায় না, বাবলগুলোর
  /// চারপাশে হালকা ভাসমান অবয়ব)।
  void _showActionSphere(Map<String, dynamic> e) {
    final id = e['id'] as String;
    final text = e['text'] as String? ?? '';
    final type = e['type'] as String? ?? 'text';
    final starred = e['starred'] == true;
    final sensitive = e['sensitive'] == true;
    final c = AppTheme.of(context);

    final List<_SphereAction> actions = [
      _SphereAction(
        Icons.copy_rounded, c.primary, 'কপি',
        () {
          Clipboard.setData(ClipboardData(text: text));
          _toast('কপি হয়েছে');
        },
      ),
      _SphereAction(
        Icons.note_add_rounded, c.secondary, 'নোট',
        () async {
          final dest = await NoteChooser.pick(context);
          if (dest == null) return;
          NoteChooser.appendTo(
            noteId: dest['id'] as String?,
            title: dest['title'] as String?,
            block: '# 📋 ${type.toUpperCase()}\n>$text',
          );
          _toast('নোটে যোগ হয়েছে: ${dest['title']}');
        },
      ),
      _SphereAction(
        Icons.auto_awesome_rounded, c.glow, 'AI গাছ',
        () => _genTree(id, text),
      ),
      if (!sensitive && _isTaskHint(text))
        _SphereAction(
          Icons.task_alt_rounded, c.secondary, 'কাজ',
          () => _makeTask(text),
        ),
      _SphereAction(
        starred ? Icons.star_rounded : Icons.star_border_rounded, Colors.amber, 'তারকা',
        () {
          final b = Hive.box('clipboard');
          final idx = b.values.toList().indexWhere((x) => (x is Map) && x['id'] == id);
          if (idx >= 0) {
            final entry = Map<String, dynamic>.from(b.getAt(idx) as Map);
            entry['starred'] = !starred;
            b.putAt(idx, entry);
            setState(() {});
          }
        },
      ),
      _SphereAction(
        Icons.delete_outline, c.expense, 'মুছো',
        () {
          final b = Hive.box('clipboard');
          final idx = b.values.toList().indexWhere((x) => (x is Map) && x['id'] == id);
          if (idx >= 0) b.deleteAt(idx);
          setState(() {});
        },
      ),
    ];

    final centerTitle = sensitive ? '🔐 ${type.toUpperCase()}' : type.toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Center(
          child: _Sphere(
            key: ValueKey(id),
            centerIcon: Icons.content_paste_go_rounded,
            centerTitle: centerTitle,
            centerText: text.replaceAll('\n', ' ').trim(),
            centerColor: c.primary,
            actionCount: actions.length,
            actions: actions,
          ),
        ),
      ),
    );
  }
}

class _SphereAction {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SphereAction(this.icon, this.color, this.label, this.onTap);
}

/// Action-sphere: কেন্দ্রে একটি বড় বাবল + চারপাশে বৃত্তাকারে action বাবল।
/// Entrance staggered (elastic), প্রতিটা হালকা ভাসে। একটাই controller।
class _Sphere extends StatefulWidget {
  final IconData centerIcon;
  final String centerTitle;
  final String centerText;
  final Color centerColor;
  final int actionCount;
  final List<_SphereAction> actions;
  const _Sphere({
    super.key,
    required this.centerIcon,
    required this.centerTitle,
    required this.centerText,
    required this.centerColor,
    required this.actionCount,
    required this.actions,
  });

  @override
  State<_Sphere> createState() => _SphereState();
}

class _SphereState extends State<_Sphere> with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _t = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final n = widget.actionCount;
    return LayoutBuilder(
      builder: (context, cons) {
        final size = (math.min(cons.maxWidth, cons.maxHeight) - 16)
            .clamp(150.0, 320.0);
        final radius = size * (100 / 320);
        final cx = size / 2, cy = size / 2;
        final centerD = (size * 0.42).clamp(80.0, 132.0);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _t,
                builder: (context, _) {
                  final s = Curves.elasticOut
                      .transform(((_t.value - 0.0) / 0.4).clamp(0.0, 1.0));
                  return Transform.scale(
                    scale: s,
                    child: _bubbleBox(
                      c,
                      widget.centerIcon,
                      widget.centerTitle,
                      widget.centerText,
                      widget.centerColor,
                      diameter: centerD,
                      big: centerD > 100,
                    ),
                  );
                },
              ),
              for (int i = 0; i < n; i++)
                AnimatedBuilder(
                  animation: _t,
                  builder: (context, _) {
                    final double p = ((_t.value - i * 0.075) / 0.35)
                        .clamp(0.0, 1.0);
                    final double scale = Curves.elasticOut.transform(p);
                    final double hover =
                        math.sin((_t.value * 2.0 * math.pi) * 1.2 - i * 0.45) *
                            3;
                    final double a = -math.pi / 2 + (2 * math.pi * i) / n;
                    final double x = cx + math.cos(a) * radius;
                    final double y = cy + math.sin(a) * radius + hover;
                    return Positioned(
                      left: x - 27,
                      top: y - 27,
                      child: Opacity(
                        opacity: p.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          child: _ActBubble(
                            action: widget.actions[i],
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.actions[i].onTap();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubbleBox(
    AppColors c,
    IconData icon,
    String title,
    String text,
    Color color, {
    required double diameter,
    required bool big,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.06)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: big ? 26 : 20),
            if (big) ...[
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(text,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9, color: c.textSecondary, height: 1.2)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActBubble extends StatelessWidget {
  final _SphereAction action;
  final VoidCallback onPressed;
  const _ActBubble({required this.action, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [action.color.withValues(alpha: 0.3), action.color.withValues(alpha: 0.08)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(color: action.color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: action.color, size: 22),
              Text(action.label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}