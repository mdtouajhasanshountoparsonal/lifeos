// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InboxItemAdapter extends TypeAdapter<InboxItem> {
  @override
  final int typeId = 4;

  @override
  InboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InboxItem(
      id: fields[0] as String,
      path: fields[1] as String?,
      text: fields[2] as String?,
      receivedAt: fields[3] as DateTime,
      ocrText: fields[4] as String?,
      kind: fields[5] as String?,
      processed: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InboxItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.receivedAt)
      ..writeByte(4)
      ..write(obj.ocrText)
      ..writeByte(5)
      ..write(obj.kind)
      ..writeByte(6)
      ..write(obj.processed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
