import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/animated_counter.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/command_sheet.dart';
import 'package:lifeos/widgets/hub_screen.dart';
import 'package:lifeos/widgets/theme_engine_screen.dart';
import 'package:lifeos/widgets/fluid_home.dart';
import 'package:lifeos/widgets/morning_snapshot.dart';
import 'package:lifeos/screens/clipboard_inbox_screen.dart';
import 'package:lifeos/screens/habits_screen.dart';
import 'package:lifeos/screens/qr_scanner_screen.dart';
import 'package:lifeos/screens/screenshot_inbox_screen.dart';
import 'package:lifeos/nova/nova_screen.dart';
import 'package:lifeos/services/ai_tree_store.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/phonex/device_api.dart';
import 'package:lifeos/phonex/phonex_screen.dart';
import 'package:lifeos/phonex/app_lock_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int> themeIndex;
  final ValueChanged<int> onOpenTab;

  const DashboardScreen({super.key, required this.themeIndex, required this.onOpenTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late bool _fluidMode;

  @override
  void initState() {
    super.initState();
    _fluidMode = Hive.box('settings').get('home_mode', defaultValue: true) as bool;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openCommandCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommandSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              _buildHeader(c),
              const SizedBox(height: 14),
              MorningSnapshot(onCapture: _openCommandCenter),
              if (_fluidMode) ...[
                const SizedBox(height: 14),
                Expanded(
                  child: FluidHome(onOpenTab: widget.onOpenTab),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DailyProgress(card: c),
                        const SizedBox(height: 10),
                        _buildStatsRow(c),
                        const SizedBox(height: 10),
                        _DeviceLiveCard(c: c),
                        const SizedBox(height: 16),
                        _buildToolsSection(context, c),
                        const SizedBox(height: 16),
                        _buildSectionTitle(c, 'TODAY\'S FOCUS'),
                        const SizedBox(height: 10),
                        _buildFocusList(c),
                        const SizedBox(height: 14),
                        _buildCommandHint(c),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(AppColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: 1.4,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [c.primary, c.secondary],
                ).createShader(bounds),
                child: Text(
                  'SHOUNTO',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _Clock(),
            ],
          ),
        ),
        Row(
          children: [
            _modeToggle(c),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openCommandCenter,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.glow.withValues(alpha: 0.4)),
                ),
                child: Icon(Icons.bolt_rounded, color: c.glow),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeToggle(AppColors c) {
    return GestureDetector(
      onTap: () {
        setState(() => _fluidMode = !_fluidMode);
        Hive.box('settings').put('home_mode', _fluidMode);
      },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.primary.withValues(alpha: 0.4)),
        ),
        child: Icon(
          _fluidMode ? Icons.waves_rounded : Icons.grid_view_rounded,
          color: c.primary,
        ),
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(AppColors c) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList();
        final total = tasks.length;
        final done = tasks.where((t) => t.isCompleted).length;
        final focusMin =
            tasks.where((t) => !t.isCompleted).fold<int>(0, (s, t) => s + t.estimatedMinutes);

        return Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.task_alt_rounded,
              value: '$done/$total',
              label: 'Tasks',
              color: c.primary,
              right: c,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              icon: Icons.timer_rounded,
              value: _fmtDuration(focusMin),
              label: 'Focus',
              color: c.secondary,
              right: c,
            )),
          ],
        );
      },
    );
  }

  String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static TreeBlueprint? _focusTree(Task t) {
    final s = AiTreeStore.get(t.id, task: true);
    if (s == null || !s.blueprint.hasNodes) return null;
    return s.blueprint;
  }

  String _focusTitle(Task t) {
    final b = _focusTree(t);
    if (b != null) return '${b.titleEmoji} ${b.title}';
    return t.title;
  }

  String _focusSubLabel(Task t) {
    final b = _focusTree(t);
    final dur = t.estimatedMinutes > 0 ? _fmtDuration(t.estimatedMinutes) : null;
    if (b != null) {
      final treeMeta = '🌳 ${b.nodes.length} ধাপ';
      if (dur == null) return treeMeta;
      return '$treeMeta • ⏱️ $dur';
    }
    return dur ?? '';
  }

  // ─── TOOLS hub ────────────────────────────────────────────────────────────
  Widget _buildToolsSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(c, 'TOOLS MY WORKSPACE'),
        const SizedBox(height: 10),
        _ToolsCard(c: c, themeIndex: widget.themeIndex),
      ],
    );
  }

  // ─── Sections ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(AppColors c, String title) {
    return Row(
      children: [
        Container(width: 20, height: 3, decoration: BoxDecoration(
          color: c.glow,
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusList(AppColors c) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values
            .where((t) => !t.isCompleted)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
        final list = tasks.take(5).toList();

        if (list.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.celebration_rounded, size: 34, color: c.glow),
                const SizedBox(height: 10),
                Text(
                  'সব কাজ সম্পন্ন! 🎉',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: list.asMap().entries.map((e) {
            final task = e.value;
            final colors = [
              c.lowPriority,
              c.mediumPriority,
              c.highPriority,
            ];
            final color = colors[task.priority];
            return EntranceItem(
              order: e.key,
              child: GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                accent: color,
                onTap: () {
                  task.isCompleted = true;
                  task.save();
                },
                child: Row(
                  children: [
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 8,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _focusTitle(task),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          Text(
                            _focusSubLabel(task),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_outline_rounded, size: 20, color: c.textSecondary.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommandHint(AppColors c) {
    return GestureDetector(
      onTap: _openCommandCenter,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        accent: c.glow,
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '+ আগামীকাল ৬টায় গিট যোগ করো — অ্যাপ নিজেই বুঝবে',
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.trending_flat_rounded, size: 18, color: c.glow),
          ],
        ),
      ),
    );
  }
}

// ─── Daily progress ring card ───────────────────────────────────────────────
class _DailyProgress extends StatelessWidget {
  final AppColors card;
  const _DailyProgress({required this.card});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList();
        final total = tasks.length;
        final done = tasks.where((t) => t.isCompleted).length;
        final progress = total == 0 ? 0.0 : done / total;
        final percent = (progress * 100).round();

        return GlassCard(
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CustomPaint(
                    painter: _RingPainter(progress: v, color: card.primary, track: card.textSecondary.withValues(alpha: 0.12)),
                    child: Center(
                      child: AnimatedCounter(
                        value: percent,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: card.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DAILY PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: card.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total == 0 ? 'আজ শুরু করো 🚀' : '$done/$total সম্পন্ন',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: card.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color, color.withValues(alpha: 0.4)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Animated live clock ────────────────────────────────────────────────────
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final hh = DateFormat('hh').format(_now);
    final mm = DateFormat('mm').format(_now);
    final ss = DateFormat('ss').format(_now);
    final ampm = DateFormat('a').format(_now);
    final date = DateFormat('EEEE • MMMM d', 'bn').format(_now);
    final colonOn = _now.second.isEven;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              hh,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: c.textPrimary,
              ),
            ),
            AnimatedOpacity(
              opacity: colonOn ? 1 : 0.25,
              duration: const Duration(milliseconds: 500),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: c.textPrimary,
                ),
              ),
            ),
            Text(
              mm,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 520),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -0.6), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                ss,
                key: ValueKey(ss),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.glow,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ampm,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

// ─── Stat card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final AppColors right;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      accent: color,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: right.textPrimary),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: right.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceLiveCard extends StatefulWidget {
  final AppColors c;
  const _DeviceLiveCard({required this.c});

  @override
  State<_DeviceLiveCard> createState() => _DeviceLiveCardState();
}

class _DeviceLiveCardState extends State<_DeviceLiveCard> {
  int? _pct;
  bool? _charging;
  double? _temp;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await DeviceApi.batteryNow();
      if (!mounted) return;
      setState(() {
        _pct = b['percent'] as int?;
        _charging = b['charging'] == true;
        _temp = (b['tempC'] as num?)?.toDouble();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final pct = _pct ?? -1;
    final charging = _charging ?? false;
    final temp = _temp ?? 0;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      borderRadius: BorderRadius.circular(16),
      accent: c.glow,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PhonexScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.glow.withValues(alpha: 0.3), c.glow.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(charging ? Icons.bolt_rounded : Icons.battery_charging_full_rounded,
                size: 19, color: charging ? c.secondary : c.glow),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _pct == null ? 'PHONEX — Device Intelligence' : '$pct%  ·  ${temp.toStringAsFixed(0)}°C  ·  টাইমলাইন/অ্যাপ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textSecondary),
        ],
      ),
    );
  }
}

// ─── Tools tree card (Home-এর 'TOOLS' ঘর) ─────────────────────────────────
class _ToolsCard extends StatefulWidget {
  final AppColors c;
  final ValueNotifier<int> themeIndex;

  const _ToolsCard({required this.c, required this.themeIndex});

  @override
  State<_ToolsCard> createState() => _ToolsCardState();
}

class _ToolsCardState extends State<_ToolsCard> {
  bool _open = false;

  List<HubEntryData> _entries() {
    final c = widget.c;
    return [
      HubEntryData(
        icon: Icons.calculate_rounded,
        color: c.primary,
        title: '🧮 NOVA Calculator',
        subtitle: 'ক্যালকুলেটর, গ্রাফ, ক্যালকুলাস, ম্যাট্রিক্স, ফিজিক্স...',
        badge: '1',
        builder: (_) => const NovaScreen(),
      ),
      HubEntryData(
        icon: Icons.functions_rounded,
        color: c.glow,
        title: '📈 Scientific Workspace',
        subtitle: 'রসায়ন, ইউনিট, পরিসংখ্যান, সিমুলেশন, ধ্রুবক',
        badge: '2',
        builder: (_) => const NovaScreen(),
      ),
      HubEntryData(
        icon: Icons.qr_code_2_rounded,
        color: c.glow,
        title: '📷 QR স্ক্যানার',
        subtitle: 'স্ক্যান, গ্যালারি, ইতিহাস, করণীয় খোলো',
        badge: '3',
        builder: (_) => const QrScannerScreen(),
      ),
      HubEntryData(
        icon: Icons.image_search_rounded,
        color: c.primary,
        title: '📸 Screenshot Inbox',
        subtitle: 'বিল/ত্রুটি/বার্তা → খরচ, নোট, রিমাইন্ডার',
        badge: '4',
        builder: (_) => const ScreenshotInboxScreen(),
      ),
      HubEntryData(
        icon: Icons.content_paste_rounded,
        color: c.mediumPriority,
        title: '📋 Smart Clipboard',
        subtitle: 'কপি/Share → ধরন সনাক্ত, গোপন লুকানো, নোটে যোগ',
        badge: '5',
        builder: (_) => const ClipboardInboxScreen(),
      ),
      HubEntryData(
        icon: Icons.loop_rounded,
        color: c.secondary,
        title: '🔁 অভ্যাস',
        subtitle: 'ধারাবাহিকতা (streak) ট্র্যাক ও যোগ',
        badge: '7',
        builder: (_) => const HabitsScreen(),
      ),
      HubEntryData(
        icon: Icons.monitor_heart_rounded,
        color: c.glow,
        title: '📱 Device Intelligence',
        subtitle: 'টাইমলাইন, ব্যাটারি, নোটিফিকেশন, অ্যাপ বিশ্লেষণ',
        badge: '8',
        builder: (_) => const PhonexScreen(),
      ),
      HubEntryData(
        icon: Icons.security_rounded,
        color: c.primary,
        title: '🔐 App Lock + Privacy',
        subtitle: 'প্রতি অ্যাপ আলাদা PIN, intruder সতর্কতা',
        badge: '9',
        builder: (_) => const AppLockScreen(),
      ),
      HubEntryData(
        icon: Icons.palette_outlined,
        color: c.mediumPriority,
        title: '🎨 Theme Engine',
        subtitle: 'থিম বদলাও — আগের সব ঠিক থাকবে',
        badge: '10',
        builder: (_) => ThemeEngineScreen(themeIndex: widget.themeIndex),
      ),
    ];
  }

  Widget _tile(AppColors c, HubEntryData e) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 6, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 2,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [e.color.withValues(alpha: 0.7), c.surfaceColor],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: e.builder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(e.icon, color: e.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final entries = _entries();
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      accent: c.mediumPriority,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HubScreen(
                        title: 'TOOLS',
                        subtitle: 'My Workspace — সব টুল এক গাছে',
                        icon: Icons.widgets_rounded,
                        color: c.mediumPriority,
                        entries: entries,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [c.mediumPriority.withValues(alpha: 0.9), c.mediumPriority.withValues(alpha: 0.4)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: c.mediumPriority.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'TOOLS',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.mediumPriority.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${entries.length}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.mediumPriority),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Calculator • QR • Screenshot • Clipboard • থিম',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _open = !_open),
                tooltip: _open ? 'গোটাও' : 'খোলো',
                icon: AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Icon(Icons.arrow_drop_down_rounded, color: c.mediumPriority, size: 28),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _open
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final e in entries) _tile(c, e)])
                : const SizedBox.shrink(),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 10),
              child: Row(
                children: [
                  Text('▼ গোপন', style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.6))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}