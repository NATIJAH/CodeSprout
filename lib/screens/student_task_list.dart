// student_task_list.dart - Enhanced with Status Colors & Progress (Bahasa Melayu)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_task_submission.dart';

class StudentTaskList extends StatefulWidget {
  const StudentTaskList({super.key});

  @override
  State<StudentTaskList> createState() => _StudentTaskListState();
}

class _StudentTaskListState extends State<StudentTaskList> {
  final supabase = Supabase.instance.client;
  String filter = "all";
  String sortBy = "due_date";
  bool ascending = true;

  // Enhanced Color System
  static const matchaGreen = Color(0xFF7C9473);
  static const matchaLight = Color(0xFFA8B99E);
  static const matchaDark = Color(0xFF5A6C51);
  static const matchaBg = Color(0xFFF5F7F3);
  
  // Status Colors
  static const submittedGreen = Color(0xFF4CAF50);
  static const submittedGreenLight = Color(0xFFE8F5E9);
  static const overdueRed = Color(0xFFDC4C4C);
  static const overdueRedLight = Color(0xFFFFEBEE);
  static const pendingOrange = Color(0xFFE88D3D);
  static const pendingOrangeLight = Color(0xFFFFF3E0);

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Pengguna tidak disahkan');

      var query = supabase.from('Tasks').select();
      
      if (filter == "pending") {
        query = query.eq('status_text', 'pending');
      } else if (filter == "completed") {
        query = query.eq('status_text', 'completed');
      }

      final data = await query;
      List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(data);

      // Check submissions for each task
      for (var task in tasks) {
        final submission = await supabase
            .from('submissions')
            .select()
            .eq('task_id', task['id'])
            .eq('student_uid', currentUser.id)
            .maybeSingle();
        
        task['has_submission'] = submission != null;
        task['submission_status'] = submission?['status'];
      }

      tasks.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'due_date':
            final aDate = DateTime.tryParse(a['due_date'] ?? '') ?? DateTime(2100);
            final bDate = DateTime.tryParse(b['due_date'] ?? '') ?? DateTime(2100);
            comparison = aDate.compareTo(bDate);
            break;
          case 'priority':
            final priorityOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
            comparison = (priorityOrder[a['priority']] ?? 4)
                .compareTo(priorityOrder[b['priority']] ?? 4);
            break;
          case 'points':
            comparison = (a['points'] ?? 0).compareTo(b['points'] ?? 0);
            break;
          case 'title':
            comparison = (a['title'] ?? '').compareTo(b['title'] ?? '');
            break;
        }
        return ascending ? comparison : -comparison;
      });

      return tasks;
    } catch (e) {
      print('Ralat mendapatkan tugasan: $e');
      return [];
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent': return const Color(0xFFDC4C4C);
      case 'High': return const Color(0xFFE88D3D);
      case 'Medium': return matchaGreen;
      case 'Low': return matchaLight;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Assignment': return Icons.assignment_outlined;
      case 'Homework': return Icons.home_work_outlined;
      case 'Project': return Icons.work_outline;
      case 'Quiz': return Icons.quiz_outlined;
      case 'Reading': return Icons.menu_book_outlined;
      case 'Lab Work': return Icons.science_outlined;
      default: return Icons.task_alt_outlined;
    }
  }

  Map<String, dynamic> _getTaskStatus(Map<String, dynamic> task) {
    final dueDate = task['due_date'] != null ? DateTime.tryParse(task['due_date']) : null;
    final hasSubmission = task['has_submission'] == true;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    if (hasSubmission) {
      return {
        'label': 'Telah Dihantar',
        'icon': Icons.check_circle,
        'color': submittedGreen,
        'bgColor': submittedGreenLight,
        'borderColor': submittedGreen,
      };
    } else if (isOverdue) {
      return {
        'label': 'Lewat',
        'icon': Icons.error,
        'color': overdueRed,
        'bgColor': overdueRedLight,
        'borderColor': overdueRed,
      };
    } else {
      return {
        'label': 'Belum Selesai',
        'icon': Icons.pending_outlined,
        'color': pendingOrange,
        'bgColor': pendingOrangeLight,
        'borderColor': pendingOrange.withOpacity(0.3),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: matchaBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: matchaDark,
            elevation: 0,
            title: const Text(
              "Tugasan Saya",
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(filter == 'all' ? 'Semua' : filter == 'pending' ? 'Belum Selesai' : 'Selesai'),
                  selected: filter != 'all',
                  selectedColor: matchaLight,
                  backgroundColor: Colors.white,
                  onSelected: (_) => _showFilterMenu(context),
                  side: BorderSide(color: matchaLight.withOpacity(0.3)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  avatar: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                  label: Text(_getSortLabel()),
                  selected: sortBy != 'due_date',
                  selectedColor: matchaLight,
                  backgroundColor: Colors.white,
                  onSelected: (_) => _showSortMenu(context),
                  side: BorderSide(color: matchaLight.withOpacity(0.3)),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                padding: EdgeInsets.all(isWideScreen ? 32 : 16),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(64.0),
                          child: CircularProgressIndicator(color: matchaGreen, strokeWidth: 3),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(() => setState(() {}));
                    }

                    final tasks = snapshot.data ?? [];

                    if (tasks.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Add stats summary
                    return Column(
                      children: [
                        _buildStatsBar(tasks),
                        const SizedBox(height: 24),
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
                                itemCount: tasks.length,
                                itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<Map<String, dynamic>> tasks) {
    final submitted = tasks.where((t) => t['has_submission'] == true).length;
    final overdue = tasks.where((t) {
      final dueDate = t['due_date'] != null ? DateTime.tryParse(t['due_date']) : null;
      return dueDate != null && dueDate.isBefore(DateTime.now()) && t['has_submission'] != true;
    }).length;
    final pending = tasks.length - submitted - overdue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: matchaLight.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: matchaDark.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: matchaGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Ringkasan Tugasan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Dihantar',
                  count: submitted,
                  total: tasks.length,
                  color: submittedGreen,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.pending_outlined,
                  label: 'Belum Selesai',
                  count: pending,
                  total: tasks.length,
                  color: pendingOrange,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.error,
                  label: 'Lewat',
                  count: overdue,
                  total: tasks.length,
                  color: overdueRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (submitted > 0)
                    Expanded(
                      flex: submitted,
                      child: Container(color: submittedGreen),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(color: pendingOrange),
                    ),
                  if (overdue > 0)
                    Expanded(
                      flex: overdue,
                      child: Container(color: overdueRed),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = _getTaskStatus(task);
    final dueDate = task['due_date'] != null ? DateTime.tryParse(task['due_date']) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status['borderColor'],
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: status['color'].withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentTaskSubmission(task: task)),
            ).then((_) => setState(() {}));
          },
          child: Column(
            children: [
              // Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: status['bgColor'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(status['icon'], size: 16, color: status['color']),
                    const SizedBox(width: 8),
                    Text(
                      status['label'],
                      style: TextStyle(
                        color: status['color'],
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task['priority']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['priority'] ?? 'Medium',
                        style: TextStyle(
                          color: _getPriorityColor(task['priority']),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Task Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: matchaBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(task['category']),
                            size: 22,
                            color: matchaDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'] ?? 'Tiada Tajuk',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: matchaDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                task['category'] ?? 'Tugasan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (dueDate != null)
                          _buildInfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                            color: matchaGreen,
                          ),
                        if (task['points'] != null)
                          _buildInfoChip(
                            icon: Icons.stars_outlined,
                            label: '${task['points']} mata',
                            color: const Color(0xFFE88D3D),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
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

  String _getSortLabel() {
    switch (sortBy) {
      case 'due_date': return 'Tarikh Akhir';
      case 'priority': return 'Keutamaan';
      case 'points': return 'Mata';
      case 'title': return 'Tajuk';
      default: return 'Susun';
    }
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tapis Tugasan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _buildFilterOption('all', 'Semua Tugasan', Icons.all_inclusive),
            _buildFilterOption('pending', 'Belum Selesai', Icons.pending_actions),
            _buildFilterOption('completed', 'Selesai', Icons.check_circle_outline),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Susun Mengikut', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _buildSortOption('due_date', 'Tarikh Akhir', Icons.calendar_today_outlined),
            _buildSortOption('priority', 'Keutamaan', Icons.flag_outlined),
            _buildSortOption('points', 'Mata', Icons.stars_outlined),
            _buildSortOption('title', 'Tajuk', Icons.sort_by_alpha),
            const Divider(height: 32),
            ListTile(
              leading: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, color: matchaGreen),
              title: Text(ascending ? 'Menaik' : 'Menurun'),
              trailing: Switch(
                value: ascending,
                activeColor: matchaGreen,
                onChanged: (value) {
                  setState(() => ascending = value);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => ascending = !ascending);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String value, String label, IconData icon) {
    final isSelected = filter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? matchaGreen : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: matchaGreen) : null,
      tileColor: isSelected ? matchaBg : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => filter = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? matchaGreen : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: matchaGreen) : null,
      tileColor: isSelected ? matchaBg : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        setState(() => sortBy = value);
        Navigator.pop(context);
      },
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
              decoration: const BoxDecoration(color: matchaBg, shape: BoxShape.circle),
              child: Icon(
                filter == 'completed' ? Icons.check_circle_outline : Icons.task_alt_outlined,
                size: 64,
                color: matchaLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filter == 'completed'
                  ? "Tiada tugasan selesai lagi"
                  : filter == 'pending'
                      ? "Tiada tugasan belum selesai"
                      : "Tiada tugasan diberikan",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Semak semula nanti untuk tugasan baru",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            const Text('Tidak dapat memuatkan tugasan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Sila semak sambungan anda dan cuba lagi',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Cuba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: matchaGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}