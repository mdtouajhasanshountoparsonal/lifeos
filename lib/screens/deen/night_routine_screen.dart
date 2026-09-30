import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/dua_word_sheet.dart';
import 'package:lifeos/services/arabic_tts.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/services/night_routine.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/moon_background.dart';

/// 🌙 ঘুম ও সকাল রুটিন — আয়াতুল কুরসি, ৩ কুল ও ঘুমের দোয়া ধাপে ধাপে।
class NightRoutineScreen extends StatefulWidget {
  const NightRoutineScreen({super.key});

  @override
  State<NightRoutineScreen> createState() => _NightRoutineScreenState();
}

class _NightRoutineScreenState extends State<NightRoutineScreen> {
  List<NightRoutineStep> _steps = const [];
  int _i = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final steps = NightRoutine.available(await NightRoutine.build());
    if (!mounted) return;
    setState(() {
      _steps = steps;
      _loaded = true;
    });
    _jumpToFirstPending();
  }

  /// প্রথম অসমাপ্ত ধাপে নামে — ফিরে এলে যেখানে ছিলেন সেখান থেকেই শুরু।
  void _jumpToFirstPending() {
    final idx = _steps.indexWhere((s) => !DeenStore.isNightStepDone(s.duaId));
    if (idx >= 0 && idx != _i) setState(() => _i = idx);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: Stack(
        children: [
          const MoonBackground(),
          SafeArea(
            child: ListenableBuilder(
              listenable: Hive.box('amal_log').listenable(),
              builder: (context, _) {
                final done = _steps.where((s) => DeenStore.isNightStepDone(s.duaId)).length;
                final allDone = _steps.isNotEmpty && done == _steps.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(c, done),
                    if (_loaded && _steps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: done / _steps.length,
                            minHeight: 5,
                            backgroundColor: c.textSecondary.withValues(alpha: 0.12),
                            color: c.glow,
                          ),
                        ),
                      ),
                    Expanded(
                      child: !_loaded
                          ? Center(
                              child: CircularProgressIndicator(
                                color: c.glow,
                                strokeWidth: 2.5,
                              ),
                            )
                          : _steps.isEmpty
                          ? _empty(c)
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              children: [
                                _stepCard(c, allDone),
                                const SizedBox(height: 14),
                                _nav(c),
                                const SizedBox(height: 18),
                                _stepList(c),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppColors c, int done) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
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
                  '🌙 ঘুম ও সকাল রুটিন',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  _steps.isEmpty
                      ? 'ধাপে ধাপে, ধীরে ও স্মরণে'
                      : 'আজ ${_bn(done.toString())}/${_bn(_steps.length.toString())} ধাপ শেষ',
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors c) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'রুটিনের দোয়াগুলো এখনো লোড হয়নি। "আবার নামাও" চেপে ডেটা আপডেট করে নিন।',
      style: TextStyle(fontSize: 12.5, height: 1.5, color: c.textSecondary),
    ),
  );

  Widget _stepCard(AppColors c, bool allDone) {
    final s = _steps[_i.clamp(0, _steps.length - 1)];
    final d = s.dua;
    if (d == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ধাপ ${_bn((_i + 1).toString())} / ${_bn(_steps.length.toString())}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: c.glow,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.when,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
            ),
            if (s.count > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.glow.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_bn(s.count.toString())} বার',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: c.glow,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (allDone)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.lowPriority.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '🌙 আজকের রুটিনের সব ধাপ শেষ হয়েছে। অনুশীলন সম্পন্ন — বাকি আখিরাতের উপর ভরসা।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              DuaTappableArabic(text: d.arabic, fontSize: 25),
              const SizedBox(height: 8),
              Text(
                d.transliteration,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                d.bangla,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Material(
                    color: c.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => speakPron(d.arabic),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              size: 17,
                              color: c.glow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'শুনুন',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: c.glow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '📚 ${s.source}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (s.authenticity.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'সূত্রের ধরন: ${s.authenticity}',
                    style: TextStyle(fontSize: 10.5, color: c.mediumPriority),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nav(AppColors c) {
    final s = _steps[_i.clamp(0, _steps.length - 1)];
    final isDone = DeenStore.isNightStepDone(s.duaId);
    final last = _i == _steps.length - 1;
    return Row(
      children: [
        IconButton(
          tooltip: 'আগের ধাপ',
          onPressed: _i == 0
              ? null
              : () => setState(() => _i = (_i - 1).clamp(0, _steps.length - 1)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Material(
            color: isDone ? c.lowPriority : c.glow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                DeenStore.toggleNightStep(s.duaId);
                if (!isDone && !last) {
                  setState(() => _i = (_i + 1).clamp(0, _steps.length - 1));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(
                  isDone
                      ? (last ? '✓ আজকের রুটিন শেষ' : '✓ হয়েছে — ফিরে যান')
                      : (last ? '✓ শেষ ধাপ পড়েছি' : '✓ পড়েছি — পরের ধাপ'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDone ? Colors.black : c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'পরের ধাপ',
          onPressed: last
              ? null
              : () => setState(() => _i = (_i + 1).clamp(0, _steps.length - 1)),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ],
    );
  }

  Widget _stepList(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'সব ধাপ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (var k = 0; k < _steps.length; k++) ...[
          _stepRow(c, _steps[k], k),
          if (k != _steps.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 10),
        Text(
          'সূত্র ও অনুশীলন-নির্দেশনা যাচাইকৃত দোয়া-ডেটা থেকে — কোনো লেখা বানানো হয়নি।',
          style: TextStyle(
            fontSize: 10.5,
            height: 1.4,
            color: c.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _stepRow(AppColors c, NightRoutineStep s, int idx) {
    final isDone = DeenStore.isNightStepDone(s.duaId);
    final active = idx == _i;
    return Material(
      color: active
          ? c.glow.withValues(alpha: 0.12)
          : isDone
          ? c.lowPriority.withValues(alpha: 0.08)
          : c.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _i = idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 18,
                color: isDone ? c.lowPriority : c.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.when,
                      style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                _bn((idx + 1).toString()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? c.glow : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _bn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }
}
