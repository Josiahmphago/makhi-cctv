// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_alert_contact_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuickAlertContactLocalAdapter
    extends TypeAdapter<QuickAlertContactLocal> {
  @override
  final int typeId = 0;

  @override
  QuickAlertContactLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuickAlertContactLocal(
      name: fields[0] as String,
      phoneNumber: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuickAlertContactLocal obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phoneNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickAlertContactLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
