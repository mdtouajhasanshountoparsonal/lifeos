import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/note_meta.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/markup_text.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  String _view = 'timeline';

  static const _views = [
    ('timeline', 'টাইমলাইন', Icons.timeline_rounded),
    ('connections', 'সংযোগ', Icons.hub_rounded),
    ('tags', 'ট্যাগ', Icons.tag_rounded),
  ];

  String _bucketOf(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'গতকাল';
    return DateFormat('dd MMM yyyy').format(d);
  }

  void _preview(AppColors c, Note n) {
    final savedTree = AiTreeStore.get(n.id, task: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Text(n.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary)),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy h:mm a').format(n.updatedAt),
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
            const SizedBox(height: 14),
            if (savedTree != null && savedTree.blueprint.hasNodes) ...[
              BeautifiedTreeCard(
                raw: n.content,
                blueprint: savedTree.blueprint,
                aiSource: savedTree.source,
                animate: false,
              ),
              const SizedBox(height: 14),
            ],
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SelectionArea(
                  child: MarkupText(n.content, baseColor: c.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  Text('জ্ঞান নেটওয়ার্ক', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('Graph', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.primary)),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (key, label, icon) in _views)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(icon, size: 16, color: _view == key ? Colors.white : c.textSecondary),
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        selected: _view == key,
                        onSelected: (_) => setState(() => _view = key),
                        selectedColor: c.primary,
                        labelStyle: TextStyle(
                          color: _view == key ? Colors.white : c.textSecondary,
                          fontSize: 12,
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
                valueListenable: Hive.box<Note>('notes').listenable(),
                builder: (context, Box<Note> box, _) {
                  final notes = box.values.where((n) => !n.isArchived).toList();
                  if (_view == 'timeline') return _timeline(c, notes);
                  if (_view == 'connections') return _connections(c, notes);
                  return _tags(c, notes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(AppColors c, List<Note> notes) {
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (notes.isEmpty) {
      return Center(child: Text('কোনো নোট নেই', style: TextStyle(fontSize: 14, color: c.textSecondary)));
    }
    final groups = <String, List<Note>>{};
    for (final n in notes) {
      groups.putIfAbsent(_bucketOf(n.updatedAt), () => []).add(n);
    }
    final model = <Object?>[];
    for (final entry in groups.entries) {
      model.add(entry.key);
      for (int i = 0; i < entry.value.length; i++) {
        model.add((i: i, note: entry.value[i]));
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: model.length,
      itemBuilder: (context, index) {
        final it = model[index];
        if (it is String) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(it, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.primary)),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 1, color: c.textSecondary.withValues(alpha: 0.15))),
              ],
            ),
          );
        }
        final nt = it as ({int i, Note note});
        return EntranceItem(order: nt.i, child: _timelineRow(c, nt.note));
      },
    );
  }

  Widget _timelineRow(AppColors c, Note n) {
    final tags = NoteMeta.getTags(n.id);
    final links = NoteMeta.getLinks(n.id);
    final private = NoteMeta.isPrivate(n.id);
    return InkWell(
      onTap: () => _preview(c, n),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: private ? c.glow : c.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary))),
                      if (private) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_rounded, size: 12, color: c.glow),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stripMarkup(n.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('h:mm a').format(n.updatedAt), style: TextStyle(fontSize: 10, color: c.textSecondary.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (links.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.hub_rounded, size: 12, color: c.mediumPriority),
                      ),
                    if (tags.isNotEmpty)
                      Icon(Icons.tag_rounded, size: 12, color: c.lowPriority),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _connections(AppColors c, List<Note> notes) {
    final byId = {for (final n in notes) n.id: n};
    final raw = NoteMeta.allConnections();
    final seen = <String>{};
    final pairs = <(String, String)>[];
    for (final e in raw) {
      final a = (e['a'] as String?) ?? '';
      final b = (e['b'] as String?) ?? '';
      if (a.isEmpty || b.isEmpty) continue;
      final key = a.compareTo(b) < 0 ? '$a\x00$b' : '$b\x00$a';
      if (!seen.add(key)) continue;
      pairs.add((a, b));
    }
    if (pairs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_outlined, size: 56, color: c.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('এখনো কোনো সংযোগ নেই', style: TextStyle(fontSize: 14, color: c.textSecondary)),
              const SizedBox(height: 6),
              Text('নোটে @শিরোনাম লিখলে (যেমন @home) লিংক তৈরি হবে', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: pairs.length,
      itemBuilder: (context, i) {
        final (a, b) = pairs[i];
        final aN = byId[a];
        final bN = byId[b];
        return EntranceItem(
          order: i,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.cardColor.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(child: Text(aN?.title ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('↔', style: TextStyle(fontSize: 13)),
                ),
                Expanded(child: Text(bN?.title ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tags(AppColors c, List<Note> notes) {
    final counts = <String, int>{};
    for (final n in notes) {
      for (final t in NoteMeta.getTags(n.id)) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) {
      return Center(child: Text('কোনো ট্যাগ নেই', style: TextStyle(fontSize: 14, color: c.textSecondary)));
    }
    final maxCount = sorted.first.value;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final e in sorted)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10 + (e.value / maxCount) * 10, vertical: 6 + (e.value / maxCount) * 4),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.10 + (e.value / maxCount) * 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '#${e.key} (${e.value})',
                  style: TextStyle(fontSize: 11 + (e.value / maxCount) * 3, fontWeight: FontWeight.w700, color: c.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}