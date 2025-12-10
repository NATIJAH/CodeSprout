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
  String filter = "all"; // all, pending, completed
  String sortBy = "due_date"; // due_date, priority, points, title
  bool ascending = true;

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('✅ Current user ID: ${currentUser.id}');
      print('📋 Fetching tasks with filter: $filter');

      // Fetch ALL tasks first (for debugging)
      final allTasks = await supabase.from('Tasks').select();
      print('📊 Total tasks in database: ${allTasks.length}');
      
      if (allTasks.isNotEmpty) {
        print('Sample task: ${allTasks.first}');
      }

      // Fetch tasks - remove student_uid filter to see all tasks
      // (Teachers don't assign to specific students in current setup)
      var query = supabase.from('Tasks').select();

      // Apply status filter
      if (filter == "pending") {
        query = query.eq('status_text', 'pending');
      } else if (filter == "completed") {
        query = query.eq('status_text', 'completed');
      }

      final data = await query;
      print('✅ Fetched ${data.length} tasks after filter');
      
      List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(data);

      // Sort tasks
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
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Assignment':
        return Icons.assignment;
      case 'Homework':
        return Icons.home_work;
      case 'Project':
        return Icons.work;
      case 'Quiz':
        return Icons.quiz;
      case 'Reading':
        return Icons.menu_book;
      case 'Lab Work':
        return Icons.science;
      default:
        return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        backgroundColor: const Color(0xff5b7cff),
        actions: [
          // Filter Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                filter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "all",
                child: Row(
                  children: [
                    Icon(filter == 'all' ? Icons.check : Icons.all_inclusive, size: 20),
                    const SizedBox(width: 8),
                    const Text("All Tasks"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "pending",
                child: Row(
                  children: [
                    Icon(filter == 'pending' ? Icons.check : Icons.pending_actions, size: 20),
                    const SizedBox(width: 8),
                    const Text("Pending"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "completed",
                child: Row(
                  children: [
                    Icon(filter == 'completed' ? Icons.check : Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    const Text("Completed"),
                  ],
                ),
              ),
            ],
          ),
          // Sort Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == 'toggle_order') {
                  ascending = !ascending;
                } else {
                  sortBy = value;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'due_date',
                child: Row(
                  children: [
                    Icon(sortBy == 'due_date' ? Icons.check : Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sort by Due Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'priority',
                child: Row(
                  children: [
                    Icon(sortBy == 'priority' ? Icons.check : Icons.flag, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sort by Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'points',
                child: Row(
                  children: [
                    Icon(sortBy == 'points' ? Icons.check : Icons.stars, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sort by Points'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_order',
                child: Row(
                  children: [
                    Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 20),
                    const SizedBox(width: 8),
                    Text(ascending ? 'Ascending' : 'Descending'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter/Sort indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text(filter == 'all' ? 'All' : filter == 'pending' ? 'Pending' : 'Completed'),
                  backgroundColor: filter == 'all' 
                      ? Colors.grey.shade200 
                      : filter == 'pending' 
                          ? Colors.orange.shade100 
                          : Colors.green.shade100,
                ),
                Chip(
                  avatar: const Icon(Icons.sort, size: 16),
                  label: Text(sortBy == 'due_date' 
                      ? 'Due Date' 
                      : sortBy == 'priority' 
                          ? 'Priority'
                          : sortBy == 'points'
                              ? 'Points'
                              : 'Title'),
                  deleteIcon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  onDeleted: () {
                    setState(() {
                      ascending = !ascending;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filter == 'completed' 
                              ? Icons.check_circle_outline 
                              : Icons.task_alt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter == 'completed'
                              ? "No completed tasks yet"
                              : filter == 'pending'
                                  ? "No pending tasks"
                                  : "No tasks assigned",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final dueDate = task['due_date'] != null
                        ? DateTime.tryParse(task['due_date'])
                        : null;
                    final isOverdue = dueDate != null &&
                        dueDate.isBefore(DateTime.now()) &&
                        task['status_text'] != 'completed';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isOverdue ? Colors.red.shade300 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentTaskSubmission(
                                task: task,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & Priority Badge
                              Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(task['category']),
                                    size: 20,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task['priority']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task['priority'] ?? 'Medium',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Description
                              if (task['description_text'] != null && task['description_text'].toString().isNotEmpty)
                                Text(
                                  task['description_text'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              const SizedBox(height: 12),

                              // Info chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  // Due Date
                                  if (dueDate != null)
                                    Chip(
                                      avatar: Icon(
                                        isOverdue ? Icons.warning : Icons.calendar_today,
                                        size: 14,
                                        color: isOverdue ? Colors.red : Colors.blue,
                                      ),
                                      label: Text(
                                        '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isOverdue ? Colors.red : Colors.black87,
                                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      backgroundColor: isOverdue 
                                          ? Colors.red.shade50 
                                          : Colors.blue.shade50,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),

                                  // Points
                                  if (task['points'] != null)
                                    Chip(
                                      avatar: const Icon(Icons.stars, size: 14, color: Colors.amber),
                                      label: Text(
                                        '${task['points']} pts',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.amber.shade50,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),

                                  // Category
                                  Chip(
                                    label: Text(
                                      task['category'] ?? 'Task',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.purple.shade50,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),

                                  // Status
                                  Chip(
                                    avatar: Icon(
                                      task['status_text'] == 'completed'
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      size: 14,
                                      color: task['status_text'] == 'completed'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    label: Text(
                                      task['status_text'] == 'completed' ? 'Completed' : 'Pending',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: task['status_text'] == 'completed'
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),

                              // Overdue warning
                              if (isOverdue)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error, size: 16, color: Colors.red.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Overdue!',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}