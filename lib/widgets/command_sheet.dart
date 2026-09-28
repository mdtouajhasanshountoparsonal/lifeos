import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/services/command_parser.dart';
import 'package:lifeos/services/market_parser.dart' show marketNumText;
import 'package:lifeos/services/task_brain.dart';
import 'package:lifeos/services/bazar_note.dart' show understandNote;

class CommandSheet extends StatefulWidget {
  const CommandSheet({super.key});

  @override
  State<CommandSheet> createState() => _CommandSheetState();
}

class _CommandSheetState extends State<CommandSheet> {
  final _ctrl = TextEditingController();
  ParsedCommand? _result;
  TaskBrain? _brain;

  void _onChanged(String v) {
    setState(() {
      _result = CommandParser.parse(v);
      _brain = TaskBrain.analyze(v);
    });
  }

  void _save() {
    final r = _result;
    if (r == null) return;
    final now = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);

    switch (r.type) {
      case CommandType.task:
        final b = _brain;
        Hive.box<Task>('tasks').add(Task(
          id: now.millisecondsSinceEpoch.toString(),
          title: (b?.title ?? r.title).trim(),
          priority: CommandParser.exportPriority(b?.priority ?? r.priority),
          createdAt: now,
          deadline: b?.deadline ?? r.deadline,
          category: b?.category ?? r.category,
          expectedCost: b?.expectedCost,
          recurrence: b?.recurrence?.toMap(),
        )..setItemList(b?.items ?? const []));
      case CommandType.note:
        Hive.box<Note>('notes').add(Note(
          id: now.millisecondsSinceEpoch.toString(),
          title: r.title,
          content: '',
          createdAt: now,
          updatedAt: now,
        ));
      case CommandType.bazar:
        final id = now.millisecondsSinceEpoch.toString();
        Hive.box<Note>('notes').add(Note(
          id: id,
          title: '🛒 ${r.title}',
          content: r.raw,
          createdAt: now,
          updatedAt: now,
        ));
        // একই সাথে বাজার DB-তে দর-সিভ — note-ই entry point
        understandNote(r.raw, save: true, noteId: id);
      case CommandType.expense:
        Hive.box<Expense>('expenses').add(Expense(
          id: now.millisecondsSinceEpoch.toString(),
          title: r.title,
          amount: r.amount ?? 0,
          category: r.category ?? 'other',
          date: now,
        ));
    }

    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(
      content: Text(
        '✓ ${CommandParser.typeLabel(r.type)} যোগ হয়েছে',
        textAlign: TextAlign.center,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.of(context).surfaceColor,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final typeColors = {
      CommandType.task: c.primary,
      CommandType.note: c.secondary,
      CommandType.expense: c.expense,
      CommandType.bazar: c.glow,
    };

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: c.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Command Center',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                onChanged: _onChanged,
                autofocus: true,
                style: TextStyle(color: c.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'কি করবো লিখি...',
                  hintStyle: TextStyle(color: c.textSecondary),
                  prefixIcon: Icon(Icons.bolt_rounded, color: c.glow),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _result == null
                    ? _buildExamples(c)
                    : _buildPreview(c, typeColors),
              ),
            ),
            Container(
              width: double.infinity,
              height: 52,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton.icon(
                onPressed: _result == null ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  disabledBackgroundColor: c.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, color: Colors.white),
                label: Text(
                  'যোগ করুন',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _result == null ? c.textSecondary : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamples(AppColors c) {
    final examples = [
      ('আজ ২ কেজি ইলিশ ১২০০ টাকা', CommandType.bazar),
      ('+ আগামীকাল সন্ধ্যা ৬টায় ইন্টারনেট প্যাকেজ কিনব', CommandType.task),
      ('Spent 120 on lunch', CommandType.expense),
      ('remember Flutter animation idea', CommandType.note),
      ('শুক্রবার সকাল ৭টায় ব্যায়াম করবো', CommandType.task),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'বলো বা লিখো — অ্যাপ নিজে বুঝে যোগ করবে',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        ...examples.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.cardColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: c.glow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.$1,
                      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildPreview(AppColors c, Map<CommandType, Color> typeColors) {
    final r = _result!;
    final color = typeColors[r.type]!;
    if (r.type == CommandType.task && _brain != null) {
      return _buildTaskTreePreview(c, color, r, _brain!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                CommandParser.typeLabel(r.type),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (r.priority > 0 && r.type == CommandType.task) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.mediumPriority.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  CommandParser.priorityLabel(r.priority),
                  style: TextStyle(fontSize: 12, color: c.mediumPriority),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text(
          r.raw.isNotEmpty ? r.raw : r.title,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
        if (r.type == CommandType.bazar) ...[
          const SizedBox(height: 8),
          Text(
            '🛒 নোট-এ সেভ হবে + বাজার দর হিসাবেও যোগ হবে',
            style: TextStyle(fontSize: 12, color: c.glow),
          ),
        ],
        const SizedBox(height: 10),
        if (r.type == CommandType.expense && r.amount != null)
          Text(
            '৳${r.amount!.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.expense),
          ),
        if (r.deadline != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 14, color: c.secondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM d, hh:mm a').format(r.deadline!),
                style: TextStyle(fontSize: 13, color: c.secondary),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'নিচে "যোগ করুন" চাপলে অটো তৈরি হবে',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      ],
    );
  }

  /// Task-এর Brain-বানানো **Structured Tree** প্রিভিউ — technical file-tree style।
  Widget _buildTaskTreePreview(AppColors c, Color color, ParsedCommand r, TaskBrain b) {
    final branchColor = c.primary.withValues(alpha: 0.5);
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                CommandParser.typeLabel(r.type),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            if (b.category != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${TaskBrain.categoryEmoji(b.category)} ${TaskBrain.categoryLabel(b.category)}',
                  style: TextStyle(fontSize: 12, color: c.secondary),
                ),
              ),
            ],
            if (b.priority > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.mediumPriority.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  CommandParser.priorityLabel(b.priority),
                  style: TextStyle(fontSize: 12, color: c.mediumPriority),
                ),
              ),
            ],
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.cardColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: branchColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${b.isShopping ? TaskBrain.categoryEmoji('Shopping') : '🗂️'}  ${b.title}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              if (b.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('│', style: TextStyle(color: branchColor, fontSize: 12, height: 1)),
                    Icon(Icons.schedule_rounded, size: 13, color: c.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '⏰ ${DateFormat('MMM d, hh:mm a').format(b.deadline!)}',
                      style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
              for (var i = 0; i < b.items.length; i++) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      i == b.items.length - 1 && b.expectedCost == null ? '└─' : '├─',
                      style: TextStyle(color: branchColor, fontSize: 12, height: 1),
                    ),
                    Text(b.items[i].emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        b.items[i].name,
                        style: TextStyle(fontSize: 12.5, color: c.textPrimary),
                      ),
                    ),
                    if (b.items[i].qtyText.isNotEmpty)
                      Text(
                        b.items[i].qtyText,
                        style: TextStyle(fontSize: 11.5, color: c.mediumPriority),
                      ),
                  ],
                ),
              ],
              if (b.expectedCost != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text('└─', style: TextStyle(color: branchColor, fontSize: 12, height: 1)),
                    Icon(Icons.payments_rounded, size: 13, color: c.expense),
                    const SizedBox(width: 5),
                    Text(
                      'Expected ৳${marketNumText(b.expectedCost!)}',
                      style: TextStyle(fontSize: 12, color: c.expense),
                    ),
                  ],
                ),
              ],
              if (b.items.isEmpty && b.expectedCost == null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text('└─', style: TextStyle(color: branchColor, fontSize: 12, height: 1)),
                    Text('⏳ Pending', style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets + [
        const SizedBox(height: 16),
        Text(
          'নিচে "যোগ করুন" চাপলে অটো কাজ+তালিকা তৈরি হবে',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
      ],
    );
  }
}