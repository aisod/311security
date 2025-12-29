// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_operation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineOperationAdapter extends TypeAdapter<OfflineOperation> {
  @override
  final int typeId = 1;

  @override
  OfflineOperation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineOperation(
      id: fields[0] as String,
      type: fields[1] as OfflineOperationType,
      data: (fields[2] as Map).cast<String, dynamic>(),
      timestamp: fields[3] as DateTime,
      retryCount: fields[4] as int,
      userId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineOperation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.retryCount)
      ..writeByte(5)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineOperationTypeAdapter extends TypeAdapter<OfflineOperationType> {
  @override
  final int typeId = 0;

  @override
  OfflineOperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OfflineOperationType.createCrimeReport;
      case 1:
        return OfflineOperationType.updateCrimeReport;
      case 2:
        return OfflineOperationType.createEmergencyAlert;
      case 3:
        return OfflineOperationType.updateProfile;
      case 4:
        return OfflineOperationType.markNotificationRead;
      case 5:
        return OfflineOperationType.createEmergencyContact;
      case 6:
        return OfflineOperationType.updateEmergencyContact;
      case 7:
        return OfflineOperationType.deleteEmergencyContact;
      default:
        return OfflineOperationType.createCrimeReport;
    }
  }

  @override
  void write(BinaryWriter writer, OfflineOperationType obj) {
    switch (obj) {
      case OfflineOperationType.createCrimeReport:
        writer.writeByte(0);
        break;
      case OfflineOperationType.updateCrimeReport:
        writer.writeByte(1);
        break;
      case OfflineOperationType.createEmergencyAlert:
        writer.writeByte(2);
        break;
      case OfflineOperationType.updateProfile:
        writer.writeByte(3);
        break;
      case OfflineOperationType.markNotificationRead:
        writer.writeByte(4);
        break;
      case OfflineOperationType.createEmergencyContact:
        writer.writeByte(5);
        break;
      case OfflineOperationType.updateEmergencyContact:
        writer.writeByte(6);
        break;
      case OfflineOperationType.deleteEmergencyContact:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineOperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
