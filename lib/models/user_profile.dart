class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCheckedIn;
  final DateTime? lastCheckedInAt;
  final DateTime? lastCheckedOutAt;
  final double? lastKnownLatitude;
  final double? lastKnownLongitude;
  final String? lastKnownAddress;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.isCheckedIn = false,
    this.lastCheckedInAt,
    this.lastCheckedOutAt,
    this.lastKnownLatitude,
    this.lastKnownLongitude,
    this.lastKnownAddress,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      lastCheckedInAt: json['last_checked_in_at'] != null
          ? DateTime.parse(json['last_checked_in_at'] as String)
          : null,
      lastCheckedOutAt: json['last_checked_out_at'] != null
          ? DateTime.parse(json['last_checked_out_at'] as String)
          : null,
      lastKnownLatitude: json['last_known_latitude'] as double?,
      lastKnownLongitude: json['last_known_longitude'] as double?,
      lastKnownAddress: json['last_known_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_checked_in': isCheckedIn,
      'last_checked_in_at': lastCheckedInAt?.toIso8601String(),
      'last_checked_out_at': lastCheckedOutAt?.toIso8601String(),
      'last_known_latitude': lastKnownLatitude,
      'last_known_longitude': lastKnownLongitude,
      'last_known_address': lastKnownAddress,
    };
  }

  String get displayName => fullName ?? email.split('@').first;

  String get roleDisplayName {
    switch (role) {
      case 'packaging_expert':
        return 'Packaging Expert';
      case 'owner':
        return 'Owner';
      case 'stock_mover':
        return 'Stock Mover';
      default:
        return role
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  // Helper methods for location and check-in/out status
  bool get hasLocation =>
      lastKnownLatitude != null && lastKnownLongitude != null;

  String get checkInStatus {
    if (isCheckedIn) {
      return 'Checked In';
    } else if (lastCheckedOutAt != null) {
      return 'Checked Out';
    } else {
      return 'Never Checked In';
    }
  }

  String get lastActivityTime {
    final DateTime? lastActivity =
        isCheckedIn ? lastCheckedInAt : lastCheckedOutAt;
    if (lastActivity == null) return 'No activity';

    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profilePictureUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCheckedIn,
    DateTime? lastCheckedInAt,
    DateTime? lastCheckedOutAt,
    double? lastKnownLatitude,
    double? lastKnownLongitude,
    String? lastKnownAddress,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      lastCheckedInAt: lastCheckedInAt ?? this.lastCheckedInAt,
      lastCheckedOutAt: lastCheckedOutAt ?? this.lastCheckedOutAt,
      lastKnownLatitude: lastKnownLatitude ?? this.lastKnownLatitude,
      lastKnownLongitude: lastKnownLongitude ?? this.lastKnownLongitude,
      lastKnownAddress: lastKnownAddress ?? this.lastKnownAddress,
    );
  }
}
