import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

// ============= TASK SERVICE =============
class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current student ID
  String? get currentStudentId => _supabase.auth.currentUser?.id;

  // ============= ALL DASHBOARD DATA IN ONE CALL =============

  /// Get all dashboard data in a single call (more efficient)
  Future<DashboardData> getDashboardData() async {
    try {
      // Fetch all tasks at once
      final allTasks = await _supabase
          .from('tasks')
          .select('*')
          .order('created_timestamp', ascending: false);

      final tasks = List<Map<String, dynamic>>.from(allTasks);
      
      // DEBUG: Print untuk check
      debugPrint('========== TASK SERVICE DEBUG ==========');
      debugPrint('Total tasks fetched: ${tasks.length}');

      // Categorize tasks
      // TUGASAN = Assignment + Homework
      final assignments = tasks.where((t) => 
        t['category'] == 'Assignment' || t['category'] == 'Homework'
      ).toList();
      
      // LATIHAN = Quiz + Lab Work
      final quizzes = tasks.where((t) => t['category'] == 'Quiz').toList();
      final labWorks = tasks.where((t) => t['category'] == 'Lab Work').toList();
      
      // AKTIVITI = Project + Other
      final projects = tasks.where((t) => t['category'] == 'Project').toList();
      final others = tasks.where((t) => t['category'] == 'Other').toList();

      // DEBUG
      debugPrint('Assignments + Homework: ${assignments.length}');
      debugPrint('Quiz: ${quizzes.length}, Lab Work: ${labWorks.length}');
      debugPrint('Projects: ${projects.length}, Other: ${others.length}');

      // Counts
      final tugasanCount = assignments.length;
      final latihanCount = quizzes.length + labWorks.length;
      final aktivitiCount = projects.length + others.length;
      final totalCount = tugasanCount + latihanCount + aktivitiCount;

      // Pending counts (status_text != 'completed')
      final tugasanPending = assignments.where((t) => t['status_text'] != 'completed').length;
      final latihanPending = [...quizzes, ...labWorks].where((t) => t['status_text'] != 'completed').length;

      // Completed counts
      final tugasanCompleted = assignments.where((t) => t['status_text'] == 'completed').length;
      final latihanCompleted = [...quizzes, ...labWorks].where((t) => t['status_text'] == 'completed').length;
      final aktivitiCompleted = [...projects, ...others].where((t) => t['status_text'] == 'completed').length;

      // DEBUG
      debugPrint('Tugasan - Total: $tugasanCount, Pending: $tugasanPending, Completed: $tugasanCompleted');
      debugPrint('Latihan - Total: $latihanCount, Pending: $latihanPending, Completed: $latihanCompleted');
      debugPrint('Aktiviti - Total: $aktivitiCount, Completed: $aktivitiCompleted');

      // Progress calculations (0.0 to 1.0)
      final tugasanProgress = tugasanCount > 0 ? tugasanCompleted / tugasanCount : 0.0;
      final latihanProgress = latihanCount > 0 ? latihanCompleted / latihanCount : 0.0;
      final aktivitiProgress = aktivitiCount > 0 ? aktivitiCompleted / aktivitiCount : 0.0;

      // Percentages for pie chart (0 to 100)
      final tugasanPercent = totalCount > 0 ? (tugasanCount / totalCount) * 100 : 0.0;
      final latihanPercent = totalCount > 0 ? (latihanCount / totalCount) * 100 : 0.0;
      final aktivitiPercent = totalCount > 0 ? (aktivitiCount / totalCount) * 100 : 0.0;

      // Recent tasks (last 5)
      final recentTasks = tasks.take(5).toList();

      debugPrint('========== END DEBUG ==========');

      return DashboardData(
        tugasanPending: tugasanPending,
        latihanPending: latihanPending,
        tugasanProgress: tugasanProgress,
        latihanProgress: latihanProgress,
        aktivitiProgress: aktivitiProgress,
        tugasanPercent: tugasanPercent,
        latihanPercent: latihanPercent,
        aktivitiPercent: aktivitiPercent,
        tugasanCount: tugasanCount,
        latihanCount: latihanCount,
        aktivitiCount: aktivitiCount,
        totalTasks: totalCount,
        recentTasks: recentTasks,
      );
    } catch (e) {
      debugPrint('Error getDashboardData: $e');
      return DashboardData.empty();
    }
  }

  // ============= INDIVIDUAL METHODS (Optional) =============

  /// Get recent tasks
  Future<List<Map<String, dynamic>>> getRecentTasks({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .order('created_timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getRecentTasks: $e');
      return [];
    }
  }
}

// ============= DASHBOARD DATA MODEL =============
class DashboardData {
  final int tugasanPending;
  final int latihanPending;
  final double tugasanProgress;
  final double latihanProgress;
  final double aktivitiProgress;
  final double tugasanPercent;
  final double latihanPercent;
  final double aktivitiPercent;
  final int tugasanCount;
  final int latihanCount;
  final int aktivitiCount;
  final int totalTasks;
  final List<Map<String, dynamic>> recentTasks;

  DashboardData({
    required this.tugasanPending,
    required this.latihanPending,
    required this.tugasanProgress,
    required this.latihanProgress,
    required this.aktivitiProgress,
    required this.tugasanPercent,
    required this.latihanPercent,
    required this.aktivitiPercent,
    required this.tugasanCount,
    required this.latihanCount,
    required this.aktivitiCount,
    required this.totalTasks,
    required this.recentTasks,
  });

  factory DashboardData.empty() {
    return DashboardData(
      tugasanPending: 0,
      latihanPending: 0,
      tugasanProgress: 0.0,
      latihanProgress: 0.0,
      aktivitiProgress: 0.0,
      tugasanPercent: 0.0,
      latihanPercent: 0.0,
      aktivitiPercent: 0.0,
      tugasanCount: 0,
      latihanCount: 0,
      aktivitiCount: 0,
      totalTasks: 0,
      recentTasks: [],
    );
  }
}