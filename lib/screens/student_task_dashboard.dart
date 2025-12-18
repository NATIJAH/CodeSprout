import 'package:flutter/material.dart';
import 'student_task_list.dart';

// This replaces student_task.dart - use this as the main entry point
class StudentTask extends StatelessWidget {
  const StudentTask({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly show the task list instead of "Coming Soon"
    return const StudentTaskList();
  }
}

// Enhanced dashboard with better UI
class StudentTaskDashboard extends StatelessWidget {
  const StudentTaskDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f6ff),
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff5b7cff),
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome message
              const Icon(
                Icons.school,
                size: 80,
                color: Color(0xff5b7cff),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome, Student!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage your tasks and submissions',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // View Tasks Button
              SizedBox(
                width: 280,
                height: 160,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentTaskList(),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xff5b7cff).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment,
                            size: 48,
                            color: Color(0xff5b7cff),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View & Submit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Quick stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}