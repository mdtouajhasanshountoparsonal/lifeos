// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      priority: fields[3] as int,
      createdAt: fields[4] as DateTime,
      deadline: fields[5] as DateTime?,
      isCompleted: fields[6] as bool,
      estimatedMinutes: fields[7] as int,
      actualMinutes: fields[8] as int,
      category: fields[9] as String?,
      parentId: fields[10] as String?,
      order: fields[11] as int? ?? 0,
      items: (fields[12] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      expectedCost: fields[13] as double?,
      completedAt: fields[14] as DateTime?,
      location: fields[15] as String?,
      archived: fields[16] as bool? ?? false,
      recurrence: fields[17] as Map<String, dynamic>?,
      history: (fields[18] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      expenseSaved: fields[19] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.deadline)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.estimatedMinutes)
      ..writeByte(8)
      ..write(obj.actualMinutes)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.parentId)
      ..writeByte(11)
      ..write(obj.order)
      ..writeByte(12)
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.expectedCost)
      ..writeByte(14)
      ..write(obj.completedAt)
      ..writeByte(15)
      ..write(obj.location)
      ..writeByte(16)
      ..write(obj.archived)
      ..writeByte(17)
      ..write(obj.recurrence)
      ..writeByte(18)
      ..write(obj.history)
      ..writeByte(19)
      ..write(obj.expenseSaved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
