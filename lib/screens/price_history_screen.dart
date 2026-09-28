import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/services/market_parser.dart' show marketEmoji, marketNumText;
import 'package:lifeos/services/price_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';

/// 🕘 বাজার-দর ইতিহাস (Time Machine) — প্রতি আইটেমের সব সঞ্চিত দর, newest প্রথম।
/// সব offline, দাম-লাইনে সেভ হওয়া প্রতিটা এন্ট্রি এখানে visible।
class PriceHistoryScreen extends StatelessWidget {
  const PriceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _header(context, c),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('prices').listenable(),
                builder: (context, _, _) => _list(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppColors c) {
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
            '🕘 বাজার-দর ইতিহাস',
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

  Widget _list(AppColors c) {
    final all = PriceStore.all();
    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 42, color: c.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text('দর এখনো সেভ হয়নি',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
              const SizedBox(height: 6),
              Text('দাম লিখলেই এখানে ইতিহাস হবে — যেমন: "আজ ১ কেজি চাল ৬০ টাকা"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
          ),
        ),
      );
    }

    final byItem = <String, List<PriceEntry>>{};
    for (final e in all) {
      byItem.putIfAbsent(e.item, () => []).add(e);
    }
    final items = byItem.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final list = byItem[item]!;
        final latest = list.first;
        return _itemCard(c, item, list, latest);
      },
    );
  }

  Widget _itemCard(AppColors c, String item, List<PriceEntry> list, PriceEntry latest) {
    final nfTime = DateFormat('d MMM, hh:mm a', 'bn');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Text(marketEmoji(item), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
                ),
                Text('${list.length} বার', style: TextStyle(fontSize: 10.5, color: c.textSecondary)),
                const SizedBox(width: 6),
                Text(PriceFmt.tk2(perBase(latest.unit, latest.total, latest.qty)),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.glow)),
              ],
            ),
          ),
          ...list.map((e) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: c.surfaceColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag_rounded, size: 13, color: c.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${marketNumText(e.qty)} ${e.unit} = ${PriceFmt.tk(e.total)}',
                      style: TextStyle(fontSize: 12, color: c.textPrimary),
                    ),
                  ),
                  Text(
                    perDisplay(e.unit, e.total, e.qty),
                    style: TextStyle(fontSize: 11, color: c.mediumPriority),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nfTime.format(DateTime.fromMillisecondsSinceEpoch(e.time)),
                    style: TextStyle(fontSize: 10, color: c.textSecondary),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}