import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetch all activities with submission status for the current user
  Future<Map<String, dynamic>> fetchActivitiesWithSubmissionStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'activities': [], 'submitted': [], 'notSubmitted': [], 'performance': []};

    try {
      // Fetch all activities
      final activitiesRes = await supabase
          .from('activity')
          .select()
          .order('created_at', ascending: false);
      final activities = List<Map<String, dynamic>>.from(activitiesRes ?? []);

      // Fetch submitted performance records for this user
      final submittedRes = await supabase
          .from('student_performance')
          .select()
          .eq('student_id', user.id);
      final submitted = List<Map<String, dynamic>>.from(submittedRes ?? []);

      // Separate submitted and not-submitted
      final submittedIds = submitted.map((p) => p['activity_id']).toSet();
      final notSubmitted = activities.where((a) => !submittedIds.contains(a['id'])).toList();
      final submittedActivities = activities.where((a) => submittedIds.contains(a['id'])).toList();

      return {
        'activities': activities,
        'submitted': submittedActivities,
        'notSubmitted': notSubmitted,
        'performance': submitted,
      };
    } catch (e) {
      return {'activities': [], 'submitted': [], 'notSubmitted': [], 'performance': []};
    }
  }

  /// Fetch current user's performance records only
  Future<List<Map<String, dynamic>>> fetchMyPerformance() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final res = await supabase
        .from('student_performance')
        .select()
        .eq('student_id', user.id)
        .order('recorded_at', ascending: false);

    return List<Map<String, dynamic>>.from(res ?? []);
  }

  Future<void> upsertPerformance({
    required String studentId,
    required int activityId,
    required int score,
    required int maxScore,
    String? feedback,
  }) async {
    await supabase.from('student_performance').upsert({
      'student_id': studentId,
      'activity_id': activityId,
      'score': score,
      'max_score': maxScore,
      'feedback': feedback,
    });
  }

  /// Fetch all students' performance (for teachers)
  Future<List<Map<String, dynamic>>> fetchAllStudentsPerformance() async {
    try {
      final res = await supabase
          .from('student_performance')
          .select()
          .order('recorded_at', ascending: false);
      return List<Map<String, dynamic>>.from(res ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Fetch class performance summary with stats
  Future<Map<String, dynamic>> fetchClassPerformanceSummary() async {
    try {
      final perfRes = await supabase
          .from('student_performance')
          .select()
          .order('recorded_at', ascending: false);
      final performance = List<Map<String, dynamic>>.from(perfRes ?? []);

      if (performance.isEmpty) {
        return {
          'totalRecords': 0,
          'averageScore': 0.0,
          'averagePercentage': 0.0,
          'gradeDistribution': {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0},
          'atRiskStudents': [],
        };
      }

      // Calculate stats
      final totalRecords = performance.length;
      double sumScore = 0;
      double sumPercentage = 0;
      int countWithPercentage = 0;
      final gradeDistribution = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0, 'E': 0, 'F': 0};
      final atRiskStudents = <Map<String, dynamic>>[]; // score < 50%

      for (final p in performance) {
        final score = p['score'] as int? ?? 0;
        final maxScore = p['max_score'] as int? ?? 1;
        final percentage = p['percentage'] as double? ?? 0;
        final grade = p['grade'] as String? ?? 'F';

        sumScore += score;
        if (percentage > 0) {
          sumPercentage += percentage;
          countWithPercentage++;
        }

        // Count grades
        if (gradeDistribution.containsKey(grade)) {
          gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
        }

        // Identify at-risk students (percentage < 50%)
        if (percentage < 50) {
          atRiskStudents.add(p);
        }
      }

      final averageScore = totalRecords > 0 ? sumScore / totalRecords : 0.0;
      final averagePercentage = countWithPercentage > 0 ? sumPercentage / countWithPercentage : 0.0;

      return {
        'totalRecords': totalRecords,
        'averageScore': averageScore.toStringAsFixed(2),
        'averagePercentage': averagePercentage.toStringAsFixed(2),
        'gradeDistribution': gradeDistribution,
        'atRiskStudents': atRiskStudents,
      };
    } catch (e) {
      return {
        'totalRecords': 0,
        'averageScore': 0,
        'averagePercentage': 0,
        'gradeDistribution': {},
        'atRiskStudents': [],
      };
    }
  }
}