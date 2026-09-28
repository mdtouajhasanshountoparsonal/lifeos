import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/models/note.dart';
import 'nova_engine.dart';

String novaFmt(double v) => fmtSmart(v);

Box novaHistoryBox() => Hive.box('nova_history');

Color novaColor(BuildContext context) => AppTheme.of(context).primary;

Widget novaSection(BuildContext context, String title, Widget child, {VoidCallback? onTap, Color? accent}) {
  final c = AppTheme.of(context);
  return GlassCard(
    accent: accent ?? c.primary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 20, height: 3, decoration: BoxDecoration(color: c.glow, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ),
            if (onTap != null)
              GestureDetector(
                onTap: onTap,
                child: Icon(Icons.add_circle_outline, color: c.primary, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget novaField(BuildContext context, {
  required TextEditingController controller,
  required String label,
  String hint = '',
  TextInputType? keyboard,
  int maxLines = 1,
  TextStyle? style,
  ValueChanged<String>? onChanged,
}) {
  final c = AppTheme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard ?? TextInputType.text,
        onChanged: onChanged,
        style: (style ?? const TextStyle(fontSize: 15)).copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary.withValues(alpha: 0.6), fontSize: 13),
          filled: true,
          fillColor: c.cardColor.withValues(alpha: 0.75),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ],
  );
}

Widget novaLabel(BuildContext context, String text, {Color? color, FontWeight w = FontWeight.w600, double size = 12}) {
  final c = AppTheme.of(context);
  return Text(text, style: TextStyle(color: color ?? c.textSecondary, fontSize: size, fontWeight: w));
}

class NovaOutput extends StatelessWidget {
  final String text;
  final String? unit;
  final bool error;
  final List<String> steps;
  final String category;
  final VoidCallback? onSave;
  const NovaOutput({
    super.key,
    required this.text,
    this.unit,
    this.error = false,
    this.steps = const [],
    this.category = '',
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? c.expense.withValues(alpha: 0.12) : c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error ? c.expense.withValues(alpha: 0.6) : c.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(text,
                    style: TextStyle(
                      color: error ? c.expense : c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    )),
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(unit!, style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final s in steps)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 4, height: 4, decoration: BoxDecoration(color: c.textSecondary, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s,
                          style: TextStyle(color: c.textPrimary.withValues(alpha: 0.85), fontSize: 12.5, height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
          if (onSave != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _actionChip(context, Icons.history, 'ইতিহাসে', onSave!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  final c = AppTheme.of(context);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.glow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.glow.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: c.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

/// Save a calculation entry into Hive 'nova_history' (auto).
String novaSaveHistory({required String category, required String expr, required String result, String? unit, List<String> steps = const []}) {
  final box = Hive.box('nova_history');
  final id = DateTime.now().millisecondsSinceEpoch.toString();
  box.add({
    'id': id,
    'category': category,
    'expr': expr,
    'result': result,
    'unit': unit,
    'steps': steps,
    'at': DateTime.now().toIso8601String(),
  });
  return id;
}

List<Map> novaHistory() {
  final box = Hive.box('nova_history');
  if (box.isEmpty) return [];
  List<Map> out = [];
  for (final e in box.values) {
    if (e is Map) out.add(Map<String, dynamic>.from(e));
  }
  out.sort((a, b) => (b['at'] as String? ?? '').compareTo(a['at'] as String? ?? ''));
  return out;
}

/// Push a formatted calculation into the Notes box as a new Note.
void novaSaveToNotes({required String title, required String content, String? category}) {
  final box = Hive.box<Note>('notes');
  final now = DateTime.now();
  final n = Note(
    id: now.microsecondsSinceEpoch.toString(),
    title: title,
    content: content,
    category: category ?? 'NOVA',
    createdAt: now,
    updatedAt: now,
  );
  box.add(n);
}

String novaFmtTime(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return DateFormat('dd MMM, HH:mm', 'bn').format(dt);
}

/// Guided explanation (local heuristic — offline "AI" layer)
String novaExplain(String category, String q) {
  final s = q.toLowerCase();
  if (s.contains('negative') || s.contains('ঋণাত্মক')) {
    if (category == 'quadratic') return 'দ্বিঘাত সমীকরণে Δ < 0 হলে মূলদ্বয় জটিল (b²−4ac ঋণাত্মক) — তা বাস্তব অক্ষের ওপর ছেদ করে না।';
    if (category == 'physics' || category.contains('phys')) return 'ফিজিক্সে ঋণাত্মক মান মানে দিক/চিহ্ন বিপরীত — যেমন বেগ কমলে ত্বরণ ঋণাত্মক (retardation)।';
    return 'ঋণাত্মক ফলাফল সাধারণত ভেক্টরের দিক, হ্রাস বা ক্ষতির নির্দেশ করে; একক ঠিক আছে কিনা দেখুন।';
  }
  if (category == 'quadratic') return 'ax²+bx+c=0 সমাধানে প্রথমে নিরূপক Δ=b²−4ac দেখুন — Δ>0: দুই বাস্তব মূল, Δ=0: সমান মূল, Δ<0: জটিল মূল।';
  if (category == 'graph') return 'ফাংশনটি x-অক্ষকে যেখানে ছেদ করে সেটিই মূল (root); শীর্ষবিন্দু দিতে dy/dx=0 হাল করুন।';
  if (s.contains('unit') || s.contains('একক')) return 'একই মাত্রার (যেমন দৈর্ঘ্য) এককগুলোই যোগ/বিয়োগ সম্ভব; অন্যথায় dimension mismatch।';
  return 'NOVA'+(category.isEmpty?' ক্যালকুলেটর ': ' ($category) ')+'দিয়ে হিসাবটি হয়, ফলাফলের একক আর স্টেপগুলো ইতিহাসে আছে।';
}