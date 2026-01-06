import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import 'student_task.dart';
import 'student_teaching_material.dart';
import 'student_exercise.dart';
import 'student_mcq.dart';
import 'student_profile.dart';
import 'activity_hub.dart';
import 'account_view.dart';
import 'login_screen.dart';
import 'student_support_page.dart';
import 'chat_list_screen.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/calendar_service.dart';
import '../widgets/notification_dropdown.dart';
import '../widgets/calendar_dropdown.dart';
import '../models/calendar_event_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final ChatService chatService = ChatService();
  final NotificationService notificationService = NotificationService();
  final CalendarService calendarService = CalendarService();
  final supabase = Supabase.instance.client;

  // Dashboard Stats
  int totalTasks = 0;
  int completedTasks = 0;
  int pendingTasks = 0;
  int totalExercises = 0;
  int totalSubmissions = 0;
  List<Map<String, dynamic>> recentActivities = [];
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoadingStats = true);
    
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // 1. Load Tasks Statistics
      final tasksData = await supabase.from('Tasks').select();
      final tasks = List<Map<String, dynamic>>.from(tasksData);
      
      int completed = 0;
      int pending = 0;
      
      for (var task in tasks) {
        final submission = await supabase
            .from('submissions')
            .select()
            .eq('task_id', task['id'])
            .eq('student_uid', currentUser.id)
            .maybeSingle();
        
        if (submission != null) {
          completed++;
        } else {
          pending++;
        }
      }

      // 2. Load PDF/Exercises Count
      final pdfData = await supabase
          .from('teacher_pdf')
          .select()
          .then((data) => data.length)
          .catchError((_) => 0);

      // 3. Load Submissions Count
      final submissionsData = await supabase
          .from('submissions')
          .select()
          .eq('student_uid', currentUser.id);
      final submissions = List<Map<String, dynamic>>.from(submissionsData);

      // 4. Load Recent Activities (last 3 tasks)
      List<Map<String, dynamic>> activities = [];
      for (var task in tasks.take(3)) {
        final submission = await supabase
            .from('submissions')
            .select()
            .eq('task_id', task['id'])
            .eq('student_uid', currentUser.id)
            .maybeSingle();
        
        activities.add({
          'title': task['title'] ?? 'Tugasan',
          'date': task['created_at'] ?? DateTime.now().toIso8601String(),
          'status': submission != null ? 'Selesai' : 'Dalam progress',
          'icon': _getCategoryIcon(task['category']),
          'color': submission != null 
              ? const Color(0xff8fad91) 
              : const Color(0xffd4a574),
          'dueDate': task['due_date'],
        });
      }

      setState(() {
        totalTasks = tasks.length;
        completedTasks = completed;
        pendingTasks = pending;
        totalExercises = pdfData;
        totalSubmissions = submissions.length;
        recentActivities = activities;
        isLoadingStats = false;
      });

    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => isLoadingStats = false);
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

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
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
      backgroundColor: const Color(0xfff4f6f0),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.eco, color: Color(0xff6b8e6e), size: 28);
              },
            ),
            const SizedBox(width: 12),
            const Text(
              "CodeSprout",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Color(0xff5a7a5c),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xfffdfefb),
        foregroundColor: const Color(0xff5a7a5c),
        actions: [
          const StudentCalendarDropdown(),
          const StudentNotificationDropdown(),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ViewProfilePage()),
                );
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff8fad91),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff8fad91), Color(0xffa8c5aa)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '"Kerana Tuhan Untuk Manusia"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 40,
                    height: 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Menu Pelajar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile(Icons.dashboard, "Papan Pemuka", null),
            _drawerTile(Icons.task, "Tugasan", const StudentTask()),
            _drawerTile(Icons.menu_book, "Bahan Pengajaran",
                const StudentTeachingMaterial()),
            _drawerTile(Icons.picture_as_pdf, "Latihan", StudentExercisePage()),
            if (currentUserId != null)
              _drawerTileWithBadge(
                  Icons.chat, "Perbualan", const ChatListScreen(), currentUserId)
            else
              _drawerTile(Icons.chat, "Perbualan", const ChatListScreen()),
            _drawerTile(Icons.help_outline, "Bantuan & Sokongan",
                const StudentSupportPage()),
            _drawerTile(Icons.settings, "Tetapan", const AccountView()),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xff6b8e6e)),
              title: const Text('Log Keluar'),
              onTap: () async => await _logout(context),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 900;

          return RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: const Color(0xff8fad91),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildMainContent(),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 350,
                          child: _buildUpcomingEvents(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMainContent(),
                        const SizedBox(height: 20),
                        _buildUpcomingEvents(),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoadingStats) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(64.0),
          child: CircularProgressIndicator(
            color: Color(0xff8fad91),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat Datang 👋",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff5a7a5c),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Plant the seed of success",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xff6b8e6e).withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stats Cards Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Tugasan",
                "$pendingTasks",
                "Belum selesai",
                Icons.task_alt,
                const Color(0xff8fad91),
                const Color(0xffa8c5aa),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                "Latihan",
                "$totalExercises",
                "Tersedia",
                Icons.quiz,
                const Color(0xffd4a574),
                const Color(0xffe8c9a8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Access Card
        _buildQuickAccessSection(),
        const SizedBox(height: 16),

        // Progress Card
        _buildProgressCard(),
        const SizedBox(height: 16),

        // Recent Activities
        _buildRecentActivities(),
        const SizedBox(height: 16),

        // Statistics Donut Chart
        _buildStatisticsChart(),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfffdfefb),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8fad91).withOpacity(0.1),
            blurRadius: 10,
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
                "Event Akan Datang",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff8fad91),
                    fontWeight: FontWeight.w600,
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
                      color: Color(0xff8fad91),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tiada event akan datang',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: event.colorValue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: event.colorValue,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: event.colorValue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${event.eventDate.day}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: event.colorValue,
                                ),
                              ),
                              Text(
                                months[event.eventDate.month - 1],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: event.colorValue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff5a7a5c),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.timeRange.isEmpty ? 'Sepanjang hari' : event.timeRange,
                                    style: TextStyle(
                                      fontSize: 12,
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
              );
            },
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xffa8c5aa)),
          const SizedBox(height: 12),
          
          _buildMiniCalendarPreview(),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarPreview() {
    final now = DateTime.now();
    final daysInWeek = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minggu Ini',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = startOfWeek.add(Duration(days: index));
            final isToday = day.day == now.day && 
                           day.month == now.month && 
                           day.year == now.year;
            
            return Column(
              children: [
                Text(
                  daysInWeek[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday 
                        ? const Color(0xff8fad91) 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday 
                            ? Colors.white 
                            : const Color(0xff5a7a5c),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle,
      IconData icon, Color color, Color lightColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffdfefb),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xff5a7a5c),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff8fad91), Color(0xffa8c5aa)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8fad91).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Akses Pantas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tekan untuk lihat tugasan dan latihan terkini anda",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentTask()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff5a7a5c),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Lihat Tugasan",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.eco,
            size: 80,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    // Calculate percentages
    final taskProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final submissionProgress = totalTasks > 0 ? totalSubmissions / totalTasks : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfffdfefb),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8fad91).withOpacity(0.1),
            blurRadius: 10,
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
                "Pencapaian Minggu Ini",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentTask()),
                  );
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    color: Color(0xff8fad91),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar("Tugasan Selesai", taskProgress, const Color(0xff8fad91)),
          const SizedBox(height: 12),
          _buildProgressBar("Latihan Tersedia", totalExercises > 0 ? 1.0 : 0.0, const Color(0xffa8c5aa)),
          const SizedBox(height: 12),
          _buildProgressBar("Penghantaran", submissionProgress, const Color(0xffd4a574)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfffdfefb),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8fad91).withOpacity(0.1),
            blurRadius: 10,
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
                "Aktiviti Terkini",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityHub()),
                  );
                },
                child: const Text(
                  "Lihat Semua",
                  style: TextStyle(
                    color: Color(0xff8fad91),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Tiada aktiviti terkini',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
                ),
            )
          else
            ...recentActivities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final dueDate = activity['dueDate'] != null 
                  ? DateTime.tryParse(activity['dueDate']) 
                  : null;
              final dueDateStr = dueDate != null
                  ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
                  : 'Tiada tarikh akhir';
              
              return Column(
                children: [
                  if (index > 0) const Divider(height: 24, color: Color(0xfff4f6f0)),
                  _buildActivityItem(
                    activity['title'],
                    dueDateStr,
                    activity['status'],
                    activity['color'],
                    activity['icon'],
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String date, String status, Color bgColor, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: bgColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff5a7a5c),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tarikh akhir: $date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bgColor.withOpacity(0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsChart() {
    // Calculate percentages
    final total = totalTasks + totalExercises + totalSubmissions;
    
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xfffdfefb),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff8fad91).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data statistik',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final taskPercentage = (totalTasks / total * 100).round();
    final exercisePercentage = (totalExercises / total * 100).round();
    final submissionPercentage = (totalSubmissions / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfffdfefb),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff8fad91).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistik Mengikut Kategori",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff5a7a5c),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: totalTasks.toDouble(),
                          color: const Color(0xff8fad91),
                          radius: 40,
                          title: '$taskPercentage%',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalExercises.toDouble(),
                          color: const Color(0xffd4a574),
                          radius: 40,
                          title: '$exercisePercentage%',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalSubmissions.toDouble(),
                          color: const Color(0xffa8c5aa),
                          radius: 40,
                          title: '$submissionPercentage%',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem("Tugasan", "$taskPercentage%", const Color(0xff8fad91)),
                      const SizedBox(height: 12),
                      _buildLegendItem("Latihan", "$exercisePercentage%", const Color(0xffd4a574)),
                      const SizedBox(height: 12),
                      _buildLegendItem("Penghantaran", "$submissionPercentage%", const Color(0xffa8c5aa)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _drawerTile(IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff8fad91)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }

  Widget _drawerTileWithBadge(
      IconData icon, String title, Widget page, String userId) {
    return StreamBuilder<int>(
      stream: chatService.getTotalUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: const Color(0xff8fad91)),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xffd4a574),
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
          title: Text(title),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
        );
      },
    );
  }
}

// Notification & Calendar Dropdowns remain the same...
class StudentNotificationDropdown extends StatefulWidget {
  const StudentNotificationDropdown({super.key});

  @override
  State<StudentNotificationDropdown> createState() => _StudentNotificationDropdownState();
}

class _StudentNotificationDropdownState extends State<StudentNotificationDropdown> {
  final NotificationService _notificationService = NotificationService();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx - 300 + size.width,
            top: offset.dy + size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 450),
                decoration: BoxDecoration(
                  color: const Color(0xfffdfefb),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _StudentNotificationPanel(
                  notificationService: _notificationService,
                  onClose: _closeDropdown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                _isOpen ? Icons.notifications : Icons.notifications_outlined,
                color: const Color(0xff6b8e6e),
              ),
              onPressed: _toggleDropdown,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xffd4a574),
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
        );
      },
    );
  }
}

class _StudentNotificationPanel extends StatelessWidget {
  final NotificationService notificationService;
  final VoidCallback onClose;

  const _StudentNotificationPanel({
    required this.notificationService,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xffa8c5aa), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await notificationService.markAllAsRead();
                    },
                    child: const Text(
                      'Tandai dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff8fad91),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
        Flexible(
          child: StreamBuilder(
            stream: notificationService.getNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: Color(0xff8fad91),
                    ),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 56,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tiada notifikasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length > 8 ? 8 : notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return InkWell(
                    onTap: () async {
                      if (!notification.isRead) {
                        await notificationService.markAsRead(notification.id);
                      }
                      onClose();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      color: notification.isRead 
                          ? Colors.transparent 
                          : const Color(0xfff4f6f0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(notification.colorValue).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: Color(notification.colorValue),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: notification.isRead 
                                              ? FontWeight.w500 
                                              : FontWeight.bold,
                                          color: const Color(0xff5a7a5c),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xff8fad91),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.timeAgo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'submission':
        return Icons.upload_file_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

class StudentCalendarDropdown extends StatefulWidget {
  const StudentCalendarDropdown({super.key});

  @override
  State<StudentCalendarDropdown> createState() => _StudentCalendarDropdownState();
}

class _StudentCalendarDropdownState extends State<StudentCalendarDropdown> {
  final CalendarService _calendarService = CalendarService();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx - 320 + size.width,
            top: offset.dy + size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black.withOpacity(0.15),
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 550),
                decoration: BoxDecoration(
                  color: const Color(0xfffdfefb),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _StudentCalendarPanel(
                  calendarService: _calendarService,
                  onClose: _closeDropdown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isOpen ? Icons.calendar_month : Icons.calendar_month_outlined,
        color: const Color(0xff6b8e6e),
      ),
      onPressed: _toggleDropdown,
    );
  }
}

class _StudentCalendarPanel extends StatefulWidget {
  final CalendarService calendarService;
  final VoidCallback onClose;

  const _StudentCalendarPanel({
    required this.calendarService,
    required this.onClose,
  });

  @override
  State<_StudentCalendarPanel> createState() => _StudentCalendarPanelState();
}

class _StudentCalendarPanelState extends State<_StudentCalendarPanel> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<CalendarEventModel>> _events = {};
  List<CalendarEventModel> _selectedDayEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    _events = await widget.calendarService.getEventsGroupedByDate(firstDay, lastDay);
    _selectedDayEvents = await widget.calendarService.getEventsByDate(_selectedDay);
    
    setState(() => _isLoading = false);
  }

  List<CalendarEventModel> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _StudentAddEventDialog(
        calendarService: widget.calendarService,
        selectedDate: _selectedDay,
        onEventAdded: _loadEvents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xffa8c5aa), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kalendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: const Color(0xff8fad91),
                    onPressed: _showAddEventDialog,
                    tooltip: 'Tambah Event',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TableCalendar<CalendarEventModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selected, focused) async {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _selectedDayEvents = await widget.calendarService.getEventsByDate(selected);
              setState(() {});
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEvents();
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xff8fad91),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xff8fad91).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xffd4a574),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xff5a7a5c),
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Color(0xff8fad91),
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Color(0xff8fad91),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              weekendStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((event) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: event.colorValue,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xffa8c5aa), width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatSelectedDate(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff5a7a5c),
                 ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff8fad91),
                    ),
                  ),
                )
              else if (_selectedDayEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tiada event',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedDayEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: event.colorValue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: event.colorValue,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (event.timeRange.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                event.timeRange,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSelectedDate() {
    final months = [
      'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
      'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember'
    ];
    return '${_selectedDay.day} ${months[_selectedDay.month - 1]} ${_selectedDay.year}';
  }
}

class _StudentAddEventDialog extends StatefulWidget {
  final CalendarService calendarService;
  final DateTime selectedDate;
  final VoidCallback onEventAdded;

  const _StudentAddEventDialog({
    required this.calendarService,
    required this.selectedDate,
    required this.onEventAdded,
  });

  @override
  State<_StudentAddEventDialog> createState() => _StudentAddEventDialogState();
}

class _StudentAddEventDialogState extends State<_StudentAddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _eventDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  String _selectedColor = '#8fad91';
  bool _isLoading = false;

  final List<String> _colorPresets = [
    '#8fad91', '#a8c5aa', '#d4a574', '#6b8e6e', '#e8c9a8',
    '#5a7a5c', '#FF6B6B', '#45B7D1', '#A29BFE', '#FD79A8',
  ];

  @override
  void initState() {
    super.initState();
    _eventDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final event = await widget.calendarService.createEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      eventDate: _eventDate,
      startTime: _isAllDay ? null : _startTime,
      endTime: _isAllDay ? null : _endTime,
      isAllDay: _isAllDay,
      color: _selectedColor,
      eventType: 'personal',
    );

    setState(() => _isLoading = false);

    if (event != null) {
      widget.onEventAdded();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berjaya ditambah'),
          backgroundColor: Color(0xff8fad91),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 550),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff8fad91), Color(0xffa8c5aa)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Tambah Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tajuk Event',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xff8fad91), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Sila masukkan tajuk';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Keterangan (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xff8fad91), width: 2),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _eventDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (date != null) {
                            setState(() => _eventDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tarikh',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_eventDate.day}/${_eventDate.month}/${_eventDate.year}'),
                              const Icon(Icons.calendar_today, size: 18, color: Color(0xff8fad91)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isAllDay,
                            onChanged: (value) {
                              setState(() => _isAllDay = value ?? false);
                            },
                            activeColor: const Color(0xff8fad91),
                          ),
                          const Text('Sepanjang hari'),
                        ],
                      ),
                      if (!_isAllDay) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() => _startTime = time);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Masa Mula',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _startTime?.format(context) ?? 'Pilih',
                                    style: TextStyle(
                                      color: _startTime != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setState(() => _endTime = time);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Masa Tamat',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _endTime?.format(context) ?? 'Pilih',
                                    style: TextStyle(
                                      color: _endTime != null ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Warna',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _colorPresets.map((color) {
                          final isSelected = _selectedColor == color;
                          final colorValue = Color(int.parse('FF${color.replaceAll('#', '')}', radix: 16));
                          return InkWell(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorValue,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8fad91),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
                