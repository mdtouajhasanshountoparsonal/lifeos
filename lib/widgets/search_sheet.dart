import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/task_search.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Smart Search sheet — Task + Money + Notes একসাথে, natural-language query।
class SearchSheet extends StatefulWidget {
  const SearchSheet({super.key});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    final variants = [
      ('🔥 জরুরি কাজ', 'জরুরি'),
      ('আজ', 'আজ'),
      ('৫০০ টাকার বেশি', '৫০০ টাকার বেশি'),
      ('ওভারডিউ', 'ওভারডিউ'),
      ('মাছ', 'মাছ'),
    ];
    return Padding(
      padding: EdgeInsets.only(
          left: 8, right: 8, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'যেমন: ৫০০ টাকার বেশি, জরুরি, আজ…',
                    hintStyle: TextStyle(color: c.textSecondary),
                    prefixIcon:
                        Icon(Icons.manage_search_rounded, color: c.glow, size: 22),
                    filled: true,
                    fillColor: c.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: c.textSecondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, value) in variants)
                _chip(c, label, () {
                  _ctrl.text = value;
                  setState(() => _query = value);
                  _focus.requestFocus();
                }),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(child: _results(c)),
        ],
      ),
    );
  }

  Widget _chip(AppColors c, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11.5, color: c.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _results(AppColors c) {
    if (_query.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('বলো কী খুঁজবে — কাজ, খরচ, নোট সব এক সাথে',
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ),
      );
    }
    final hits = TaskSearchService.run(
      _query,
      tasks: Hive.box<Task>('tasks'),
      exps: Hive.box<Expense>('expenses'),
      notes: Hive.box<Note>('notes'),
    );
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('কিছু পাওয়া যায়নি 😔',
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ),
      );
    }
    final tasks = hits.where((h) => h.kind == 'task').toList();
    final exps = hits.where((h) => h.kind == 'expense').toList();
    final notes = hits.where((h) => h.kind == 'note').toList();

    return ListView(
      shrinkWrap: true,
      children: [
        if (tasks.isNotEmpty) ...[
          _header(c, '📌 কাজ', tasks.length),
          for (final h in tasks.take(8)) _hitTile(c, h),
        ],
        if (exps.isNotEmpty) ...[
          _header(c, '💸 খরচ', exps.length),
          for (final h in exps.take(8)) _hitTile(c, h),
        ],
        if (notes.isNotEmpty) ...[
          _header(c, '📝 নোট', notes.length),
          for (final h in notes.take(8)) _hitTile(c, h),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _header(AppColors c, String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: Text('$label  ($count)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary)),
    );
  }

  Widget _hitTile(AppColors c, SearchHit h) {
    final Color? toneColor = switch (h.tone) {
      SearchTone.urgent => c.highPriority,
      SearchTone.completed => c.lowPriority,
      SearchTone.overdue => c.expense,
      SearchTone.normal => null,
    };
    return ListTile(
      dense: true,
      leading: Icon(
        switch (h.kind) {
          'task' => Icons.task_alt_rounded,
          'expense' => Icons.savings_rounded,
          _ => Icons.sticky_note_2_rounded,
        },
        color: switch (h.kind) {
          'task' => c.primary,
          'expense' => c.expense,
          _ => c.secondary,
        },
        size: 20,
      ),
      title: Text(h.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
      subtitle: h.subtitle.isEmpty
          ? null
          : Text(h.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c.textSecondary)),
      trailing: h.amount != null
          ? Text('৳${_num(h.amount!)}',
              style: TextStyle(fontWeight: FontWeight.w800, color: toneColor ?? c.expense))
          : (toneColor != null
              ? Icon(Icons.local_fire_department_rounded, color: toneColor, size: 16)
              : null),
    );
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}