import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';
import 'package:lifeos/widgets/glass_card.dart';

class TreeBranch extends StatelessWidget {
  final Color dotColor;
  final Color? lineColor;
  final Widget child;

  const TreeBranch({super.key, required this.dotColor, this.lineColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final lc = lineColor ?? c.textSecondary.withValues(alpha: 0.25);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: lc,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 17),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                          boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 6)],
                        ),
                      ),
                      Container(
                        width: 17,
                        height: 3,
                        decoration: BoxDecoration(
                          color: dotColor.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class HubEntryData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
  final String badge;

  const HubEntryData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.builder,
    this.badge = '',
  });
}

class HubScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<HubEntryData> entries;

  const HubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, c),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _rootDrop(c),
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) _gutter(c),
                    _branch(context, c, entries[i], isLast: i == entries.length - 1),
                  ],
                  _treeTip(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rootDrop(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(left: 21, top: 6, bottom: 2),
      child: Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.7), c.textSecondary.withValues(alpha: 0.25)],
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _gutter(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: Container(
        width: 3,
        height: 10,
        decoration: BoxDecoration(
          color: c.textSecondary.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _treeTip(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 8),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${entries.length}টি সংযোগ',
            style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _branch(BuildContext context, AppColors c, HubEntryData entry, {
    required bool isLast,
  }) {
    return EntranceItem(
      order: 0,
      child: TreeBranch(
        dotColor: entry.color,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _leafCard(context, c, entry),
        ),
      ),
    );
  }

  Widget _leafCard(BuildContext context, AppColors c, HubEntryData entry) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: entry.builder),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, color: entry.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                        ),
                      ),
                      if (entry.badge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: entry.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(entry.badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: entry.color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
}