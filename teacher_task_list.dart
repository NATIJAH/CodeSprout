import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'teacher_add_task.dart';
import 'teacher_edit_task.dart';
import 'teacher_completed_task.dart';

class TeacherTaskList extends StatefulWidget {
  const TeacherTaskList({super.key});

  @override
  _TeacherTaskListState createState() => _TeacherTaskListState();
}

class _TeacherTaskListState extends State<TeacherTaskList> {
  final supabase = Supabase.instance.client;
  Map<String, String> studentNames = {}; // uid → name mapping

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

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final data =
        await supabase.from('Tasks').select().eq('status_text', 'pending');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markTaskAsCompleted(Map<String, dynamic> task) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text('Mark "${task['title']}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('Tasks').update({
          'status_text': 'completed',
          'completed_timestamp': DateTime.now().toIso8601String(),
        }).eq('id', task['id']);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task marked as completed!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {}); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Task List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle),
            tooltip: 'View Completed Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherCompletedTask()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherAddTask()),
          ).then((_) => setState(() {})); // Refresh after adding
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTasks(),
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
                    "No pending tasks.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap + to create a new task",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.pending_actions, color: Colors.white),
                  ),
                  title: Text(
                    task['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Assigned to: $studentName\nDue: ${task['due_date'] ?? 'No due date'}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Complete button
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        tooltip: 'Mark as Complete',
                        onPressed: () => markTaskAsCompleted(task),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Task',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeacherEditTask(task: task),
                            ),
                          ).then((_) => setState(() {})); // Refresh after editing
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}