import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/services/money_intel.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/glass_card.dart';

/// Note2 #13 — Money Tree: মাসের গোড়া → আয়/খরচ-ক্যাটাগরি/বিশ্লেষণ/বাকি
class MoneyTreeView extends StatelessWidget {
  final Box<Expense> box;
  final DateTime month;
  final AppColors c;

  const MoneyTreeView({
    super.key,
    required this.box,
    required this.month,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final exps = MoneyIntel.inMonth(box, month);
    final spend = MoneyIntel.spendOf(exps);
    final income = MoneyIntel.incomeOf(exps);
    final remaining = income - spend;
    final prevSpend = MoneyIntel.spendOf(MoneyIntel.inMonth(box, MoneyIntel.addMonth(month, -1)));
    final delta = MoneyIntel.monthDelta(spend, prevSpend);

    final incomeTxns = exps.where((e) => e.isIncome).toList();
    final spendTxns = exps.where((e) => !e.isIncome).toList();
    final cats = MoneyIntel.categoryTotals(spendTxns);

    final anomaly = MoneyIntel.anomalyToday(box);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RootHeader(c: c, month: month, income: income, spend: spend, remaining: remaining),
        const SizedBox(height: 12),
        _Branch(
          c: c,
          dot: c.secondary,
          icon: Icons.savings_rounded,
          title: '💵 আয়',
          trail: income == 0 ? '' : MoneyIntel.fmt(income),
          children: [
            if (incomeTxns.isEmpty)
              _Leaf(c: c, dot: c.secondary.withValues(alpha: 0.5), title: 'এই মাসে আয় নেই', trail: ''),
            for (final t in incomeTxns) _Leaf(c: c, dot: c.secondary, title: t.title, trail: MoneyIntel.fmt(t.amount)),
            if (incomeTxns.isNotEmpty) _Leaf(c: c, dot: c.secondary, title: 'মোট আয়', trail: MoneyIntel.fmt(income), bold: true),
          ],
        ),
        const SizedBox(height: 10),
        _Branch(
          c: c,
          dot: c.primary,
          icon: Icons.account_balance_wallet_rounded,
          title: '💸 খরচ',
          trail: spend == 0 ? '' : MoneyIntel.fmt(spend),
          children: [
            if (spendTxns.isEmpty)
              _Leaf(c: c, dot: c.primary.withValues(alpha: 0.5), title: 'এই মাসে খরচ নেই', trail: ''),
            for (final cat in cats)
              _Branch(
                c: c,
                dot: catOf(cat.category).icon == Icons.more_horiz_rounded ? c.lowPriority : c.mediumPriority,
                icon: catOf(cat.category).icon,
                title: catOf(cat.category).label,
                trail: '${MoneyIntel.fmt(cat.total)} · ${cat.count}টি',
                children: [
                  for (final e in spendTxns.where((x) => (x.category == cat.category) || (cat.category == 'groceries' && x.category == 'food')))
                    _Leaf(
                      c: c,
                      dot: c.mediumPriority.withValues(alpha: 0.6),
                      title: e.title.isEmpty ? catOf(cat.category).label : e.title,
                      trail: MoneyIntel.fmt(e.amount),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Branch(
          c: c,
          dot: c.glow,
          icon: Icons.insights_rounded,
          title: '📊 বিশ্লেষণ',
          trail: '',
          children: [
            _Leaf(c: c, dot: c.glow, title: 'আজ খরচ', trail: MoneyIntel.fmt(MoneyIntel.daySpend(box, DateTime.now()))),
            _Leaf(c: c, dot: c.glow, title: 'এই সপ্তাহ', trail: MoneyIntel.fmt(MoneyIntel.weekSpend(box, DateTime.now()))),
            _Leaf(c: c, dot: c.glow, title: 'এই মাস', trail: MoneyIntel.fmt(spend)),
            if (anomaly.unusual)
              _Leaf(
                c: c,
                dot: c.expense,
                title: '⚠️ অস্বাভাবিক খরচ (গড় ${MoneyIntel.fmt(anomaly.avg)} থেকে বেশি)',
                trail: MoneyIntel.fmt(anomaly.today),
                danger: true,
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Branch(
          c: c,
          dot: remaining < 0 ? c.expense : c.lowPriority,
          icon: Icons.savings_outlined,
          title: '💾 বাকি',
          trail: MoneyIntel.fmt(remaining),
          children: [
            _Leaf(c: c, dot: remaining < 0 ? c.expense : c.lowPriority, title: 'আয় − খরচ', trail: MoneyIntel.fmt(remaining), bold: true),
            if (delta != null)
              _Leaf(
                c: c,
                dot: delta > 0 ? c.expense : c.lowPriority,
                title: 'গত মাসের তুলনা',
                trail: '${delta > 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(0)}%',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'কোনো শাখা ট্যাপ করলেই ভাঁজ/খোলে — সব হিসাব তোমার ডেটা থেকেই',
          style: TextStyle(fontSize: 11, color: c.textSecondary.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _RootHeader extends StatelessWidget {
  final AppColors c;
  final DateTime month;
  final double income;
  final double spend;
  final double remaining;

  const _RootHeader({
    required this.c,
    required this.month,
    required this.income,
    required this.spend,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      accent: remaining < 0 ? c.expense : c.glow,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [remaining < 0 ? c.expense.withValues(alpha: 0.9) : c.glow.withValues(alpha: 0.9), remaining < 0 ? c.expense.withValues(alpha: 0.4) : c.glow.withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (remaining < 0 ? c.expense : c.glow).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💰 ${MoneyIntel.bnMonthYear(month)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'আয় ${MoneyIntel.fmt(income)} · খরচ ${MoneyIntel.fmt(spend)}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            MoneyIntel.fmt(remaining),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: remaining < 0 ? c.expense : c.lowPriority,
            ),
          ),
        ],
      ),
    );
  }
}

class _Branch extends StatefulWidget {
  final AppColors c;
  final Color dot;
  final IconData icon;
  final String title;
  final String trail;
  final List<Widget> children;

  const _Branch({
    required this.c,
    required this.dot,
    required this.icon,
    required this.title,
    required this.trail,
    required this.children,
  });

  @override
  State<_Branch> createState() => _BranchState();
}

class _BranchState extends State<_Branch> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _open = !_open),
          child: GlassCard(
            borderRadius: BorderRadius.circular(16),
            accent: widget.dot,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: widget.dot),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ),
                if (widget.trail.isNotEmpty)
                  Text(
                    widget.trail,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: widget.dot),
                  ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0 : 0.5,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: Icon(Icons.expand_more_rounded, size: 20, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      for (var i = 0; i < widget.children.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 2,
                                margin: const EdgeInsets.only(top: 4),
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                  color: widget.dot.withValues(alpha: i == widget.children.length - 1 && _open ? 0.15 : 0.35),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: widget.children[i]),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Leaf extends StatelessWidget {
  final AppColors c;
  final Color dot;
  final String title;
  final String trail;
  final bool bold;
  final bool danger;

  const _Leaf({
    required this.c,
    required this.dot,
    required this.title,
    required this.trail,
    this.bold = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: danger ? c.expense.withValues(alpha: 0.12) : c.cardColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: danger ? c.expense : c.textPrimary,
              ),
            ),
          ),
          if (trail.isNotEmpty)
            Text(
              trail,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: danger ? c.expense : c.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}