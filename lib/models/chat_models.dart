class ChatUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'student' or 'teacher'

  ChatUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
    );
  }
}

class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? user1Email;
  final String? user2Email;
  final String? user1Name;
  final String? user2Name;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageTime,
    this.user1Email,
    this.user2Email,
    this.user1Name,
    this.user2Name,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      user1Id: json['user1_id'] ?? '',
      user2Id: json['user2_id'] ?? '',
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      user1Email: json['user1_email'],
      user2Email: json['user2_email'],
      user1Name: json['user1_name'],
      user2Name: json['user2_name'],
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final String? senderEmail;
  final String? senderName;
  final String type; // 'text' or 'system'
  final String? groupId;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.senderEmail,
    this.senderName,
    this.type = 'text',
    this.groupId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      senderEmail: json['sender_email'],
      senderName: json['sender_name'],
      type: json['type'] ?? 'text',
      groupId: json['group_id'],
    );
  }
}

// NEW: Group model
class Group {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int memberCount;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.memberCount = 0,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      memberCount: json['member_count'] ?? 0,
    );
  }
}

// NEW: Group member model
class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final bool isAdmin;
  final DateTime joinedAt;
  final String? userName;
  final String? userEmail;
  final String? userRole;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.isAdmin,
    required this.joinedAt,
    this.userName,
    this.userEmail,
    this.userRole,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      userId: json['user_id'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
      userName: json['user_name'],
      userEmail: json['user_email'],
      userRole: json['user_role'],
    );
  }
}