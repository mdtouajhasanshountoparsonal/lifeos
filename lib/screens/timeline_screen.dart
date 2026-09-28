import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/services/price_parser.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';

/// 🕰️ Life Timeline — সব module-এর কার্যক্রম এক চেইনে (দিন অনুযায়ী)।
/// নোট, কাজ, খরচ, বাজার-দর — সব অফলাইন, কোনো heavy কাজ UI-তে নেই।
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _header(context, c),
            Expanded(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  Hive.box<Note>('notes').listenable(),
                  Hive.box<Task>('tasks').listenable(),
                  Hive.box<Expense>('expenses').listenable(),
                  Hive.box('prices').listenable(),
                ]),
                builder: (context, _) => _list(c),
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
            '🕰️ জীবন-টাইমলাইন',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            'সব কার্যক্রম',
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  List<_Event> _events(AppColors c) {
    final out = <_Event>[];
    for (final n in Hive.box<Note>('notes').values.where((n) => !n.isArchived)) {
      out.add(_Event(
        when: n.updatedAt,
        icon: Icons.sticky_note_2_rounded,
        color: c.secondary,
        title: n.title.isEmpty ? 'নোট' : n.title,
        sub: 'নোট',
      ));
    }
    for (final t in Hive.box<Task>('tasks').values.where((t) => !t.archived)) {
      final done = t.isCompleted;
      final w = done ? (t.completedAt ?? t.createdAt) : (t.deadline ?? t.createdAt);
      out.add(_Event(
        when: w,
        icon: done ? Icons.check_circle_rounded : Icons.fact_check_rounded,
        color: done ? c.lowPriority : c.primary,
        title: t.title,
        sub: done ? 'কাজ শেষ ✅' : (t.deadline != null ? 'কাজ • ডেডলাইন' : 'কাজ'),
      ));
    }
    for (final e in Hive.box<Expense>('expenses').values) {
      out.add(_Event(
        when: e.date,
        icon: e.isIncome ? Icons.south_west_rounded : Icons.payments_rounded,
        color: e.isIncome ? c.income : c.expense,
        title: e.title,
        sub: '${e.isIncome ? 'আয়' : 'খরচ'} • ${PriceFmt.tk2(e.amount)}',
      ));
    }
    for (final p in PriceStore.all()) {
      out.add(_Event(
        when: DateTime.fromMillisecondsSinceEpoch(p.time),
        icon: Icons.shopping_cart_rounded,
        color: c.glow,
        title: p.item,
        sub: 'দর • ${PriceFmt.tk2(p.total)} • ${perDisplay(p.unit, p.total, p.qty)}',
      ));
    }
    out.sort((a, b) => b.when.compareTo(a.when));
    return out;
  }

  Widget _list(AppColors c) {
    final events = _events(c);
    if (events.isEmpty) {
      return Center(
        child: Text(
          'এখনো কোনো কার্যক্রম নেই',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      );
    }
    final nfDay = DateFormat('d MMMM, yyyy', 'bn');
    final nfTime = DateFormat('h:mm a', 'bn');
    final todayStr = nfDay.format(DateTime.now());

    final groups = <String, List<_Event>>{};
    for (final e in events) {
      groups.putIfAbsent(nfDay.format(e.when), () => []).add(e);
    }
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final dayEvents = groups[key]!;
        final isToday = key == todayStr;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? c.glow : c.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? '$key — আজ' : key,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isToday ? c.glow : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            for (final ev in dayEvents) _eventCard(c, ev, nfTime),
          ],
        );
      },
    );
  }

  Widget _eventCard(AppColors c, _Event ev, DateFormat nfTime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ev.icon, size: 18, color: ev.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                Text(
                  ev.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            nfTime.format(ev.when),
            style: TextStyle(fontSize: 10.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Event {
  final DateTime when;
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  const _Event({
    required this.when,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
  });
}