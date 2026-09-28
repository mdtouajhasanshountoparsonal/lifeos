import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/inbox_item.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/services/screenshot_parser.dart';
import 'package:lifeos/widgets/note_chooser_sheet.dart';

class ScreenshotReviewSheet extends StatefulWidget {
  final InboxItem item;
  final ScreenshotParseResult result;

  const ScreenshotReviewSheet({super.key, required this.item, required this.result});

  @override
  State<ScreenshotReviewSheet> createState() => _ScreenshotReviewSheetState();
}

class _ScreenshotReviewSheetState extends State<ScreenshotReviewSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _amountCtrl;
  late double _amount;
  late String _category;
  late DateTime _date;
  bool _isIncome = false;
  bool _makeReminder = false;
  late DateTime _deadline;

  static const _categories = ['food', 'groceries', 'transport', 'bills', 'shopping', 'health', 'other'];

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _makeReminder = r.reminderDate != null;
    _titleCtrl = TextEditingController(text: r.title);
    _contentCtrl = TextEditingController(text: r.content);
    _amount = r.amount ?? 0;
    _amountCtrl = TextEditingController(text: _amount > 0 ? _amount.toStringAsFixed(2) : '');
    _category = r.category ?? 'other';
    _date = r.date ?? DateTime.now();
    _deadline = r.reminderDate ?? DateTime.now().add(const Duration(hours: 6));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final kind = widget.result.kind;

    if (kind == ScreenshotKind.expense) {
      Hive.box<Expense>('expenses').add(Expense(
        id: id,
        title: _titleCtrl.text.isEmpty ? 'খরচ' : _titleCtrl.text,
        amount: _amount,
        category: _category,
        date: _date,
        isIncome: _isIncome,
        note: _contentCtrl.text,
      ));
    } else if (kind == ScreenshotKind.error) {
      Hive.box<Note>('notes').add(Note(
        id: id,
        title: _titleCtrl.text.isEmpty ? 'ত্রুটি' : _titleCtrl.text,
        content: _contentCtrl.text,
        category: 'Error',
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      Hive.box<Note>('notes').add(Note(
        id: '$id-note',
        title: _titleCtrl.text.isEmpty ? 'গুরুত্বপূর্ণ বার্তা' : _titleCtrl.text,
        content: _contentCtrl.text,
        category: 'Screenshot',
        createdAt: now,
        updatedAt: now,
      ));
      if (_makeReminder) {
        Hive.box<Task>('tasks').add(Task(
          id: '$id-task',
          title: _titleCtrl.text,
          description: _contentCtrl.text,
          category: 'reminder',
          priority: 1,
          createdAt: now,
          deadline: _deadline,
        ));
      }
    }

    widget.item
      ..kind = kind.name
      ..processed = true
      ..save();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addToNote() async {
    final dest = await NoteChooser.pick(context);
    if (dest == null) return;
    final stamp = DateFormat('dd MMM yyyy h:mm a').format(DateTime.now());
    final photo = widget.item.path != null ? '\n> 📷 screenshot সংযোজিত\n' : '\n';
    NoteChooser.appendTo(
      noteId: dest['id'] as String?,
      title: dest['title'] as String?,
      block: '> ${widget.result.title}\n${_contentCtrl.text.trim()}$photo($stamp)',
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('নোটে যোগ হয়েছে: ${dest['title']}'), backgroundColor: Colors.green));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline));
    if (t == null) return;
    setState(() => _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final kind = widget.result.kind;

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: c.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text('${ScreenshotParser.kindEmoji(kind)} ', style: const TextStyle(fontSize: 20)),
                Text(
                  ScreenshotParser.kindLabel(kind),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.primary),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.path != null && File(widget.item.path!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.item.path!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (kind == ScreenshotKind.expense) ...[
                    _label(c, 'পরিমাণ'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary),
                            decoration: InputDecoration(
                              prefixText: '৳ ',
                              prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.primary),
                              filled: true,
                              fillColor: c.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) => _amount = double.tryParse(v.replaceAll(',', '')) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _incomeToggle(c),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(c, 'শিরোনাম'),
                    _field(c, _titleCtrl, hint: 'কেন খরচ?'),
                    const SizedBox(height: 16),
                    _label(c, 'ক্যাটাগরি'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = _category == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? c.primary.withValues(alpha: 0.18) : c.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? c.primary : Colors.transparent),
                            ),
                            child: Text(
                              _catLabel(cat),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? c.primary : c.textSecondary),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _label(c, 'তারিখ'),
                    _dateTile(c, DateFormat('dd MMM yyyy', 'bn').format(_date), _pickDate),
                  ],
                  if (kind == ScreenshotKind.error || kind == ScreenshotKind.message) ...[
                    _label(c, 'শিরোনাম'),
                    _field(c, _titleCtrl, hint: 'সংক্ষেপে'),
                    const SizedBox(height: 16),
                    _label(c, kind == ScreenshotKind.error ? 'ত্রুটি/সমাধান নোট' : 'বার্তা'),
                    Container(
                      height: 150,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
                      child: TextField(
                        controller: _contentCtrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(fontSize: 13, color: c.textPrimary),
                        decoration: InputDecoration.collapsed(hintText: 'লিখুন...', hintStyle: TextStyle(color: c.textSecondary)),
                      ),
                    ),
                  ],
                  if (kind == ScreenshotKind.message) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => _makeReminder = !_makeReminder),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _makeReminder ? c.primary : Colors.transparent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _makeReminder ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                              color: _makeReminder ? c.primary : c.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('রিমাইন্ডার তৈরির কাজ', style: TextStyle(fontSize: 14, color: c.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_makeReminder) ...[
                      const SizedBox(height: 12),
                      _dateTile(c, DateFormat('dd MMM yyyy, h:mm a', 'bn').format(_deadline), _pickDeadline),
                    ],
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _addToNote,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
                      ),
                      icon: Icon(Icons.note_add_rounded, size: 18, color: c.primary),
                      label: Text('নোটে যোগ করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.primary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: Text(
                        'সংরক্ষণ করুন',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(AppColors c, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textSecondary)),
    );
  }

  Widget _field(AppColors c, TextEditingController ctrl, {required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 14, color: c.textPrimary),
        decoration: InputDecoration.collapsed(hintText: hint, hintStyle: TextStyle(fontSize: 13, color: c.textSecondary)),
      ),
    );
  }

  Widget _dateTile(AppColors c, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 20, color: c.primary),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 14, color: c.textPrimary)),
            const Spacer(),
            Icon(Icons.edit_rounded, size: 16, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _incomeToggle(AppColors c) {
    return GestureDetector(
      onTap: () => setState(() => _isIncome = !_isIncome),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _isIncome ? Color(0xFF6BCB77).withValues(alpha: 0.15) : c.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _isIncome ? const Color(0xFF6BCB77) : Colors.transparent),
        ),
        child: Text(_isIncome ? 'আয়' : 'খরচ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _isIncome ? const Color(0xFF6BCB77) : c.textSecondary)),
      ),
    );
  }

  String _catLabel(String cat) {
    return switch (cat) {
      'food' => 'খাবার',
      'groceries' => 'বাজার',
      'transport' => 'যাতায়াত',
      'bills' => 'বিল',
      'shopping' => 'শপিং',
      'health' => 'স্বাস্থ্য',
      _ => 'অন্যান্য',
    };
  }
}