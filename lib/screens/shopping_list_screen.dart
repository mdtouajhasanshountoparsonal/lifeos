import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/bazar_note.dart'
    show estimateAmount, estimateItemLine;
import 'package:lifeos/services/market_items.dart' show MarketItems;
import 'package:lifeos/services/market_parser.dart' show marketNumText;
import 'package:lifeos/services/price_parser.dart' show PriceFmt, PriceParser;
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/widgets/command_sheet.dart';

/// 🛒 Smart Shopping List — বাজার-দর (Hive 'prices') থেকে live আনুমানিক মোট।
/// আইটেম যোগ → current দর খোঁজা হয়; দর নেই → লেখা-শিক্ষা; সব offline।
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _ctrl = TextEditingController();
  final Box _box = Hive.box('shopping_list');

  List<Map> _items() =>
      _box.values.whereType<Map>().toList()
        ..sort((a, b) {
          final ad = a['done'] == true;
          final bd = b['done'] == true;
          if (ad != bd) return ad ? 1 : -1;
          final at = (a['addedAt'] is num) ? (a['addedAt'] as num) : 0;
          final bt = (b['addedAt'] is num) ? (b['addedAt'] as num) : 0;
          return at.compareTo(bt);
        });

  void _addItem(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    final p = PriceParser.parse(t);
    var item = p.item.trim();
    if (item.isEmpty || item == 'জিনিস') item = t;
    if (item.length < 2) return;
    MarketItems.addForItem(item);
    _box.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': item,
      'qty': p.qty,
      'unit': p.unit.isEmpty ? 'পিস' : p.unit,
      'done': false,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _ctrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _toggle(Map m) => _box.putAt(_items().indexOf(m), {...m, 'done': m['done'] != true});

  void _remove(Map m) => _box.deleteAt(_items().indexOf(m));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _header(c),
            _addRow(c),
            _quickChips(c),
            const SizedBox(height: 6),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, _, _) {
                  final items = _items();
                  if (items.isEmpty) return _empty(c);
                  return ValueListenableBuilder(
                    valueListenable: Hive.box('prices').listenable(),
                    builder: (context, _, _) => _list(c, _items()),
                  );
                },
              ),
            ),
            _totalBar(c),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          ),
          const SizedBox(width: 4),
          Text(
            '🛒 কেনাকাটার তালিকা',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            'দর live',
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _addRow(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: _addItem,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'আইটেম + পরিমাণ... (যেমন: ২ কেজি চাল)',
                hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                prefixIcon: Icon(Icons.add_shopping_cart_rounded,
                    size: 18, color: c.glow),
                filled: true,
                fillColor: c.cardColor,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _addItem(_ctrl.text),
            style: IconButton.styleFrom(backgroundColor: c.primary),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _quickChips(AppColors c) {
    final common = MarketItems.seed.values.expand((l) => l).toList();
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: common.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              onPressed: () => _addItem(item),
              backgroundColor: c.cardColor.withValues(alpha: 0.7),
              side: BorderSide(color: c.glow.withValues(alpha: 0.3)),
              label: Text(
                item,
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _empty(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 42, color: c.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(
              'তালিকা এখনো খালি',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'উপরে লিখো, অথবা নিচের সাধারণ আইটেমে ট্যাপ করো।\nদাম আগে লিখে রাখলে মোট আপনা-আপনি হিসাব হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(AppColors c, List<Map> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: items.length,
      itemBuilder: (context, i) => _itemCard(c, items[i]),
    );
  }

  Widget _itemCard(AppColors c, Map m) {
    final name = '${m['name']}';
    final qty = (m['qty'] is num) ? (m['qty'] as num).toDouble() : 1.0;
    final unit = '${m['unit'] ?? 'পিস'}';
    final done = m['done'] == true;
    final est = estimateItemLine(name, qty: qty, unit: unit);
    final hasPrice = estimateAmount(name, qty: qty, unit: unit) != null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      accent: done ? c.lowPriority : c.glow,
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggle(m),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                done ? '☑' : '☐',
                style: TextStyle(
                  fontSize: 22,
                  height: 1,
                  color: done ? c.primary : c.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(est.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${marketNumText(qty)} $unit',
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
                const SizedBox(height: 4),
                if (hasPrice)
                  Text(
                    '${est.main}  •  ${est.sub}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.mediumPriority),
                  )
                else
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const CommandSheet(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'দর নেই — ⚡ লেখো',
                          style: TextStyle(fontSize: 11, color: c.glow, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _remove(m),
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: c.textSecondary.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _totalBar(AppColors c) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box('prices').listenable(),
        _box.listenable(),
      ]),
      builder: (context, _) {
        final items = _items();
        if (items.isEmpty) return const SizedBox.shrink();
        final total = items.fold<double>(
            0,
            (s, m) =>
                s +
                (m['done'] == true
                    ? 0
                    : (estimateAmount(
                              '${m['name']}',
                              qty: (m['qty'] is num)
                                  ? (m['qty'] as num).toDouble()
                                  : 1.0,
                              unit: '${m['unit'] ?? 'পিস'}',
                            ) ??
                            0)));
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: BorderRadius.circular(16),
            accent: c.expense,
            child: Row(
              children: [
                Icon(Icons.payments_rounded, size: 16, color: c.expense),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'আনুমানিক মোট (সঞ্চয় করা দর থেকে)',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ),
                Text(
                  total > 0 ? '≈ ${PriceFmt.tk2(total)}' : 'দর এখনো জানা নেই',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: total > 0 ? c.expense : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}