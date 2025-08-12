// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReportModelAdapter extends TypeAdapter<ReportModel> {
  @override
  final int typeId = 105;

  @override
  ReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReportModel(
      id: fields[0] as String,
      name: fields[1] as String,
      companyId: fields[2] as String,
      folderId: fields[4] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReportModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.companyId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.folderId)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
