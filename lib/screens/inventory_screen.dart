import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/services/market_parser.dart' show marketEmoji, marketNumText;
import 'package:lifeos/services/price_parser.dart' show PriceParser, isCountable;
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';

/// 📦 Personal Inventory — স্টক ট্র্যাক: +/−, কম-সতর্কতা, খালি হোল "🛒 তালিকায়"।
/// 'inventory' box-এ map {id,name,stock,unit,updatedAt} — সব অফলাইন।
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _ctrl = TextEditingController();
  final Box _box = Hive.box('inventory');

  List<Map> _items() => _box.values.whereType<Map>().toList()
    ..sort((a, b) {
      return '${a['name']}'.compareTo('${b['name']}');
    });

  void _add() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      final p = PriceParser.parse(t);
      var name = p.item.trim();
      if (name.isEmpty || name == 'জিনিস') name = t;
      if (name.length < 2) return;
      final qty = p.qty > 0 ? p.qty : 1.0;
      final unit = p.unit.isEmpty ? 'টা' : p.unit;
      final existing =
          _box.values.whereType<Map>().where((m) => '${m['name']}' == name).toList();
      if (existing.isNotEmpty) {
        final idx = _box.values.toList().indexOf(existing.first);
        _box.putAt(
            idx, {...existing.first, 'stock': (existing.first['stock'] is num ? (existing.first['stock'] as num).toDouble() : 0) + qty, 'updatedAt': DateTime.now().millisecondsSinceEpoch});
      } else {
        _box.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'stock': qty,
          'unit': unit,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      _ctrl.clear();
      FocusScope.of(context).unfocus();
    });
  }

  void _bump(Map m, double delta) {
    final idx = _box.values.toList().indexOf(m);
    if (idx < 0) return;
    final cur = (m['stock'] is num) ? (m['stock'] as num).toDouble() : 0;
    _box.putAt(idx, {...m, 'stock': (cur + delta).clamp(0, 99999), 'updatedAt': DateTime.now().millisecondsSinceEpoch});
  }

  void _remove(Map m) {
    final idx = _box.values.toList().indexOf(m);
    if (idx >= 0) _box.deleteAt(idx);
  }

  /// খালি/কম আইটেম → 🛒 কেনাকাটার তালিকায় যোগ (qty ১), থাকলে +১।
  void _toShopping(Map m) {
    final sbox = Hive.box('shopping_list');
    final t = '${m['name']}';
    final unit = '${m['unit'] ?? 'টা'}';
    final existing = sbox.values
        .whereType<Map>()
        .where((x) => '${x['name']}' == t)
        .toList();
    if (existing.isNotEmpty) {
      final idx = sbox.values.toList().indexOf(existing.first);
      final q = (existing.first['qty'] is num) ? (existing.first['qty'] as num).toDouble() : 1.0;
      sbox.putAt(idx, {...existing.first, 'qty': q + 1});
    } else {
      sbox.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': t,
        'qty': 1.0,
        'unit': unit,
        'done': false,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🛒 "$t" তালিকায়', textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.of(context).surfaceColor,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _statusLabel(double s, String unit) {
    final low = isCountable(unit) ? s <= 1 : s <= 0.5;
    if (s <= 0) return 'শেষ ⚠️';
    if (low) return 'কম';
    return 'পর্যাপ্ত';
  }

  Color _statusColor(double s, String unit, AppColors c) {
    final low = isCountable(unit) ? s <= 1 : s <= 0.5;
    if (s <= 0) return c.highPriority;
    if (low) return c.mediumPriority;
    return c.primary;
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ' + / − দিয়ে স্টক বদলাও; খালি হলে "🛒 তালিকায়" টিপ।',
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, _, _) {
                  final items = _items();
                  if (items.isEmpty) return _empty(c);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _itemCard(c, items[i]),
                  );
                },
              ),
            ),
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
            '📦 স্টক-ইনভেন্টরি',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addRow(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _add(),
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'আইটেম + পরিমাণ... (যেমন: ডিম ১২টা)',
                hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                prefixIcon: Icon(Icons.inventory_2_rounded, size: 18, color: c.mediumPriority),
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
            onPressed: _add,
            style: IconButton.styleFrom(backgroundColor: c.mediumPriority),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: c.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text('স্টক এখনো নেই', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 6),
          Text('যেমন: "ডিম ১২টা", "চাল ৫ কেজি" — লিখে যোগ করো।',
              style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ],
      ),
    );
  }

  Widget _itemCard(AppColors c, Map m) {
    final name = '${m['name']}';
    final unit = '${m['unit'] ?? 'টা'}';
    final stock = (m['stock'] is num) ? (m['stock'] as num).toDouble() : 0.0;
    final label = _statusLabel(stock, unit);
    final color = _statusColor(stock, unit, c);
    final low = label != 'পর্যাপ্ত';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: low ? color.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Row(
        children: [
          Text(marketEmoji(name), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 2),
                Text('${marketNumText(stock)} $unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: label == 'পর্যাপ্ত' ? c.textSecondary : color)),
              ],
            ),
          ),
          if (low)
            InkWell(
              onTap: () => _toShopping(m),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: c.glow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('🛒 তালিকায়', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.glow)),
              ),
            ),
          IconButton(
            onPressed: () => _bump(m, -1),
            icon: Icon(Icons.remove_circle_outline_rounded, size: 20, color: c.expense),
          ),
          IconButton(
            onPressed: () => _bump(m, 1),
            icon: Icon(Icons.add_circle_outline_rounded, size: 20, color: c.income),
          ),
          IconButton(
            onPressed: () => _remove(m),
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.textSecondary.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}