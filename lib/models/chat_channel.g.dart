// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_channel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatChannelAdapter extends TypeAdapter<ChatChannel> {
  @override
  final int typeId = 10;

  @override
  ChatChannel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatChannel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as String,
      participants: (fields[4] as List).cast<String>(),
      lastMessageId: fields[5] as String?,
      lastMessageAt: fields[6] as DateTime?,
      createdBy: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatChannel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.participants)
      ..writeByte(5)
      ..write(obj.lastMessageId)
      ..writeByte(6)
      ..write(obj.lastMessageAt)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChannelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatParticipantAdapter extends TypeAdapter<ChatParticipant> {
  @override
  final int typeId = 11;

  @override
  ChatParticipant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatParticipant(
      id: fields[0] as String,
      channelId: fields[1] as String,
      userId: fields[2] as String,
      role: fields[3] as String,
      joinedAt: fields[4] as DateTime,
      lastSeenAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatParticipant obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.lastSeenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParticipantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
