// teacher_task_list.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_add_task.dart';
import 'teacher_edit_task.dart';
import 'teacher_completed_task.dart';

// Matcha Colors
class MatchaColors {
  static const primary = Color(0xFF7C9473);
  static const light = Color(0xFFA8B99E);
  static const dark = Color(0xFF5A6C51);
  static const background = Color(0xFFF5F7F3);
  static const accent = Color(0xFFB8C5A8);
  static const surface = Colors.white;
}

class TeacherTaskList extends StatefulWidget {
  const TeacherTaskList({super.key});

  @override
  State<TeacherTaskList> createState() => _TeacherTaskListState();
}

class _TeacherTaskListState extends State<TeacherTaskList> {
  final supabase = Supabase.instance.client;
  Map<String, String> studentNames = {};
  bool _isLoading = true;
  int _pendingCount = 0;
  int _completedCount = 0;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchTasks();
  }

  Future<void> fetchStudents() async {
    final data = await supabase.from('profile_student').select('uid, name');
    final Map<String, String> map = {};
    for (var s in data) {
      final uid = s['uid']?.toString();
      final name = s['name']?.toString() ?? 'Tanpa Nama';
      if (uid != null) map[uid] = name;
    }
    setState(() {
      studentNames = map;
    });
  }

  Future<void> fetchTasks() async {
    setState(() => _isLoading = true);

    final pendingData =
        await supabase.from('Tasks').select().eq('status_text', 'pending');
    final completedData =
        await supabase.from('Tasks').select().eq('status_text', 'completed');

    setState(() {
      _tasks = List<Map<String, dynamic>>.from(pendingData);
      _pendingCount = pendingData.length;
      _completedCount = completedData.length;
      _isLoading = false;
    });
  }

  Future<void> markTaskAsCompleted(Map<String, dynamic> task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tandakan Selesai',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tandakan "${task['title']?.toString() ?? 'Tiada Tajuk'}" sebagai selesai?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MatchaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('Tasks').update({
        'status_text': 'completed',
        'completed_timestamp': DateTime.now().toIso8601String(),
      }).eq('id', task['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Tugasan ditandakan sebagai selesai'),
              ],
            ),
            backgroundColor: MatchaColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      fetchTasks();
    }
  }

  Future<void> deleteTask(Map<String, dynamic> task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Padam Tugasan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Adakah anda pasti mahu memadam "${task['title']?.toString() ?? 'Tiada Tajuk'}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC4C4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Padam'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('Tasks').delete().eq('id', task['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Tugasan berjaya dipadam'),
              ],
            ),
            backgroundColor: const Color(0xFFDC4C4C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      fetchTasks();
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent':
        return const Color(0xFFDC4C4C);
      case 'High':
        return const Color(0xFFE88D3D);
      case 'Medium':
        return MatchaColors.primary;
      case 'Low':
        return MatchaColors.light;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Assignment':
        return Icons.assignment_outlined;
      case 'Homework':
        return Icons.home_work_outlined;
      case 'Project':
        return Icons.work_outline;
      case 'Quiz':
        return Icons.quiz_outlined;
      case 'Reading':
        return Icons.menu_book_outlined;
      case 'Lab Work':
        return Icons.science_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: MatchaColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherAddTask()),
          );
          fetchTasks();
        },
        backgroundColor: MatchaColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tugasan Baru'),
        elevation: 4,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: MatchaColors.surface,
            foregroundColor: MatchaColors.dark,
            title: const Text(
              'Senarai Tugasan',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Lihat Tugasan Selesai',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherCompletedTask(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                child: Column(
                  children: [
                    // Stats Cards
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(64.0),
                            child: CircularProgressIndicator(
                              color: MatchaColors.primary,
                              strokeWidth: 3,
                            ),
                          )
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatCard(
                                icon: Icons.pending_actions_outlined,
                                label: 'Belum Selesai',
                                count: _pendingCount,
                                color: const Color(0xFFE88D3D),
                                gradient: [
                                  const Color(0xFFE88D3D).withOpacity(0.1),
                                  const Color(0xFFE88D3D).withOpacity(0.05),
                                ],
                              ),
                              _buildStatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Selesai',
                                count: _completedCount,
                                color: MatchaColors.primary,
                                gradient: [
                                  MatchaColors.primary.withOpacity(0.1),
                                  MatchaColors.primary.withOpacity(0.05),
                                ],
                              ),
                              _buildStatCard(
                                icon: Icons.emoji_events_outlined,
                                label: 'Jumlah',
                                count: _pendingCount + _completedCount,
                                color: const Color(0xFF9B7EBD),
                                gradient: [
                                  const Color(0xFF9B7EBD).withOpacity(0.1),
                                  const Color(0xFF9B7EBD).withOpacity(0.05),
                                ],
                              ),
                            ],
                          ),

                    const SizedBox(height: 40),

                    // Task List
                    if (_isLoading)
                      const SizedBox()
                    else if (_tasks.isEmpty)
                      _buildEmptyState()
                    else
                      isWideScreen
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                              ),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
                            ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final studentName = studentNames[task['student_uid']] ?? 'Semua Pelajar';
    final title = task['title']?.toString() ?? 'Tiada Tajuk';
    final dueDate = task['due_date'] != null
        ? DateTime.tryParse(task['due_date'])
        : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: MatchaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFDC4C4C).withOpacity(0.3)
              : MatchaColors.light.withOpacity(0.2),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: MatchaColors.dark.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherEditTask(task: task),
              ),
            );
            fetchTasks();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MatchaColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(task['category']),
                        size: 22,
                        color: MatchaColors.dark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: MatchaColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            studentName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task['priority']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task['priority'] ?? 'Medium',
                        style: TextStyle(
                          color: _getPriorityColor(task['priority']),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task['description_text'] != null &&
                    task['description_text'].toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    task['description_text'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (dueDate != null)
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          color: isOverdue ? const Color(0xFFDC4C4C) : MatchaColors.primary,
                        ),
                      ),
                    if (task['points'] != null) ...[
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        icon: Icons.stars_outlined,
                        label: '${task['points']} mata',
                        color: const Color(0xFFE88D3D),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => markTaskAsCompleted(task),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Selesai'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MatchaColors.primary,
                          side: BorderSide(color: MatchaColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => deleteTask(task),
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFDC4C4C),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFDC4C4C).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC4C4C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Color(0xFFDC4C4C)),
                        SizedBox(width: 6),
                        Text(
                          'Tarikh akhir telah berlalu',
                          style: TextStyle(
                            color: Color(0xFFDC4C4C),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: MatchaColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_outlined,
                size: 64,
                color: MatchaColors.light,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tiada tugasan belum selesai",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Klik butang + untuk menambah tugasan baru",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}