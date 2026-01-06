import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class ActivityService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ============ ACTIVITIES CRUD ============

  // Get all activities (teacher: all, student: published only)
  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // Check if user is teacher
      final teacherData = await supabase
          .from('profile_teacher')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final isTeacher = teacherData != null;

      if (isTeacher) {
        // Teacher sees all activities
        final activities = await supabase
            .from('activities')
            .select('''
              *,
              creator_profile:user_profiles!created_by(full_name, avatar_url)
            ''')
            .order('created_at', ascending: false);

        return activities;
      } else {
        // Student sees only published activities
        final activities = await supabase
            .from('activities')
            .select('''
              *,
              creator_profile:user_profiles!created_by(full_name, avatar_url)
            ''')
            .eq('status', 'published')
            .order('created_at', ascending: false);

        return activities;
      }
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

  // Create activity (teacher only)
  Future<bool> createActivity({
    required String title,
    required String description,
    String activityType = 'assignment',
    DateTime? dueDate,
    int maxScore = 100,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('activities').insert({
        'title': title,
        'description': description,
        'activity_type': activityType,
        'due_date': dueDate?.toIso8601String(),
        'max_score': maxScore,
        'created_by': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error creating activity: $e');
      return false;
    }
  }

  // Update activity (teacher only)
  Future<bool> updateActivity({
    required int id,
    required String title,
    required String description,
    String activityType = 'assignment',
    String status = 'draft',
    DateTime? dueDate,
    int maxScore = 100,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('activities')
          .update({
            'title': title,
            'description': description,
            'activity_type': activityType,
            'status': status,
            'due_date': dueDate?.toIso8601String(),
            'max_score': maxScore,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('created_by', user.id);

      return true;
    } catch (e) {
      print('Error updating activity: $e');
      return false;
    }
  }

  // Delete activity (teacher only)
  Future<bool> deleteActivity(int id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('activities')
          .delete()
          .eq('id', id)
          .eq('created_by', user.id);

      return true;
    } catch (e) {
      print('Error deleting activity: $e');
      return false;
    }
  }

  // Create activity from Activity model
  Future<bool> createActivityFromModel(Activity activity) async {
    try {
      await supabase.from('activities').insert(activity.toJson());
      return true;
    } catch (e) {
      print('Error creating activity from model: $e');
      return false;
    }
  }

  // Update activity from Activity model
  Future<bool> updateActivityFromModel(Activity activity) async {
    try {
      final id = activity.id;
      if (id == null) return false;

      final data = Map<String, dynamic>.from(activity.toJson());
      data.remove('id');

      await supabase.from('activities').update(data).eq('id', id);
      return true;
    } catch (e) {
      print('Error updating activity from model: $e');
      return false;
    }
  }

  // ============ HELPER METHODS ============

  Future<bool> isTeacher() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final teacherData = await supabase
        .from('profile_teacher')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return teacherData != null;
  }
}