import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/habit.dart';
import 'package:lifeos/models/inbox_item.dart';
import 'package:lifeos/services/money_intel.dart';
import 'package:lifeos/services/text_normalizer.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/screens/screenshot_inbox_screen.dart';
import 'package:lifeos/screens/clipboard_inbox_screen.dart';
import 'package:lifeos/screens/qr_scanner_screen.dart';
import 'package:lifeos/screens/habits_screen.dart';
import 'package:lifeos/screens/debts_screen.dart';
import 'package:lifeos/nova/nova_screen.dart';

/// 🌊 Fluid Home — module "বাবল" ধীরে ভাসে; tap → pulse + যাবে জায়গায়।
/// একটাই AnimationController + Transform → ৬০fps-এ সস্তা। Layoutে setState নেই।
class FluidHome extends StatefulWidget {
  final ValueChanged<int> onOpenTab;

  const FluidHome({super.key, required this.onOpenTab});

  @override
  State<FluidHome> createState() => _FluidHomeState();
}

class _FluidHomeState extends State<FluidHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 46),
  )..repeat();

  int? _pulse;
  bool _showWsBubble = true;

  Future<void> _bang(int id, VoidCallback open) async {
    if (mounted) setState(() => _pulse = id);
    await Future.delayed(const Duration(milliseconds: 205));
    if (!mounted) return;
    setState(() => _pulse = null);
    open();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 6, 2),
          child: Row(
            children: [
              Icon(Icons.waves_rounded, size: 15, color: c.glow),
              const SizedBox(width: 6),
              Text(
                'FLUID HOME — সব এক দৃষ্টিতে',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: c.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showWsBubble = !_showWsBubble),
                visualDensity: VisualDensity.compact,
                tooltip: 'Workspace বুদবুদ',
                icon: Icon(
                  _showWsBubble
                      ? Icons.account_tree_rounded
                      : Icons.account_tree_outlined,
                  size: 16,
                  color: c.glow.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBoard(c)),
        _staticWaves(c),
      ],
    );
  }

  Widget _buildBoard(AppColors c) {
    final notes = Hive.box<Note>('notes').length;
    final pending =
        Hive.box<Task>('tasks').values.where((t) => !t.isCompleted).length;
    final todaySpend =
        MoneyIntel.daySpend(Hive.box<Expense>('expenses'), DateTime.now());
    final inbox = Hive.box<InboxItem>('inbox').length;
    final clip = Hive.box('clipboard').length;
    final qr = Hive.box('qr_history').length;
    final habits = Hive.box<Habit>('habits').length;
    final debts = Hive.box('debts').length;

    final entries = <_FB>[
      _FB(Icons.sticky_note_2_rounded, c.primary, 'নোট', notes.toString(),
          () => widget.onOpenTab(2)),
      _FB(Icons.balance_rounded, c.income, 'দেনা-পাওনা', debts.toString(),
          () => _open(const DebtsScreen())),
      _FB(Icons.fact_check_rounded, c.glow, 'কাজ', pending.toString(),
          () => widget.onOpenTab(1)),
      _FB(Icons.account_balance_wallet_rounded, c.income, 'অর্থ',
          _shortMoney(todaySpend), () => widget.onOpenTab(3)),
      _FB(Icons.image_search_rounded, c.mediumPriority, 'স্ক্রিনশট',
          inbox.toString(), () => _open(const ScreenshotInboxScreen())),
      _FB(Icons.content_paste_rounded, c.secondary, 'ক্লিপবোর্ড',
          clip.toString(), () => _open(const ClipboardInboxScreen())),
      _FB(Icons.qr_code_2_rounded, c.glow, 'QR', qr.toString(),
          () => _open(const QrScannerScreen())),
      _FB(Icons.loop_rounded, c.lowPriority, 'অভ্যাস', habits.toString(),
          () => _open(const HabitsScreen())),
      _FB(Icons.calculate_rounded, c.primary, 'NOVA', '🧮',
          () => _open(const NovaScreen())),
    ];
    if (_showWsBubble) {
      entries.insert(
        0,
        _FB(Icons.settings_rounded, c.mediumPriority, 'আরও', '⚙',
            () => widget.onOpenTab(4)),
      );
    }

    return LayoutBuilder(
      builder: (context, cons) {
        const cols = 3.0;
        const pad = 8.0;
        final cell = (cons.maxWidth - pad * 2) / cols;
        final s = cell * 0.7;
        final rows = (entries.length / cols).ceil();
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: cons.maxWidth,
            height: rows * cell,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) {
                    final t = _drift.value;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          SizedBox(
                            width: cell,
                            height: cell,
                            child: Center(
                              child: Transform.translate(
                                offset: _float(cell, i, t),
                                child: AnimatedScale(
                                  scale: _pulse == i ? 1.22 : 1,
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutBack,
                                  child: _bubble(
                                      c, s, () => _bang(i, entries[i].onTap), entries[i]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _float(double cell, int i, double t) {
    final ph = (i % 5) / 5.0 * 6.28318530718;
    final amp = cell * 0.035;
    return Offset(
      amp * math.sin(2 * math.pi * t + ph),
      amp * math.cos(2 * math.pi * (t * 0.8) + ph * 1.3),
    );
  }

  Widget _bubble(AppColors c, double s, VoidCallback onTap, _FB e) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              e.color.withValues(alpha: 0.32),
              e.color.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: e.color.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: e.color.withValues(alpha: 0.28),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(s * 0.06),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.icon, size: s * 0.34, color: e.color),
                const SizedBox(height: 3),
                Text(
                  e.count,
                  style: TextStyle(
                    fontSize: s * 0.26,
                    fontWeight: FontWeight.w900,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  e.label,
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: s * 0.19,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _shortMoney(double v) {
    if (v <= 0) return '৳0';
    if (v >= 100000) return '৳${TextNormalizer.banglaDigits((v / 100000).round().toString())}L';
    if (v >= 1000) return '৳${TextNormalizer.banglaDigits((v / 1000).round().toString())}k';
    return MoneyIntel.fmt(v);
  }

  Widget _staticWaves(AppColors c) {
    return SizedBox(
      height: 26,
      child: CustomPaint(
        size: Size(double.infinity, 26),
        painter: _WavePainter(color: c.glow, secondary: c.primary),
      ),
    );
  }
}

class _FB {
  final IconData icon;
  final Color color;
  final String label;
  final String count;
  final VoidCallback onTap;
  const _FB(this.icon, this.color, this.label, this.count, this.onTap);
}

class _WavePainter extends CustomPainter {
  final Color color;
  final Color secondary;
  _WavePainter({required this.color, required this.secondary});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.10);
    final path1 = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      path1.lineTo(
          x, size.height * 0.55 + 6 * math.sin(x / size.width * 4 * 3.14159265));
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, p1);

    final p2 = Paint()
      ..style = PaintingStyle.fill
      ..color = secondary.withValues(alpha: 0.06);
    final path2 = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      path2.lineTo(x,
          size.height * 0.72 + 4 * math.cos(x / size.width * 6 * 3.14159265));
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => false;
}