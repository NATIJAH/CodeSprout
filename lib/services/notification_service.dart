/*import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // Get all notifications with teacher profile
      final notifications = await supabase
          .from('notifications')
          .select('''
            *,
            profile_teacher!created_by(full_name, email)
          ''')
          .order('created_at', ascending: false);

      // Get user's read status
      final statusData = await supabase
          .from('user_notification_status')
          .select()
          .eq('user_id', user.id);

      // Combine data
      List<Map<String, dynamic>> result = [];
      for (var notification in notifications) {
        final status = statusData.firstWhere(
          (s) => s['notification_id'] == notification['id'],
          orElse: () => {},
        );

        result.add({
          ...notification,
          'is_read': status['is_read'] ?? false,
          'read_at': status['read_at'],
          'is_deleted': status['is_deleted'] ?? false,
        });
      }

      // Filter out deleted notifications
      return result.where((n) => n['is_deleted'] == false).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Create notification
  Future<bool> createNotification({
    required String title,
    required String content,
    String? shortMessage,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('notifications').insert({
        'title': title,
        'content': content,
        'short_message': shortMessage,
        'created_by': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Update notification
  Future<bool> updateNotification({
    required int id,
    required String title,
    required String content,
    String? shortMessage,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('notifications')
          .update({
            'title': title,
            'content': content,
            'short_message': shortMessage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('created_by', user.id);

      return true;
    } catch (e) {
      print('Error updating notification: $e');
      return false;
    }
  }

  // Mark as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('user_notification_status')
          .upsert({
            'user_id': user.id,
            'notification_id': notificationId,
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // Check if user is teacher
      final teacherData = await supabase
          .from('profile_teacher')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (teacherData != null) {
        // Teacher: Delete from database
        await supabase
            .from('notifications')
            .delete()
            .eq('id', notificationId)
            .eq('created_by', user.id);
      } else {
        // Student: Mark as deleted
        await supabase
            .from('user_notification_status')
            .upsert({
              'user_id': user.id,
              'notification_id': notificationId,
              'is_deleted': true,
              'deleted_at': DateTime.now().toIso8601String(),
            });
      }

      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      final data = await supabase
          .from('user_notification_status')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false)
          .eq('is_deleted', false);

      return data.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}*/