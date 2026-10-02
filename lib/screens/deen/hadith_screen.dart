import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 📜 হাদিস লাইব্রেরি — topic/grade filter + search + bookmark।
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  List<HadithItem> _hadiths = const [];
  List<String> _topics = const [];
  bool _loaded = false;
  String _query = '';
  String _topic = 'সব';
  String _grade = 'সব';
  bool _onlySaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hadiths = await DeenSeed.hadiths();
    if (!mounted) return;
    setState(() {
      _hadiths = hadiths;
      _topics = hadiths.map((h) => h.topic).toSet().toList();
      _loaded = true;
    });
  }

  List<HadithItem> get _filtered {
    return _hadiths.where((h) {
      if (!h.matches(_query)) return false;
      if (_topic != 'সব' && h.topic != _topic) return false;
      if (_grade != 'সব' && h.grade != _grade) return false;
      if (_onlySaved && !DeenStore.isBookmarked('hadith:${h.id}')) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📜 হাদিস',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary),
                            ),
                            Text(
                              'কিতাব-নম্বরসহ — অজানা কোনোটি Sahih নয়',
                              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: Hive.box('deen_meta').listenable(),
                        builder: (context, _) {
                          return IconButton(
                            tooltip: 'সংরক্ষিত শুধু দেখুন',
                            onPressed: () => setState(() => _onlySaved = !_onlySaved),
                            icon: Icon(
                              _onlySaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: _onlySaved ? c.glow : c.textSecondary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(fontSize: 14, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'বাংলা/আরবি/কিতাব খুঁজুন…',
                      hintStyle: TextStyle(fontSize: 13, color: c.textSecondary.withValues(alpha: 0.7)),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: c.textSecondary),
                      filled: true,
                      fillColor: c.cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final g in ['সব', 'সহিহ', 'হাসান'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _chip(c, g, _grade == g, () => setState(() => _grade = g)),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      for (final t in ['সব', ..._topics])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: c.cardColor,
                            borderRadius: BorderRadius.circular(11),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(11),
                              onTap: () => setState(() => _topic = t),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _topic == t ? c.glow : c.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loaded
                      ? _list(c)
                      : Center(child: CircularProgressIndicator(color: c.glow, strokeWidth: 2.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(AppColors c, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? c.glow : c.cardColor,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Color _gradeColor(AppColors c, String grade) => switch (grade) {
        'সহিহ' => c.lowPriority,
        'হাসান' => c.mediumPriority,
        _ => c.textSecondary.withValues(alpha: 0.8),
      };

  Widget _list(AppColors c) {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text('কিছু পাওয়া যায়নি — অন্য ফিল্টার বা শব্দে খুঁজুন', style: TextStyle(fontSize: 13, color: c.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final h = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _detail(context, h),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _gradeColor(c, h.grade).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        h.grade.isEmpty ? '—' : h.grade,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _gradeColor(c, h.grade)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.bangla,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, height: 1.5, color: c.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${h.topic} · ${h.sourceLabel}',
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: Hive.box('deen_meta').listenable(),
                      builder: (context, _) {
                        final saved = DeenStore.isBookmarked('hadith:${h.id}');
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => DeenStore.toggleBookmark('hadith:${h.id}'),
                          icon: Icon(
                            saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                            size: 20,
                            color: saved ? c.glow : c.textSecondary.withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _detail(BuildContext context, HadithItem h) {
    final c = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.topic, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.textSecondary)),
                          const SizedBox(height: 3),
                          Text(
                            h.grade.isEmpty ? 'শ্রেণি অজানা' : h.grade,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _gradeColor(c, h.grade)),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: Hive.box('deen_meta').listenable(),
                      builder: (context, _) {
                        final saved = DeenStore.isBookmarked('hadith:${h.id}');
                        return IconButton(
                          tooltip: saved ? 'সংরক্ষণ মুছে ফেলুন' : 'সংরক্ষণ করুন',
                          onPressed: () => DeenStore.toggleBookmark('hadith:${h.id}'),
                          icon: Icon(
                            saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                            color: saved ? c.glow : c.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (h.arabic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    h.arabic,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.9),
                  ),
                  const SizedBox(height: 12),
                ],
                _label(c, 'অর্থ (সারমর্ম)'),
                Text(h.bangla, style: TextStyle(fontSize: 14.5, height: 1.7, color: c.textPrimary)),
                if (h.rules.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _label(c, 'নিয়ম'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in h.rules)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(height: 1.6)),
                              Expanded(
                                child: Text(r, style: TextStyle(fontSize: 13.5, height: 1.6, color: c.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (h.conditions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _label(c, 'শর্ত'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final cnd in h.conditions)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(height: 1.6)),
                              Expanded(
                                child: Text(cnd, style: TextStyle(fontSize: 13.5, height: 1.6, color: c.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.textSecondary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📚 ', style: TextStyle(fontSize: 13)),
                      Text(
                        h.sourceLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: h.hasSource ? c.textSecondary : c.mediumPriority,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(AppColors c, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.textSecondary)),
      );
}