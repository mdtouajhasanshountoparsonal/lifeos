import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 3)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  List<DateTime> completedDates;

  @HiveField(4)
  DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.completedDates,
    required this.createdAt,
  });

  int get streak {
    if (completedDates.isEmpty) return 0;
    final sorted = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime.now();
    for (final date in sorted) {
      if (date.year == check.year &&
          date.month == check.month &&
          date.day == check.day) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (date.isBefore(check)) {
        break;
      }
    }
    return streak;
  }

  bool get completedToday {
    final now = DateTime.now();
    return completedDates.any((d) =>
        d.year == now.year && d.month == now.month && d.day == now.day);
  }
}
