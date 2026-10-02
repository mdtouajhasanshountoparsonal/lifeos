import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/services/deen_seed.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/count_ring.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

const _prayerNames = <String, String>{
  'fajr': 'ফজর',
  'dhuhr': 'যোহর',
  'asr': 'আসর',
  'maghrib': 'মাগরিব',
  'isha': 'ইশা',
};

/// নামাজ আদায়ের পরের ধাপে-ধাপে জিকির ফ্লো (৩৩/৩৩/৩৪ + ইস্তিগফার + আয়াতুল কুরসি)।
/// ফোকাস-based — কোনো অ্যানিমেশন নেই, প্রতি ট্যাপ haptic, mid-done resume Hive-এ।
class PostPrayerScreen extends StatefulWidget {
  final String prayer;

  const PostPrayerScreen({super.key, required this.prayer});

  @override
  State<PostPrayerScreen> createState() => _PostPrayerScreenState();
}

class _PostPrayerScreenState extends State<PostPrayerScreen> {
  List<PostPrayerStep> _steps = const [];
  late final PageController _page;
  final List<int> _counts = [];
  final Set<int> _doneSteps = {};
  int _step = 0;
  bool _loaded = false;
  bool _finished = false;

  String get _dayKey => DeenStore.dayKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final steps = await DeenSeed.postPrayer();
    final save = DeenStore.postPrayerSave(_dayKey, widget.prayer);
    final counts = List<int>.filled(steps.length, 0);
    if (save != null && !save.done) {
      for (var i = 0; i < counts.length && i < save.counts.length; i++) {
        counts[i] = save.counts[i];
      }
      _step = save.step.clamp(0, steps.length - 1);
    }
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _counts
        ..clear()
        ..addAll(counts);
      _loaded = true;
      _doneSteps.addAll([
        for (var i = 0; i < _steps.length; i++)
          if (_counts[i] >= _steps[i].repeat) i,
      ]);
    });
    _page = PageController(initialPage: _step);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _persist() {
    DeenStore.savePostPrayer(
      _dayKey,
      widget.prayer,
      step: _step,
      counts: List<int>.from(_counts),
      done: _finished,
    );
  }

  void _tapCount() {
    final s = _steps[_step];
    if (s.readOnly || _counts[_step] >= s.repeat) return;
    HapticFeedback.lightImpact();
    setState(() {
      _counts[_step]++;
      if (_counts[_step] >= s.repeat) _doneSteps.add(_step);
    });
    _persist();
  }

  void _next() {
    if (_step + 1 < _steps.length) {
      setState(() => _step++);
      _page.animateToPage(_step, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
      _persist();
    } else {
      setState(() => _finished = true);
      _persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: PopScope(
        canPop: _finished,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _persist();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const MoonBackground(),
              SafeArea(
                child: _loaded
                    ? _body(c)
                    : Center(
                        child: CircularProgressIndicator(color: c.glow, strokeWidth: 2.5),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppColors c) {
    if (_finished) return _finishedView(c);
    final s = _steps[_step];
    final _ = _doneSteps.contains(_step) || _counts[_step] >= s.repeat;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _persist();
                  Navigator.of(context).pop();
                },
                tooltip: 'বন্ধ করুন (প্রগতি সংরক্ষিত)',
                icon: Icon(Icons.close_rounded, color: c.textSecondary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'নামাজের পরের জিকির',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary),
                    ),
                    Text(
                      '${_prayerNames[widget.prayer]} · ধাপ ${_bnNum((_step + 1).toString())} / ${_bnNum(_steps.length.toString())}',
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${_bnNum(_counts.where((n) => n > 0).length.toString())} ধাপ শুরু',
                style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            onPageChanged: (i) => setState(() => _step = i),
            itemBuilder: (context, i) {
              final step = _steps[i];
              final stepDone = _counts[i] >= step.repeat;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: step.readOnly
                    ? _readStep(c, step, stepDone)
                    : _countStep(c, step, stepDone),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Counting step (3/33/33/34 ইত্যাদি) ──────────────────────────────
  Widget _countStep(AppColors c, PostPrayerStep s, bool done) {
    final count = _counts[_step];
    return Column(
      children: [
        const Spacer(flex: 2),
        Text(
          s.arabic,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: c.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(s.bangla, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textSecondary)),
        const SizedBox(height: 4),
        Text(s.meaning, style: TextStyle(fontSize: 12.5, color: c.textSecondary.withValues(alpha: 0.85))),
        const Spacer(flex: 2),
        Expanded(
          flex: 4,
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tapCount,
                child: CountRing(
                  progress: count / s.repeat,
                  color: done ? c.lowPriority : c.glow,
                  trackColor: c.cardColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _bnNum(count.toString()),
                          style: TextStyle(
                            fontSize: count >= 10 ? 46 : 56,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: done ? c.lowPriority : c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '/ ${_bnNum(s.repeat.toString())}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textSecondary),
                        ),
                        if (done) ...[
                          const SizedBox(height: 8),
                          Text('✓ সম্পন্ন', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.lowPriority)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 2),
        _sourceChip(c, s),
        const SizedBox(height: 14),
        if (done) _nextButton(c, s) else _tapHint(c),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _nextButton(AppColors c, PostPrayerStep s) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: c.glow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _next,
        icon: Icon(
          _step + 1 < _steps.length ? Icons.arrow_forward_rounded : Icons.check_rounded,
          size: 18,
        ),
        label: Text(
          _step + 1 < _steps.length ? 'পরের ধাপ' : 'সম্পন্ন হয়েছে',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _tapHint(AppColors c) => Text(
        'পুরো কলাম ট্যাপ করে গুনে যান',
        style: TextStyle(fontSize: 12, color: c.textSecondary.withValues(alpha: 0.8)),
      );

  // ─── Reading step (আয়াতুল কুরসি) ────────────────────────────────────
  Widget _readStep(AppColors c, PostPrayerStep s, bool done) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          s.arabic,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c.textPrimary, height: 1.9),
        ),
        const SizedBox(height: 14),
        if (s.transliteration.isNotEmpty) ...[
          Text(
            'উচ্চারণ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                s.transliteration,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.7, color: c.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (s.meaning.isNotEmpty) ...[
          Text(
            'অর্থ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                s.meaning,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.7, color: c.textSecondary),
              ),
            ),
          ),
        ],
        const Spacer(),
        _sourceChip(c, s),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: c.glow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              setState(() => _doneSteps.add(_step));
              _next();
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('সম্পন্ন হয়েছে', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _sourceChip(AppColors c, PostPrayerStep s) {
    return Container(
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
            s.hasSource ? s.source : 'source নেই',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: s.hasSource ? c.textSecondary : c.mediumPriority,
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishedView(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✨', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                'আলহামদুলিল্লাহ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '${_prayerNames[widget.prayer]} এর পরের জিকির সম্পন্ন — আজকের আমল নোটে যোগ হলো',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.6, color: c.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.glow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ফিরে যান', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _bnNum(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }
}