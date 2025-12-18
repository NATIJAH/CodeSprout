import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherCompletedTask extends StatefulWidget {
  const TeacherCompletedTask({super.key});

  @override
  _TeacherCompletedTaskState createState() => _TeacherCompletedTaskState();
}

class _TeacherCompletedTaskState extends State<TeacherCompletedTask> {
  final supabase = Supabase.instance.client;
  Map<String, String> studentNames = {}; // uid → name mapping
  
  // Filter and sort options
  String sortBy = 'due_date'; // Options: 'due_date', 'title', 'completed_timestamp'
  bool ascending = false; // For date sorting, false = newest first

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final data = await supabase.from('profile_student').select('uid, name');
    final Map<String, String> map = {};
    for (var s in data) {
      map[s['uid'] as String] = s['name'] ?? '';
    }
    setState(() {
      studentNames = map;
    });
  }

  Future<List<Map<String, dynamic>>> fetchCompletedTasks() async {
    final data = await supabase
        .from('Tasks')
        .select()
        .eq('status_text', 'completed');
    
    List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(data);
    
    // Sort based on selected option
    tasks.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'due_date':
          final aDate = DateTime.tryParse(a['due_date'] ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b['due_date'] ?? '') ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;
        case 'title':
          comparison = (a['title'] ?? '').toString().compareTo((b['title'] ?? '').toString());
          break;
        case 'completed_timestamp':
          final aDate = DateTime.tryParse(a['completed_timestamp'] ?? '') ?? DateTime(1970);
          final bDate = DateTime.tryParse(b['completed_timestamp'] ?? '') ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Tasks"),
        actions: [
          // Sort/Filter Menu
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
                value: 'completed_timestamp',
                child: Row(
                  children: [
                    Icon(sortBy == 'completed_timestamp' ? Icons.check : Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sort by Completion Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'title',
                child: Row(
                  children: [
                    Icon(sortBy == 'title' ? Icons.check : Icons.title, size: 20),
                    const SizedBox(width: 8),
                    const Text('Sort by Title'),
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
          // Filter indicator chip
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.sort, size: 16),
                  label: Text(
                    sortBy == 'due_date' 
                        ? 'Due Date' 
                        : sortBy == 'completed_timestamp'
                            ? 'Completion Date'
                            : 'Title',
                  ),
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
              future: fetchCompletedTasks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!;

                if (tasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No completed tasks yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final studentName =
                        studentNames[task['student_uid']] ?? task['student_uid'];
                    
                    final completedDate = task['completed_timestamp'] != null
                        ? DateTime.tryParse(task['completed_timestamp'])
                        : null;
                    
                    final dueDate = task['due_date'] != null
                        ? DateTime.tryParse(task['due_date'])
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          task['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("👤 Assigned to: $studentName"),
                            if (dueDate != null)
                              Text("📅 Due: ${dueDate.toLocal().toString().split(' ')[0]}"),
                            if (completedDate != null)
                              Text(
                                "✅ Completed: ${completedDate.toLocal().toString().split(' ')[0]}",
                                style: const TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Optional: Show task details dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(task['title'] ?? 'Task Details'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Student: $studentName"),
                                  const SizedBox(height: 8),
                                  Text("Description: ${task['description_text'] ?? 'No description'}"),
                                  const SizedBox(height: 8),
                                  if (dueDate != null)
                                    Text("Due: ${dueDate.toLocal()}"),
                                  if (completedDate != null)
                                    Text("Completed: ${completedDate.toLocal()}"),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
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