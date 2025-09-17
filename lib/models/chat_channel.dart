import 'package:hive/hive.dart';

part 'chat_channel.g.dart';

@HiveType(typeId: 10)
class ChatChannel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String type; // 'public', 'private', 'direct'

  @HiveField(4)
  List<String> participants;

  @HiveField(5)
  String? lastMessageId;

  @HiveField(6)
  DateTime? lastMessageAt;

  @HiveField(7)
  String createdBy;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  ChatChannel({
    required this.id,
    required this.name,
    this.description,
    this.type = 'public',
    this.participants = const [],
    this.lastMessageId,
    this.lastMessageAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'public',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessageId: json['last_message_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'participants': participants,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    List<String>? participants,
    String? lastMessageId,
    DateTime? lastMessageAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@HiveType(typeId: 11)
class ChatParticipant extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String channelId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  String role; // 'admin', 'member'

  @HiveField(4)
  DateTime joinedAt;

  @HiveField(5)
  DateTime? lastSeenAt;

  ChatParticipant({
    required this.id,
    required this.channelId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.lastSeenAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}