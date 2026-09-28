import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/services/ai_enhancer.dart';
import 'package:lifeos/services/tree_text_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/beautified_tree_card.dart';
import 'package:lifeos/services/debt_store.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  static String _fmt(double v) {
    final s = v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return _bn(s);
  }

  static String _bn(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((c) {
      final i = c.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : c;
    }).join();
  }

  void _edit(Debt? d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DebtEditorSheet(existing: d),
    );
  }

  Future<void> _aiAdvice() async {
    final debts = DebtStore.all();
    if (debts.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: const Text('আগে কাউকে টাকা দেওয়া/নেওয়ার ডেটা যোগ করো')));
      return;
    }
    final lent = debts.where((d) => d.isLent && !d.settled).toList();
    final borrowed = debts.where((d) => !d.isLent && !d.settled).toList();
    double sum(Iterable<Debt> xs) => xs.fold(0.0, (a, d) => a + d.amount);
    final prompt = StringBuffer('আমার দেনা-পাওনার হিসাব — সকাল পরামর্শ দাও:\n');
    if (lent.isNotEmpty) {
      prompt.writeln('আমি দিয়েছি (পাওনা):');
      for (final d in lent) {
        prompt.writeln('- ${d.name}: ${_fmt(d.amount)} টাকা${d.note.isNotEmpty ? ' (${d.note})' : ''}');
      }
    }
    if (borrowed.isNotEmpty) {
      prompt.writeln('আমি নিয়েছি (দেনা):');
      for (final d in borrowed) {
        prompt.writeln('- ${d.name}: ${_fmt(d.amount)} টাকা${d.note.isNotEmpty ? ' (${d.note})' : ''}');
      }
    }
    prompt.writeln('সবচেয়ে বড় পাওনা কাদের, বড় দেনা কোথায়, কীভাবে পর্যায়ক্রমে মেটানো যায় — পরামর্শের গাছ বানাও।');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiAdviceSheet(prompt: prompt.toString(), userPays: sum(lent), userOwes: sum(borrowed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.balance_rounded, color: c.income, size: 24),
                  const SizedBox(width: 10),
                  Text('দেনা-পাওনা',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _aiAdvice,
                    tooltip: '✨ AI পরামর্শ',
                    icon: Icon(Icons.auto_awesome_rounded, color: c.glow),
                  ),
                  FilledButton.icon(
                    onPressed: () => _edit(null),
                    style: FilledButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text('যোগ', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('debts').listenable(),
                builder: (context, Box box, _) {
                  final debts = DebtStore.all();
                  if (debts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.balance_rounded, size: 60, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 14),
                          Text('কাউকে টাকা দিয়েছ বা নিয়েছ?',
                              style: TextStyle(fontSize: 15, color: c.textSecondary)),
                          const SizedBox(height: 4),
                          Text('এখানে রাখো — কে কত নিবে, কত দেবে সব হিসাব থাকবে',
                              style: TextStyle(fontSize: 12, color: c.textSecondary.withValues(alpha: 0.7))),
                        ],
                      ),
                    );
                  }
                  final lent = debts.where((d) => d.isLent).toList();
                  final borrowed = debts.where((d) => !d.isLent).toList();
                  final lentOpen = lent.where((d) => !d.settled).toList();
                  final borrowedOpen = borrowed.where((d) => !d.settled).toList();
                  double sum(Iterable<Debt> xs) => xs.fold(0.0, (a, d) => a + d.amount);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _summary(c, sum(lentOpen), sum(borrowedOpen)),
                      const SizedBox(height: 14),
                      _section(c, '💸 আমি দিয়েছি — পাওনা', lent, Icons.south_west_rounded, c.income),
                      const SizedBox(height: 16),
                      _section(c, '🧾 আমি নিয়েছি — দেনা', borrowed, Icons.north_east_rounded, c.expense),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(AppColors c, double lent, double borrowed) {
    final net = lent - borrowed;
    final netColor = net >= 0 ? c.income : c.expense;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary.withValues(alpha: 0.18), c.glow.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.glow.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statBlock(c, 'আমার পাওনা', lent, c.income, Icons.south_west_rounded)),
              Container(width: 1, height: 44, color: c.textSecondary.withValues(alpha: 0.2)),
              Expanded(child: _statBlock(c, 'আমার দেনা', borrowed, c.expense, Icons.north_east_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: netColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16, color: netColor),
                const SizedBox(width: 8),
                Text(net >= 0 ? 'নেট পাওনা' : 'নেট দেনা', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: netColor)),
                const Spacer(),
                Text('৳${_fmt(net.abs())}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: netColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(AppColors c, String label, double value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('৳${_fmt(value)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _section(AppColors c, String title, List<Debt> debts, IconData arrow, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.textPrimary)),
        ),
        if (debts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('কিছু নেই', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ),
        for (final d in debts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _debtRow(c, d),
          ),
      ],
    );
  }

  Future<void> _remove(Debt d) async {
    final c = AppTheme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceColor,
        title: const Text('মুছে ফেলব?'),
        content: Text('${d.name} এর এই হিসাবটা মুছে যাবে', style: TextStyle(fontSize: 14, color: c.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছো'),
          ),
        ],
      ),
    );
    if (ok == true) DebtStore.remove(d.id);
  }

  Widget _debtRow(AppColors c, Debt d) {
    final color = d.isLent ? c.income : c.expense;
    final initial = d.name.trim().isEmpty ? '?' : d.name.trim().characters.first;
    return Material(
      color: d.settled ? c.textSecondary.withValues(alpha: 0.06) : c.cardColor.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _edit(d),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                child: Text(initial, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: d.settled ? c.textSecondary : c.textPrimary,
                                    decoration: d.settled ? TextDecoration.lineThrough : null)),
                          ),
                          if (d.settled) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded, size: 14, color: c.income),
                          ],
                        ],
                      ),
                      if (d.note.isNotEmpty)
                        Text(d.note, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.textSecondary)),
                      Text(DateFormat('dd MMM, yyyy', 'bn').format(d.date),
                          style: TextStyle(fontSize: 10, color: c.textSecondary.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('৳${_fmt(d.amount)}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (d.settled ? c.income : color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(d.settled ? 'শোধ হয়েছে' : (d.isLent ? 'পাওনা' : 'দেনা'),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: d.settled ? c.income : color)),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _remove(d),
                tooltip: 'মুছো',
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.textSecondary.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtEditorSheet extends StatefulWidget {
  final Debt? existing;
  const _DebtEditorSheet({this.existing});

  @override
  State<_DebtEditorSheet> createState() => _DebtEditorSheetState();
}

class _DebtEditorSheetState extends State<_DebtEditorSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.existing == null ? '' : (widget.existing!.amount.truncateToDouble() == widget.existing!.amount
          ? widget.existing!.amount.toStringAsFixed(0)
          : widget.existing!.amount.toString()));
  late final TextEditingController _note = TextEditingController(text: widget.existing?.note ?? '');
  late DebtKind _kind = widget.existing?.kind ?? DebtKind.lent;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late bool _settled = widget.existing?.settled ?? false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static double _parseAmount(String s) {
    final digits = s.replaceAll(RegExp(r'[^০-৯0-9.]'), '');
    if (digits.isEmpty) return 0;
    var fixed = digits;
    for (var i = 0; i < 10; i++) {
      fixed = fixed.replaceAll('${'০১২৩৪৫৬৭৮৯'[i]}', '$i');
    }
    return double.tryParse(fixed) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: c.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'নতুন দেনা-পাওনা' : 'হিসাব আপডেট',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
            const SizedBox(height: 12),
            SegmentedButton<DebtKind>(
              segments: const [
                ButtonSegment(value: DebtKind.lent, icon: Icon(Icons.south_west_rounded), label: Text('আমি দিয়েছি')),
                ButtonSegment(value: DebtKind.borrowed, icon: Icon(Icons.north_east_rounded), label: Text('আমি নিয়েছি')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'নাম (যাকে/যার কাছ থেকে)',
                labelStyle: TextStyle(color: c.textSecondary),
                filled: true,
                fillColor: c.cardColor.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'টাকা',
                labelStyle: TextStyle(color: c.textSecondary),
                prefixText: '৳ ',
                prefixStyle: TextStyle(color: c.textPrimary),
                filled: true,
                fillColor: c.cardColor.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'নোট (ঐচ্ছিক)',
                labelStyle: TextStyle(color: c.textSecondary),
                filled: true,
                fillColor: c.cardColor.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (p != null) setState(() => _date = p);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: c.cardColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18, color: c.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMMM, yyyy','bn').format(_date),
                        style: TextStyle(fontSize: 13, color: c.textPrimary)),
                  ],
                ),
              ),
            ),
            if (widget.existing != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('পরিশোধ / ফেরত পেয়েছি', style: TextStyle(fontSize: 13, color: c.textPrimary)),
                value: _settled,
                onChanged: (v) => setState(() => _settled = v),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: c.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final name = _name.text.trim();
                  final amt = _parseAmount(_amount.text);
                  if (name.isEmpty || amt <= 0) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('নাম আর টাকার পরিমাণ ঠিক করো')));
                    return;
                  }
                  final now = DateTime.now();
                  final d = Debt(
                    id: widget.existing?.id ?? '${now.millisecondsSinceEpoch}',
                    name: name,
                    amount: amt,
                    kind: _kind,
                    date: _date,
                    note: _note.text.trim(),
                    settled: widget.existing != null && _settled,
                  );
                  DebtStore.upsert(d);
                  Navigator.pop(context);
                },
                child: Text('সংরক্ষণ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAdviceSheet extends StatefulWidget {
  final String prompt;
  final double userPays;
  final double userOwes;
  const _AiAdviceSheet({required this.prompt, required this.userPays, required this.userOwes});

  @override
  State<_AiAdviceSheet> createState() => _AiAdviceSheetState();
}

class _AiAdviceSheetState extends State<_AiAdviceSheet> {
  TreeBlueprint? _tree;
  String? _source;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final r = await AiEnhancer.enhance(widget.prompt, allowOnline: true).timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() {
        _tree = r.tree;
        _source = r.source;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final netDiff = widget.userPays - widget.userOwes;
    return Container(
      height: MediaQuery.of(context).size.height * 0.66,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: c.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.glow),
              const SizedBox(width: 8),
              Text('✨ AI পরামর্শ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: netDiff >= 0 ? c.income.withValues(alpha: 0.14) : c.expense.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'নেট ${netDiff >= 0 ? 'পাওনা' : 'দেনা'} ৳${_fmt(netDiff.abs())}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: netDiff >= 0 ? c.income : c.expense),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final s = v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    const bn = '০১২৩৪৫৬৭৮৯';
    return s.split('').map((ch) {
      final i = ch.codeUnitAt(0);
      return i >= 0x30 && i <= 0x39 ? bn[i - 0x30] : ch;
    }).join();
  }

  Widget _body(AppColors c) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: c.textSecondary),
            const SizedBox(height: 10),
            Text('পরামর্শ নেয়া গেল না', style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: c.expense)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(onPressed: _run,
                icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('আবার চেষ্টা')),
          ],
        ),
      );
    }
    if (_tree == null) {
      return const Center(
        child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (!_tree!.hasNodes) {
      return Center(child: Text('কোনো পরামর্শ মেলেনি', style: TextStyle(color: c.textSecondary)));
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: BeautifiedTreeCard(raw: widget.prompt, blueprint: _tree, aiSource: _source, animate: true),
    );
  }
}