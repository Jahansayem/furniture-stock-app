// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WarehouseAdapter extends TypeAdapter<Warehouse> {
  @override
  final int typeId = 10;

  @override
  Warehouse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Warehouse(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      address: fields[3] as String,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
      type: fields[6] as WarehouseType,
      managerId: fields[7] as String,
      managerName: fields[8] as String?,
      isActive: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      description: fields[12] as String?,
      capacity: fields[13] as double?,
      contactPhone: fields[14] as String?,
      contactEmail: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Warehouse obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.managerId)
      ..writeByte(8)
      ..write(obj.managerName)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.description)
      ..writeByte(13)
      ..write(obj.capacity)
      ..writeByte(14)
      ..write(obj.contactPhone)
      ..writeByte(15)
      ..write(obj.contactEmail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockTransferAdapter extends TypeAdapter<StockTransfer> {
  @override
  final int typeId = 12;

  @override
  StockTransfer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockTransfer(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      fromWarehouseId: fields[3] as String,
      fromWarehouseName: fields[4] as String,
      toWarehouseId: fields[5] as String,
      toWarehouseName: fields[6] as String,
      quantity: fields[7] as int,
      status: fields[8] as TransferStatus,
      initiatedBy: fields[9] as String,
      approvedBy: fields[10] as String?,
      completedBy: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      approvedAt: fields[13] as DateTime?,
      completedAt: fields[14] as DateTime?,
      notes: fields[15] as String?,
      rejectionReason: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StockTransfer obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.fromWarehouseId)
      ..writeByte(4)
      ..write(obj.fromWarehouseName)
      ..writeByte(5)
      ..write(obj.toWarehouseId)
      ..writeByte(6)
      ..write(obj.toWarehouseName)
      ..writeByte(7)
      ..write(obj.quantity)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.initiatedBy)
      ..writeByte(10)
      ..write(obj.approvedBy)
      ..writeByte(11)
      ..write(obj.completedBy)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.approvedAt)
      ..writeByte(14)
      ..write(obj.completedAt)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(16)
      ..write(obj.rejectionReason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockTransferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WarehouseTypeAdapter extends TypeAdapter<WarehouseType> {
  @override
  final int typeId = 11;

  @override
  WarehouseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WarehouseType.factory;
      case 1:
        return WarehouseType.showroom;
      case 2:
        return WarehouseType.storage;
      case 3:
        return WarehouseType.distribution;
      case 4:
        return WarehouseType.retail;
      default:
        return WarehouseType.factory;
    }
  }

  @override
  void write(BinaryWriter writer, WarehouseType obj) {
    switch (obj) {
      case WarehouseType.factory:
        writer.writeByte(0);
        break;
      case WarehouseType.showroom:
        writer.writeByte(1);
        break;
      case WarehouseType.storage:
        writer.writeByte(2);
        break;
      case WarehouseType.distribution:
        writer.writeByte(3);
        break;
      case WarehouseType.retail:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransferStatusAdapter extends TypeAdapter<TransferStatus> {
  @override
  final int typeId = 13;

  @override
  TransferStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransferStatus.pending;
      case 1:
        return TransferStatus.approved;
      case 2:
        return TransferStatus.inProgress;
      case 3:
        return TransferStatus.completed;
      case 4:
        return TransferStatus.cancelled;
      case 5:
        return TransferStatus.rejected;
      default:
        return TransferStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TransferStatus obj) {
    switch (obj) {
      case TransferStatus.pending:
        writer.writeByte(0);
        break;
      case TransferStatus.approved:
        writer.writeByte(1);
        break;
      case TransferStatus.inProgress:
        writer.writeByte(2);
        break;
      case TransferStatus.completed:
        writer.writeByte(3);
        break;
      case TransferStatus.cancelled:
        writer.writeByte(4);
        break;
      case TransferStatus.rejected:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
