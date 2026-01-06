// models/notification_model.dart
// UPDATED - Match dengan existing table structure

class NotificationModel {
  final String id;
  final String? userId;          // recipient
  final String title;
  final String message;
  final String type;
  final String? senderId;        // siapa hantar
  final String? senderType;      // 'teacher', 'student', 'system'
  final String? entityType;      // 'task', 'submission', 'chat', etc
  final String? entityId;        // reference id
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.senderId,
    this.senderType,
    this.entityType,
    this.entityId,
    this.metadata = const {},
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      metadata: json['metadata'] ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'sender_id': senderId,
      'sender_type': senderType,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  // For inserting new notification
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'sender_id': senderId,
      'sender_type': senderType,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? senderId,
    String? senderType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper method to get icon based on notification type
  String get iconName {
    switch (type) {
      case 'chat':
        return 'chat';
      case 'assignment':
        return 'assignment';
      case 'submission':
        return 'upload_file';
      case 'announcement':
        return 'campaign';
      case 'reminder':
        return 'alarm';
      case 'system':
      default:
        return 'notifications';
    }
  }

  // Helper method to get color based on notification type
  int get colorValue {
    switch (type) {
      case 'chat':
        return 0xFF42A5F5; // Blue
      case 'assignment':
        return 0xFF66BB6A; // Green
      case 'submission':
        return 0xFF9C27B0; // Purple
      case 'announcement':
        return 0xFFFF9800; // Orange
      case 'reminder':
        return 0xFFFF6B6B; // Red
      case 'system':
      default:
        return 0xFF6B9B7F; // Theme green
    }
  }

  // Helper to format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}