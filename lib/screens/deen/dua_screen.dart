import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/dua_word_sheet.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🤲 দুআ লাইব্রেরি — curated local JSON, search (বাংলা/আরবি), bookmark।
class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  List<DuaItem> _duas = const [];
  List<String> _sections = const [];
  bool _loaded = false;
  String _query = '';
  String _section = 'সব';
  bool _onlySaved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final duas = await DeenSeed.duas();
    final sections = await DeenSeed.duaSections();
    if (!mounted) return;
    setState(() {
      _duas = duas;
      _sections = sections;
      _loaded = true;
    });
  }

  List<DuaItem> get _filtered {
    return _duas.where((d) {
      if (!d.matches(_query)) return false;
      if (_section != 'সব' && d.section != _section) return false;
      if (_onlySaved && !DeenStore.isBookmarked('dua:${d.id}')) return false;
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
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🤲 দুআ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              'সংগ্রহশালা — সোর্সসহ, AI নয়',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListenableBuilder(
                        listenable: Hive.box('deen_meta').listenable(),
                        builder: (context, _) {
                          return IconButton(
                            tooltip: 'সংরক্ষিত শুধু দেখুন',
                            onPressed: () =>
                                setState(() => _onlySaved = !_onlySaved),
                            icon: Icon(
                              _onlySaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
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
                      hintText: 'বাংলা বা আরবিতে খুঁজুন…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: c.textSecondary.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: c.textSecondary,
                      ),
                      filled: true,
                      fillColor: c.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final s in ['সব', ..._sections])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _chip(
                            c,
                            s,
                            _section == s,
                            () => setState(() => _section = s),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loaded
                      ? _list(c)
                      : Center(
                          child: CircularProgressIndicator(
                            color: c.glow,
                            strokeWidth: 2.5,
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

  Widget _list(AppColors c) {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'কিছু পাওয়া যায়নি — অন্য সেকশন বা শব্দে খুঁজুন',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final d = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _detail(context, d),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _typeBadge(c, d.type),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.bangla,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_authColor(d.authenticity) != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    d.authenticityLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _authColor(d.authenticity),
                                    ),
                                  ),
                                ),
                              if (d.count != null && d.count! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    '× ${_bn(d.count!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: c.mediumPriority,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  '${d.section} · ${d.hasSource ? d.source : 'source নেই'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: Hive.box('deen_meta').listenable(),
                      builder: (context, _) {
                        final saved = DeenStore.isBookmarked('dua:${d.id}');
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              DeenStore.toggleBookmark('dua:${d.id}'),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            size: 20,
                            color: saved
                                ? c.glow
                                : c.textSecondary.withValues(alpha: 0.6),
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

  Widget _typeBadge(AppColors c, String type) {
    final map = {
      'hadith': (Icons.forum_rounded, 'হাদিস', c.lowPriority),
      'quran': (Icons.menu_book_rounded, 'কুরআন', c.glow),
      'general': (Icons.record_voice_over_rounded, 'সাধারণ', c.mediumPriority),
    };
    final (icon, label, color) = map[type] ?? map['general']!;
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _detail(BuildContext context, DuaItem d) {
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
                      child: Text(
                        '${d.section} · ${_typeLabel(d.type)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'উচ্চারণ শুনুন',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => speakPron(d.arabic),
                      icon: Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: c.glow,
                      ),
                    ),
                    ListenableBuilder(
                      listenable: Hive.box('deen_meta').listenable(),
                      builder: (context, _) {
                        final saved = DeenStore.isBookmarked('dua:${d.id}');
                        return IconButton(
                          tooltip: saved
                              ? 'সংরক্ষণ মুছে ফেলুন'
                              : 'সংরক্ষণ করুন',
                          onPressed: () =>
                              DeenStore.toggleBookmark('dua:${d.id}'),
                          icon: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            color: saved ? c.glow : c.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (d.arabic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _tappableArabic(c, d),
                  const SizedBox(height: 6),
                  Text(
                    '👆 যেকোনো শব্দে চাপ দিন — অক্ষর-হরকত ভাঙা ও পড়ার অনুশীলন',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: c.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (d.count != null && d.count! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.glow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🔢 ${_bn(d.count!)} বার',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: c.glow,
                        ),
                      ),
                    ),
                  ),
                if (d.transliteration.isNotEmpty) ...[
                  _label(c, 'উচ্চারণ'),
                  Text(
                    d.transliteration,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _label(c, 'অর্থ'),
                Text(
                  d.bangla,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _sourceChip(c, d.source, d.hasSource, 'dua:${d.id}'),
                const SizedBox(height: 12),
                _learnedRow(c, d),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// আরবি লাইন শব্দে ভেঙে প্রতিটি শব্দ ট্যাপযোগ্য — অক্ষর-হরকত ভাঙা,
  /// পড়ার অনুশীলন ও ভাণ্ডার-অর্থ একই জায়গায়।
  Widget _tappableArabic(AppColors c, DuaItem d) =>
      DuaTappableArabic(text: d.arabic);

  Color? _authColor(String authenticity) {
    return switch (authenticity) {
      'sahih' => const Color(0xFF2E7D32),
      'hasan' => const Color(0xFFB26A00),
      'quran' => const Color(0xFF1565C0),
      _ => null,
    };
  }

  /// জীবনবৃত্তান্ত digit -> বাংলা সংখ্যা।
  static String _bn(int n) {
    const en = '0123456789';
    const bn = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map(
      (ch) => en.contains(ch) ? bn[en.indexOf(ch)] : ch,
    ).join();
  }

  Widget _learnedRow(AppColors c, DuaItem d) {
    return ListenableBuilder(
      listenable: Hive.box('deen_meta').listenable(),
      builder: (context, _) {
        final learned = DeenStore.isArabicKnown('dua-learn:${d.id}');
        return Material(
          color: learned ? c.glow.withValues(alpha: 0.16) : c.cardColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => learned
                ? DeenStore.arabicUnmark('dua-learn:${d.id}')
                : DeenStore.arabicMark('dua-learn:${d.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    learned
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: learned ? c.glow : c.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      learned
                          ? 'মুখস্থ করার চেষ্টা হচ্ছে… ট্যাপ করলে বাদ যাবে'
                          : 'আমি মুখস্থ করেছি ✓',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: learned ? Colors.black : c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(AppColors c, String s) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      s,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: c.textSecondary,
      ),
    ),
  );

  Widget _sourceChip(AppColors c, String source, bool hasSource, String key) {
    final saved = DeenStore.isBookmarked(key);
    return Row(
      children: [
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
                hasSource ? source : 'source নেই',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: hasSource ? c.textSecondary : c.mediumPriority,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (saved)
          Text(
            '🔖 সংরক্ষিত',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.glow,
            ),
          ),
      ],
    );
  }

  static String _typeLabel(String type) => switch (type) {
    'hadith' => 'হাদিস থেকে',
    'quran' => 'কুরআন থেকে',
    'general' => 'সাধারণ দোয়া (হাদিস নয়)',
    _ => 'সাধারণ',
  };
}
