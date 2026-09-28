import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/services/note_meta.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Shared "add captured content (QR / clipboard / screenshot) to a note"
/// destination picker + writer so every capture consumer behaves identically.
class NoteChooser {
  /// Returns `{id, title, created}`; null when cancelled.
  static Future<Map<String, dynamic>?> pick(BuildContext context) async {
    final c = AppTheme.of(context);
    final ctrl = TextEditingController();
    final notes = Hive.box<Note>('notes').values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('নোটে যোগ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                style: TextStyle(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'নতুন নোটের শিরোনাম',
                  hintStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, {
                    'id': null,
                    'title': ctrl.text.trim().isEmpty ? 'নতুন নোট' : ctrl.text.trim(),
                    'created': true,
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: c.primary),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('নতুন নোট তৈরি', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text('অথবা বিদ্যমান নোটে', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary)),
              const SizedBox(height: 8),
              if (notes.isEmpty)
                Text('কোনো নোট নেই', style: TextStyle(fontSize: 13, color: c.textSecondary))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.3),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final n in notes)
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.note_rounded, color: c.primary, size: 20),
                          title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            stripForPreview(n.content),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                          onTap: () => Navigator.pop(ctx, {'id': n.id, 'title': n.title, 'created': false}),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Appends `block` to an existing note or creates a new one.
  static void appendTo({String? noteId, String? title, required String block}) {
    final box = Hive.box<Note>('notes');
    final now = DateTime.now();
    if (noteId == null) {
      final id = now.millisecondsSinceEpoch.toString();
      box.add(Note(
        id: id,
        title: title ?? 'নতুন নোট',
        content: block,
        createdAt: now,
        updatedAt: now,
      ));
      NoteMeta.scanMentions(id, block);
      return;
    }
    final n = box.values.where((x) => x.id == noteId).firstOrNull;
    if (n == null) return;
    NoteMeta.pushVersion(n);
    n
      ..content = '${n.content}\n---\n$block'
      ..updatedAt = now
      ..save();
    NoteMeta.scanMentions(n.id, block);
  }

  /// Local mirror so this file does not depend on the markup widget.
  static String stripForPreview(String s) {
    var t = s.replaceAll('\r\n', '\n');
    t = t
        .replaceAll(RegExp(r'(\*\*|_{2})(.*?)\1', multiLine: true), r'$2')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'</?(big|small|b|i|u)>'), '');
    t = t.split('\n').map((l) {
      var x = l;
      if (x.trim() == '---') return ' ';
      x = x.replaceFirst(RegExp(r'^#{1,3} '), '').replaceFirst(RegExp(r'^>\s+'), '');
      final chk = RegExp(r'^(\[\s?\]|\[x\]|☐|☑)\s+').hasMatch(x);
      if (chk) x = x.replaceFirst(RegExp(r'^(\[\s?\]|\[x\]|☐|☑)\s+'), '');
      x = x.replaceFirst(RegExp(r'^\d+[.)]\s+'), '').replaceFirst(RegExp(r'^-\s+'), '');
      return x;
    }).join(' ');
    return t.trim();
  }
}