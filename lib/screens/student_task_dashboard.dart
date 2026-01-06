// student_task.dart - Dashboard Entry Point
import 'package:flutter/material.dart';
import 'student_task_list.dart';

class StudentTask extends StatelessWidget {
  const StudentTask({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentTaskList();
  }
}

// Matcha Green Color Palette - Shared Constants
class MatchaColors {
  static const primary = Color(0xFF7C9473);
  static const light = Color(0xFFA8B99E);
  static const dark = Color(0xFF5A6C51);
  static const background = Color(0xFFF5F7F3);
  static const accent = Color(0xFFB8C5A8);
  static const surface = Colors.white;
}

class StudentTaskDashboard extends StatefulWidget {
  const StudentTaskDashboard({super.key});

  @override
  State<StudentTaskDashboard> createState() => _StudentTaskDashboardState();
}

class _StudentTaskDashboardState extends State<StudentTaskDashboard> {
  int _pendingCount = 0;
  int _completedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // TODO: Load actual stats from database
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _pendingCount = 5;
        _completedCount = 12;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: MatchaColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            backgroundColor: MatchaColors.surface,
            foregroundColor: MatchaColors.dark,
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: EdgeInsets.all(isWideScreen ? 48 : 24),
                child: Column(
                  children: [
                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            MatchaColors.primary.withOpacity(0.1),
                            MatchaColors.accent.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: MatchaColors.light.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: MatchaColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: MatchaColors.dark.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: MatchaColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: isWideScreen ? 32 : 28,
                              fontWeight: FontWeight.w700,
                              color: MatchaColors.dark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready to tackle your tasks today?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Stats Cards
                    _isLoading
                        ? const CircularProgressIndicator(color: MatchaColors.primary)
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatCard(
                                icon: Icons.pending_actions_outlined,
                                label: 'Pending Tasks',
                                count: _pendingCount,
                                color: const Color(0xFFE88D3D),
                                gradient: [
                                  const Color(0xFFE88D3D).withOpacity(0.1),
                                  const Color(0xFFE88D3D).withOpacity(0.05),
                                ],
                              ),
                              _buildStatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Completed',
                                count: _completedCount,
                                color: MatchaColors.primary,
                                gradient: [
                                  MatchaColors.primary.withOpacity(0.1),
                                  MatchaColors.primary.withOpacity(0.05),
                                ],
                              ),
                              _buildStatCard(
                                icon: Icons.emoji_events_outlined,
                                label: 'Total Tasks',
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

                    // Main Action Button
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Material(
                        color: Colors.transparent,
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
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: MatchaColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: MatchaColors.light.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: MatchaColors.dark.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: MatchaColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    size: 32,
                                    color: MatchaColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'View All Tasks',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: MatchaColors.dark,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Manage and submit your work',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: MatchaColors.light,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
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
}