import 'package:hive_flutter/hive_flutter.dart';

enum DebtKind { lent, borrowed }

class Debt {
  final String id;
  final String name;
  final double amount;
  final DebtKind kind;
  final DateTime date;
  final String note;
  final bool settled;

  const Debt({
    required this.id,
    required this.name,
    required this.amount,
    required this.kind,
    required this.date,
    this.note = '',
    this.settled = false,
  });

  bool get isLent => kind == DebtKind.lent;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'kind': kind.name,
        'date': date.toIso8601String(),
        'note': note,
        'settled': settled,
      };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        amount: (m['amount'] as num).toDouble(),
        kind: m['kind'] == 'borrowed' ? DebtKind.borrowed : DebtKind.lent,
        date: DateTime.parse(m['date'] as String? ?? DateTime.now().toIso8601String()),
        note: m['note'] as String? ?? '',
        settled: m['settled'] as bool? ?? false,
      );

  Debt copyWith({
    String? name,
    double? amount,
    DebtKind? kind,
    DateTime? date,
    String? note,
    bool? settled,
  }) =>
      Debt(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        kind: kind ?? this.kind,
        date: date ?? this.date,
        note: note ?? this.note,
        settled: settled ?? this.settled,
      );
}

class DebtStore {
  static const _boxName = 'debts';

  static Box get _box => Hive.box(_boxName);

  static String _key(String id) => 'd_$id';

  static List<Debt> all() {
    final list = <Debt>[];
    for (final v in _box.values) {
      if (v is Map) {
        try {
          list.add(Debt.fromMap(Map<String, dynamic>.from(v)));
        } catch (_) {}
      }
    }
    list.sort((a, b) {
      if (a.settled != b.settled) return a.settled ? 1 : -1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  static void upsert(Debt d) => _box.put(_key(d.id), d.toMap());

  static void remove(String id) => _box.delete(_key(id));
}