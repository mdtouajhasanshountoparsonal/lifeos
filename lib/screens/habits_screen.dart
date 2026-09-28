import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/models/habit.dart';
import 'package:lifeos/theme/app_theme.dart';
import 'package:lifeos/widgets/app_background.dart';
import 'package:lifeos/widgets/entrance_item.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const _habitIcons = ['📖', '💻', '🏃', '💧', '🧹', '📱', '🎯', '✍️'];

  void _addHabit(AppColors c) {
    final nameCtrl = TextEditingController();
    var icon = _habitIcons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('নতুন অভ্যাস', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'অভ্যাসের নাম (যেমন: ইংরেজি পড়া)',
                  hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: c.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('আইকন বাছাই', style: TextStyle(fontSize: 13, color: c.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _habitIcons.map((hIcon) {
                  final selected = icon == hIcon;
                  return GestureDetector(
                    onTap: () => setSheetState(() => icon = hIcon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected ? c.primary.withValues(alpha: 0.18) : c.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? c.primary : Colors.transparent),
                      ),
                      child: Text(hIcon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      Hive.box<Habit>('habits').add(Habit(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text,
                        icon: icon,
                        completedDates: [],
                        createdAt: DateTime.now(),
                      ));
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('যোগ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'অভ্যাস',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: () => _addHabit(c),
                    style: IconButton.styleFrom(backgroundColor: c.primary),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Habit>('habits').listenable(),
                builder: (context, Box<Habit> box, _) {
                  if (box.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.loop_rounded, size: 64, color: c.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('কোনো অভ্যাস নেই', style: TextStyle(fontSize: 16, color: c.textSecondary)),
                          const SizedBox(height: 8),
                          Text('+ চাপে নতুন অভ্যাস যোগ করো', style: TextStyle(fontSize: 13, color: c.textSecondary.withValues(alpha: 0.6))),
                        ],
                      ),
                    );
                  }
                  final habits = box.values.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      return EntranceItem(
                        order: index,
                        child: _buildHabitCard(context, c, habits[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, AppColors c, Habit habit) {
    final now = DateTime.now();
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
              ),
              if (habit.streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.mediumPriority.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔥 ${habit.streak}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.mediumPriority),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = now.subtract(Duration(days: now.weekday - 1 - i));
              final completed = habit.completedDates.any((d) =>
                  d.year == date.year && d.month == date.month && d.day == date.day);
              return GestureDetector(
                onTap: () => _toggleDay(habit, date),
                child: Column(
                  children: [
                    Text(
                      weekDays[i],
                      style: TextStyle(fontSize: 10, color: c.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: completed ? c.lowPriority.withValues(alpha: 0.18) : c.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: completed ? c.lowPriority : c.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: completed
                          ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF6BCB77))
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _toggleDay(Habit habit, DateTime date) {
    final index = habit.completedDates.indexWhere((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
    if (index >= 0) {
      habit.completedDates.removeAt(index);
    } else {
      habit.completedDates.add(date);
    }
    habit.save();
  }
}