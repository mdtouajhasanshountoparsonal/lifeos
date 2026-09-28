import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/command_parser.dart';
import 'package:lifeos/services/money_intel.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/money_tree.dart';
import 'package:lifeos/screens/debts_screen.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  static final DateFormat _txTime = DateFormat('MMM d • hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');
  static final DateFormat _dayMonth = DateFormat('d MMMM');
  static final DateFormat _dM = DateFormat('d MMM');
  static final DateFormat _dMy = DateFormat('d MMM yyyy');

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _filterCat;
  bool _treeMode = false;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text('অর্থ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _month.month == 1 ? null : () => setState(() => _month = MoneyIntel.addMonth(_month, -1)),
                    icon: Icon(Icons.chevron_left_rounded, color: c.textSecondary),
                  ),
                  Flexible(
                    child: Text(
                      MoneyIntel.bnMonthYear(_month),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: MoneyIntel.sameMonth(_month, DateTime.now())
                        ? null
                        : () => setState(() => _month = MoneyIntel.addMonth(_month, 1)),
                    icon: Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebtsScreen()),
                    ),
                    tooltip: 'দেনা-পাওনা',
                    icon: Icon(
                      Icons.balance_rounded,
                      color: c.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _treeMode = !_treeMode),
                    tooltip: 'Money Tree',
                    icon: Icon(
                      _treeMode ? Icons.account_tree_rounded : Icons.account_tree_outlined,
                      color: _treeMode ? c.glow : c.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openExpenseSheet(context, c),
                    style: IconButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Expense>('expenses').listenable(),
                builder: (context, Box<Expense> box, _) {
                  return _buildBody(context, c, box);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppColors c, Box<Expense> box) {
    final now = DateTime.now();
    final isCur = MoneyIntel.sameMonth(_month, now);
    final monthExps = MoneyIntel.inMonth(box, _month);
    final spend = MoneyIntel.spendOf(monthExps);
    final income = MoneyIntel.incomeOf(monthExps);
    final prev = MoneyIntel.inMonth(box, MoneyIntel.addMonth(_month, -1));
    final delta = MoneyIntel.monthDelta(spend, MoneyIntel.spendOf(prev));
    final anomalies = MoneyIntel.anomalyToday(box);

    if (_treeMode) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          MoneyTreeView(box: box, month: _month, c: c),
        ],
      );
    }

    final sections = <Widget>[
      RepaintBoundary(child: _summaryCard(c, box, isCur, income, spend, delta)),
      const SizedBox(height: 12),
      RepaintBoundary(child: _quickStats(c, box, now)),
      if (anomalies.unusual) ...[
        const SizedBox(height: 12),
        RepaintBoundary(child: _anomalyCard(c, box, anomalies)),
      ],
      const SizedBox(height: 12),
      RepaintBoundary(child: _barCard(c, box)),
      const SizedBox(height: 12),
      RepaintBoundary(child: _calendarCard(c, box)),
      const SizedBox(height: 12),
      RepaintBoundary(child: _categoryCard(c, box, monthExps, now)),
      const SizedBox(height: 12),
      RepaintBoundary(child: _budgetCard(c, box)),
      if (MoneyIntel.recurring(box).isNotEmpty) ...[
        const SizedBox(height: 12),
        RepaintBoundary(child: _recurringCard(c, box)),
      ],
      const SizedBox(height: 20),
      _transactionsHeader(c, box, monthExps),
      const SizedBox(height: 8),
    ];

    if (monthExps.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [...sections, _emptyMonth(c)],
      );
    }

    final filtered = (_filterCat == null ? monthExps : monthExps.where((e) => e.category == _filterCat)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          ...sections,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('এই ক্যাটাগরিতে কিছু নেই')),
          ),
        ],
      );
    }

    final byDay = <DateTime, List<Expense>>{};
    for (final e in filtered) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      (byDay[day] ??= []).add(e);
    }
    final flat = <Object>[];
    for (final day in byDay.keys) {
      flat.add(day);
      flat.addAll(byDay[day]!);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length + flat.length,
      itemBuilder: (context, i) {
        if (i < sections.length) return sections[i];
        final obj = flat[i - sections.length];
        if (obj is DateTime) return RepaintBoundary(child: _dayNode(c, obj, byDay[obj]!));
        return RepaintBoundary(child: _buildExpenseCard(c, obj as Expense));
      },
    );
  }

  Widget _summaryCard(AppColors c, Box<Expense> box, bool isCur, double income, double spend, double? delta) {
    final settings = Hive.box('money_settings');
    final budgetTotal = MoneyIntel.budgets(settings).values.fold<double>(0, (a, b) => a + b);
    final remaining = income - spend;
    final percent = income > 0 ? (remaining / income * 100).clamp(0, 100) : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      accent: c.glow,
      child: Column(
        children: [
          Row(
            children: [
              Text(isCur ? 'এই মাস' : 'বছরের হিসাব', style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const Spacer(),
              if (delta != null && income > 0)
                Row(
                  children: [
                    Icon(delta >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, size: 20, color: delta >= 0 ? c.expense : c.income),
                    Text(
                      '${delta.abs().round()}% ${delta >= 0 ? 'বেশি' : 'কম'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: delta >= 0 ? c.expense : c.income),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCur ? MoneyIntel.fmt(remaining.clamp(0, double.infinity)) : MoneyIntel.fmt(remaining < 0 ? 0 : remaining),
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: remaining >= 0 ? c.income : c.expense),
          ),
          const SizedBox(height: 4),
          Text(remaining >= 0 ? 'বাকি আছে' : 'খরচ বেশি হয়েছে', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(c, 'আয়', MoneyIntel.fmt(income), c.income),
              _item(c, 'খরচ', MoneyIntel.fmt(spend), c.expense),
              if (budgetTotal > 0) _item(c, 'বাজেট', MoneyIntel.fmt(budgetTotal), c.secondary),
            ],
          ),
          if (income > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                color: percent > 50 ? c.income : c.expense,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text('${percent.round()}% বাকি', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _quickStats(AppColors c, Box<Expense> box, DateTime now) {
    final today = MoneyIntel.daySpend(box, now);
    final week = MoneyIntel.weekSpend(box, now);
    final monthSpend = MoneyIntel.spendOf(MoneyIntel.inMonth(box, now));
    final day = now.day;
    final avg = monthSpend / (day > 0 ? day : 1);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          _stat(c, 'আজ', today),
          _stat(c, 'এই সপ্তাহ', week),
          _stat(c, 'এই মাস', monthSpend),
          _stat(c, 'গড়/দিন', avg),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String label, double v) {
    return Expanded(
      child: Column(
        children: [
          Text(MoneyIntel.fmt(v), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _anomalyCard(AppColors c, Box<Expense> box, ({double today, double avg, bool unusual, double high}) a) {
    final settings = Hive.box('money_settings');
    final note = settings.get('anomaly_note') as String? ?? '';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      accent: c.expense,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.expense.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded, color: c.expense),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('অস্বাভাবিক খরচ ⚠️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.expense)),
                const SizedBox(height: 2),
                Text(
                  'আজ ${MoneyIntel.fmt(a.today)} — গড়ে ${MoneyIntel.fmt(a.avg)}\n(+${MoneyIntel.fmt(a.today - a.avg)})',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('📝 $note', style: TextStyle(fontSize: 12, color: c.textPrimary)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => _editAnomalyNote(c, note),
            child: const Text('কারণ...'),
          ),
        ],
      ),
    );
  }

  void _editAnomalyNote(AppColors c, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: Text('কেন বেশি খরচ?', style: TextStyle(fontSize: 16, color: c.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(hintText: 'যেমন: নতুন হেডফোন', hintStyle: TextStyle(color: c.textSecondary)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          FilledButton(
            onPressed: () {
              Hive.box('money_settings').put('anomaly_note', ctrl.text.trim());
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  Widget _barCard(AppColors c, Box<Expense> box) {
    final series = MoneyIntel.lastNDays(box, 30);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📈 গত ৩০ দিন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              Text('মোট ${MoneyIntel.fmt(series.fold(0.0, (s, e) => s + e.total))}', style: TextStyle(fontSize: 11, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: Size(double.infinity, 90),
              painter: _BarChartPainter(
                values: [for (final e in series) e.total],
                bar: c.primary,
                empty: c.textSecondary.withValues(alpha: 0.18),
                todayIndex: series.length - 1,
                todayColor: c.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard(AppColors c, Box<Expense> box) {
    final now = DateTime.now();
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final spends = MoneyIntel.monthDaySpends(box, _month);
    double maxSpend = 1;
    for (final s in spends) {
      if (s > maxSpend) maxSpend = s;
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📅 মাসের মানচিত্র', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              Text('কম → বেশি', style: TextStyle(fontSize: 10, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['র', 'সো', 'ম', 'বু', 'বৃ', 'শু', 'শ'].map((d) => Expanded(
                  child: Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.textSecondary))),
                )).toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: offset + days,
            itemBuilder: (context, i) {
              final d = i - offset + 1;
              if (d < 1 || d > days) return const SizedBox.shrink();
              final dayTotal = spends[d - 1];
              final t = maxSpend > 0 ? (dayTotal / maxSpend).clamp(0.0, 1.0) : 0.0;
              final bg = dayTotal == 0 ? c.cardColor : Color.lerp(c.primary.withValues(alpha: 0.25), c.expense, t.toDouble())!;
              final isToday = MoneyIntel.sameMonth(_month, now) && d == now.day;
              return GestureDetector(
                onTap: () => _showDaySheet(c, box, DateTime(_month.year, _month.month, d)),
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isToday ? c.glow : Colors.transparent, width: 1.4),
                  ),
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: dayTotal == 0 ? c.textSecondary : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDaySheet(AppColors c, Box<Expense> box, DateTime day) {
    final items = box.values.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final spend = MoneyIntel.spendOf(items);
    final cats = MoneyIntel.categoryTotals(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(_dayMonth.format(day), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
                const Spacer(),
                Text(MoneyIntel.fmt(spend), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.expense)),
              ],
            ),
            const SizedBox(height: 6),
            if (cats.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final cct in cats)
                    Chip(
                      label: Text('${catOf(cct.category).label} ${MoneyIntel.fmt(cct.total)}', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Expanded(child: Center(child: Text('কোনো লেনদেন নেই', style: TextStyle(fontSize: 13, color: c.textSecondary))))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _dayRow(c, items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dayRow(AppColors c, Expense e) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (e.isIncome ? c.income : c.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(e.isIncome ? Icons.south_west_rounded : catOf(e.category).icon, size: 16, color: e.isIncome ? c.income : c.primary),
      ),
      title: Text(e.title, style: TextStyle(fontSize: 13, color: c.textPrimary)),
      subtitle: Text(_timeOnly.format(e.date), style: TextStyle(fontSize: 10, color: c.textSecondary)),
      trailing: Text('${e.isIncome ? '+' : '-'}${MoneyIntel.fmt(e.amount).replaceFirst('৳', '৳')}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: e.isIncome ? c.income : c.expense)),
      onTap: () => _openExpenseSheet(context, c, existing: e),
    );
  }

  Widget _categoryCard(AppColors c, Box<Expense> box, List<Expense> monthExps, DateTime now) {
    final cats = MoneyIntel.categoryTotals(monthExps);
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.fold<double>(0, (s, e) => s + e.total);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 কোথায় যাচ্ছে?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 10),
          for (final ct in cats)
            GestureDetector(
              onTap: () => setState(() => _filterCat = _filterCat == ct.category ? null : ct.category),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(catOf(ct.category).icon, size: 15, color: c.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(catOf(ct.category).label, style: TextStyle(fontSize: 12, color: c.textPrimary))),
                        Text('${ct.count}টি', style: TextStyle(fontSize: 10, color: c.textSecondary)),
                        const SizedBox(width: 8),
                        Text(MoneyIntel.fmt(ct.total), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
                        const SizedBox(width: 8),
                        Text('${total > 0 ? (ct.total / total * 100).round() : 0}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: total > 0 ? (ct.total / total).clamp(0.0, 1.0) : 0,
                        minHeight: 5,
                        backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                        color: Color.lerp(c.primary, c.expense, total > 0 ? (ct.total / total).clamp(0.0, 1.0) : 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetCard(AppColors c, Box<Expense> box) {
    final settings = Hive.box('money_settings');
    final budgets = MoneyIntel.budgets(settings);
    final cats = MoneyIntel.categoryTotals(MoneyIntel.inMonth(box, _month));
    final usedByCat = {for (final ct in cats) ct.category: ct.total};
    final rows = <Widget>[];
    for (final e in budgets.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
      final used = usedByCat[e.key] ?? 0;
      final ratio = e.value > 0 ? used / e.value : 0;
      final over = ratio > 1;
      final warn = !over && ratio >= 0.8;
      final color = over ? c.expense : warn ? c.mediumPriority : c.income;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Row(
              children: [
                Icon(catOf(e.key).icon, size: 15, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${catOf(e.key).label} — ${used == 0 ? 'ব্যবহার হয়নি' : 'ব্যবহৃত ${MoneyIntel.fmt(used)} / ${MoneyIntel.fmt(e.value)}'}',
                    style: TextStyle(fontSize: 12, color: c.textPrimary),
                  ),
                ),
                Text('${(ratio * 100).clamp(0, 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                backgroundColor: c.textSecondary.withValues(alpha: 0.15),
                color: color,
              ),
            ),
          ],
        ),
      ));
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🎯 বাজেট', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              TextButton(onPressed: () => _editBudgets(c, budgets), child: const Text('সেট করুন')),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('ক্যাটাগরি বাজেট সেট করলে লিমিট ট্র্যাক হবে', style: TextStyle(fontSize: 12, color: c.textSecondary)),
            )
          else
            ...rows,
        ],
      ),
    );
  }

  void _editBudgets(AppColors c, Map<String, double> current) {
    final ctrls = <String, TextEditingController>{
      for (final cat in kMoneyCategories) cat.key: TextEditingController(text: (current[cat.key] ?? 0) == 0 ? '' : (current[cat.key]!.round()).toString()),
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            void save() {
              final out = <String, double>{};
              for (final e in ctrls.entries) {
                final v = double.tryParse(e.value.text.replaceAll(',', ''));
                if (v != null && v > 0) out[e.key] = v;
              }
              MoneyIntel.saveBudgets(Hive.box('money_settings'), out);
              Navigator.pop(ctx);
              setState(() {});
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Text('ক্যাটাগরি বাজেট', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final cat in kMoneyCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 16, color: c.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(cat.label, style: TextStyle(fontSize: 13, color: c.textPrimary)),
                              ),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: ctrls[cat.key],
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: c.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '০',
                                    hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                                    prefixText: '৳ ',
                                    prefixStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                                    filled: true,
                                    fillColor: c.cardColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(backgroundColor: c.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('সংরক্ষণ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _recurringCard(AppColors c, Box<Expense> box) {
    final rows = MoneyIntel.recurring(box);
    if (rows.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔁 প্রতি মাসে', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
          const SizedBox(height: 6),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 14, color: c.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.textPrimary)),
                  ),
                  Text(MoneyIntel.fmt(r.amount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(width: 8),
                  Text('পরের: ${_dM.format(r.next)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.secondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _transactionsHeader(AppColors c, Box<Expense> box, List<Expense> monthExps) {
    final cats = MoneyIntel.categoryTotals(monthExps);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('লেনদেন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
            const Spacer(),
            Text('${monthExps.length}টি', style: TextStyle(fontSize: 11, color: c.textSecondary)),
          ],
        ),
        if (cats.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('সব'),
                  selected: _filterCat == null,
                  visualDensity: VisualDensity.compact,
                  selectedColor: c.primary,
                  labelStyle: TextStyle(color: _filterCat == null ? Colors.white : c.textSecondary, fontSize: 12),
                  onSelected: (_) => setState(() => _filterCat = null),
                ),
                const SizedBox(width: 6),
                for (final ct in cats)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${catOf(ct.category).label} (${ct.count})', style: TextStyle(fontSize: 12)),
                      selected: _filterCat == ct.category,
                      visualDensity: VisualDensity.compact,
                      selectedColor: c.primary,
                      labelStyle: TextStyle(color: _filterCat == ct.category ? Colors.white : c.textSecondary, fontSize: 12),
                      onSelected: (_) => setState(() => _filterCat = _filterCat == ct.category ? null : ct.category),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dayNode(AppColors c, DateTime day, List<Expense> exps) {
    final spend = MoneyIntel.spendOf(exps);
    final income = MoneyIntel.incomeOf(exps);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 20, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(MoneyIntel.bnDay(day), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.textPrimary)),
                Text('${exps.length}টি লেনদেন', style: TextStyle(fontSize: 11, color: c.textSecondary)),
              ],
            ),
          ),
          if (income > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text('+${MoneyIntel.fmt(income)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.income)),
            ),
          if (spend > 0)
            Text('-${MoneyIntel.fmt(spend)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.expense)),
        ],
      ),
    );
  }

  Widget _emptyMonth(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 56, color: c.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('এই মাসে কোনো হিসাব নেই', style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text('+ চাপ দিয়ে খরচ যোগ করো', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(AppColors c, Expense expense) {
    final amount = '${expense.isIncome ? '+' : '-'}${MoneyIntel.fmt(expense.amount).replaceFirst('৳', '৳')}';
    final color = expense.isIncome ? c.income : c.expense;
    return GestureDetector(
      onTap: () => _openExpenseSheet(context, c, existing: expense),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (expense.isIncome ? c.income : c.primary).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                expense.isIncome ? Icons.south_west_rounded : catOf(expense.category).icon,
                size: 20,
                color: expense.isIncome ? c.income : c.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title, style: TextStyle(fontSize: 14, color: c.textPrimary)),
                  Text(
                    '${catOf(expense.category).label} • ${_txTime.format(expense.date)}',
                    style: TextStyle(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded, size: 14, color: c.textSecondary.withValues(alpha: 0.45)),
          ],
        ),
      ),
    );
  }

  void _openExpenseSheet(BuildContext context, AppColors c, {Expense? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(text: existing == null ? '' : existing.amount.round().toString());
    final amountCtrlParsed = amountCtrl;
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    var category = existing?.category ?? 'other';
    var isIncome = existing?.isIncome ?? false;
    var date = existing?.date ?? DateTime.now();
    final smartCtrl = TextEditingController();
    String? smartHint = 'Smart: আজ ৩০০ টাকা বাজার / 120 tk lunch';
    var titleBusy = false;
    var noteBusy = false;

    Future<void> aiClean(
      TextEditingController ctrl,
      StateSetter setSheetState,
      bool busy,
      void Function(bool) setBusy,
    ) async {
      final t = ctrl.text.trim();
      if (t.isEmpty || busy) return;
      setBusy(true);
      setSheetState(() {});
      try {
        final r = await AiEnhancer.enhance(ctrl.text, allowOnline: true)
            .timeout(const Duration(seconds: 25));
        final cleaned = r.normalized.text.trim();
        setBusy(false);
        setSheetState(() {
          if (cleaned.isNotEmpty && cleaned != ctrl.text) ctrl.text = cleaned;
        });
      } catch (_) {
        setBusy(false);
        setSheetState(() {});
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void applySmart() {
            final p = CommandParser.parse(smartCtrl.text);
            if (p == null || p.type != CommandType.expense || p.amount == null) return;
            titleCtrl.text = p.title;
            amountCtrlParsed.text = p.amount!.round().toString();
            setSheetState(() {
              category = p.category ?? 'other';
              if (p.deadline != null && sameDaySafe(p.deadline!)) date = p.deadline!;
            });
          }

          Widget aiField(TextEditingController ctrl, String hint, bool busy, void Function(bool) setBusy) {
            return TextField(
              controller: ctrl,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                filled: true,
                fillColor: c.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: busy
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: () => aiClean(ctrl, setSheetState, busy, setBusy),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'AI দিয়ে গুছাও — বানান ঠিক, বাংলিশ→বাংলা/ইংরেজি',
                        icon: Icon(Icons.auto_awesome_rounded, size: 17, color: c.glow),
                      ),
              ),
            );
          }

          Widget field(TextEditingController ctrl, String hint, {bool number = false, TextInputType? type}) {
            return TextField(
              controller: ctrl,
              keyboardType: number ? TextInputType.number : type,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                filled: true,
                fillColor: c.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: c.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                Row(
                  children: [
                    _typeBtn(c, setSheetState, () => isIncome = false, !isIncome, 'খরচ', c.expense),
                    const SizedBox(width: 10),
                    _typeBtn(c, setSheetState, () => isIncome = true, isIncome, 'আয়', c.income),
                  ],
                ),
                const SizedBox(height: 14),
                if (existing == null) ...[
                  TextField(
                    controller: smartCtrl,
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: smartHint,
                      hintStyle: TextStyle(color: c.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                      filled: true,
                      fillColor: c.cardColor,
                      suffixIcon: TextButton(onPressed: applySmart, child: Text('⚡', style: TextStyle(color: c.glow, fontSize: 18))),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                aiField(titleCtrl, 'বিবরণ', titleBusy, (v) => titleBusy = v),
                const SizedBox(height: 12),
                field(amountCtrl, 'পরিমাণ (৳)', number: true),
                const SizedBox(height: 12),
                aiField(noteCtrl, 'মন্তব্য (ঐচ্ছিক)', noteBusy, (v) => noteBusy = v),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(now().year + 1, 12, 31),
                          );
                          if (picked != null) setSheetState(() => date = picked);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: c.textSecondary),
                        icon: Icon(Icons.calendar_month_rounded, size: 16, color: c.primary),
                        label: Text(_dMy.format(date), style: TextStyle(color: c.textPrimary, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('ক্যাটাগরি', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kMoneyCategories.map((cat) {
                        final sel = category == cat.key;
                        return GestureDetector(
                          onTap: () => setSheetState(() => category = cat.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? c.primary.withValues(alpha: 0.18) : c.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? c.primary : Colors.transparent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon, size: 16, color: sel ? c.primary : c.textSecondary),
                                const SizedBox(width: 6),
                                Text(cat.label, style: TextStyle(fontSize: 12, color: sel ? c.primary : c.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
                      if (titleCtrl.text.trim().isNotEmpty && amount > 0) {
                        if (existing != null) {
                          existing.title = titleCtrl.text.trim();
                          existing.amount = amount;
                          existing.category = category;
                          existing.isIncome = isIncome;
                          existing.date = date;
                          existing.note = noteCtrl.text.trim();
                          existing.save();
                        } else {
                          Hive.box<Expense>('expenses').add(Expense(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            amount: amount,
                            category: category,
                            date: date,
                            isIncome: isIncome,
                            note: noteCtrl.text.trim(),
                          ));
                        }
                      }
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(existing == null ? 'যোগ করুন' : 'আপডেট', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                if (existing != null)
                  TextButton.icon(
                    onPressed: () {
                      existing.delete();
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon: Icon(Icons.delete_outline, size: 16, color: c.expense),
                    label: Text('লেনদেন মুছুন', style: TextStyle(color: c.expense, fontSize: 12)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _typeBtn(AppColors c, StateSetter setState, VoidCallback onTap, bool selected, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(onTap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : c.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: selected ? color : c.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _item(AppColors c, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ],
    );
  }
}

bool sameDaySafe(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

DateTime now() => DateTime.now();

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color bar;
  final Color empty;
  final int todayIndex;
  final Color todayColor;

  _BarChartPainter({required this.values, required this.bar, required this.empty, required this.todayIndex, required this.todayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.fold<double>(1, (m, v) => v > m ? v : m);
    final n = values.length;
    final step = size.width / n;
    final barW = step * 0.55;
    final base = size.height - 14;
    final gridPaint = Paint()
      ..color = bar.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (var g = 1; g <= 3; g++) {
      final y = base - base * g / 3.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    const todayX = 14;
    if (todayIndex >= 0) {
      final tx = todayIndex * step + step / 2;
      canvas.drawLine(Offset(tx, 0), Offset(tx, base), Paint()..color = todayColor.withValues(alpha: 0.35)..strokeWidth = 1);
    }
    for (var i = 0; i < n; i++) {
      final h = values[i] <= 0 ? 2.0 : (values[i] / maxV * (base - todayX)).clamp(3.0, base - todayX);
      final x = i * step + (step - barW) / 2;
      final isToday = i == todayIndex;
      final color = values[i] <= 0 ? empty : (isToday ? todayColor : bar);
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, base - h, barW, h), const Radius.circular(3));
      canvas.drawRRect(rrect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.values != values || old.todayIndex != todayIndex;
}