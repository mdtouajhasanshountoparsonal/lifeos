import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/screens/dashboard_screen.dart';
import 'package:lifeos/screens/tasks_screen.dart';
import 'package:lifeos/screens/notes_screen.dart';
import 'package:lifeos/screens/money_screen.dart';
import 'package:lifeos/screens/more_screen.dart';
import 'package:lifeos/screens/clipboard_inbox_screen.dart';
import 'package:lifeos/screens/screenshot_inbox_screen.dart';
import 'package:lifeos/screens/qr_scanner_screen.dart';
import 'package:lifeos/nova/nova_screen.dart';
import 'package:lifeos/screens/habits_screen.dart';
import 'package:lifeos/screens/debts_screen.dart';
import 'package:lifeos/screens/shopping_list_screen.dart';
import 'package:lifeos/screens/timeline_screen.dart';
import 'package:lifeos/screens/inventory_screen.dart';
import 'package:lifeos/screens/price_history_screen.dart';
import 'package:lifeos/widgets/command_sheet.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<int> themeIndex;

  const MainScreen({super.key, required this.themeIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        themeIndex: widget.themeIndex,
        onOpenTab: (i) {
          if (i == _currentIndex) return;
          setState(() => _currentIndex = i);
        },
      ),
      const TasksScreen(),
      const NotesScreen(),
      const MoneyScreen(),
      MoreScreen(themeIndex: widget.themeIndex),
    ];
  }

  void _openCommandCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CommandSheet(),
    );
  }

  void _openWorkspace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _workspaceSheet(context),
    );
  }

  void _goTab(int index) {
    Navigator.of(context).pop();
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _pushScreen(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _workspaceSheet(BuildContext context) {
    final c = AppTheme.of(context);
    final tabEntries = <_WsEntry>[
      _WsEntry(Icons.home_rounded, c.primary, 'Home', 'আজকের ড্যাশবোর্ড', onTap: () => _goTab(0)),
      _WsEntry(Icons.fact_check_rounded, c.glow, 'কাজ', 'টাস্ক, ডেডলাইন, রুটিন', onTap: () => _goTab(1)),
      _WsEntry(Icons.sticky_note_2_rounded, c.secondary, 'নোট', 'লেখা, বাজার, AI গাছ', onTap: () => _goTab(2)),
      _WsEntry(Icons.account_balance_wallet_rounded, c.income, 'অর্থ', 'খরচ, হিসাব, গ্রাফ', onTap: () => _goTab(3)),
    ];
    final toolEntries = <_WsEntry>[
      _WsEntry(Icons.content_paste_rounded, c.mediumPriority, 'Smart Clipboard', 'কপি → ধরন সনাক্ত, নোটে যোগ',
          onTap: () => _pushScreen(const ClipboardInboxScreen())),
      _WsEntry(Icons.image_search_rounded, c.primary, 'Screenshot Inbox', 'বিল/ত্রুটি → খরচ, নোট, AI গাছ',
          onTap: () => _pushScreen(const ScreenshotInboxScreen())),
      _WsEntry(Icons.qr_code_2_rounded, c.glow, 'QR স্ক্যানার', 'স্ক্যান, গ্যালারি, ইতিহাস',
          onTap: () => _pushScreen(const QrScannerScreen())),
      _WsEntry(Icons.calculate_rounded, c.secondary, 'NOVA Calculator', 'ক্যালকুলেটর, গ্রাফ, ম্যাট্রিক্স',
          onTap: () => _pushScreen(const NovaScreen())),
      _WsEntry(Icons.loop_rounded, c.secondary, 'অভ্যাস', 'ধারাবাহিকতা (streak) ট্র্যাক',
          onTap: () => _pushScreen(const HabitsScreen())),
      _WsEntry(Icons.balance_rounded, c.income, 'দেনা-পাওনা', 'কে নিবে, কত দেবে — AI পরামর্শসহ',
          onTap: () => _pushScreen(const DebtsScreen())),
      _WsEntry(Icons.shopping_cart_rounded, c.glow, 'Shopping List', 'কেনাকাটার তালিকা — সঞ্চিত দর থেকে আনুমানিক মোট',
          onTap: () => _pushScreen(const ShoppingListScreen())),
      _WsEntry(Icons.timeline_rounded, c.primary, 'Life Timeline', 'নোট, কাজ, খরচ, দর — সব এক চেইনে',
          onTap: () => _pushScreen(const TimelineScreen())),
      _WsEntry(Icons.inventory_2_rounded, c.mediumPriority, 'স্টক-ইনভেন্টরি', 'স্টক, কম-সতর্কতা, খালি হলে তালিকায়',
          onTap: () => _pushScreen(const InventoryScreen())),
      _WsEntry(Icons.history_rounded, c.secondary, 'দর-ইতিহাস', 'প্রতি আইটেমের সব দাম — Time Machine',
          onTap: () => _pushScreen(const PriceHistoryScreen())),
      _WsEntry(Icons.settings_rounded, c.mediumPriority, 'Settings ও আরও', 'থিম, PhoneX, AI, সম্পূর্ণ More',
          onTap: () => _pushScreen(Scaffold(
                backgroundColor: Colors.transparent,
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: c.textPrimary),
                ),
                body: MoreScreen(themeIndex: widget.themeIndex),
              ))),
    ];

    return Container(
      height: math.min(MediaQuery.of(context).size.height * 0.78, 620),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
            child: Row(
              children: [
                Icon(Icons.account_tree_rounded, color: c.glow, size: 22),
                const SizedBox(width: 10),
                Text(
                  '🌳 WORKSPACE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'পুরো LifeOS এক ঝলকে',
            style: TextStyle(fontSize: 11.5, color: c.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _wsBranch(c, 'ট্যাব', tabEntries),
                  _wsBranch(c, 'টুল ও সেটিংস', toolEntries),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wsBranch(AppColors c, String title, List<_WsEntry> entries) {
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final isLast = i == entries.length - 1;
      rows.add(Entrance(c: c, item: e, isLast: isLast));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: c.textSecondary,
            ),
          ),
        ),
        ...rows,
        if (entries.isNotEmpty) const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      floatingActionButton: _CommandCore(onTap: _openCommandCenter, color: c),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildNavBar(c),
    );
  }

  Widget _buildNavBar(AppColors c) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.surfaceColor.withValues(alpha: c.isLight ? 0.98 : 0.97),
                  c.cardColor.withValues(alpha: c.isLight ? 0.99 : 0.96),
                ],
              ),
            ),
            child: LayoutBuilder(
                builder: (context, cons) {
                  final slot = cons.maxWidth / 5;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                c.glow.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedPositioned(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutBack,
                          left: _currentIndex * slot + 7,
                          width: slot - 14,
                          top: 9,
                          bottom: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [c.primary, c.secondary],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.glow.withValues(alpha: 0.55),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(_entries.length, (i) {
                          return Expanded(
                            child: _DockItem(
                              icon: _entries[i].icon,
                              label: _entries[i].label,
                              selected: _currentIndex == i,
                              isWorkspace: _entries[i].isWorkspace,
                              color: c,
                              onTap: () => _entries[i].isWorkspace
                                  ? _openWorkspace()
                                  : setState(() => _currentIndex = i),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
            ),
          ),
        ),
      ),
    );
  }

  static const _entries = <_Entry>[
    _Entry(Icons.home_rounded, 'Home', false),
    _Entry(Icons.fact_check_rounded, 'কাজ', false),
    _Entry(Icons.sticky_note_2_rounded, 'নোট', false),
    _Entry(Icons.account_balance_wallet_rounded, 'অর্থ', false),
    _Entry(Icons.account_tree_rounded, 'Workspace', true),
  ];
}

class _Entry {
  final IconData icon;
  final String label;
  final bool isWorkspace;
  const _Entry(this.icon, this.label, this.isWorkspace);
}

class _WsEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _WsEntry(this.icon, this.color, this.title, this.subtitle, {required this.onTap});
}

class Entrance extends StatelessWidget {
  final _WsEntry item;
  final bool isLast;
  final AppColors c;
  const Entrance({super.key, required this.item, required this.isLast, required this.c});

  @override
  Widget build(BuildContext context) {
    final e = item;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 6, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 2,
            height: isLast ? 0 : 18,
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: e.onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(e.icon, size: 18, color: e.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary)),
                            Text(e.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w400,
                                    color: c.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isWorkspace;
  final AppColors color;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isWorkspace,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, selected ? -3 : 0, 0),
            child: Icon(
              icon,
              size: 20,
              color: isWorkspace
                  ? color.glow
                  : selected
                      ? Colors.white
                      : color.textSecondary.withValues(alpha: 0.72),
              shadows: selected && !isWorkspace
                  ? [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 1)),
                    ]
                  : const [],
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: selected ? 20 : 0,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.primary, color.glow, color.secondary],
              ),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(color: color.glow.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : isWorkspace
                      ? color.glow.withValues(alpha: 0.85)
                      : color.textSecondary.withValues(alpha: 0.7),
              shadows: selected
                  ? [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 1)),
                    ]
                  : const [],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandCore extends StatefulWidget {
  final VoidCallback onTap;
  final AppColors color;

  const _CommandCore({required this.onTap, required this.color});

  @override
  State<_CommandCore> createState() => _CommandCoreState();
}

class _CommandCoreState extends State<_CommandCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 54,
        height: 54,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            final rig = math.sin(_ctrl.value * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50 + 10 * t,
                  height: 50 + 10 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.glow.withValues(alpha: (0.10 + 0.16 * t)),
                    boxShadow: [
                      BoxShadow(
                        color: c.glow.withValues(alpha: 0.30 * rig + 0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.primary, c.secondary],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: 1 + 0.03 * rig,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}