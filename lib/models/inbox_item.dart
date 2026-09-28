import 'package:hive/hive.dart';

part 'inbox_item.g.dart';

@HiveType(typeId: 4)
class InboxItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String? path;

  @HiveField(2)
  String? text;

  @HiveField(3)
  final DateTime receivedAt;

  @HiveField(4)
  String? ocrText;

  @HiveField(5)
  String? kind;

  @HiveField(6)
  bool processed;

  InboxItem({
    required this.id,
    this.path,
    this.text,
    required this.receivedAt,
    this.ocrText,
    this.kind,
    this.processed = false,
  });
}