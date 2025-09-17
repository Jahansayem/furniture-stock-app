// This file exists only to prevent compilation errors.
// Chat features have been removed from the application.

import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 12)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  ChatMessage({required this.id});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(id: json['id'] ?? '');
  }

  Map<String, dynamic> toJson() => {'id': id};
}

@HiveType(typeId: 13)
class MessageReaction extends HiveObject {
  @HiveField(0)
  String id;

  MessageReaction({required this.id});

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(id: json['id'] ?? '');
  }

  Map<String, dynamic> toJson() => {'id': id};
}