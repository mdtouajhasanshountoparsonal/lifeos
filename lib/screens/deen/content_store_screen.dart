import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/services/content_repository.dart';
import 'package:lifeos/services/arabic_seed.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

class ContentStoreScreen extends StatefulWidget {
  const ContentStoreScreen({super.key});

  @override
  State<ContentStoreScreen> createState() => _ContentStoreScreenState();
}

class _ContentStoreScreenState extends State<ContentStoreScreen> {
  List<ContentFileItem>? _files;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await ArabicSeed.manifest();
    if (!mounted) return;
    setState(() => _files = files);
  }

  Future<void> _update() async {
    final box = Hive.box('content_data');
    setState(() {
      for (final f in box.keys.toList()) {
        box.delete(f);
      }
      Hive.box('content_meta')
          .deleteAll(Hive.box('content_meta').keys.toList());
    });
    await ContentRepository.ensureReady(force: true);
    await _load();
  }

  String _cn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    final t = DateTime.parse(iso).toLocal();
    return '${_cn(t.day.toString())}/${_cn(t.month.toString())}/${_cn(t.year.toString())} ${_cn(t.hour.toString().padLeft(2, '0'))}:${_cn(t.minute.toString().padLeft(2, '0'))}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final files = _files;
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: files == null
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      Text(
                        '🗂️ কনটেন্ট-স্টোর',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'সব শিখা-সম্পদ এখন ভাসা-GitHub রিপো থেকে আসে — অ্যাপে কোনো কনটেন্ট বান্ডল নেই।',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListenableBuilder(
                        listenable: ContentRepository.state,
                        builder: (context, _) {
                          final st = ContentRepository.state.value;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.cardColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_download_rounded,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        st.ready
                                            ? 'সব নামানো হয়েছে — ${_cn(files.length.toString())}টি ফাইল'
                                            : 'রিপোথেকে নামছে… ${_cn(st.done.toString())} / ${_cn(st.total.toString())}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'আবার নামাও',
                                      onPressed: st.busy ? null : _update,
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                if (st.busy) ...[
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: st.total > 0
                                        ? st.done / st.total
                                        : null,
                                    minHeight: 5,
                                    backgroundColor: c.surfaceColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      c.glow,
                                    ),
                                  ),
                                ],
                                Text(
                                  'শেষ সিঙ্ক: ${_formatTime(Hive.box('content_meta').get('downloadedAt') as String?)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textSecondary,
                                  ),
                                ),
                                if (st.error != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    st.error!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.5,
                                      color: c.highPriority,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      for (final f in files)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.cardColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.kind,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_cn(f.count.toString())}টি • v${_cn(f.version.toString())}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      f.source,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: c.textSecondary.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 18,
                                color: c.glow,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'রিপো: ${ContentRepository.repoBase}',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            color: c.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
