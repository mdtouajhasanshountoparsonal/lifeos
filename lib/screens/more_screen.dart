import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/habit.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/ai_fix_store.dart';
import 'package:lifeos/services/ai_settings.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/screens/habits_screen.dart';
import 'package:lifeos/screens/qr_scanner_screen.dart';
import 'package:lifeos/screens/screenshot_inbox_screen.dart';
import 'package:lifeos/screens/clipboard_inbox_screen.dart';
import 'package:lifeos/screens/timeline_screen.dart';
import 'package:lifeos/screens/inventory_screen.dart';
import 'package:lifeos/screens/price_history_screen.dart';
import 'package:lifeos/screens/deen/deen_home_screen.dart';
import 'package:lifeos/phonex/app_lock_screen.dart';
import 'package:lifeos/phonex/phonex_screen.dart';
import 'package:lifeos/nova/nova_screen.dart';
import 'package:lifeos/widgets/hub_screen.dart';

class MoreScreen extends StatelessWidget {
  final ValueNotifier<int> themeIndex;

  const MoreScreen({super.key, required this.themeIndex});

  void _pickTheme(BuildContext context, int index) {
    themeIndex.value = index;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Theme → ${AppColors.themeNames[index]}',
        textAlign: TextAlign.center,
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.of(context).surfaceColor,
      duration: const Duration(milliseconds: 800),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            Text(
              'MORE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeSection(context, c),
            const SizedBox(height: 22),
            _buildPhonexSection(context, c),
            const SizedBox(height: 22),
            _buildNovaSection(context, c),
            const SizedBox(height: 22),
            _buildDeenSection(context, c),
            const SizedBox(height: 22),
            _buildToolsSection(context, c),
            const SizedBox(height: 22),
            _buildIntelligenceSection(context, c),
            const SizedBox(height: 22),
            _buildHabitsSection(context, c),
            const SizedBox(height: 22),
            _buildAiSection(context, c),
            const SizedBox(height: 22),
            _buildAbout(c),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'THEME ENGINE'),
        const SizedBox(height: 12),
        ValueListenableBuilder<int>(
          valueListenable: themeIndex,
          builder: (context, current, _) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(AppColors.themes.length, (i) {
              final t = AppColors.themes[i];
              final selected = i == current;
              return GestureDetector(
                onTap: () => _pickTheme(context, i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? t.glow : c.textSecondary.withValues(alpha: 0.15),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [t.primary, t.secondary],
                          ),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: t.glow.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppColors.themeNames[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: t.textPrimary,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_rounded, size: 14, color: t.glow),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPhonexSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'PHONEX'),
        const SizedBox(height: 12),
        _TreeCard(
          c: c,
          icon: Icons.monitor_heart_rounded,
          color: c.glow,
          title: 'ডিভাইস ইন্টেলিজেন্স',
          subtitle: 'টাইমলাইন, ব্যাটারি, অ্যাপ বিশ্লেষণ',
          count: 2,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HubScreen(
                title: 'PHONEX',
                subtitle: 'ডিভাইস ইন্টেলিজেন্স ও প্রাইভেসি',
                icon: Icons.monitor_heart_rounded,
                color: c.glow,
                entries: [
                  HubEntryData(
                    icon: Icons.monitor_heart_rounded,
                    color: c.glow,
                    title: 'Device Intelligence',
                    subtitle: 'টাইমলাইন, ব্যাটারি, নোটিফিকেশন, অ্যাপ বিশ্লেষণ',
                    badge: '2',
                    builder: (_) => const PhonexScreen(),
                  ),
                  HubEntryData(
                    icon: Icons.security_rounded,
                    color: c.primary,
                    title: 'App Lock + Privacy',
                    subtitle: 'প্রতি অ্যাপ আলাদা PIN, intruder সতর্কতা',
                    badge: '1',
                    builder: (_) => const AppLockScreen(),
                  ),
                ],
              ),
            ),
          ),
          children: [
            _treeLeaf(
              c,
              icon: Icons.monitor_heart_rounded,
              color: c.glow,
              title: 'Device Intelligence',
              subtitle: 'টাইমলাইন, ব্যাটারি, নোটিফিকেশন, অ্যাপ বিশ্লেষণ',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhonexScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.security_rounded,
              color: c.primary,
              title: 'App Lock + Privacy',
              subtitle: 'প্রতি অ্যাপ আলাদা PIN, intruder সতর্কতা',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppLockScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNovaSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'NOVA'),
        const SizedBox(height: 12),
        _TreeCard(
          c: c,
          icon: Icons.calculate_outlined,
          color: c.primary,
          title: 'বিজ্ঞান ও গণিত',
          subtitle: 'ক্যালকুলেটর, গ্রাফ, ক্যালকুলাস, ফিজিক্স, রসায়ন...',
          count: 2,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HubScreen(
                title: 'NOVA',
                subtitle: 'বিজ্ঞান ও গণিত',
                icon: Icons.calculate_outlined,
                color: c.primary,
                entries: [
                  HubEntryData(
                    icon: Icons.calculate_outlined,
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
                ],
              ),
            ),
          ),
          children: [
            _treeLeaf(
              c,
              icon: Icons.calculate_outlined,
              color: c.primary,
              title: '🧮 NOVA Calculator',
              subtitle: 'ক্যালকুলেটর, গ্রাফ, ক্যালকুলাস, ম্যাট্রিক্স, ফিজিক্স...',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NovaScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.functions_rounded,
              color: c.glow,
              title: '📈 Scientific Workspace',
              subtitle: 'রসায়ন, ইউনিট, পরিসংখ্যান, সিমুলেশন, ধ্রুবক',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NovaScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeenSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'DEEN'),
        const SizedBox(height: 12),
        _TreeCard(
          c: c,
          icon: Icons.nights_stay_rounded,
          color: c.secondary,
          title: 'ইবাদাত ও দুআ',
          subtitle: 'নামাজ ট্র্যাকার, সময়, ইতিহাস',
          count: 1,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeenHomeScreen()),
          ),
          children: [
            _treeLeaf(
              c,
              icon: Icons.nights_stay_rounded,
              color: c.secondary,
              title: '🕌 নামাজ ট্র্যাকার',
              subtitle: 'আজকের ৫ ওয়াক্ত, ইতিহাস, সেটিংস',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeenHomeScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'TOOLS'),
        const SizedBox(height: 12),
        _TreeCard(
          c: c,
          icon: Icons.widgets_rounded,
          color: c.mediumPriority,
          title: 'ক্যাপচার ও সংযোগ',
          subtitle: 'Screenshot, QR, Clipboard',
          count: 3,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HubScreen(
                title: 'TOOLS',
                subtitle: 'ক্যাপচার ও সংযোগ',
                icon: Icons.widgets_rounded,
                color: c.mediumPriority,
                entries: [
                  HubEntryData(
                    icon: Icons.image_search_rounded,
                    color: c.primary,
                    title: 'Screenshot Inbox',
                    subtitle: 'বিল/ত্রুটি/বার্তা → খরচ, নোট, রিমাইন্ডার',
                    badge: '1',
                    builder: (_) => const ScreenshotInboxScreen(),
                  ),
                  HubEntryData(
                    icon: Icons.qr_code_2_rounded,
                    color: c.glow,
                    title: 'QR স্ক্যানার',
                    subtitle: 'স্ক্যান, গ্যালারি, ইতিহাস, করণীয় খোলো',
                    badge: '2',
                    builder: (_) => const QrScannerScreen(),
                  ),
                  HubEntryData(
                    icon: Icons.content_paste_rounded,
                    color: c.mediumPriority,
                    title: 'Smart Clipboard',
                    subtitle: 'কপি/Share → ধরন সনাক্ত, গোপন লুকানো, নোটে যোগ',
                    badge: '3',
                    builder: (_) => const ClipboardInboxScreen(),
                  ),
                ],
              ),
            ),
          ),
          children: [
            _treeLeaf(
              c,
              icon: Icons.image_search_rounded,
              color: c.primary,
              title: 'Screenshot Inbox',
              subtitle: 'বিল/ত্রুটি/বার্তা → খরচ, নোট, রিমাইন্ডার',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScreenshotInboxScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.qr_code_2_rounded,
              color: c.glow,
              title: 'QR স্ক্যানার',
              subtitle: 'স্ক্যান, গ্যালারি, ইতিহাস, করণীয় খোলো',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.content_paste_rounded,
              color: c.mediumPriority,
              title: 'Smart Clipboard',
              subtitle: 'কপি/Share → ধরন সনাক্ত, গোপন লুকানো, নোটে যোগ',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ClipboardInboxScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _treeLeaf(
    AppColors c, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
                colors: [color.withValues(alpha: 0.7), c.surfaceColor],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Expanded(
            child: _toolTile(c,
                icon: icon, color: color, title: title, subtitle: subtitle, onTap: onTap),
          ),
        ],
      ),
    );
  }

  Widget _toolTile(
    AppColors c, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'AI ENGINE'),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: Hive.box('settings').listenable(),
          builder: (context, box, _) {
            final online = AiSettings.onlineEnabled;
            final prov = AiSettings.provider;
            return GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.glow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: c.glow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Online AI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              online
                                  ? '${prov == AiSettings.openai ? '🤖 GPT' : '🌐 Gemini'} চেষ্টা — না পারলে offline'
                                  : 'offline বট সদা চালু (ইন্টারনেট লাগে না)',
                              style:
                                  TextStyle(fontSize: 12, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: online,
                        activeColor: c.glow,
                        onChanged: (v) => AiSettings.setOnlineEnabled(v),
                      ),
                    ],
                  ),
                  if (online) ...[
                    const SizedBox(height: 14),
                    Text(
                      'PROVIDER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: AiSettings.gemini,
                          icon: Icon(Icons.auto_awesome_rounded, size: 15),
                          label: Text('Gemini'),
                        ),
                        ButtonSegment(
                          value: AiSettings.openai,
                          icon: Icon(Icons.memory_rounded, size: 15),
                          label: Text('GPT'),
                        ),
                      ],
                      selected: {prov},
                      onSelectionChanged: (s) => AiSettings.setProvider(s.first),
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle:
                            WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Key: --dart-define=LIFEOS_GEMINI_KEY / LIFEOS_OPENAI_KEY',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: c.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const Divider(height: 22),
                  ValueListenableBuilder(
                    valueListenable: Hive.box('learned_fixes').listenable(),
                    builder: (context, lb, _) => Row(
                      children: [
                        Icon(Icons.school_rounded,
                            size: 18, color: c.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${AiFixStore.learnedWords.length} শব্দ + ${AiFixStore.learnedEmoji.length} এমোজি শিখেছি',
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await AiFixStore.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('🧹 শেখা মুছে ফেলা হলো')),
                              );
                            }
                          },
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Text('শেখা মুছুন',
                              style: TextStyle(fontSize: 12, color: c.expense)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () async {
                      final r = await AiEnhancer.enhance(
                        'kal bajar theke mac 2kg ar dim 1 dozen kinbo, tarpor gym a jabo',
                        allowOnline: true,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            r.usedOnline
                                ? '🌐 ${r.source} দিয়ে কাজ করছে ✓'
                                : '🤖 offline বট কাজ করছে ✓',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: r.usedOnline ? c.secondary : c.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.flash_on_rounded, size: 15),
                    label: const Text('AI পরীক্ষা',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIntelligenceSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'LIFE INTELLIGENCE'),
        const SizedBox(height: 12),
        _TreeCard(
          c: c,
          icon: Icons.auto_awesome_rounded,
          color: c.glow,
          title: 'জীবন-ইন্টেলিজেন্স',
          subtitle: 'টাইমলাইন, স্টক, দর-ইতিহাস',
          count: 3,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HubScreen(
                title: 'LIFE INTELLIGENCE',
                subtitle: 'জীবন-ইন্টেলিজেন্স',
                icon: Icons.auto_awesome_rounded,
                color: c.glow,
                entries: [
                  HubEntryData(
                    icon: Icons.timeline_rounded,
                    color: c.primary,
                    title: '🕰️ Life Timeline',
                    subtitle: 'নোট, কাজ, খরচ, দর — সব এক চেইনে',
                    badge: '1',
                    builder: (_) => const TimelineScreen(),
                  ),
                  HubEntryData(
                    icon: Icons.inventory_2_rounded,
                    color: c.mediumPriority,
                    title: '📦 স্টক-ইনভেন্টরি',
                    subtitle: '+/− স্টক, কম-সতর্কতা, খালি হলে তালিকায়',
                    badge: '2',
                    builder: (_) => const InventoryScreen(),
                  ),
                  HubEntryData(
                    icon: Icons.history_rounded,
                    color: c.secondary,
                    title: '🕘 বাজার-দর ইতিহাস',
                    subtitle: 'প্রতি আইটেমের সব দাম, তুলনাসহ',
                    badge: '3',
                    builder: (_) => const PriceHistoryScreen(),
                  ),
                ],
              ),
            ),
          ),
          children: [
            _treeLeaf(
              c,
              icon: Icons.timeline_rounded,
              color: c.primary,
              title: '🕰️ Life Timeline',
              subtitle: 'নোট, কাজ, খরচ, দর — সব এক চেইনে',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimelineScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.inventory_2_rounded,
              color: c.mediumPriority,
              title: '📦 স্টক-ইনভেন্টরি',
              subtitle: '+/− স্টক, কম-সতর্কতা, খালি হলে তালিকায়',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),
            _treeLeaf(
              c,
              icon: Icons.history_rounded,
              color: c.secondary,
              title: '🕘 বাজার-দর ইতিহাস',
              subtitle: 'প্রতি আইটেমের সব দাম, তুলনাসহ',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PriceHistoryScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitsSection(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'HABITS'),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: Hive.box<Habit>('habits').listenable(),
          builder: (context, Box<Habit> box, _) {
            final habits = box.values.take(3).toList();
            return GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (habits.isEmpty)
                    Text(
                      'এখনো কোনো অভ্যাস নেই — নিচের বাটনে যোগ করো',
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    )
                  else
                    ...habits.map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text(h.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  h.name,
                                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                                ),
                              ),
                              Text(
                                '🔥 ${h.streak}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: c.mediumPriority,
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HabitsScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: c.primary.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.loop_rounded, size: 18, color: c.primary),
                      label: Text(
                        'অভ্যাস খুলো / যোগ করো',
                        style: TextStyle(fontWeight: FontWeight.w600, color: c.primary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAbout(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, 'ABOUT'),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_rounded, color: c.glow, size: 30),
              const SizedBox(height: 8),
              Text(
                'LIFeOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personal Life Operating System',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0',
                style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(AppColors c, String title) {
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
}

class _TreeCard extends StatefulWidget {
  final AppColors c;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int count;
  final List<Widget> children;
  final VoidCallback onOpen;

  const _TreeCard({
    required this.c,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.children,
    required this.onOpen,
  });

  @override
  State<_TreeCard> createState() => _TreeCardState();
}

class _TreeCardState extends State<_TreeCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: widget.onOpen,
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
                              colors: [widget.color.withValues(alpha: 0.9), widget.color.withValues(alpha: 0.4)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Icon(widget.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(widget.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.color.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('${widget.count}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: widget.color)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(widget.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textSecondary)),
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
                  child: Icon(Icons.arrow_drop_down_rounded, color: widget.color, size: 28),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  )
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