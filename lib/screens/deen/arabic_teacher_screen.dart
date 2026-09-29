import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/screens/deen/weakness_challenge_screen.dart';
import 'package:lifeos/services/arabic_teacher.dart';
import 'package:lifeos/services/deen_progress.dart';
import 'package:lifeos/services/deen_store.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/moon_background.dart';

class _Msg {
  final String text;
  final bool fromUser;
  final TeacherReply? reply;
  _Msg.user(this.text) : fromUser = true, reply = null;
  _Msg.bot(this.reply) : text = '', fromUser = false;
}

class ArabicTeacherScreen extends StatefulWidget {
  const ArabicTeacherScreen({super.key});

  @override
  State<ArabicTeacherScreen> createState() => _ArabicTeacherScreenState();
}

class _ArabicTeacherScreenState extends State<ArabicTeacherScreen> {
  final _controller = TextEditingController();
  final _messages = <_Msg>[
    _Msg.bot(
      const TeacherReply(
        title: 'আসসালামু আলাইকুম 👋',
        body: 'তুমি প্রশ্ন করো, আমি অফলাইনে নিজের বাক্স থেকে উত্তর দিই; ইন্টারনেট + Gemini চালু থাকলে আরও বিস্তারিত।\nউদাহরণ: "rhahman মানে কী?", "كِتَاب কী?", "কীভাবে শুরু করব?", "আমার প্রগ্রেস কী?"',
      ),
    ),
  ];
  bool _busy = false;
  DeenProgressSummary? _summary;
  int _hardCount = 0;
  StreamSubscription<dynamic>? _boxSub;

  final _chips = const [
    'কীভাবে শুরু করব?',
    'رَحْمَة মানে?',
    'فَتْحَة কী?',
    'صبْر মানে?',
    'سورَۃ الفاتحة বলো',
    'ব্যাকরণ কী?',
    '📈 আমার প্রগ্রেস',
  ];

  @override
  void initState() {
    super.initState();
    _refreshProgress();
    try {
      _boxSub = Hive.box('deen_arabic')
          .watch()
          .listen((_) => _refreshProgress());
    } catch (_) {}
  }

  Future<void> _refreshProgress() async {
    try {
      final s = await DeenProgress.summary();
      var h = 0;
      try {
        h = DeenStore.arabicHard().length;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _summary = s;
          _hardCount = h;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _boxSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_Msg.user(text));
      _busy = true;
    });
    final reply = await ArabicTeacher.ask(text);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg.bot(reply));
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: Stack(
          children: [
            const MoonBackground(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '🧑‍🏫 আরবি শিক্ষক',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (_summary != null) _progressStrip(c),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _chips.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return ActionChip(
                            avatar: Icon(
                              Icons.bolt_rounded,
                              size: 15,
                              color: c.highPriority,
                            ),
                            label: Text(
                              _hardCount > 0
                                  ? '🎯 অনুশীলন — দুর্বলতা $_hardCount'
                                  : '🎯 অনুশীলন — দুর্বলতা',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: c.highPriority,
                              ),
                            ),
                            side: BorderSide(
                              color: c.highPriority.withValues(alpha: 0.5),
                            ),
                            backgroundColor: c.highPriority.withValues(
                              alpha: 0.1,
                            ),
                            onPressed: () => Navigator.of(
                              context,
                            ).push(FadeRoute(const WeaknessChallengeScreen())),
                          );
                        }
                        return ActionChip(
                          label: Text(
                            _chips[i - 1],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.glow,
                            ),
                          ),
                          side: BorderSide(
                            color: c.glow.withValues(alpha: 0.4),
                          ),
                          backgroundColor: c.glow.withValues(alpha: 0.08),
                          onPressed: () => _send(_chips[i - 1]),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) =>
                          _messageBubble(c, _messages[i]),
                    ),
                  ),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ভাবছি…',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.cardColor,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: c.textPrimary,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: 'বাংলায় প্রশ্ন লিখুন…',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : _send,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          color: c.glow,
                        ),
                      ],
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

  Widget _progressStrip(AppColors c) {
    final s = _summary!;
    final parts = <String>[
      for (final m in s.modules)
        m.countOnly
            ? '${m.name} ${_bn(m.known)}'
            : '${m.name} ${_bn(m.known)}/${_bn(m.total)}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '📈 আমার রেকর্ড · ${parts.join(' · ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.5, color: c.lowPriority),
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text(
              'বিস্তারিত',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
            side: BorderSide(color: c.lowPriority.withValues(alpha: 0.5)),
            backgroundColor: c.lowPriority.withValues(alpha: 0.1),
            visualDensity: VisualDensity.compact,
            onPressed: () => _send('📈 আমার প্রগ্রেস'),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(AppColors c, _Msg m) {
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.secondary.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(
            m.text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    final r = m.reply!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🧑‍🏫 ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    r.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (r.fromGemini)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.glow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '🌐 Gemini',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: c.glow,
                      ),
                    ),
                  ),
              ],
            ),
            if (r.arabic != null) ...[
              const SizedBox(height: 8),
              Text(
                r.arabic!,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              r.body,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _bn(int n) {
    const digits = '০১২৩৪৫৬৭৮৯';
    return n.toString().split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? digits[i - 0x30] : ch;
    }).join();
  }
}
