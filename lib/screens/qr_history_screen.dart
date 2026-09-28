import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:lifeos/services/qr_types.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/widgets/entrance_item.dart';

const Map<QrType, String> qrEmoji = {
  QrType.url: '🌐',
  QrType.wifi: '📶',
  QrType.phone: '📞',
  QrType.email: '✉️',
  QrType.location: '📍',
  QrType.event: '📅',
  QrType.contact: '👤',
  QrType.text: '📝',
};

String qrPreview(QrScan s) {
  final m = s.fields;
  if (s.type == QrType.url) return (m['Link'] ?? s.raw).replaceAll('\n', ' ');
  if (s.type == QrType.wifi) {
    return '${m['SSID'] ?? ''}${m['Password']?.isNotEmpty == true ? '  🔑 ${m['Password']}' : ''}';
  }
  if (s.type == QrType.phone) return m['Number'] ?? s.raw;
  if (s.type == QrType.email) return m['Email'] ?? s.raw;
  if (s.type == QrType.location) return '${m['Latitude'] ?? ''}, ${m['Longitude'] ?? ''}';
  if (s.type == QrType.contact) return m['Name'] ?? s.raw;
  final v = m['Text'] ?? s.raw;
  return v.replaceAll('\n', ' ');
}

Future<void> qrOpenExternal(String uri) async {
  try {
    if (uri.startsWith('https://') || uri.startsWith('http://')) {
      await AndroidIntent(action: 'android.intent.action.VIEW', data: uri).launch();
    } else if (uri.startsWith('tel:')) {
      await AndroidIntent(action: 'android.intent.action.DIAL', data: uri).launch();
    } else if (uri.startsWith('mailto:')) {
      await AndroidIntent(action: 'android.intent.action.SENDTO', data: uri).launch();
    } else if (uri.startsWith('geo:')) {
      await AndroidIntent(action: 'android.intent.action.VIEW', data: uri).launch();
    }
  } catch (_) {}
}

/// QR scan ইতিহাসের আলাদা পেজ — কী স্ক্যান হয়েছে, সময়সহ বিস্তারিত।
class QrHistoryScreen extends StatefulWidget {
  const QrHistoryScreen({super.key});

  @override
  State<QrHistoryScreen> createState() => _QrHistoryScreenState();
}

class _QrHistoryScreenState extends State<QrHistoryScreen> {
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব ইতিহাস মুছে ফেলব?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (ok == true) Hive.box('qr_history').clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: c.cardColor),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'QR ইতিহাস',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _confirmClear,
                    tooltip: 'সব মুছো',
                    icon: Icon(Icons.delete_sweep_rounded, color: c.expense),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('qr_history').listenable(),
                builder: (context, Box box, _) {
                  final history = box.values.toList().reversed.toList();
                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 64, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 14),
                          Text('কোনো স্ক্যান নেই',
                              style: TextStyle(fontSize: 15, color: c.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final e = Map<String, dynamic>.from(history[i] is Map ? history[i] : const {});
                      return EntranceItem(order: i, child: _card(c, e));
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

  Widget _card(AppColors c, Map<String, dynamic> e) {
    final text = (e['text'] as String? ?? '').trim();
    final time = DateTime.tryParse(e['time'] as String? ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    final scan = QrScan.parse(text);
    final emoji = qrEmoji[scan.type] ?? '📝';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.typeLabel,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: c.primary),
                ),
                const SizedBox(height: 3),
                Text(
                  qrPreview(scan),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  time != null
                      ? DateFormat('MMM d, h:mm a', 'bn').format(time)
                      : '',
                  style: TextStyle(
                      fontSize: 10, color: c.textSecondary.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'কপি',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              _toast('কপি হয়েছে');
            },
            icon: Icon(Icons.copy_rounded, size: 17, color: c.textSecondary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: scan.type == QrType.url ? 'খুলো' : 'আরো',
            onPressed: () {
              if (scan.type == QrType.url || scan.type == QrType.location) {
                qrOpenExternal(scan.type == QrType.url
                    ? (scan.fields['Link'] ?? text)
                    : 'geo:${scan.fields['Latitude']},${scan.fields['Longitude']}');
              } else {
                Clipboard.setData(ClipboardData(text: text));
                _toast('কপি হয়েছে');
              }
            },
            icon: Icon(
              scan.type == QrType.url
                  ? Icons.open_in_new_rounded
                  : Icons.copy_all_rounded,
              size: 17,
              color: c.primary,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'বিস্তারিত',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QrHistoryDetailScreen(text: text, scan: scan),
                ),
              );
            },
            icon: Icon(Icons.info_outline_rounded, size: 17, color: c.glow),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'মুছো',
            onPressed: () {
              final box = Hive.box('qr_history');
              final idx = box.values.toList().indexWhere((x) =>
                  (x is Map) &&
                  (x['text'] == text) &&
                  (x['time'] == e['time']));
              if (idx >= 0) box.deleteAt(idx);
            },
            icon: Icon(Icons.delete_outline, size: 17, color: c.expense),
          ),
        ],
      ),
    );
  }
}

/// ইতিহাসের একটি স্ক্যানের বিস্তারিত পেজ — AI-গাছ (এমোজি সহ) + ডেটা selectable
/// কপি-করার ব্যবস্থা।
class QrHistoryDetailScreen extends StatefulWidget {
  final String text;
  final QrScan scan;
  const QrHistoryDetailScreen({super.key, required this.text, required this.scan});

  @override
  State<QrHistoryDetailScreen> createState() => _QrHistoryDetailScreenState();
}

class _QrHistoryDetailScreenState extends State<QrHistoryDetailScreen> {
  TreeBlueprint? _tree;
  String? _error;
  String? _source;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  void _copyAll() {
    if (_tree == null) return;
    Clipboard.setData(ClipboardData(text: _flatten(_tree!)));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('কপি হয়েছে'), backgroundColor: Colors.green));
    }
  }

  void _copyRaw() {
    Clipboard.setData(ClipboardData(text: widget.text));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('র ডেটা কপি হয়েছে'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final scan = widget.scan;
    final emoji = qrEmoji[scan.type] ?? '📝';
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: c.cardColor),
                    icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QR বিস্তারিত',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary)),
                        Text(scan.typeLabel,
                            style: TextStyle(
                                fontSize: 11, color: c.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Raw কপি',
                    onPressed: _copyRaw,
                    icon: Icon(Icons.content_copy_rounded,
                        size: 19, color: c.textSecondary),
                  ),
                  IconButton(
                    tooltip: 'সব কপি',
                    onPressed: _tree == null ? null : _copyAll,
                    icon: Icon(Icons.copy_all_rounded,
                        size: 19, color: c.glow),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  QrTypeCard(
                      scan: scan,
                      showSensitive: true,
                      onOpenUrl: (u) => qrOpenExternal(u)),
                  const SizedBox(height: 10),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text('AI লোড হয়নি (নেটওয়ার্ক?): $_error',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: c.expense)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('আবার'),
                          ),
                        ],
                      ),
                    )
                  else if (_tree == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.cardColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (_tree != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.cardColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: c.glow.withValues(alpha: 0.25)),
                      ),
                      child: SelectableText(
                        _flatten(_tree!),
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}