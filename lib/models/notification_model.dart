class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String? shortMessage;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final Map<String, dynamic>? teacherProfile;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    this.shortMessage,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.teacherProfile,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      shortMessage: json['short_message'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      teacherProfile: json['profile_teacher'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'short_message': shortMessage,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'profile_teacher': teacherProfile,
    };
  }
}