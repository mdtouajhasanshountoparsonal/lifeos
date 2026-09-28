import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/inbox_item.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/services/ocr_service.dart';
import 'package:lifeos/services/screenshot_parser.dart';
import 'package:lifeos/services/detect_text.dart';
import 'package:lifeos/services/shared_inbox.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/screenshot_review_sheet.dart';

class ScreenshotInboxScreen extends StatefulWidget {
  const ScreenshotInboxScreen({super.key});

  @override
  State<ScreenshotInboxScreen> createState() => _ScreenshotInboxScreenState();
}

class _ScreenshotInboxScreenState extends State<ScreenshotInboxScreen> {
  Timer? _timer;
  bool _processing = false;
  final _picker = ImagePicker();
  bool _isNudgedByShare = false;

  @override
  void initState() {
    super.initState();
    _drainShared();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _drainShared());
  }

  @override
  void deactivate() {
    _timer?.cancel();
    super.deactivate();
  }

  Future<void> _drainShared() async {
    if (_isNudgedByShare) return;
    _isNudgedByShare = true;
    try {
      final inbox = Hive.box<InboxItem>('inbox');
      while (true) {
        final share = await SharedInbox.poll();
        if (share == null) break;
        if (share['type'] == 'text') {
          final now = DateTime.now();
          Hive.box('clipboard').add({
            'id': now.millisecondsSinceEpoch.toString(),
            'text': (share['text'] as String? ?? ''),
            'type': TextInsight.typeOf(share['text'] as String? ?? ''),
            'at': now.toIso8601String(),
            'sensitive': TextInsight.isSensitive(share['text'] as String? ?? ''),
            'starred': false,
          });
        } else if (share['type'] == 'image' && share['path'] != null) {
          inbox.add(InboxItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: share['path'] as String?,
            receivedAt: DateTime.now(),
          ));
        }
      }
      _maybeAutoProcess();
    } finally {
      _isNudgedByShare = false;
    }
  }

  void _maybeAutoProcess() {
    if (_processing) return;
    final bpin = Hive.box<InboxItem>('inbox')
        .values
        .where((e) => !e.processed)
        .toList();
    if (bpin.isEmpty) return;
    _process(bpin.first);
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final item = InboxItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: file.path,
      receivedAt: DateTime.now(),
    );
    await Hive.box<InboxItem>('inbox').add(item);
    _maybeAutoProcess();
  }

  Future<void> _process(InboxItem item) async {
    _processing = true;
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.path != null ? 'OCR পড়ছে...' : 'বিশ্লেষণ হচ্ছে...',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
      }
      String text;
      if (item.path != null) {
        text = await OcrService.extractText(item.path!);
      } else {
        text = item.text ?? '';
      }
      item.ocrText = text;
      await item.save();
      if (!mounted) return;
      final result = ScreenshotParser.parse(text);
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ScreenshotReviewSheet(item: item, result: result),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR ব্যর্থ: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.black87,
          ),
        );
      }
      item
        ..kind = 'error'
        ..processed = true
        ..save();
    } finally {
      _processing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeAutoProcess();
      });
    }
  }

  void _reprocess(InboxItem item) {
    item.processed = false;
    item.save();
    _maybeAutoProcess();
  }

  Future<void> _showDetails(InboxItem item) async {
    final c = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.path != null && File(item.path!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(item.path!), height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
            ],
            Text('OCR টেক্সট', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textSecondary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(14)),
              child: SingleChildScrollView(
                child: SelectableText(
                  item.ocrText ?? item.text ?? '—',
                  style: TextStyle(fontSize: 13, color: c.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    _aiRewrite(item);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: c.glow.withValues(alpha: 0.14),
                    foregroundColor: c.glow,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('✨ AI লেখা'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    _aiAnalyze(item);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary.withValues(alpha: 0.14),
                    foregroundColor: c.primary,
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('AI গাছ'),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addNote(item);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: c.secondary.withValues(alpha: 0.14),
                    foregroundColor: c.secondary,
                  ),
                  icon: const Icon(Icons.note_add_rounded, size: 18),
                  label: const Text('নোটে যোগ'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _reprocess(item);
                  },
                  icon: Icon(Icons.refresh_rounded, color: c.primary),
                  label: Text('আবার প্রসেস', style: TextStyle(color: c.primary)),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () {
                    item.delete();
                    Navigator.pop(context);
                  },
                  style: IconButton.styleFrom(backgroundColor: c.expense),
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aiRewrite(InboxItem item) async {
    final text = (item.ocrText ?? item.text ?? '').trim();
    if (text.isEmpty) {
      _toast('কোনো টেক্সট নেই — আগে আবার প্রসেস করো', isError: true);
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiRewriteSheet(item: item, text: text),
    );
    if (saved == true && mounted) {
      _toast('✅ OCR-এর জায়গায় AI লেখা সেভ হলো');
    }
  }

  Future<void> _aiAnalyze(InboxItem item) async {
    final text = (item.ocrText ?? item.text ?? '').trim();
    if (text.isEmpty) {
      _toast('কোনো টেক্সট নেই — আগে আবার প্রসেস করো', isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiTreeSheet(text: text),
    );
  }

  Future<void> _addNote(InboxItem item) async {
    final text = (item.ocrText ?? item.text ?? '').trim();
    if (text.isEmpty) {
      _toast('কোনো টেক্সট নেই — আগে আবার প্রসেস করো', isError: true);
      return;
    }
    final now = DateTime.now();
    final first = text
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'Screenshot নোট')
        .trim();
    Hive.box<Note>('notes').add(Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: first.length > 42 ? '${first.substring(0, 42)}…' : first,
      content: text,
      category: 'Screenshot',
      createdAt: now,
      updatedAt: now,
    ));
    item
      ..processed = true
      ..save();
    _toast('✅ নোটে যোগ হলো');
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.black87 : Colors.green,
        duration: const Duration(seconds: 2),
      ));
  }

  Widget _buildCard(BuildContext context, AppColors c, InboxItem item, int index) {
    final isNew = !item.processed;
    final kind = item.kind != null ? ScreenshotKind.values.byName(item.kind!) : null;
    return EntranceItem(
      order: index,
      child: GestureDetector(
        onTap: isNew ? () => _reprocess(item) : () => _showDetails(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.path != null && File(item.path!).existsSync()
                    ? Image.file(File(item.path!), width: 52, height: 52, fit: BoxFit.cover)
                    : Container(
                        width: 52, height: 52, color: c.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.notes_rounded, color: c.primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (kind != null) ...[
                          Text('${ScreenshotParser.kindEmoji(kind)} ', style: const TextStyle(fontSize: 14)),
                          Text(
                            ScreenshotParser.kindLabel(kind),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isNew ? c.mediumPriority.withValues(alpha: 0.15) : c.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isNew ? 'নতুন' : 'সংরক্ষিত',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isNew ? c.mediumPriority : c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (item.ocrText ?? item.text ?? '—').replaceAll('\n', ' '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a', 'bn').format(item.receivedAt),
                      style: TextStyle(fontSize: 10, color: c.textSecondary.withValues(alpha: 0.6)),
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
                  Text('Screenshot Inbox', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: _pickFromGallery,
                    style: IconButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, size: 18, color: c.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'যেকোনো app থেকে screenshot/টেক্সট Share → LifeOS করুন। এখানেই দেখা যাবে।',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<InboxItem>('inbox').listenable(),
                builder: (context, Box<InboxItem> box, _) {
                  final items = box.values.toList()..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search_rounded, size: 64, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 14),
                          Text('এখনো কিছু নেই', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                          const SizedBox(height: 6),
                          Text('ধরো: বিলের screenshot → খরচ, ত্রুটির screenshot → নোট', style: TextStyle(fontSize: 12, color: c.textSecondary.withValues(alpha: 0.6))),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildCard(context, c, items[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTreeSheet extends StatefulWidget {
  final String text;
  const _AiTreeSheet({required this.text});

  @override
  State<_AiTreeSheet> createState() => _AiTreeSheetState();
}

class _AiTreeSheetState extends State<_AiTreeSheet> {
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
      final r = await AiEnhancer.enhance(widget.text, allowOnline: true)
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
    final c = AppTheme.of(context);
    return Container(
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
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
              const SizedBox(width: 8),
              Text('AI গাছ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
            Icon(Icons.cloud_off_rounded, size: 34, color: c.textSecondary),
            const SizedBox(height: 10),
            Text('AI গাছ বানানো গেল না', style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.expense)),
            const SizedBox(height: 12),
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
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: BeautifiedTreeCard(
        raw: widget.text,
        blueprint: _tree!,
        aiSource: _source,
        animate: true,
      ),
    );
  }
}

/// OCR লেখাকে AI দিয়ে সুন্দরভাবে গুছিয়ে (এমোজি সহ) নতুন লেখা — SelectableText,
/// তাই লং-প্রেস → select → copy করা যায়। "সেভ" চাপলে OCR-এর জায়গায় AI লেখা সেভ হয়।
class _AiRewriteSheet extends StatefulWidget {
  final InboxItem item;
  final String text;
  const _AiRewriteSheet({required this.item, required this.text});

  @override
  State<_AiRewriteSheet> createState() => _AiRewriteSheetState();
}

class _AiRewriteSheetState extends State<_AiRewriteSheet> {
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
      final r = await AiEnhancer.enhance(widget.text, allowOnline: true)
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

  String _flatten(TreeBlueprint t) {
    final b = StringBuffer()..writeln('${t.titleEmoji} ${t.title}');
    void walk(List<TreeNode> nodes, int depth) {
      for (final n in nodes) {
        b.writeln('${'   ' * depth}${n.emoji} ${n.text}');
        if (n.children.isNotEmpty) walk(n.children, depth + 1);
      }
    }

    walk(t.nodes, 0);
    return b.toString();
  }

  void _copyText() {
    if (_tree == null) return;
    Clipboard.setData(ClipboardData(text: _flatten(_tree!)));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('কপি হয়েছে'), backgroundColor: Colors.green));
    }
  }

  void _save() {
    final t = _tree;
    if (t == null) return;
    widget.item
      ..ocrText = _flatten(t)
      ..processed = true
      ..save();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.64,
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
              Icon(Icons.edit_note_rounded, size: 18, color: c.glow),
              const SizedBox(width: 8),
              Text('✨ AI লেখা',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary)),
              const Spacer(),
              if (_tree != null)
                IconButton(
                  onPressed: _copyText,
                  tooltip: 'সব কপি',
                  icon: Icon(Icons.copy_all_rounded, color: c.glow),
                ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('লেখাটা ধরে-রেখে সিলেক্ট করে কপি করতে পারো',
              style: TextStyle(fontSize: 11, color: c.textSecondary)),
          const SizedBox(height: 8),
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
            Icon(Icons.cloud_off_rounded, size: 34, color: c.textSecondary),
            const SizedBox(height: 10),
            Text('AI লেখা বানানো গেল না',
                style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.expense)),
            const SizedBox(height: 12),
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
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.glow.withValues(alpha: 0.25)),
          ),
          child: SelectableText(
            _flatten(_tree!),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BeautifiedTreeCard(
          raw: widget.text,
          blueprint: _tree!,
          aiSource: _source,
          animate: false,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.glow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text('AI লেখা দিয়ে সেভ করুন',
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}