// services/notification_service.dart
// UPDATED - Match dengan existing table structure

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============= NOTIFICATION FUNCTIONS =============

  // Get all notifications for current user (stream for realtime)
  Stream<List<NotificationModel>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    print('🔔 Setting up notifications stream for user: $userId');

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
      print('📨 Notifications stream data: ${data.length} notifications');
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    });
  }

  // Get unread count (stream for realtime badge)
  Stream<int> getUnreadCount() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((notifications) {
      return notifications.where((n) => n['is_read'] == false).length;
    });
  }

  // Get notifications (one-time fetch)
  Future<List<NotificationModel>> getNotifications({int limit = 20}) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      print('📋 Getting notifications for user: $userId');

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      print('📋 Found ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  // Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('📖 Marking notification as read: $notificationId');

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', currentUserId);

      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      print('📖 Marking all notifications as read');

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('🗑️ Deleting notification: $notificationId');

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', currentUserId);

      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      print('🗑️ Clearing all notifications');

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  // ============= CREATE NOTIFICATION HELPERS =============

  // Create notification (general) - UPDATED untuk match table structure
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'system',
    String? senderId,
    String? senderType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔔 Creating notification for user: $userId');

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'sender_id': senderId,
        'sender_type': senderType,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata ?? {},
        'is_read': false,
      });

      print('✅ Notification created');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // Create chat notification
  Future<void> createChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String senderType, // 'teacher' or 'student'
    required String messagePreview,
    String? conversationId,
  }) async {
    await createNotification(
      userId: receiverId,
      title: 'Mesej baru dari $senderName',
      message: messagePreview.length > 50 
          ? '${messagePreview.substring(0, 50)}...' 
          : messagePreview,
      type: 'chat',
      senderId: senderId,
      senderType: senderType,
      entityType: 'conversation',
      entityId: conversationId,
      metadata: {'sender_name': senderName},
    );
  }

  // Create assignment notification (for students)
  Future<void> createAssignmentNotification({
    required String studentId,
    required String teacherId,
    required String assignmentTitle,
    required String teacherName,
    String? taskId,
  }) async {
    await createNotification(
      userId: studentId,
      title: 'Tugasan Baru',
      message: '$teacherName telah menambah tugasan: $assignmentTitle',
      type: 'assignment',
      senderId: teacherId,
      senderType: 'teacher',
      entityType: 'task',
      entityId: taskId,
      metadata: {'teacher_name': teacherName, 'task_title': assignmentTitle},
    );
  }

  // Create submission notification (for teachers)
  Future<void> createSubmissionNotification({
    required String teacherId,
    required String studentId,
    required String studentName,
    required String assignmentTitle,
    String? submissionId,
    String? taskId,
  }) async {
    await createNotification(
      userId: teacherId,
      title: 'Submission Baru',
      message: '$studentName telah menghantar: $assignmentTitle',
      type: 'submission',
      senderId: studentId,
      senderType: 'student',
      entityType: 'submission',
      entityId: submissionId,
      metadata: {
        'student_name': studentName, 
        'task_title': assignmentTitle,
        'task_id': taskId,
      },
    );
  }

  // Create announcement notification
  Future<void> createAnnouncementNotification({
    required String userId,
    required String senderId,
    required String senderType,
    required String title,
    required String message,
    String? announcementId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Pengumuman: $title',
      message: message,
      type: 'announcement',
      senderId: senderId,
      senderType: senderType,
      entityType: 'announcement',
      entityId: announcementId,
    );
  }

  // Create reminder notification
  Future<void> createReminderNotification({
    required String userId,
    required String title,
    required String message,
    String? eventId,
  }) async {
    await createNotification(
      userId: userId,
      title: '⏰ Peringatan: $title',
      message: message,
      type: 'reminder',
      entityType: 'event',
      entityId: eventId,
    );
  }

  // Bulk create notifications (for sending to multiple users)
  Future<void> createBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    String type = 'system',
    String? senderId,
    String? senderType,
    String? entityType,
    String? entityId,
  }) async {
    try {
      print('🔔 Creating bulk notifications for ${userIds.length} users');

      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'sender_id': senderId,
        'sender_type': senderType,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': {},
        'is_read': false,
      }).toList();

      await _supabase.from('notifications').insert(notifications);

      print('✅ Bulk notifications created');
    } catch (e) {
      print('❌ Error creating bulk notifications: $e');
    }
  }
}