import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/command_parser.dart' show CommandParser;
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/services/task_brain.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/hub_screen.dart' show TreeBranch;
import 'package:lifeos/widgets/ocean_background.dart';
import 'package:lifeos/widgets/search_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// P2: Task Tree — flattened rows + ListView.builder (virtualized)
// ─────────────────────────────────────────────────────────────────────────────

sealed class _Row {}

class _SectionRow extends _Row {
  final String emoji;
  final String title;
  final int count;
  _SectionRow(this.emoji, this.title, this.count);
}

class _GroupRow extends _Row {
  final String emoji;
  final String label;
  final Color dot;
  final int count;
  _GroupRow(this.emoji, this.label, this.dot, this.count);
}

class _TaskRow extends _Row {
  final Task task;
  final int depth;
  final bool isLast;
  final (int, int)? childStat; // (done, total)
  _TaskRow(this.task, {required this.depth, required this.isLast, this.childStat});
}

class _ItemRow extends _Row {
  final TaskItem item;
  final int depth;
  final bool isLast;
  _ItemRow(this.item, {required this.depth, required this.isLast});
}

class _ReminderRow extends _Row {
  final List<Task> overdue;
  final List<Task> soon;
  _ReminderRow(this.overdue, this.soon);
}

class _Group {
  final String emoji;
  final String label;
  final Color dot;
  final List<Task> tasks;
  _Group(this.emoji, this.label, this.dot, this.tasks);
}

class _Section {
  final String emoji;
  final String title;
  final List<_Group> groups;
  _Section(this.emoji, this.title, this.groups);
  int get count =>
      groups.fold(0, (a, g) => a + g.tasks.length);
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'সব';
  bool _initExpand = false;
  final Set<String> _expanded = {};
  final Set<String> _treeShown = {};
  final Set<String> _treeLoading = {};

  List<Task> _getFilteredTasks(Box<Task> box) {
    final tasks = box.values.toList();
    switch (_selectedFilter) {
      case 'বাকি':
        return tasks.where((t) => !t.isCompleted).toList();
      case 'সম্পন্ন':
        return tasks.where((t) => t.isCompleted).toList();
      default:
        return tasks;
    }
  }

  // ── Tree flattening ─────────────────────────────────────────────────────

  List<_Row> _flatten(Box<Task> box) {
    final all = box.values.toList();
    if (!_initExpand) {
      _initExpand = true;
      _expanded.addAll(all.where((t) => t.itemList.isNotEmpty).map((t) => t.id));
    }

    final byParent = <String, List<Task>>{};
    final roots = <Task>[];
    for (final t in all) {
      if (t.parentId == null) {
        roots.add(t);
      } else {
        (byParent[t.parentId!] ??= []).add(t);
      }
    }

    final now = DateTime.now();
    final sToday = DateTime(now.year, now.month, now.day);
    final sTomorrow = sToday.add(const Duration(days: 1));

    final pending = roots.where((t) => !t.isCompleted && !t.archived).toList();
    final completed = roots.where((t) => t.isCompleted && !t.archived).toList();

    final todayP = <Task>[];
    final upP = <Task>[];
    for (final t in pending) {
      final d = t.deadline;
      if (d == null || d.isBefore(sTomorrow)) {
        todayP.add(t);
      } else {
        upP.add(t);
      }
    }

    final sections = <_Section>[];
    if (_selectedFilter == '📅 দিন') {
      sections.addAll(_calendarSections(pending));
    } else {
      if (todayP.isNotEmpty) sections.add(_section('ওয়েভ', 'আজ', todayP));
      if (upP.isNotEmpty) sections.add(_section('ক্রিস্টাল', 'সামনের', upP));
      if (_selectedFilter == 'সব' && completed.isNotEmpty) {
        sections.add(_section('চেক', 'শেষ', completed));
      }
      if (_selectedFilter == 'সব') {
        final archivedRoots = roots.where((t) => t.archived).toList()
          ..sort((a, b) {
            final ac = a.completedAt ?? a.createdAt;
            final bc = b.completedAt ?? b.createdAt;
            return bc.compareTo(ac);
          });
        if (archivedRoots.isNotEmpty) {
          sections.add(_Section('🗄️', 'আর্কাইভ', [
            _Group('🗄️', 'আর্কাইভ', AppTheme.of(context).textSecondary, archivedRoots),
          ]));
        }
      }
    }

    final out = <_Row>[];
    if (_selectedFilter == 'সব') {
      final now = DateTime.now();
      final overdue = pending
          .where((t) =>
              t.deadline != null && t.deadline!.isBefore(now))
          .toList()
        ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
      final soon = pending
          .where((t) =>
              t.deadline != null &&
              !t.deadline!.isBefore(now) &&
              t.deadline!.isBefore(now.add(const Duration(hours: 2))))
          .toList()
        ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
      if (overdue.isNotEmpty || soon.isNotEmpty) {
        out.add(_ReminderRow(overdue, soon));
      }
    }
    for (final sec in sections) {
      out.add(_SectionRow(sec.emoji, sec.title, sec.count));
      for (var gi = 0; gi < sec.groups.length; gi++) {
        final g = sec.groups[gi];
        if (g.tasks.isEmpty) continue;
        out.add(_GroupRow(g.emoji, g.label, g.dot, g.tasks.length));
        for (var ti = 0; ti < g.tasks.length; ti++) {
          _emitTask(out, g.tasks[ti], 0, byParent,
              isLast: ti == g.tasks.length - 1);
        }
      }
    }
    return out;
  }

  void _emitTask(List<_Row> out, Task t, int depth,
      Map<String, List<Task>> byParent, {required bool isLast}) {
    out.add(_TaskRow(t, depth: depth, isLast: isLast, childStat: _childStat(t, byParent)));
    if (t.isCompleted) return;
    if (!_expanded.contains(t.id)) return;

    final items = t.itemList;
    final kids = (byParent[t.id] ?? const <Task>[]).toList()
      ..sort((a, b) {
        final o = a.order.compareTo(b.order);
        return o != 0 ? o : a.createdAt.compareTo(b.createdAt);
      });
    final hasKids = kids.isNotEmpty;
    for (var i = 0; i < items.length; i++) {
      out.add(_ItemRow(items[i], depth: depth, isLast: i == items.length - 1 && !hasKids));
    }
    for (var i = 0; i < kids.length; i++) {
      _emitTask(out, kids[i], depth + 1, byParent, isLast: i == kids.length - 1);
    }
  }

  (int, int)? _childStat(Task t, Map<String, List<Task>> byParent) {
    var done = 0;
    var total = 0;
    void walk(Task tt) {
      for (final k in byParent[tt.id] ?? const <Task>[]) {
        total++;
        if (k.isCompleted) done++;
        walk(k);
      }
    }

    walk(t);
    return total == 0 ? null : (done, total);
  }

  List<_Section> _calendarSections(List<Task> pending) {
    final c = AppTheme.of(context);
    final byDay = <DateTime, List<Task>>{};
    final noDeadline = <Task>[];
    for (final t in pending) {
      final d = t.deadline;
      if (d == null) {
        noDeadline.add(t);
        continue;
      }
      final day = DateTime(d.year, d.month, d.day);
      (byDay[day] ??= []).add(t);
    }

    final days = byDay.keys.toList()..sort();
    final out = <_Section>[];
    const meta = ['সকাল', 'দুপুর', 'বিকাল', 'রাত'];
    const emojis = ['🌅', '☀️', '🌆', '🌙'];
    final dots = <Color>[c.secondary, c.highPriority, c.primary, c.glow];
    for (final day in days) {
      final list = byDay[day]!;
      final periods = <String, List<Task>>{
        'সকাল': <Task>[],
        'দুপুর': <Task>[],
        'বিকাল': <Task>[],
        'রাত': <Task>[],
      };
      for (final t in list) {
        final h = t.deadline!.hour;
        if (h >= 5 && h < 12) {
          periods['সকাল']!.add(t);
        } else if (h >= 12 && h < 16) {
          periods['দুপুর']!.add(t);
        } else if (h >= 16 && h < 19) {
          periods['বিকাল']!.add(t);
        } else {
          periods['রাত']!.add(t);
        }
      }
      final groups = <_Group>[];
      for (var i = 0; i < meta.length; i++) {
        final l = periods[meta[i]]!..sort(_taskCmp);
        if (l.isEmpty) continue;
        groups.add(_Group(emojis[i], meta[i], dots[i], l));
      }
      out.add(_Section('📅', _dayLabel(day), groups));
    }
    if (noDeadline.isNotEmpty) {
      out.add(_Section('📆', 'ডেডলাইন নেই',
          [_Group('⏰', 'ডেডলাইন নেই', c.textSecondary, noDeadline..sort(_taskCmp))]));
    }
    return out;
  }

  String _dayLabel(DateTime d) {
    const months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    final base = '${d.day} ${months[d.month - 1]}';
    if (diff == 0) return '$base — আজ';
    if (diff == -1) return '$base — কাল';
    if (diff < -1) return '$base (আগামী)';
    return '$base — ওভারডিউ';
  }

  _Section _section(String emoji, String title, List<Task> tasks) {
    final urgent = <Task>[];
    final byCat = <String?, List<Task>>{};
    for (final t in tasks) {
      if (t.priority >= 2) {
        urgent.add(t);
      } else {
        (byCat[t.category] ??= []).add(t);
      }
    }

    final groups = <_Group>[];
    if (urgent.isNotEmpty) {
      urgent.sort(_taskCmp);
      groups.add(_Group('🔥', 'জরুরি', AppTheme.of(context).highPriority, urgent));
    }
    final catKeys = byCat.keys.toList();
    catKeys.sort((a, b) {
      final av = _catIndex(a), bv = _catIndex(b);
      return av.compareTo(bv);
    });
    for (final k in catKeys) {
      final list = byCat[k]!..sort(_taskCmp);
      final label = k == null ? 'অন্যান্য' : TaskBrain.categoryLabel(k);
      groups.add(_Group(
        k == null ? '📌' : TaskBrain.categoryEmoji(k),
        label,
        _catColor(k),
        list,
      ));
    }
    return _Section(emoji, title, groups);
  }

  Color _catColor(String? cat) {
    final c = AppTheme.of(context);
    return switch (cat) {
      'Study' => c.secondary,
      'Shopping' => c.primary,
      'Health' => c.highPriority,
      'Work' => c.glow,
      'Home' => c.lowPriority,
      _ => c.textSecondary,
    };
  }

  int _catIndex(String? cat) => switch (cat) {
        'Shopping' => 0,
        'Study' => 1,
        'Health' => 2,
        'Work' => 3,
        'Home' => 4,
        _ => 9,
      };

  int _taskCmp(Task a, Task b) {
    if (a.isCompleted && b.isCompleted) {
      final ac = a.completedAt ?? a.createdAt;
      final bc = b.completedAt ?? b.createdAt;
      return bc.compareTo(ac);
    }
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    final p = b.priority.compareTo(a.priority);
    if (p != 0) return p;
    final ad = a.deadline, bd = b.deadline;
    if (ad == null && bd == null) return a.createdAt.compareTo(b.createdAt);
    if (ad == null) return 1;
    if (bd == null) return -1;
    final dc = ad.compareTo(bd);
    if (dc != 0) return dc;
    return a.createdAt.compareTo(b.createdAt);
  }

  // ── Rendering ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return OceanBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    'কাজ',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.manage_search_rounded, color: c.textSecondary, size: 22),
                    onPressed: _openSearch,
                    tooltip: 'স্মার্ট খোঁজ',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 6,
                children: [
                  _filterChip(c, 'সব'),
                  _filterChip(c, 'বাকি'),
                  _filterChip(c, 'সম্পন্ন'),
                  _filterChip(c, '📅 দিন'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Task>('tasks').listenable(),
                builder: (context, Box<Task> box, _) {
                  final used = _getFilteredTasks(box);
                  if (used.where((t) => !t.archived).isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt_rounded, size: 64, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('কোনো কাজ নেই', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                          const SizedBox(height: 8),
                          Text('+ চাপে নতুন কাজ যোগ করো', style: TextStyle(fontSize: 13, color: c.textSecondary.withValues(alpha: 0.6))),
                        ],
                      ),
                    );
                  }
                  final rows = _flatten(box);
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    physics: const BouncingScrollPhysics(),
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _renderRow(c, rows[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderRow(AppColors c, _Row row) {
    return switch (row) {
      _ReminderRow() => _reminderBanner(c, row),
      _SectionRow() => _sectionHeader(c, row),
      _GroupRow() => _groupHeader(c, row),
      _TaskRow() => _taskRow(c, row),
      _ItemRow() => _itemRow(c, row),
    };
  }

  Widget _reminderBanner(AppColors c, _ReminderRow r) {
    final chips = <Widget>[];
    for (final t in r.overdue) {
      chips.add(_bannerChip(c, '🚨 ${t.title}', 'ওভারডিউ', c.expense));
    }
    for (final t in r.soon) {
      chips.add(_bannerChip(
          c, '⏰ ${t.title}', '২ ঘণ্টার মধ্যে', c.highPriority));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return EntranceItem(
      order: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Wrap(spacing: 6, runSpacing: 6, children: chips),
      ),
    );
  }

  Widget _bannerChip(AppColors c, String title, String tag, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(tag,
                style: const TextStyle(
                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(AppColors c, _SectionRow s) {
    return EntranceItem(
      order: 0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 2),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.textSecondary.withValues(alpha: 0.14), width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(s.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              s.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: c.textPrimary),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${s.count}টি',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(AppColors c, _GroupRow g) {
    return EntranceItem(
      order: 0,
      child: TreeBranch(
        dotColor: g.dot,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            children: [
              Text(g.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                g.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                '${g.count}টি',
                style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _taskToText(Task t) {
    final b = StringBuffer(t.title.trim());
    for (final it in t.itemList) {
      final q = it.qtyText;
      final s = '${it.name}${q.isNotEmpty ? ' $q' : ''}'.trim();
      if (s.isEmpty) continue;
      b.write(' — ');
      b.write(s);
    }
    return b.toString();
  }

  /// P6: কাজ-এর AI গাছ — Gemini (online) অথবা offline বট, ফলাফল আলাদা করে
  /// save হয়; কাজের মূল নাম/লেখা কখনো বদলানো হয় না। ✨ ট্যাপ = বানানো/আবার।
  Future<void> _toggleTree(Task t) async {
    if (_treeLoading.contains(t.id)) return;
    setState(() => _treeLoading.add(t.id));
    try {
      final r = await AiEnhancer.enhance(_taskToText(t), allowOnline: true)
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      AiTreeStore.save(t.id, r.tree, task: true, source: r.source);
      setState(() => _treeLoading.remove(t.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _treeLoading.remove(t.id));
    }
  }

  Widget _aiTaskBody(
      AppColors c, Task t, ({TreeBlueprint blueprint, String? source}) saved) {
    final b = saved.blueprint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${b.titleEmoji} ${b.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
            ),
            GestureDetector(
              onTap: () => _editTitle(t),
              child: _metaChip(c, '✏️ মূল', c.glow),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            saved.source == 'online' ? '🤖 Gemini AI গাছ' : '🤖 AI গাছ',
            style: TextStyle(fontSize: 10.5, color: c.secondary),
          ),
        ),
      ],
    );
  }

  Widget _taskRow(AppColors c, _TaskRow r) {
    final t = r.task;
    final dot = _taskDot(c, t);
    final stat = r.childStat;
    final hasItems = t.itemList.isNotEmpty;
    final isExpanded = _expanded.contains(t.id);
    final savedTree = AiTreeStore.get(t.id, task: true);
    final aiView = savedTree != null && savedTree.blueprint.hasNodes;

    final card = GlassCard(
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      borderRadius: BorderRadius.circular(16),
      accent: t.isCompleted
          ? c.lowPriority
          : (t.deadline != null && t.deadline!.isBefore(DateTime.now()) && !t.isCompleted
              ? c.expense
              : null),
      onTap: (hasItems || stat != null) && !t.isCompleted
          ? () => setState(() {
                if (!_expanded.remove(t.id)) _expanded.add(t.id);
              })
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleComplete(t),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: t.isCompleted ? c.lowPriority : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: t.isCompleted ? c.lowPriority : c.textSecondary,
                    width: 2,
                  ),
                ),
                child: t.isCompleted
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: aiView
                ? _aiTaskBody(c, t, savedTree)
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: t.priority >= 2 ? FontWeight.w700 : FontWeight.w600,
                          color: t.isCompleted ? c.textSecondary : c.textPrimary,
                          decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (hasItems || stat != null) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18, color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (stat != null && stat.$2 > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: stat.$1 / stat.$2,
                      minHeight: 4,
                      backgroundColor: c.cardColor,
                      color: t.priority >= 2 ? c.highPriority : c.mediumPriority,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stat.$1}/${stat.$2} টা শেষ',
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (hasItems)
                      _metaChip(c, '🛒 ${t.itemList.length} আইটেম', c.primary),
                    if (t.expectedCost != null)
                      _metaChip(c, '৳${marketNum(t.expectedCost!)}', c.expense),
                    if (t.deadline != null)
                      _metaChip(c, _deadlineText(t.deadline!), c.secondary),
                    if (!t.isCompleted && t.priority >= 2)
                      _metaChip(c, '🔥 জরুরি', c.highPriority),
                    if (t.recurrenceObj != null)
                      _metaChip(c, '🔁 ${t.recurrenceObj!.label}', c.glow),
                    if (t.location != null)
                      _metaChip(c, '📍 ${t.location}', c.secondary),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: _treeLoading.contains(t.id)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    savedTree != null
                        ? Icons.auto_awesome_rounded
                        : Icons.auto_awesome_outlined,
                    color: savedTree != null ? c.glow : c.textSecondary,
                    size: 20),
            tooltip: 'AI গাছ (আবার বানাও)',
            onPressed: () => _toggleTree(t),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: c.textSecondary, size: 20),
            onPressed: () => _showNodeMenu(t),
          ),
        ],
      ),
    );

    final Widget cardWithTree = aiView
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              card,
              const SizedBox(height: 8),
              BeautifiedTreeCard(
                raw: _taskToText(t),
                blueprint: savedTree.blueprint,
                aiSource: savedTree.source,
                animate: false,
              ),
            ],
          )
        : card;

    Widget content;
    if (r.depth == 0) {
      content = EntranceItem(
        order: 0,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: TreeBranch(
            dotColor: dot,
            child: cardWithTree,
          ),
        ),
      );
    } else {
      content = Padding(
        padding: EdgeInsets.only(left: 20 + (r.depth - 1) * 18, top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 6),
              child: Text(
                r.isLast ? '└─' : '├─',
                style: TextStyle(color: c.textSecondary.withValues(alpha: 0.45), fontSize: 14),
              ),
            ),
            Expanded(child: cardWithTree),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey('task-${t.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBg(
        c, c.lowPriority, Icons.check_rounded, 'শেষ, বাদ দাও', Alignment.centerLeft),
      secondaryBackground: _swipeBg(
        c, c.expense, Icons.delete_outline_rounded, 'মুছুন', Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _toggleComplete(t);
          return false;
        }
        return _confirmDelete(t);
      },
      child: GestureDetector(
        onLongPress: () => _showNodeMenu(t),
        child: content,
      ),
    );
  }

  Widget _swipeBg(
      AppColors c, Color color, IconData icon, String label, Alignment align) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 2, bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (align == Alignment.centerRight) ...[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ] else ...[
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(width: 6),
            Icon(icon, color: color, size: 20),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(AppColors c, _ItemRow r) {
    final it = r.item;
    final conn = r.isLast ? '└─' : '├─';
    return Padding(
      padding: EdgeInsets.only(left: 54 + r.depth * 18, right: 20),
      child: Row(
        children: [
          Text(conn, style: TextStyle(color: c.textSecondary.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(width: 6),
          Text(it.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              it.name,
              style: TextStyle(fontSize: 12.5, color: c.textSecondary),
            ),
          ),
          if (it.qtyText.isNotEmpty)
            Text(
              it.qtyText,
              style: TextStyle(fontSize: 11.5, color: c.mediumPriority),
            ),
        ],
      ),
    );
  }

  Color _taskDot(AppColors c, Task t) {
    if (t.isCompleted) return c.lowPriority;
    if (t.priority >= 2) return c.highPriority;
    if (t.priority == 1) return c.mediumPriority;
    return c.lowPriority;
  }

  void _toggleComplete(Task t) {
    final completing = !t.isCompleted;
    setState(() {
      t.isCompleted = completing;
      t.completedAt = completing ? DateTime.now() : null;
    });
    t.addHistory(completing ? 'শেষ' : 'ফেরানো',
        completing ? 'কাজটি শেষ হলো ✓' : 'আবার খোলা হলো');
    t.save();

    if (completing) {
      final rec = t.recurrenceObj;
      if (rec != null) {
        _spawnNextInstance(t, rec);
      }
      if (t.expectedCost != null &&
          t.expectedCost! > 0 &&
          !t.expenseSaved) {
        _askSaveExpense(t);
      }
    }
  }

  Future<void> _askSaveExpense(Task t) async {
    final c = AppTheme.of(context);
    final cost = t.expectedCost!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text(
          '☑ ${t.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, color: c.textPrimary),
        ),
        content: Text(
          '৳${marketNum(cost)} — এটা expense হিসেবে সেভ করবো?',
          style: TextStyle(fontSize: 14, color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('না', style: TextStyle(color: c.textSecondary)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.savings_rounded, size: 16),
            label: const Text('সেভ করো'),
            style: FilledButton.styleFrom(backgroundColor: c.primary),
          ),
        ],
      ),
    );
    setState(() {
      t.expenseSaved = true;
    });
    if (ok == true) {
      String note = '🔗 Task: ${t.title}';
      final savedTreeForMoney = AiTreeStore.get(t.id, task: true);
      if (savedTreeForMoney != null) {
        final b = savedTreeForMoney.blueprint;
        note = '🧠 ${b.titleEmoji} ${b.title} — ✅ ${t.title}';
      } else {
        try {
          final r = await AiEnhancer.enhance(_taskToText(t), allowOnline: true)
              .timeout(const Duration(seconds: 15));
          AiTreeStore.save(t.id, r.tree, task: true, source: r.source);
          note = '🧠 ${r.tree.titleEmoji} ${r.tree.title} — ✅ ${t.title}';
        } catch (_) {}
      }
      Hive.box<Expense>('expenses').add(Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: t.title,
        amount: cost,
        category: _expenseCategory(t),
        date: DateTime.now(),
        note: note,
      ));
      t.addHistory('লিংক', '৳${marketNum(cost)} Money-তে expense হিসেবে');
      t.save();
      _snack('💸 ৳${marketNum(cost)} expense হিসেবে সেভ হলো');
    } else {
      t.addHistory('লিংক', 'expense হিসেবে সেভ করা হলো না');
      t.save();
    }
  }

  String _expenseCategory(Task t) {
    if (t.category == 'Shopping') return 'shopping';
    if (t.category == 'Health') return 'health';
    if (t.category == 'Study') return 'education';
    if (t.category == 'Home') return 'home';
    return 'other';
  }

  void _spawnNextInstance(Task t, Recurrence rec) {
    final now = DateTime.now();
    final box = Hive.box<Task>('tasks');
    box.add(Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: t.title,
      description: t.description,
      priority: t.priority,
      createdAt: now,
      deadline: rec.nextOccurrence(from: now, time: t.deadline),
      category: t.category,
      parentId: t.parentId,
      order: t.order,
      items: t.items,
      expectedCost: t.expectedCost,
      location: t.location,
      recurrence: rec.toMap(),
    )..addHistory('তৈরি', '🔁 পুনরাবৃত্তি থেকে নতুন সংঘটন'));
    _snack('🔁 পরের সংঘটন বসানো হলো (${rec.label})');
  }

  // ── Node menu (P3) ─────────────────────────────────────────────────────

  void _showNodeMenu(Task t) {
    final c = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Material(
        color: Colors.transparent,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _taskDot(c, t),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (t.parentId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'সাব-কাজ',
                          style: TextStyle(fontSize: 10.5, color: c.primary),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x22333333)),
              _nodeAction(sheetCtx, c, Icons.edit_rounded, 'সম্পাদনা',
                  'নাম বদলাও', () {
                Navigator.pop(sheetCtx);
                _editTitle(t);
              }),
              _nodeAction(sheetCtx, c, Icons.add_task_rounded, 'সাব-কাজ',
                  'ভেতরে আরেকটা কাজ বসাও', () {
                Navigator.pop(sheetCtx);
                _addChild(t);
              }),
              _nodeAction(sheetCtx, c, Icons.event_rounded, 'ডেডলাইন',
                  t.deadline == null ? 'দিন ঠিক করো' : '${_shortDate(t.deadline!)} — বদলাও', () {
                Navigator.pop(sheetCtx);
                _setDeadline(t);
              }),
              _nodeAction(sheetCtx, c, Icons.place_rounded, 'লোকেশন',
                  t.location == null
                      ? 'ঠিকানা/জায়গা লিখো'
                      : '📍 ${t.location}', () {
                Navigator.pop(sheetCtx);
                _editLocation(t);
              }),
              _nodeAction(sheetCtx, c, Icons.local_fire_department_rounded,
                  'অগ্রাধিকার',
                  CommandParser.priorityLabel(t.priority), () {
                Navigator.pop(sheetCtx);
                _pickPriority(t);
              }),
              _nodeAction(sheetCtx, c, Icons.copy_rounded, 'নকল',
                  'সব তথ্য নকল করে নতুন কাজ', () {
                Navigator.pop(sheetCtx);
                _duplicate(t);
              }),
              _nodeAction(sheetCtx, c, Icons.history_rounded, 'ইতিহাস',
                  'পরিবর্তনের Time Machine', () {
                Navigator.pop(sheetCtx);
                _showHistory(t);
              }),
              _nodeAction(
                  sheetCtx,
                  c,
                  t.archived ? Icons.unarchive_rounded : Icons.archive_rounded,
                  t.archived ? 'আর্কাইভ থেকে ফেরাও' : 'আর্কাইভ',
                  'তালিকা থেকে আড়াল করো', () {
                Navigator.pop(sheetCtx);
                _toggleArchive(t);
              }),
              _nodeAction(sheetCtx, c, Icons.delete_outline_rounded, 'মুছুন',
                  'সাব-কাজসহ পুরোপুরি ডিলিট', () {
                Navigator.pop(sheetCtx);
                _deleteSubtree(t);
              }, danger: true),
            ],
            ),
          ),
        ),
        ),
    );
  }

  Widget _nodeAction(BuildContext sheetCtx, AppColors c, IconData icon,
      String label, String sub, VoidCallback run,
      {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? c.expense : c.glow, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: danger ? c.expense : c.textPrimary,
        ),
      ),
      subtitle: sub.isEmpty
          ? null
          : Text(sub,
              style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
      onTap: run,
    );
  }

  Future<void> _editTitle(Task t) async {
    final c = AppTheme.of(context);
    final ctrl = TextEditingController(text: t.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('কাজ সম্পাদনা',
            style: TextStyle(fontSize: 17, color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'নতুন নাম',
            hintStyle: TextStyle(color: c.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('সেভ',
                style: TextStyle(
                    color: c.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final old = t.title;
      setState(() {
        t.title = ctrl.text.trim();
      });
      t.addHistory('সম্পাদনা', 'নাম বদল: "$old" → "${t.title}"');
      t.save();
      AiTreeStore.remove(t.id, task: true);
      if (mounted) {
        setState(() {
          _treeShown.remove(t.id);
          _treeLoading.remove(t.id);
        });
      }
    }
  }

  Future<void> _editLocation(Task t) async {
    final c = AppTheme.of(context);
    final ctrl = TextEditingController(text: t.location ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('লোকেশন',
            style: TextStyle(fontSize: 17, color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'যেমন: সদর বাজার, লাইব্রেরি, গুলশান…',
            hintStyle: TextStyle(color: c.textSecondary),
          ),
        ),
        actions: [
          if (t.location != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: Text('মুছুন', style: TextStyle(color: c.expense)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('সেভ',
                style: TextStyle(
                    color: c.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      setState(() {
        t.location = ctrl.text.trim();
      });
      t.addHistory('লোকেশন', '📍 ${t.location}');
      t.save();
      _snack('📍 লোকেশন সেট হলো');
    } else if (ok == 'clear') {
      setState(() {
        t.location = null;
      });
      t.addHistory('লোকেশন', 'লোকেশন বাদ গেল');
      t.save();
    }
  }

  Future<void> _addChild(Task parent) async {
    final c = AppTheme.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('সাব-কাজ',
            style: TextStyle(fontSize: 17, color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: '${parent.title} — এর ভেতরে কাজ লিখো',
            hintStyle: TextStyle(color: c.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('যোগ',
                style: TextStyle(
                    color: c.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    final box = Hive.box<Task>('tasks');
    final now = DateTime.now();
    setState(() {
      _expanded.add(parent.id);
    });
    final child = Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: ctrl.text.trim(),
      priority: 1,
      createdAt: now,
      parentId: parent.id,
      order: box.values.where((e) => e.parentId == parent.id).length,
      category: parent.category,
    )..addHistory('তৈরি', 'সাব-কাজ হিসেবে যোগ হলো');
    box.add(child);
  }

  Future<void> _setDeadline(Task t) async {
    final now = DateTime.now();
    final initial = t.deadline ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2036),
      helpText: 'ডেডলাইন বাছাই',
    );
    if (date == null) return;
    setState(() {
      t.deadline = DateTime(
        date.year,
        date.month,
        date.day,
        t.deadline?.hour ?? 18,
        t.deadline?.minute ?? 0,
      );
    });
    t.addHistory('ডেডলাইন', 'ডেডলাইন ঠিক হলো: ${_shortDate(t.deadline!)}');
    t.save();
  }

  Future<void> _pickPriority(Task t) async {
    final c = AppTheme.of(context);
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('অগ্রাধিকার',
            style: TextStyle(fontSize: 16, color: c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (v, label, emoji) in [
              (0, 'কম', '🟢'),
              (1, 'মাঝারি', '🟡'),
              (2, 'বেশি', '🔴'),
            ])
              ListTile(
                dense: true,
                leading: Text(emoji),
                title: Text(label,
                    style: TextStyle(
                        color: v == t.priority ? c.primary : c.textPrimary)),
                trailing: v == t.priority
                    ? Icon(Icons.check_rounded, color: c.primary, size: 18)
                    : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != t.priority) {
      setState(() {
        t.priority = picked;
      });
      t.addHistory('অগ্রাধিকার',
          'বদল হলো: ${CommandParser.priorityLabel(picked)}');
      t.save();
    }
  }

  void _duplicate(Task t) {
    final box = Hive.box<Task>('tasks');
    final now = DateTime.now();
    final copy = Task(
      id: now.millisecondsSinceEpoch.toString(),
      title: t.title,
      priority: t.priority,
      createdAt: now,
      deadline: t.deadline,
      category: t.category,
      parentId: t.parentId,
      order: t.order,
      items: t.items,
      expectedCost: t.expectedCost,
      recurrence: t.recurrence,
    )..addHistory('নকল', '"${t.title}" থেকে নকল করা হলো');
    box.add(copy);
    _snack('📋 নকল হলো');
  }

  void _toggleArchive(Task t) {
    setState(() {
      t.archived = !t.archived;
    });
    t.addHistory(t.archived ? 'আর্কাইভ' : 'ফেরানো',
        t.archived ? 'আর্কাইভে রাখা হলো 📦' : 'আর্কাইভ থেকে ফেরানো হলো ↩️');
    t.save();
    _snack(t.archived ? '📦 আর্কাইভে রাখা হলো' : '↩️ ফেরানো হলো');
  }

  void _deleteSubtree(Task t) {
    final box = Hive.box<Task>('tasks');
    for (final kid
        in box.values.where((e) => e.parentId == t.id).toList()) {
      _deleteSubtree(kid);
    }
    t.delete();
  }

  Future<bool> _confirmDelete(Task t) async {
    final c = AppTheme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('"${t.title}" মুছে ফেলবো?',
            style: TextStyle(fontSize: 16, color: c.textPrimary)),
        content: Text('সাব-কাজ থাকলে সেগুলোও মুছে যাবে।',
            style: TextStyle(fontSize: 13, color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('মুছুন',
                style: TextStyle(
                    color: c.expense, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      _deleteSubtree(t);
      return true;
    }
    return false;
  }

  void _snack(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.of(context).surfaceColor,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showHistory(Task t) {
    final c = AppTheme.of(context);
    final list = t.historyList;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    const Text('🕰️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ইতিহাস',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Icon(Icons.close_rounded,
                          size: 22, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x22333333)),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Text('এখনো কোনো পরিবর্তন নেই'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0x11333333)),
                    itemBuilder: (_, i) {
                      final h = list[i];
                      return ListTile(
                        dense: true,
                        leading: const Text('🕰️', style: TextStyle(fontSize: 15)),
                        title: Text(
                          h.action,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          h.detail,
                          style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary),
                        ),
                        trailing: Text(
                          _historyTime(h.at),
                          style: TextStyle(
                              fontSize: 10.5,
                              color: c.textSecondary.withValues(alpha: 0.7)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _historyTime(DateTime at) {
    final now = DateTime.now();
    final d = now.difference(at);
    if (d.inMinutes < 1) return 'এইমাত্র';
    if (d.inMinutes < 60) return '${d.inMinutes} মিনিট আগে';
    if (d.inHours < 24) return '${d.inHours} ঘণ্টা আগে';
    return '${at.day}/${at.month}/${at.year}';
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String marketNum(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  String _deadlineText(DateTime d) {
    final now = DateTime.now();
    final sToday = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    String prefix;
    if (dDay.isBefore(sToday)) {
      prefix = 'ওভারডিউ';
    } else if (dDay == sToday) {
      prefix = 'আজ';
    } else if (dDay == sToday.add(const Duration(days: 1))) {
      prefix = 'কাল';
    } else {
      prefix = '${d.day}/${d.month}';
    }
    if (d.hour != 0 || d.minute != 0) {
      final am = d.hour < 12;
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final m = d.minute.toString().padLeft(2, '0');
      prefix += ' • $h:$m ${am ? 'am' : 'pm'}';
    }
    return prefix;
  }

  Widget _metaChip(AppColors c, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _openSearch() {
    final c = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SearchSheet(),
    );
  }

  Widget _filterChip(AppColors c, String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? c.primary.withValues(alpha: 0.18) : c.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? c.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? c.primary : c.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}