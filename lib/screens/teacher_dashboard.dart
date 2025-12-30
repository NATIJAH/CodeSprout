import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'teacher_task_list.dart';
import 'teacher_teaching_material.dart';
import 'teacher_exercise.dart';
import 'teacher_mcq.dart';
import 'teacher_profile.dart';
import 'activity_hub.dart';
import 'login_screen.dart';
import 'teacher_support_page.dart';
import 'chat_list_screen.dart';
import '../services/chat_service.dart';

// ============= NEW IMPORTS =============
import '../services/notification_service.dart';
import '../services/calendar_service.dart';
import '../widgets/notification_dropdown.dart';
import '../widgets/calendar_dropdown.dart';
import '../models/calendar_event_model.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final ChatService chatService = ChatService();
  final NotificationService notificationService = NotificationService(); // NEW
  final CalendarService calendarService = CalendarService(); // NEW
  final supabase = Supabase.instance.client;

  int totalAssignments = 0;
  int totalSubmissions = 0;
  int pendingReviews = 0;
  int completedTasks = 0;
  List<Map<String, dynamic>> recentAssignments = [];
  List<Map<String, dynamic>> recentSubmissions = [];
  Map<int, int> weeklySubmissions = {};
  bool isLoading = true;
  String teacherName = "Guru";

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get teacher profile
      try {
        final profileResponse = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', userId)
            .single();
        teacherName = profileResponse['full_name'] ?? 'Guru';
      } catch (e) {
        teacherName = 'Guru';
      }

      // Get total assignments created by teacher
      final assignmentsResponse = await supabase
          .from('tasks')
          .select()
          .eq('created_by', userId);
      totalAssignments = (assignmentsResponse as List).length;

      // Get total submissions
      final submissionsResponse = await supabase
          .from('submissions')
          .select('id');
      totalSubmissions = (submissionsResponse as List).length;

      // Get pending reviews (submitted but not done)
      final pendingResponse = await supabase
          .from('submissions')
          .select()
          .eq('status', 'submitted');
      pendingReviews = (pendingResponse as List).length;

      // Get completed tasks
      final completedResponse = await supabase
          .from('tasks')
          .select()
          .eq('status', 'completed')
          .eq('created_by', userId);
      completedTasks = (completedResponse as List).length;

      // Get recent 6 assignments with submission counts
      final recentTasksResponse = await supabase
          .from('tasks')
          .select('id, title, description, due_date, priority, status, created_at')
          .eq('created_by', userId)
          .order('created_at', ascending: false)
          .limit(6);

      recentAssignments = [];
      for (var task in recentTasksResponse) {
        final submissionCount = await supabase
            .from('submissions')
            .select()
            .eq('task_id', task['id']);

        recentAssignments.add({
          ...task,
          'submission_count': (submissionCount as List).length,
        });
      }

      // Get recent submissions for news feed
      final recentSubResponse = await supabase
          .from('submissions')
          .select('id, task_id, submitted_at, status')
          .order('submitted_at', ascending: false)
          .limit(8);

      recentSubmissions = [];
      for (var sub in recentSubResponse) {
        try {
          final taskInfo = await supabase
              .from('tasks')
              .select('title')
              .eq('id', sub['task_id'])
              .single();

          recentSubmissions.add({
            ...sub,
            'task_title': taskInfo['title'],
          });
        } catch (e) {
          recentSubmissions.add({
            ...sub,
            'task_title': 'Unknown Task',
          });
        }
      }

      // Get weekly submissions for chart (last 7 days)
      final now = DateTime.now();
      weeklySubmissions = {};
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final count = await supabase
            .from('submissions')
            .select()
            .gte('submitted_at', startOfDay.toIso8601String())
            .lt('submitted_at', endOfDay.toIso8601String());

        weeklySubmissions[i] = (count as List).length;
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = chatService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6B9B7F),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 12),
            const Text(
              "Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          
          // ============= NEW: Calendar Dropdown =============
          const CalendarDropdown(isTeacher: true),
          
          // ============= NEW: Notification Dropdown =============
          NotificationDropdown(
            onNotificationTap: () {
              // Optional: Handle notification tap navigation
            },
          ),
          
          // Profile button
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ViewTeacherProfilePage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(currentUserId),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B9B7F)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildWeeklyChart(),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 3,
                          child: _buildCompletionChart(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRecentAssignments(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    _buildLatestNews(),
                    const SizedBox(height: 20),
                    _buildUpcomingEvents(), // NEW: Ganti calendar widget lama
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting = "Selamat Pagi";
    String emoji = "🌅";

    if (hour >= 12 && hour < 15) {
      greeting = "Selamat Tengahari";
      emoji = "☀️";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat Petang";
      emoji = "🌤️";
    } else if (hour >= 18) {
      greeting = "Selamat Malam";
      emoji = "🌙";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$greeting, $teacherName! $emoji",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Selamat kembali ke papan pemuka anda. Berikut adalah ringkasan aktiviti terkini.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(String? currentUserId) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B9B7F), Color(0xFF4A7C59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 70),
                const SizedBox(height: 12),
                const Text(
                  "Kerana tuhan untuk manusia",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _drawerTile(Icons.dashboard, "Papan Pemuka", null),
          _drawerTile(Icons.task, "Tugasan", const TeacherTaskList()),
          _drawerTile(Icons.menu_book, "Bahan Pengajaran", const TeacherTeachingMaterial()),
          _drawerTile(Icons.picture_as_pdf, "Latihan", TeacherExercise()),
          if (currentUserId != null)
            _drawerTileWithBadge(Icons.chat, "Perbualan", const ChatListScreen(), currentUserId)
          else
            _drawerTile(Icons.chat, "Perbualan", const ChatListScreen()),
          _drawerTile(Icons.settings, "Tetapan", const TeacherMcq()),
          _drawerTile(Icons.support_agent, "Support", const TeacherSupportPage()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF6B9B7F)),
            title: const Text('Log Keluar'),
            onTap: () async => await _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _statCard(
            Icons.assignment_outlined,
            "Total Assignments",
            "$totalAssignments",
            const Color(0xFF66BB6A),
            "assignments created"
        )),
        const SizedBox(width: 16),
        Expanded(child: _statCard(
            Icons.upload_file_outlined,
            "Total Submissions",
            "$totalSubmissions",
            const Color(0xFF42A5F5),
            "submissions received"
        )),
        const SizedBox(width: 16),
        Expanded(child: _statCard(
            Icons.rate_review_outlined,
            "Pending Reviews",
            "$pendingReviews",
            const Color(0xFFFF9800),
            "awaiting review"
        )),
        const SizedBox(width: 16),
        Expanded(child: _statCard(
            Icons.check_circle_outline,
            "Completed",
            "$completedTasks",
            const Color(0xFF9C27B0),
            "tasks completed"
        )),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final maxValue = weeklySubmissions.values.isEmpty ? 10.0 : weeklySubmissions.values.reduce((a, b) => a > b ? a : b).toDouble();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B9B7F), Color(0xFF5A8A6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B9B7F).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Submissions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last 7 days activity',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Weekly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklySubmissions[6 - index] ?? 0;
                final height = maxValue > 0 ? (value / maxValue) * 140 : 20.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (value > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            color: Color(0xFF6B9B7F),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (value > 0) const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: height + 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      days[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart() {
    final total = totalAssignments > 0 ? totalAssignments : 1;
    final completionRate = (completedTasks / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Task Completion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overall progress',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: DonutChartPainter(percentage: completionRate / 100),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completionRate%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF66BB6A),
                        ),
                      ),
                      Text(
                        '$completedTasks/$totalAssignments',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFF66BB6A), 'Completed'),
              const SizedBox(width: 20),
              _legendItem(Colors.grey[300]!, 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAssignments() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Assignments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherTaskList()),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6B9B7F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recentAssignments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Tiada tugasan lagi',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentAssignments.map((task) {
              final submissionCount = task['submission_count'] ?? 0;
              final dueDate = task['due_date'] != null
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(task['due_date']))
                  : 'No due date';
              final priority = task['priority'] ?? 'Medium';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B9B7F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Color(0xFF6B9B7F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priority,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$submissionCount Submissions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        dueDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherTaskList()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        side: const BorderSide(color: Color(0xFF6B9B7F), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B9B7F),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLatestNews() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E7DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Submissions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 20),
          if (recentSubmissions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tiada submission lagi',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...recentSubmissions.map((sub) {
              final taskTitle = sub['task_title'] ?? 'Unknown Task';
              final submittedAt = sub['submitted_at'] != null
                  ? _timeAgo(DateTime.parse(sub['submitted_at']))
                  : 'Unknown time';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B9B7F), Color(0xFF5A8A6F)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            taskTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                submittedAt,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // ============= NEW: Upcoming Events Widget =============
  Widget _buildUpcomingEvents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Open calendar dropdown or navigate to full calendar
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B9B7F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<CalendarEventModel>>(
            future: calendarService.getUpcomingEvents(days: 7),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B9B7F),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tiada event akan datang',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: events.take(5).map((event) {
                  final months = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 
                                  'Jul', 'Ogos', 'Sep', 'Okt', 'Nov', 'Dis'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: event.colorValue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                          color: event.colorValue,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Date badge
                        Container(
                          width: 45,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: event.colorValue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${event.eventDate.day}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: event.colorValue,
                                ),
                              ),
                              Text(
                                months[event.eventDate.month - 1],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: event.colorValue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Event details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.timeRange.isEmpty ? 'All Day' : event.timeRange,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (event.eventType == 'student') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6B9B7F).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Student',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _drawerTile(IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B9B7F)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }

  Widget _drawerTileWithBadge(IconData icon, String title, Widget page, String userId) {
    return StreamBuilder<int>(
      stream: chatService.getTotalUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: const Color(0xFF6B9B7F)),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
        );
      },
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double percentage;

  DonutChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF66BB6A), const Color(0xFF43A047)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -90 * 3.14159 / 180,
      360 * percentage * 3.14159 / 180,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
