/*import 'package:codesprout/screens/create_activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:codesprout/screens/teacher_chat.dart';
import 'package:codesprout/screens/teacher_dashboard.dart';
import 'package:codesprout/screens/teacher_mcq.dart';
import 'package:codesprout/screens/teacher_pdf.dart';
import 'package:codesprout/screens/teacher_profile.dart';
import 'package:codesprout/screens/teacher_task.dart';
import 'package:codesprout/screens/teacher_teaching_material.dart';
//import 'package:codesprout/screens/teacher_notification.dart';

//import 'notification_list.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  Widget _buildCard(BuildContext context, String title, String emoji, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36), // bigger emoji for 120x120
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15, // slightly bigger text
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      _buildCard(context, "Task", "📝", const TeacherTask()),
      _buildCard(context, "Materials", "📚", const TeacherTeachingMaterial()),
      _buildCard(context, "PDF", "📄", const TeacherPdf()),
      _buildCard(context, "MCQ", "❓", const TeacherMcq()),
      _buildCard(context, "Chat", "💬", const TeacherChat()),
      _buildCard(context, "Profile", "👤", const TeacherProfile()),
      //_buildCard(context, "Notification", "🔔", const TeacherNotification()),
      //_buildCard(context, "📅 Activities", Colors.green[300]!, const CreateActivityScreen()),
      // In both student_dashboard.dart and teacher_dashboard.dart
      _buildCard(context, "📅 Activities", Colors.green.shade400, const CreateActivityScreen()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff2f6ff),
      appBar: AppBar(
        title: const Text(
          "Teacher Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff5b7cff),
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row atas: 4 kotak
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: cards.sublist(0, 4).map((c) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: c,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // Row bawah: 3 kotak
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: cards.sublist(4).map((c) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: c,
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'teacher_task.dart';
import 'teacher_teaching_material.dart';
import 'teacher_pdf.dart';
import 'teacher_mcq.dart';
import 'teacher_chat.dart';
import 'teacher_profile.dart';
import 'login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('activities')
          .select()
          .eq('created_by', user.id)
          .order('date', ascending: true);
      
      setState(() {
        _activities = List<Map<String, dynamic>>.from(data ?? []);
      });
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout error: $e")),
      );
    }
  }

  void _showActivityForm() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController();
    final maxScoreController = TextEditingController(text: '100');
    String selectedCategory = 'Assignment';
    String selectedPriority = 'Medium';

    final categories = ['Meeting', 'Quiz', 'Assignment', 'Lab', 'Presentation', 'Testing', 'Review', 'Planning', 'Research'];
    final priorities = ['Low', 'Medium', 'High', 'Urgent'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Activity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:MM)',
                  border: OutlineInputBorder(),
                  hintText: '14:30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxScoreController,
                decoration: const InputDecoration(
                  labelText: 'Max Score',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value ?? 'Assignment';
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: priorities
                    .map((pri) => DropdownMenuItem(value: pri, child: Text(pri)))
                    .toList(),
                onChanged: (value) {
                  selectedPriority = value ?? 'Medium';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }

              try {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                await supabase.from('activities').insert({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'category': selectedCategory,
                  'priority': selectedPriority,
                  'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
                  'time': timeController.text,
                  'max_score': int.tryParse(maxScoreController.text) ?? 100,
                  'created_by': user.id,
                  'user_email': user.email,
                  'status': 'pending',
                  'created_at': DateTime.now().toIso8601String(),
                });

                Navigator.pop(ctx);
                await _loadActivities();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getActivitiesForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return _activities.where((act) => act['date'] == dateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {'title': "📝 Task", 'page': const TeacherTask()},
      {'title': "📚 Teaching", 'page': const TeacherTeachingMaterial()},
      {'title': "📄 PDF", 'page': const TeacherPdf()},
      {'title': "❓ MCQ", 'page': const TeacherMcq()},
      {'title': "💬 Chat", 'page': const TeacherChat()},
      {'title': "👤 Profile", 'page': const TeacherProfile()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff0f3f1),
      appBar: AppBar(
        title: const Text(
          "👨‍🏫 Teacher Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff7a9e8f),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Welcome message
              FutureBuilder(
                future: Supabase.instance.client.auth.getUser(),
                builder: (context, snapshot) {
                  String username = "Teacher";
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!.user;
                    if (user != null && user.email != null) {
                      username = user.email!.split('@').first;
                    }
                  }
                  
                  return Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Text(
                          "Welcome 👋, $username!",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3d38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Manage your activities and classes",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Grid of Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 100,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => card['page']),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            card['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // Calendar Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                          '📅 Activity Calendar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3d38),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showActivityForm,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff7a9e8f),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: const Color(0xff7a9e8f),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xffb8cfc5),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Activities for selected day
                    Text(
                      'Activities for ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3d38),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Stream.value(_getActivitiesForDay(_selectedDay)),
                      builder: (context, snapshot) {
                        final activities = _getActivitiesForDay(_selectedDay);
                        if (activities.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: const Text(
                              'No activities scheduled for this day',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(activity['title'] ?? 'Untitled'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity['description'] ?? ''),
                                    Text(
                                      'Time: ${activity['time'] ?? 'N/A'} | Category: ${activity['category'] ?? 'N/A'} | Max Score: ${activity['max_score'] ?? 100}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(activity['priority'] ?? 'Medium'),
                                  backgroundColor: _getPriorityColor(activity['priority']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Logout button
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Urgent':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}
