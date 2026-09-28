import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/services/price_parser.dart' show PriceFmt, PriceStore;
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/glass_card.dart';
import 'package:lifeos/screens/shopping_list_screen.dart';

/// 🌅 Morning Snapshot — আজকের হালচাল এক কার্ডে: নোট, কাজ, খরচ, বাজার-দর।
/// সঙ্গে দ্রুত ⚡ capture ও 🛒 বাজার তালিকার শর্টকাট। সব অফলাইন count।
class MorningSnapshot extends StatelessWidget {
  final VoidCallback onCapture;

  const MorningSnapshot({super.key, required this.onCapture});

  bool _sameDay(DateTime a, DateTime now) =>
      a.year == now.year && a.month == now.month && a.day == now.day;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box<Note>('notes').listenable(),
        Hive.box<Task>('tasks').listenable(),
        Hive.box<Expense>('expenses').listenable(),
        Hive.box('prices').listenable(),
      ]),
      builder: (context, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final notesToday = Hive.box<Note>('notes').values
            .where((n) => !n.isArchived && _sameDay(n.updatedAt, now))
            .length;
        final tasksDue = Hive.box<Task>('tasks').values
            .where((t) =>
                !t.isCompleted && t.deadline != null && _sameDay(t.deadline!, now))
            .length;
        final spentToday = Hive.box<Expense>('expenses').values
            .where((e) => !e.isIncome && _sameDay(e.date, now))
            .fold<double>(0, (s, e) => s + e.amount);
        final pricesToday = PriceStore.all()
            .where((p) => p.time >= today.millisecondsSinceEpoch)
            .length;

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(18),
          accent: c.glow,
          child: Column(
            children: [
              Row(
                children: [
                  _stat(c, '📝', '$notesToday', 'নোট আজ'),
                  _stat(c, '⚡', '$tasksDue', 'কাজ আজ'),
                  _stat(c, '৳', PriceFmt.tk2(spentToday), 'খরচ আজ'),
                  _stat(c, '🛒', '$pricesToday', 'দর আজ'),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: c.textSecondary.withValues(alpha: 0.12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _chip(
                      c,
                      icon: Icons.bolt_rounded,
                      label: 'দ্রুত capture',
                      color: c.glow,
                      onTap: onCapture,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _chip(
                      c,
                      icon: Icons.shopping_cart_rounded,
                      label: 'বাজার তালিকা',
                      color: c.mediumPriority,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ShoppingListScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(AppColors c, String icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _chip(AppColors c, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: c.cardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}