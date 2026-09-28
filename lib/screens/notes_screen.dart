import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/services/note_meta.dart';
import 'package:lifeos/services/notes_media.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/text_normalizer.dart';
import 'package:lifeos/services/market_parser.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/services/bazar_note.dart';
import 'package:lifeos/screens/ai_view_screen.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/bazar_caption.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/command_sheet.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/hub_screen.dart';
import 'package:lifeos/widgets/markup_text.dart';
import 'package:permission_handler/permission_handler.dart';

TreeBlueprint marketSectionsBlueprint(List<MarketSection> sections) {
  final nodes = <TreeNode>[];
  for (final sec in sections) {
    if (sec.items.isEmpty) continue;
    nodes.add(TreeNode(
      text: sec.hasTitle ? sec.title! : 'বাজার',
      emoji: sec.hasTitle ? '📅' : '🛒',
      children: sec.items
          .map((it) => TreeNode(
                text: '${stripMarkup(it.label)}'
                    '${it.hasQty ? ' — ${it.qtyText} × ${it.priceText}' : ''}',
                emoji: it.emoji,
                children: [],
              ))
          .toList(),
    ));
  }
  return TreeBlueprint(title: 'বাজার', titleEmoji: '🛒', nodes: nodes, fixCount: 0, wasEmpty: false);
}

String marketDayChipsText(MarketSection sec) =>
    '${sec.emoji} ${sec.hasTitle ? sec.title : 'বাজার'} → ${sec.subtotalText}';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDay;
  bool _marketOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    'নোট',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const CommandSheet(),
                    ),
                    style: IconButton.styleFrom(backgroundColor: c.cardColor),
                    icon: Icon(Icons.bolt_rounded, color: c.glow),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _NoteEditorSheet(c: c, note: null),
                    ),
                    style: IconButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'নোট খুঁজুন...',
                  hintStyle: TextStyle(color: c.textSecondary),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: c.textSecondary,
                  ),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _dayChip(
                    c,
                    '🛒 বাজার',
                    _marketOnly,
                    () => setState(() {
                      _marketOnly = !_marketOnly;
                      if (_marketOnly) _selectedDay = null;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _dayChip(c, 'সব', _selectedDay == null && !_marketOnly, () => setState(() => _selectedDay = null)),
                  for (var i = 0; i < 7; i++) ...[
                    const SizedBox(width: 6),
                    _dayChip(
                      c,
                      _dayLabel(i),
                      _isSameDay(_selectedDay, DateTime.now().subtract(Duration(days: i))),
                      () => setState(() => _selectedDay = DateTime.now().subtract(Duration(days: i))),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Note>('notes').listenable(),
                builder: (context, Box<Note> box, _) {
                  final notes = box.values.where((n) {
                    if (n.isArchived) return false;
                    if (_marketOnly && !_isMarketNote(n)) return false;
                    if (_selectedDay != null && !_isSameDay(_selectedDay, n.updatedAt)) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      return n.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          stripMarkup(n.content)
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                    }
                    return true;
                  }).toList();

                  if (notes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _marketOnly
                                ? Icons.shopping_cart_rounded
                                : Icons.note_rounded,
                            size: 64,
                            color: c.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _marketOnly ? 'কোনো বাজার নেই' : 'কোনো নোট নেই',
                            style: TextStyle(
                              fontSize: 16,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final groups = <DateTime, List<Note>>{};
                  for (final n in notes) {
                    final day = DateTime(n.updatedAt.year, n.updatedAt.month, n.updatedAt.day);
                    groups.putIfAbsent(day, () => []).add(n);
                  }
                  final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
                  final model = <Object?>[];
                  var order = 0;
                  for (final day in days) {
                    final dayNotes = groups[day]!
                      ..sort((a, b) {
                        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                        return b.updatedAt.compareTo(a.updatedAt);
                      });
                    model.add((order: order++, day: day, dayNotes: dayNotes));
                    for (final n in dayNotes) {
                      model.add((order: order++, note: n));
                    }
                    if (day != days.last) model.add(null);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: model.length,
                    itemBuilder: (context, i) {
                      final it = model[i];
                      if (it == null) return const SizedBox(height: 6);
                      if (it is ({int order, DateTime day, List<Note> dayNotes})) {
                        return EntranceItem(order: it.order, child: _dayHeader(c, it.day, it.dayNotes));
                      }
                      final nt = it as ({int order, Note note});
                      return EntranceItem(order: nt.order, child: _noteHanging(c, nt.note));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip(AppColors c, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }

  String _dayLabel(int i) {
    if (i == 0) return 'আজ';
    if (i == 1) return 'গতকাল';
    return '${DateTime.now().subtract(Duration(days: i)).day}';
  }

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isMarketNote(Note n) {
    if (!RegExp(r'[০-৯0-9]').hasMatch(n.content)) return false;
    return parseMarketSections(_visibleText(n.content)).any((s) => s.items.isNotEmpty);
  }

  static String _visibleText(String raw) {
    final moved = raw.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    return moved.replaceAll(RegExp(r'[#>*_~`]'), '');
  }

  List<MarketSection> _marketSections(Note n) =>
      parseMarketSections(_visibleText(n.content));

  void _showMarketTree(Note note) {
    final c = AppTheme.of(context);
    final sections = _marketSections(note);
    final items = sections.expand((s) => s.items).toList();
    if (items.isEmpty) return;
    final bp = marketSectionsBlueprint(sections);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.62,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🛒', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary)),
                ),
                const SizedBox(width: 8),
                Text(marketTotalText(items),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.income)),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('dd MMM yyyy').format(note.updatedAt)} • ${sections.length}টি কলাম • ${items.length}টি আইটেম',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
            const SizedBox(height: 10),
            if (sections.length > 1)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final sec in sections)
                    if (sec.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.income.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(marketDayChipsText(sec),
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
                      ),
                ],
              ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: bp.hasNodes
                    ? BeautifiedTreeCard(
                        raw: note.content,
                        blueprint: bp,
                        animate: true,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.income.withValues(alpha: 0.16), c.glow.withValues(alpha: 0.07)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.income.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🧮 মোট খরচ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(marketTotalText(items),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.income)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bnDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'গতকাল';
    const months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Widget _dayHeader(AppColors c, DateTime day, List<Note> notes) {
    return TreeBranch(
      dotColor: c.primary,
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 20, color: c.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _bnDay(day),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
            ),
            Text('${notes.length}টি', style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _noteHanging(AppColors c, Note note) {
    return TreeBranch(
      dotColor: note.isPinned ? c.glow : c.secondary,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _buildNoteTile(context, c, note),
      ),
    );
  }

  Widget _buildNoteTile(BuildContext context, AppColors c, Note note) {
    final saved = AiTreeStore.get(note.id, task: false);
    final hasTree = saved != null && saved.blueprint.hasNodes;
    final isPrivate = NoteMeta.isPrivate(note.id);
    final marketItems = _marketSections(note).expand((s) => s.items).toList();
    final hasMarket = marketItems.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _NoteEditorSheet(c: c, note: note),
        ),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: note.isPinned
              ? Border.all(color: c.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (note.isPinned ? c.glow : c.primary).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                note.isPinned ? Icons.push_pin_rounded : Icons.sticky_note_2_rounded,
                size: 19,
                color: note.isPinned ? c.glow : c.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(note.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: c.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (hasTree) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _openAiView(note),
                      child: BeautifiedTreeCard(
                        raw: note.content,
                        blueprint: saved.blueprint,
                        aiSource: saved.source,
                        animate: false,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else ...[
                    Text(
                      isPrivate
                          ? '🔒 ব্যক্তিগত নোট — PIN দিয়ে আনলক করুন'
                          : stripMarkup(note.content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                  BazarCaption(noteId: note.id, content: note.content),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (NoteMeta.isPrivate(note.id)) ...[
                        Icon(Icons.lock_rounded, size: 11, color: c.glow),
                        const SizedBox(width: 4),
                      ],
                      for (final t in NoteMeta.getTags(note.id).take(2))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$t',
                              style: TextStyle(fontSize: 9, color: c.primary),
                            ),
                          ),
                        ),
                      if (hasMarket)
                        GestureDetector(
                          onTap: () => _showMarketTree(note),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: c.income.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '🛒 ${marketTotalText(marketItems)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: c.income,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (hasTree)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '✏️ মূল লেখা',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: c.glow,
                            ),
                          ),
                        ),
                      if (_mediaCount(note.id) > 0)
                        Row(
                          children: [
                            Icon(Icons.attach_file_rounded, size: 11, color: c.primary),
                            const SizedBox(width: 2),
                            Text(
                              '${_mediaCount(note.id)}',
                              style: TextStyle(fontSize: 10, color: c.primary),
                            ),
                          ],
                        ),
                    ],
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

  int _mediaCount(String id) {
    final box = Hive.box('notes_media');
    final v = box.get(id);
    if (v is List && v.isNotEmpty) return v.length;
    return 0;
  }

  void _openAiView(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiViewScreen(noteId: note.id, content: note.content),
      ),
    );
  }
}

class _MarkupController extends TextEditingController {
  final Color base;

  _MarkupController({required this.base, String? text}) : super(text: text);

  /// Renders markup live while typing (markers hidden → WYSIWYG-ish).
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return MarkupText.renderInlineSpans(
      text,
      (style ?? TextStyle(color: base)).copyWith(color: base),
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  final AppColors c;
  final Note? note;

  const _NoteEditorSheet({required this.c, required this.note});

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _id;
  bool _isNew = false;
  bool _preview = false;
  bool _recording = false;
  String _playingPath = '';
  String _lastContent = '';
  List<Map<String, String>> _media = [];
  List<String> _tags = [];
  List<(String, String)> _suggestions = [];
  final ScrollController _editorScroll = ScrollController();
  bool _private = false;
  bool _unlocked = true;
  EnhanceResult? _aiResult;
  String _aiForContent = '';
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _isNew = widget.note == null;
    _id = widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _lastContent = widget.note?.content ?? '';
    _contentCtrl = _MarkupController(
      base: widget.c.textPrimary,
      text: _lastContent,
    );
    _contentCtrl.addListener(_onContentChanged);
    _tags = NoteMeta.getTags(_id);
    _private = NoteMeta.isPrivate(_id);
    if (_private && widget.note != null) {
      _unlocked = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptPin());
    }
    _loadMedia();
    _loadSavedTree();
  }

  /// আগের AI-গাছ থাকলে editor-এ আগে থেকেই দেখানো হয় (লেখা বদলানো হয় না)।
  void _loadSavedTree() {
    final saved = AiTreeStore.get(_id, task: false);
    if (saved == null) return;
    _aiResult = EnhanceResult(
      normalized: const NormalizedText(text: '', sentences: [], fixes: []),
      tree: saved.blueprint,
      usedOnline: saved.source != null && saved.source != 'offline',
      source: saved.source,
    );
    _aiForContent = _lastContent;
  }

  void _loadMedia() {
    final box = Hive.box('notes_media');
    final v = box.get(_id);
    if (v is List) {
      _media = v
          .whereType<Map>()
          .map((m) => {for (final e in m.entries) '${e.key}': '${e.value}'})
          .toList();
    }
  }

  /// P3+: ✨ AI বাটন — offline বট / ইন্টারনেট থাকলে Gemini, শেখা জমা হয়।
  Future<void> _runAi() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty || _aiLoading) return;
    setState(() => _aiLoading = true);
    try {
      final r = await AiEnhancer.enhance(_contentCtrl.text, allowOnline: true);
      if (!mounted) return;
      setState(() {
        _aiResult = r;
        _aiForContent = _contentCtrl.text;
        _preview = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.usedOnline
                ? '🌐 Gemini দিয়ে গাছ বানানো হলো'
                : '🤖 offline বট দিয়ে গাছ বানানো হলো',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: r.usedOnline ? widget.c.secondary : widget.c.primary,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiResult = null;
        _preview = true;
      });
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _snack(String msg, {Color? bg}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg ?? widget.c.primary,
      ));
  }

  /// 🤖 AI ডিজাইন — Gemini নিজেই নোটটাকে সুন্দর করে সাজায়/লিখে।
  /// ব্যর্থ হলে মূল লেখাই থাকে (কিছু হারায় না)। মূল লেখা edit করার ক্ষমতা থাকে।
  Future<void> _aiDesign() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty || _aiLoading) {
      if (mounted) _snack('আগে কিছু লিখুন — তারপর AI ডিজাইন কাজ করবে');
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final designed =
          await AiEnhancer.design(text).timeout(const Duration(seconds: 25));
      if (!mounted) return;
      final out = designed.trim();
      setState(() {
        if (out.isNotEmpty && out != text) {
          _contentCtrl.text = out;
        }
        _aiForContent = _contentCtrl.text;
        _aiResult = null;
        _preview = false;
      });
      _contentCtrl.selection =
          TextSelection.collapsed(offset: _contentCtrl.text.length);
      _snack(out == text
          ? 'ইন্টারনেট/এআই চালু নেই — লেখা আগের মতোই, পরে আবার চেষ্টা করুন'
          : '🤖 AI দিয়ে ডিজাইন করা হলো — চাইলে বদলান, তারপর সেভ করুন');
    } catch (_) {
      if (mounted) _snack('AI ডিজাইন ব্যর্থ — লেখা বদলায়নি');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _onContentChanged() {
    final c = _contentCtrl;
    final old = _lastContent;
    _lastContent = c.text;
    if (_aiResult != null && c.text != _aiForContent) {
      _aiResult = null;
      _aiForContent = '';
    }
    _suggestions = _computeSuggestions();
    setState(() {});
    if (!c.text.contains('\n')) return;
    if (c.text.length != old.length + 1) return;
    final sel = c.selection;
    final idx = sel.isValid && sel.isCollapsed
        ? sel.baseOffset
        : c.text.lastIndexOf('\n');
    if (idx <= 0 || idx > c.text.length || c.text[idx - 1] != '\n') return;

    final nlBefore = c.text.lastIndexOf('\n', idx - 2);
    final lineStart = nlBefore + 1;
    final prevLine = c.text.substring(lineStart, idx - 1);

    final m = RegExp(
      r'^(?<indent>\s*)(?:(?<bullet>[-*+])\s+|(?<num>\d+)(?<delim>[.)])\s+|(?<chk>☐|☑|\[\s?\]|\[x\])\s+|(?<quote>>)[^\S\n]*)',
    ).firstMatch(prevLine);
    if (m == null) return;
    final markerLen = m.group(0)!.length;
    final rest = prevLine.substring(markerLen);
    if (rest.isEmpty) return; // empty list item → Enter ends the list

    final indent = m.namedGroup('indent') ?? '';
    String marker;
    if (m.namedGroup('bullet') != null) {
      marker = '$indent${m.namedGroup('bullet')} ';
    } else if (m.namedGroup('num') != null) {
      final num = int.tryParse(m.namedGroup('num')!) ?? 0;
      marker = '$indent${num + 1}${m.namedGroup('delim')} ';
    } else if (m.namedGroup('chk') != null) {
      final chk = m.namedGroup('chk')!;
      marker = indent + (chk == '☐' || chk == '☑' ? '☐ ' : '[ ] ');
    } else {
      marker = '$indent> ';
    }

    final next = c.text.substring(0, idx) + marker + c.text.substring(idx);
    c.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: idx + marker.length),
    );
  }

  /// Detects shopping-list style lines (দুধ 50, আলু 20, ৳120, 5 টাকা) and
  /// returns (label, price) pairs so the app can total them automatically.
  void _insertMarketTemplate() {
    const tmpl = '# বাজার\n- মাছ ১ কেজি ৩৫০\n- আলু ২ কেজি ৯০\n- ডিম ১ হালি ৫০\n';
    final base = _contentCtrl.selection.isValid
        ? _contentCtrl.selection.start
        : _contentCtrl.text.length;
    final end = _contentCtrl.selection.isValid
        ? _contentCtrl.selection.end
        : base;
    _contentCtrl.value = TextEditingValue(
      text: _contentCtrl.text.replaceRange(base, end, tmpl),
      selection: TextSelection.collapsed(offset: base + tmpl.length),
    );
    _onContentChanged();
  }

  void _toggleCheck(int line) {
    final lines = _contentCtrl.text.split('\n');
    if (line >= lines.length) return;
    final l = lines[line];
    if (l.contains('☐')) {
      lines[line] = l.replaceFirst('☐', '☑');
    } else if (l.contains('☑')) {
      lines[line] = l.replaceFirst('☑', '☐');
    } else if (l.contains('[ ]')) {
      lines[line] = l.replaceFirst('[ ]', '[x]');
    } else if (l.contains('[x]')) {
      lines[line] = l.replaceFirst('[x]', '[ ]');
    } else {
      return;
    }
    _contentCtrl.text = lines.join('\n');
  }

  Widget _modeChip(
    AppColors c, {
    required bool active,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? c.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? c.primary : c.textSecondary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? c.primary : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketTable(
    AppColors c,
    List<MarketSection> sections, {
    required void Function(MarketItem) onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 22),
              Expanded(
                child: Text(
                  'আইটেম',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  'পরিমাণ',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  'দর',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  'মোট',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 16, color: c.textSecondary.withValues(alpha: 0.2)),
        for (final sec in sections) ...[
          if (sec.hasTitle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(sec.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sec.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sec.subtotalText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.income,
                    ),
                  ),
                ],
              ),
            ),
          for (final it in sec.items)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onEdit(it),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        it.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        stripMarkup(it.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.textPrimary),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        it.hasQty ? it.qtyText : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        it.priceText,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        it.totalText,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _jumpToEditor(it.line),
                      child: Icon(
                        Icons.north_east_rounded,
                        size: 14,
                        color: c.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<(String, String)> _computeSuggestions() {
    final c = _contentCtrl;
    final sel = c.selection;
    final idx = (sel.isValid && sel.isCollapsed)
        ? sel.baseOffset.clamp(0, c.text.length)
        : c.text.length;
    final prefix = c.text.substring(0, idx);
    final line = prefix.split('\n').last;
    final stripped = line.replaceFirst(kMarketMarkerRe, '').trim();
    if (stripped.isEmpty) return const [];
    final mt = RegExp(r'([^\s.,]+)\s*$').firstMatch(stripped);
    if (mt == null) return const [];
    final frag = mt.group(1)!.toLowerCase();
    if (frag.isEmpty || parseNumber(frag) != null) return const [];
    final seen = <String>{};
    final out = <(String, String)>[];
    for (final e in kMarketIconEntries) {
      for (final k in e.keys) {
        final key = k.trim();
        if (key.length < 2) continue;
        final kl = key.toLowerCase();
        if (kl == frag) continue;
        if (!(kl.startsWith(frag) || (frag.length >= 2 && kl.contains(frag)))) {
          continue;
        }
        if (!seen.add(kl)) continue;
        out.add((key, e.emoji));
        if (out.length >= 6) return out;
      }
    }
    out.sort((a, b) {
      final sa = a.$1.toLowerCase().startsWith(frag) ? 0 : 1;
      final sb = b.$1.toLowerCase().startsWith(frag) ? 0 : 1;
      return sa - sb;
    });
    return out;
  }

  void _applySuggestion(String word) {
    final c = _contentCtrl;
    final sel = c.selection;
    final idx = (sel.isValid && sel.isCollapsed)
        ? sel.baseOffset.clamp(0, c.text.length)
        : c.text.length;
    final prefix = c.text.substring(0, idx);
    final lineStart = prefix.lastIndexOf('\n') + 1;
    final line = c.text.substring(lineStart, idx);
    final m = kMarketMarkerRe.firstMatch(line);
    final markerLen = m?.group(0)?.length ?? 0;
    final content = line.substring(markerLen);
    final mt = RegExp(r'([^\s.,]+)\s*$').firstMatch(content);
    final fragStart = mt == null
        ? lineStart + content.length
        : lineStart + markerLen + mt.start;
    const rep = ' ';
    final newText =
        c.text.substring(0, fragStart) + word + rep + c.text.substring(idx);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: fragStart + word.length + 1),
    );
  }

  Widget _suggestionBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final (w, e) = _suggestions[i];
            return GestureDetector(
              onTap: () => _applySuggestion(w),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.glow.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$e $w',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _marketAiTree(AppColors c, List<MarketSection> sections) {
    final items = sections.expand((s) => s.items).toList();
    if (items.isEmpty) return;
    final prompt = _contentCtrl.text.trim().isEmpty
        ? sections
            .map((s) =>
                '${s.emoji} ${s.hasTitle ? s.title! : 'বাজার'}:\n${s.items.map((i) => '${i.label} ${i.qtyText} ${i.priceText}').join('\n')}')
            .join('\n')
        : _contentCtrl.text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarketAiTreeSheet(c: c, prompt: prompt, raw: _contentCtrl.text),
    );
  }

  void _showShoppingBreakdown(AppColors c, List<MarketSection> sections) {
    final items = sections.expand((s) => s.items).toList();
    var isTable = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (setCtx, setSheet) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.72,
          ),
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
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '🧮 বাজার হিসাব',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${items.length}টি আইটেম',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _marketAiTree(c, sections),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.glow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 13, color: c.glow),
                          const SizedBox(width: 4),
                          Text('AI গাছ',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700, color: c.glow)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _modeChip(
                      c,
                      active: !isTable,
                      icon: '🌳',
                      label: 'ট্রি',
                      onTap: () => setSheet(() => isTable = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeChip(
                      c,
                      active: isTable,
                      icon: '📋',
                      label: 'টেবিল',
                      onTap: () => setSheet(() => isTable = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: isTable
                      ? _marketTable(
                          c,
                          sections,
                          onEdit: (it) {
                            _editMarketItem(c, it);
                          },
                        )
                      : Column(
                          children: [
                            if (sections.length > 1) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final sec in sections)
                                    if (sec.items.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.income.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(marketDayChipsText(sec),
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.textPrimary)),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            BeautifiedTreeCard(
                              raw: _contentCtrl.text,
                              blueprint: marketSectionsBlueprint(sections),
                              animate: false,
                            ),
                            const SizedBox(height: 12),
                            for (final sec in sections) ...[
                              if (sec.hasTitle)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        sec.emoji,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          sec.title!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: c.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        sec.subtotalText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: c.income,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              for (final it in sec.items)
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _editMarketItem(c, it),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.emoji,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                stripMarkup(it.label),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: c.textPrimary,
                                                ),
                                              ),
                                              if (it.hasQty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    '${it.qtyText} × ${it.priceText}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: c.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          it.totalText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => _jumpToEditor(it.line),
                                          child: Icon(
                                            Icons.north_east_rounded,
                                            size: 14,
                                            color: c.textSecondary.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 14,
                                          color: c.textSecondary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'GRAND TOTAL',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    marketTotalText(items),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: c.income,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Hive.box<Expense>('expenses').add(
                      Expense(
                        id: '${DateTime.now().millisecondsSinceEpoch}_${items.length}',
                        title: widget.note?.title.isNotEmpty == true
                            ? widget.note!.title
                            : 'বাজার',
                        amount: marketTotal(items),
                        category: 'shopping',
                        date: DateTime.now(),
                        note: '🧮 বাজার হিসাব থেকে',
                      ),
                    );
                    Navigator.of(context).maybePop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          '💰 ${marketTotalText(items)} খরচ Money-তে যোগ হয়েছে',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text(
                    'Money-তে খরচ যোগ করুন',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToEditor(int line) {
    Navigator.of(context).maybePop();
    if (mounted) setState(() => _preview = false);
    final lines = _contentCtrl.text.split('\n');
    var offset = 0;
    var target = _contentCtrl.text.length;
    for (var i = 0; i <= line && i < lines.length; i++) {
      target = offset + lines[i].length;
      offset += lines[i].length + 1;
    }
    _contentCtrl.selection = TextSelection.collapsed(offset: target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editorScroll.hasClients) return;
      final dy = (line * 22.0).clamp(
        0.0,
        _editorScroll.position.maxScrollExtent,
      );
      _editorScroll.animateTo(
        dy,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _editMarketItem(AppColors c, MarketItem it) async {
    final nameCtrl = TextEditingController(text: it.label);
    final qtyCtrl = TextEditingController(text: it.qty?.toString() ?? '');
    final unitCtrl = TextEditingController(text: it.unit ?? '');
    final priceCtrl = TextEditingController(
      text: it.unitPrice?.toString() ?? '',
    );
    final unit = it.unit;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
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
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${it.emoji} আইটেম এডিট',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'টোটাল: ${it.totalText}',
                    style: TextStyle(fontSize: 12, color: c.income),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: TextStyle(fontSize: 15, color: c.textPrimary),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'আইটেম নাম',
                  labelStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.cardColor.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(fontSize: 15, color: c.textPrimary),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'পরিমাণ',
                        hintText: '১০',
                        labelStyle: TextStyle(color: c.textSecondary),
                        hintStyle: TextStyle(color: c.textSecondary),
                        filled: true,
                        fillColor: c.cardColor.withValues(alpha: 0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      style: TextStyle(fontSize: 15, color: c.textPrimary),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'ইউনিট',
                        hintText: 'kg / কেজি',
                        labelStyle: TextStyle(color: c.textSecondary),
                        hintStyle: TextStyle(color: c.textSecondary),
                        filled: true,
                        fillColor: c.cardColor.withValues(alpha: 0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(fontSize: 15, color: c.textPrimary),
                decoration: InputDecoration(
                  labelText: it.hasQty
                      ? 'দর (৳ প্রতি ${unit ?? 'ইউনিট'})'
                      : 'দাম (৳)',
                  labelStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.cardColor.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('বাতিল'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'হালনাগাদ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    final qty = parseNumber(qtyCtrl.text);
    final price = parseNumber(priceCtrl.text);
    final rawUnit = unitCtrl.text.trim();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    priceCtrl.dispose();

    if (ok != true) return;
    if (price == null || price <= 0) return;

    var newLine = name.isEmpty ? it.label : name;
    final u = rawUnit.isEmpty ? null : matchUnit(rawUnit);
    if (qty != null && qty > 0) {
      newLine += ' ${marketNumText(qty)}';
      if (u != null) newLine += ' $u';
      newLine += ' ${marketNumText(price)}';
    } else {
      newLine += ' ${marketNumText(price)}';
    }

    final lines = _contentCtrl.text.split('\n');
    if (it.line < lines.length) {
      lines[it.line] = newLine;
      _contentCtrl.text = lines.join('\n');
      if (mounted) setState(() {});
    }
  }

  void _showOutline() {
    final c = widget.c;
    final lines = _contentCtrl.text.split('\n');
    final sections = <({String title, int level, int from, int to})>[];
    var from = 0;
    for (var i = 0; i < lines.length; i++) {
      final m = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(lines[i]);
      if (m != null) {
        sections.add((
          title: m.group(2)!.trim(),
          level: m.group(1)!.length,
          from: from,
          to: i,
        ));
        from = i + 1;
      }
    }
    if (from < lines.length) {
      sections.add((title: '… শেষ', level: 4, from: from, to: lines.length));
    }
    final lc = [c.primary, c.secondary, c.mediumPriority, c.glow];
    Color levelColor(int lvl) => lc[((lvl - 1).clamp(0, 3)).toInt()];

    String? headingDate(String title) {
      final now = DateTime.now();
      if (title.contains('আজ'))
        return 'আজ • ${DateFormat('d MMM').format(now)}';
      if (title.contains('আগামীকাল'))
        return 'আগামীকাল • ${DateFormat('d MMM').format(now.add(const Duration(days: 1)))}';
      if (title.contains('কাল'))
        return 'কাল • ${DateFormat('d MMM').format(now.add(const Duration(days: 1)))}';
      return null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
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
              decoration: BoxDecoration(
                color: c.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '🌳 নোটের গাছ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sections.length}টি অংশ',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'প্রতি # অংশ আলাদা রঙে • ভেতরে লিখলে গাছের ডালের মতো',
              style: TextStyle(fontSize: 11, color: c.textSecondary),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sections.length <= 1
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_tree_rounded,
                            size: 46,
                            color: c.textSecondary.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'অংশ যোগ করতে # শিরোনাম লিখো',
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'যেমন: # আজকের বাজার',
                            style: TextStyle(fontSize: 12, color: c.glow),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        for (var i = 0; i < sections.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _OutlineBranch(
                              c: c,
                              title: sections[i].title,
                              level: sections[i].level,
                              color: levelColor(sections[i].level),
                              dateLabel: headingDate(sections[i].title),
                              content: lines
                                  .sublist(sections[i].from, sections[i].to)
                                  .join('\n'),
                              onToggleCheck: _toggleCheck,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedia() {
    Hive.box('notes_media')
        .put(_id, _media.map((m) => Map<String, String>.from(m)).toList());
  }

  Future<void> _promptPin() async {
    if (!mounted) return;
    final c = widget.c;
    if (!NoteMeta.hasPin) {
      final p1 = TextEditingController();
      final created = await showDialog<bool>(
        context: context,
        builder: (ctx) => _pinDialog(
          ctx,
          c,
          title: 'নতুন ভল্ট PIN সেট করুন',
          subtitle: 'ব্যক্তিগত নোট আনলক করতে এই PIN লাগবে',
          confirm: (v) async {
            if (v.length < 4) {
              return 'অন্তত ৪ সংখ্যা দিন';
            }
            NoteMeta.setPin(v);
            return null;
          },
          controller: p1,
        ),
      );
      if (created == true) {
        setState(() => _unlocked = true);
      } else {
        Navigator.pop(context);
      }
      return;
    }
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _pinDialog(
        ctx,
        c,
        title: 'ব্যক্তিগত নোট',
        subtitle: 'PIN দিন',
        confirm: (v) async => NoteMeta.verifyPin(v) ? null : 'ভুল PIN',
        controller: ctrl,
      ),
    );
    if (ok == true) {
      setState(() => _unlocked = true);
    } else {
      Navigator.pop(context);
    }
  }

  Widget _pinDialog(
    BuildContext ctx,
    AppColors c, {
    required String title,
    required String subtitle,
    required Future<String?> Function(String) confirm,
    required TextEditingController controller,
  }) {
    return AlertDialog(
      backgroundColor: c.surfaceColor,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            maxLength: 8,
            decoration: const InputDecoration(hintText: '••••'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('বাতিল', style: TextStyle(color: c.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            final err = await confirm(controller.text);
            if (err == null) {
              if (ctx.mounted) Navigator.pop(ctx, true);
            } else if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    err,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: c.primary),
          child: const Text(
            'চালিয়ে যান',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _openOptions() async {
    final c = widget.c;
    final tagsCtrl = TextEditingController();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              decoration: BoxDecoration(
                color: c.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'নোট অপশন',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _aiDesign();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.primary.withValues(alpha: 0.18),
                      c.glow.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: c.glow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🤖 AI ডিজাইন',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gemini নিজেই নোট সাজিয়ে/লিখে দেবে (হিসাবসহ) — পরে edit করা যায়',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ট্যাগ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in _tags)
                  InputChip(
                    label: Text('#$t', style: const TextStyle(fontSize: 12)),
                    onDeleted: () => setState(() => _tags.remove(t)),
                    backgroundColor: c.primary.withValues(alpha: 0.12),
                    deleteIconColor: c.primary,
                  ),
                InputChip(
                  avatar: Icon(Icons.add_rounded, size: 16, color: c.primary),
                  label: const Text('নতুন', style: TextStyle(fontSize: 12)),
                  backgroundColor: c.cardColor,
                  onPressed: () async {
                    final tag = await _askTag(ctx, tagsCtrl);
                    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
                      setState(() => _tags.add(tag));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _private,
              onChanged: (v) {
                if (v && !NoteMeta.hasPin) {
                  setState(() => _private = true);
                  return;
                }
                setState(() => _private = v);
              },
              title: Text(
                '🔒 ব্যক্তিগত নোট',
                style: TextStyle(fontSize: 13, color: c.textPrimary),
              ),
              subtitle: Text(
                'PIN ছাড়া দেখার জন্য বন্ধ',
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
              activeTrackColor: c.primary,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showVersions();
                  },
                  icon: Icon(Icons.history_rounded, size: 16, color: c.primary),
                  label: Text(
                    'সংস্করণ ইতিহাস (${NoteMeta.getVersions(_id).length})',
                    style: TextStyle(fontSize: 13, color: c.primary),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showConnections();
                  },
                  icon: Icon(Icons.link_rounded, size: 16, color: c.glow),
                  label: Text(
                    'সংযোগ (${NoteMeta.getLinks(_id).length})',
                    style: TextStyle(fontSize: 13, color: c.glow),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showOutline();
                  },
                  icon: Icon(
                    Icons.account_tree_rounded,
                    size: 16,
                    color: c.mediumPriority,
                  ),
                  label: Text(
                    '🌳 গাছ / আউটলাইন',
                    style: TextStyle(fontSize: 13, color: c.mediumPriority),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (changed == true) setState(() {});
  }

  Future<String?> _askTag(BuildContext ctx, TextEditingController ctrl) {
    return showDialog<String>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: widget.c.surfaceColor,
        title: const Text(
          'নতুন ট্যাগ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'যেমন: ফ্লাটার'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(
              'বাতিল',
              style: TextStyle(color: widget.c.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: widget.c.primary),
            child: const Text('যোগ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVersions() {
    final c = widget.c;
    final versions = NoteMeta.getVersions(_id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: versions.isEmpty
            ? Center(
                child: Text(
                  'কোনো সংস্করণ নেই',
                  style: TextStyle(color: c.textSecondary),
                ),
              )
            : ListView(
                children: [
                  for (final v in versions)
                    Card(
                      color: c.cardColor,
                      child: ListTile(
                        title: Text(
                          DateFormat('MMM d, yyyy HH:mm')
                              .format(DateTime.parse(v['at'] as String)),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          stripMarkup(
                            '${v['title'] ?? ''}\n${v['content'] ?? ''}',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                        onTap: () {
                          _titleCtrl.text = v['title'] as String? ?? '';
                          _contentCtrl.text = v['content'] as String? ?? '';
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showConnections() {
    final c = widget.c;
    final links = NoteMeta.getLinks(_id);
    final notes = Hive.box<Note>('notes');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: links.isEmpty
            ? SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'কোনো সংযোগ নেই\nনোটের ভেতরে @নোটের-শিরোনাম লিখলে স্বয়ংক্রিয় লিংক হবে',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'সংযুক্ত নোট',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final id in links)
                    Builder(
                      builder: (sb) {
                        final n = notes.values
                            .where((note) => note.id == id)
                            .firstOrNull;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.link_rounded, color: c.glow),
                          title: Text(
                            n?.title ?? 'মুছে ফেলা হয়েছে',
                            style: TextStyle(
                              fontSize: 14,
                              color: c.textPrimary,
                            ),
                          ),
                          onTap: () async {
                            final note = n;
                            if (note != null) {
                              Navigator.pop(ctx);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    _NoteEditorSheet(c: c, note: note),
                              );
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    NotesMedia.stopAudio();
    if (_recording) {
      NotesMedia.stopRecording();
    }
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    final c = widget.c;
    if (_recording) {
      final path = await NotesMedia.stopRecording();
      if (path != null && path.isNotEmpty) {
        setState(() => _media.add({'type': 'voice', 'path': path}));
        _saveMedia();
      }
      setState(() => _recording = false);
      return;
    }
    final perm = await Permission.microphone.request();
    if (perm.isDenied || perm.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'মাইক্রোফোন অনুমতি প্রয়োজন',
            style: TextStyle(color: c.surfaceColor),
          ),
        ),
      );
      return;
    }
    final ok = await NotesMedia.startRecording();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'রেকর্ডিং শুরু করা যায়নি',
            style: TextStyle(color: c.surfaceColor),
          ),
        ),
      );
      return;
    }
    setState(() => _recording = true);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = picked.path;
    if (path.isNotEmpty) {
      setState(() => _media.add({'type': 'image', 'path': path}));
      _saveMedia();
    }
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final path = picked.path;
    if (path.isNotEmpty) {
      setState(() => _media.add({'type': 'video', 'path': path}));
      _saveMedia();
    }
  }

  Future<void> _tapMedia(Map<String, String> m) async {
    final type = m['type'];
    final path = m['path'];
    if (path == null) return;
    if (type == 'voice') {
      if (_playingPath == path) {
        await NotesMedia.stopAudio();
        setState(() => _playingPath = '');
      } else {
        final ok = await NotesMedia.playAudio(path);
        setState(() => _playingPath = ok ? path : '');
      }
    } else if (type == 'image') {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          child: GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      );
    } else if (type == 'video') {
      await NotesMedia.openMedia(path);
    }
  }

  Widget _mediaStrip() {
    final c = widget.c;
    if (_media.isEmpty && !_recording) return const SizedBox.shrink();
    return SizedBox(
      height: 74,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          if (_recording)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.expense.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'রেকর্ডিং...',
                    style: TextStyle(color: c.expense, fontSize: 12),
                  ),
                ],
              ),
            ),
          for (final m in _media) _mediaCard(c, m),
        ],
      ),
    );
  }

  Widget _mediaCard(AppColors c, Map<String, String> m) {
    final type = m['type'];
    final path = m['path'];
    final active = _playingPath == path;
    IconData icon = Icons.mic_rounded;
    Color color = c.primary;
    if (type == 'image') {
      icon = Icons.image_rounded;
      color = Colors.orange.shade300;
    } else if (type == 'video') {
      icon = Icons.movie_rounded;
      color = Colors.teal.shade300;
    }
    return GestureDetector(
      onTap: () => _tapMedia(m),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (active)
              Icon(Icons.stop_circle_rounded, size: 20, color: c.expense)
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                type ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _media.remove(m));
                _saveMedia();
              },
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    final c = widget.c;
    final iconStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      foregroundColor: c.textPrimary,
      backgroundColor: c.cardColor,
      minimumSize: const Size(34, 30),
      padding: EdgeInsets.zero,
    );
    Widget btn(String label, VoidCallback fn) => Tooltip(
      message: label,
      child: InkWell(
        onTap: fn,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            btn(
              '#',
              () => insertToken(
                _contentCtrl,
                _contentCtrl.selection,
                '# ',
                block: true,
              ),
            ),
            btn(
              'B',
              () => wrapSelection(
                _contentCtrl,
                _contentCtrl.selection,
                '**',
                '**',
              ),
            ),
            btn(
              'I',
              () =>
                  wrapSelection(_contentCtrl, _contentCtrl.selection, '*', '*'),
            ),
            btn(
              'U',
              () => wrapSelection(
                _contentCtrl,
                _contentCtrl.selection,
                '__',
                '__',
              ),
            ),
            IconButton(
              onPressed: () => insertToken(
                _contentCtrl,
                _contentCtrl.selection,
                '☐ ',
                block: true,
              ),
              style: iconStyle,
              icon: const Icon(Icons.check_box_outline_blank_rounded, size: 17),
            ),
            IconButton(
              onPressed: () => insertToken(
                _contentCtrl,
                _contentCtrl.selection,
                '> ',
                block: true,
              ),
              style: iconStyle,
              icon: const Icon(Icons.format_quote_rounded, size: 17),
            ),
            IconButton(
              onPressed: () => insertToken(
                _contentCtrl,
                _contentCtrl.selection,
                '- ',
                block: true,
              ),
              style: iconStyle,
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 17),
            ),
            IconButton(
              onPressed: () => insertToken(
                _contentCtrl,
                _contentCtrl.selection,
                '1. ',
                block: true,
              ),
              style: iconStyle,
              icon: const Icon(Icons.format_list_numbered_rounded, size: 17),
            ),
            IconButton(
              onPressed: _insertMarketTemplate,
              style: iconStyle,
              icon: const Icon(Icons.shopping_cart_rounded, size: 17),
            ),
            IconButton(
              onPressed: () {
                final secs = parseMarketSections(_contentCtrl.text);
                if (secs.expand((s) => s.items).length >= 2) {
                  _showShoppingBreakdown(c, secs);
                }
              },
              tooltip: 'বাজার হিসাব',
              style: iconStyle,
              icon: const Icon(Icons.calculate_rounded, size: 17),
            ),
            btn(
              'A+',
              () => wrapSelection(
                _contentCtrl,
                _contentCtrl.selection,
                '<big>',
                '</big>',
              ),
            ),
            btn(
              'A-',
              () => wrapSelection(
                _contentCtrl,
                _contentCtrl.selection,
                '<small>',
                '</small>',
              ),
            ),
            IconButton(
              onPressed: _toggleRecord,
              style: iconStyle.copyWith(
                foregroundColor: WidgetStatePropertyAll(
                  _recording ? Colors.red : c.textPrimary,
                ),
              ),
              icon: Icon(
                _recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                size: 17,
              ),
            ),
            IconButton(
              onPressed: _pickImage,
              style: iconStyle,
              icon: const Icon(Icons.image_rounded, size: 17),
            ),
            IconButton(
              onPressed: _pickVideo,
              style: iconStyle,
              icon: const Icon(Icons.movie_rounded, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_private && !_unlocked) return;
    final now = DateTime.now();
    final title = _titleCtrl.text.isEmpty ? 'নতুন নোট' : _titleCtrl.text;
    if (widget.note != null) {
      NoteMeta.pushVersion(widget.note!);
      widget.note!
        ..title = title
        ..content = _contentCtrl.text
        ..updatedAt = now
        ..save();
    } else {
      Hive.box<Note>('notes').add(
        Note(
          id: _id,
          title: title,
          content: _contentCtrl.text,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    NoteMeta.setTags(_id, _tags);
    NoteMeta.setPrivate(_id, _private);
    NoteMeta.scanMentions(_id, _contentCtrl.text);
    _saveMedia();
    understandNote(_contentCtrl.text, save: true, noteId: _id);
    final ai = _aiResult;
    if (ai != null) {
      AiTreeStore.save(_id, ai.tree, task: false, source: ai.source);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: _isNew,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'শিরোনাম',
                      hintStyle: TextStyle(color: c.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.edit_rounded),
                      label: Text('লিখুন'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.visibility_rounded),
                      label: Text('প্রিভিউ'),
                    ),
                  ],
                  selected: {_preview},
                  onSelectionChanged: (s) => setState(() => _preview = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (st) => st.contains(WidgetState.selected)
                          ? c.primary
                          : c.cardColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _aiLoading ? null : _runAi,
                  tooltip: 'AI গাছ (online / offline)',
                  visualDensity: VisualDensity.compact,
                  icon: _aiLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.glow,
                          ),
                        )
                      : Icon(Icons.auto_awesome_rounded, color: c.glow),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _openOptions,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.more_horiz_rounded, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!_preview) _toolbar(),
            _mediaStrip(),
            const SizedBox(height: 4),
            if (!_preview && _suggestions.isNotEmpty) _suggestionBar(c),
            Expanded(
              child: !_unlocked
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 56,
                            color: c.glow.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'ব্যক্তিগত নোট',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PIN দিয়ে আনলক করুন',
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _promptPin,
                            style: FilledButton.styleFrom(
                              backgroundColor: c.primary,
                            ),
                            icon: const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text(
                              'আনলক',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _preview
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.cardColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_aiResult != null &&
                                _contentCtrl.text.trim().isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: c.glow,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI গাছ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: c.glow,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              BeautifiedTreeCard(
                                raw: _contentCtrl.text,
                                blueprint: _aiResult?.tree,
                                aiSource: _aiResult?.source,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: c.textSecondary
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'মূল লেখা',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: c.textSecondary
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            SelectionArea(
                              child: MarkupText(
                                _contentCtrl.text.isEmpty
                                    ? '_খালি_ _নোট_ _প্রিভিউ_'
                                    : _contentCtrl.text,
                                baseColor: c.textPrimary,
                                interactiveChecks: true,
                                onToggleCheck: _toggleCheck,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contentCtrl,
                            scrollController: _editorScroll,
                            maxLines: null,
                            expands: true,
                            style: TextStyle(fontSize: 14, color: c.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'লিখুন... (ফরম্যাট ব্যানার ব্যবহার করুন)',
                              hintStyle: TextStyle(color: c.textSecondary),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.note != null)
                  IconButton(
                    onPressed: () {
                      widget.note!.isPinned = !widget.note!.isPinned;
                      widget.note!.save();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      widget.note!.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: c.primary,
                    ),
                  ),
                if (widget.note != null)
                  IconButton(
                    onPressed: () {
                      NotesMedia.stopAudio();
                      widget.note!.delete();
                      if (Hive.box('notes_media').containsKey(_id)) {
                        Hive.box('notes_media').delete(_id);
                      }
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.delete_outline, color: c.expense),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'সংরক্ষণ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBranch extends StatefulWidget {
  final AppColors c;
  final String title;
  final int level;
  final Color color;
  final String? dateLabel;
  final String content;
  final ValueChanged<int> onToggleCheck;

  const _OutlineBranch({
    required this.c,
    required this.title,
    required this.level,
    required this.color,
    required this.dateLabel,
    required this.content,
    required this.onToggleCheck,
  });

  @override
  State<_OutlineBranch> createState() => _OutlineBranchState();
}

class _OutlineBranchState extends State<_OutlineBranch> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final lv = widget.level;
    final fontSize = lv == 1
        ? 17.0
        : lv == 2
        ? 15.0
        : lv == 3
        ? 13.0
        : 12.0;
    return Container(
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.account_tree_rounded,
                      size: 17,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: lv == 1
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.dateLabel != null) ...[
                          const SizedBox(height: 3),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: widget.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.dateLabel!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: widget.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: widget.color, width: 3),
                        top: BorderSide(
                          color: widget.color.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: widget.content.trim().isNotEmpty
                        ? MarkupText(
                            widget.content,
                            baseColor: c.textPrimary,
                            interactiveChecks: true,
                            onToggleCheck: widget.onToggleCheck,
                          )
                        : Text(
                            'এই অংশের বিষয়বস্তু খালি',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _MarketAiTreeSheet extends StatefulWidget {
  final AppColors c;
  final String prompt;
  final String raw;
  const _MarketAiTreeSheet({required this.c, required this.prompt, required this.raw});

  @override
  State<_MarketAiTreeSheet> createState() => _MarketAiTreeSheetState();
}

class _MarketAiTreeSheetState extends State<_MarketAiTreeSheet> {
  TreeBlueprint? _tree;
  String? _source;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final r = await AiEnhancer.enhance(widget.prompt, allowOnline: true)
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() {
        _tree = r.tree;
        _source = r.source;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      height: MediaQuery.of(context).size.height * 0.66,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
              const SizedBox(width: 8),
              Text('AI বাজার গাছ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('প্রতিদিনের বাজার → আইকন + ট্রি',
              style: TextStyle(fontSize: 11, color: c.textSecondary)),
          const SizedBox(height: 10),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  Widget _body(AppColors c) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: c.textSecondary),
            const SizedBox(height: 10),
            Text('AI গাছ বানানো গেল না', style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.expense)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _run,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('আবার চেষ্টা'),
            ),
          ],
        ),
      );
    }
    if (_tree == null) {
      return const Center(
        child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (!_tree!.hasNodes) {
      return Center(child: Text('কোনো গাছ মেলেনি', style: TextStyle(color: c.textSecondary)));
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: BeautifiedTreeCard(raw: widget.raw, blueprint: _tree, aiSource: _source, animate: true),
    );
  }
}
